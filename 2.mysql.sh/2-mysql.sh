#!/bin/bash

#-----------------------------------------------
# MySQL Secure Installation Automation Script
# For Oracle Linux 9 / RHEL 9
#-----------------------------------------------

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER=/var/log/expense-script-logs
LOG_FILE=$(basename "$0" | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/${LOG_FILE}-${TIMESTAMP}.log"

MYSQL_ROOT_PASSWORD="ExpenseApp@1"

mkdir -p $LOGS_FOLDER

VALIDATE() {
  if [ $1 -ne 0 ]; then
    echo -e "$2 ... $R FAILURE $N"
    echo -e "Check log file: $LOG_FILE_NAME"
    exit 1
  else
    echo -e "$2 ... $G SUCCESS $N"
  fi
}

CHECK_ROOT() {
  if [ $USERID -ne 0 ]; then
    echo -e "$R Error: Run this script with sudo or as root. $N"
    exit 1
  fi
}

echo "Script started at: $TIMESTAMP" &>>$LOG_FILE_NAME
CHECK_ROOT

echo "==> Installing MySQL repo..."
dnf install -y https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm &>>$LOG_FILE_NAME
VALIDATE $? "Installing MySQL repository"

echo "==> Importing MySQL GPG key..."
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 &>>$LOG_FILE_NAME
VALIDATE $? "Importing MySQL GPG key"

echo "==> Installing MySQL server..."
dnf install -y mysql-community-server &>>$LOG_FILE_NAME
VALIDATE $? "Installing MySQL server"

echo "==> Enabling and starting MySQL service..."
systemctl enable --now mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Enabling and starting MySQL"

sleep 5

#----------------------------------------------------
# Set MySQL root password
#----------------------------------------------------
TEMP_PASS=$(sudo grep 'temporary password' /var/log/mysqld.log | tail -1 | awk '{print $NF}')

if [ -z "$TEMP_PASS" ]; then
  echo -e "$R ERROR: Could not find temporary MySQL root password in log. $N"
  exit 1
fi

echo "==> Setting up MySQL root password..."
mysql --connect-expired-password -uroot -p"$TEMP_PASS" \
  -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';" &>>$LOG_FILE_NAME
VALIDATE $? "Setting MySQL root password"

#----------------------------------------------------
# Secure MySQL installation manually (non-interactive)
#----------------------------------------------------
echo "==> Securing MySQL installation..."
mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<EOF &>>$LOG_FILE_NAME
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
UPDATE mysql.user SET host='localhost' WHERE user='root' AND host!='localhost';
FLUSH PRIVILEGES;
EOF
VALIDATE $? "Securing MySQL installation"

echo -e "$G✅ MySQL setup and security configuration completed successfully!$N"
echo "🔑 Root password: ${MYSQL_ROOT_PASSWORD}"
echo "📜 Logs saved to: $LOG_FILE_NAME"
