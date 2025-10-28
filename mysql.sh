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

# Get temporary password if available
TEMP_PASS=$(sudo grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}' | tail -1)

# Check if root uses auth_socket plugin (no password)
AUTH_PLUGIN=$(sudo mysql -Nse "SELECT plugin FROM mysql.user WHERE user='root' AND host='localhost';" 2>/dev/null)

if [[ "$AUTH_PLUGIN" == "auth_socket" ]]; then
    echo "Root user is using auth_socket — logging in without password..." &>>$LOG_FILE_NAME

    sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

elif [[ -n "$TEMP_PASS" ]]; then
    echo "Using temporary password to set new root password..." &>>$LOG_FILE_NAME

    mysql --connect-expired-password -u root -p"${TEMP_PASS}" <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
else
    echo "Could not determine root authentication method or temporary password!" &>>$LOG_FILE_NAME
    echo -e "$R Failed to secure MySQL root account $N"
    exit 1
fi

# Now login with new root password and secure MySQL
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOF

if [ $? -eq 0 ]; then
    echo -e "✅ MySQL secured successfully!"
else
    echo -e "❌ MySQL securing failed!"
    exit 1
fi
🧠 How It Works
Step	What It Does
Detects MySQL auth plugin	Figures out whether root uses password or socket auth
Uses proper login method	Either sudo mysql (for socket) or mysql -p<temp_password>
Sets root password	Always changes root to use mysql_native_password
Runs cleanup SQL	Removes anonymous users, disables remote root login, deletes test DB
Logs all actions	To /var/log/expense-script-logs/mysql-<timestamp>.log

🧪 To Run:
bash
Copy code
chmod +x mysql.sh
sudo ./mysql.sh
If you’d like, I can extend this script next to:

✅ Create a new database (expense_app)

✅ Create a dedicated app user (e.g. expense_user with password)

✅ Grant limited privileges

Would you like that included?







