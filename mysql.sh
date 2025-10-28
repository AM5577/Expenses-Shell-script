#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER=/var/log/expense-script-logs
LOG_FILE=$( echo $0 | cut -d "." -f1 )
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

# Define MySQL root password
MYSQL_ROOT_PASSWORD="ExpenseApp@1"   

# create logs folders if do not exist

mkdir -p /var/log/expense-script-logs/

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 .. $R FAILURE $N"
        exit 1
    else
        echo -e "$@ ... $G SUCCESS $N"
    fi

}

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "Error: You must have sudo access to run this script"
        exit 1
    fi
}

echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf install -y https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm
VALIDATE $? "Installing MYSQL repo"

sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
VALIDATE $? "Installing MYSQL key"

dnf install mysql-community-server -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing MYSQL server"

systemctl enable --now mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Enabling MYSQL service"

systemctl start mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Starting MySQL server"

sleep 5

echo "==> Setting up root password..."
# Step 1: Connect using socket auth (works even when password isn’t set)
sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

echo "==> Cleaning up default users and test DB..."
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

echo "✅ MySQL root password set to ${MYSQL_ROOT_PASSWORD}"