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


echo "============================================"
echo " 6. Detecting or resetting MySQL root password"
echo "============================================"

TEMP_PASS=$(sudo grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}' | tail -1 || true)

if [ -n "$TEMP_PASS" ]; then
  echo "→ Found temporary password; using it to set new password"
  sudo mysql --connect-expired-password -u root -p"${TEMP_PASS}" <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
EOF
else
  echo "→ No temporary password found; resetting root password using skip-grant-tables"
  sudo systemctl stop mysqld
  sudo mysqld_safe --skip-grant-tables &
  sleep 5
  sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
  sudo pkill mysqld || true
  sleep 3
  sudo systemctl start mysqld
fi

echo "============================================"
echo " 7. Securing MySQL"
echo "============================================"

sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

echo "============================================"
echo " ✅ MySQL Installation Completed Successfully"
echo " Root password: ${MYSQL_ROOT_PASSWORD}"
echo "============================================"