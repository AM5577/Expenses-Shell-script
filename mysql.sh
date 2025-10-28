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

systemctl enable mysqld
VALIDATE $? "Enabling MYSQL service" &>>$LOG_FILE_NAME

systemctl start mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Starting mysql server"

sleep 5

# Try to set root password without password first
mysql --user=root --skip-password -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'ExpenseApp@1';" &>>$LOG_FILE_NAME
VALIDATE $? "Setting up root password"


