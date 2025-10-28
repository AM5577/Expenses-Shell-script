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

dnf install mysql-server -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing MYSQL server"

systemctl enable --now mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Enabling MYSQL service"

systemctl start mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Starting MySQL server"

sleep 5

echo "============================================"
echo " Securing MySQL Installation "
echo "============================================"
sudo mysql_secure_installation --set-root-pass "$MYSQL_ROOT_PASSWORD"

echo "============================================"
echo " MySQL Installation Completed Successfully "
echo " Root password: ${MYSQL_ROOT_PASSWORD}"
echo "============================================"