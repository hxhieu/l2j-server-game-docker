#!/bin/sh

db_host=$1
db_port=$2
db_name=$3
db_user=$4
db_pass=$5
db_install_user=$6
db_install_pass=$7
srv_dir=$8
srv_component=$9

echo "Initializing database '$db_name' on server '$db_host:$db_port'..."

#database=$(mysql -h "$db_host" -P "$db_port" -u "$db_install_user" -p"$db_install_pass" -e "SHOW DATABASES;" | grep "$db_name")
#if [ "$database" = "$db_name" ]; then
#  echo "Database '$db_name' already exists. Proceeding..."
#  return 0
#fi

echo "Ensure DB '$db_name' does not exist..."
mysql -h "$db_host" -P "$db_port" -u "$db_install_user" -p"$db_install_pass" -e "DROP DATABASE IF EXISTS ``$db_name``;"
status=$?
if [ $status -ne 0 ]; then
  return 1
fi

echo "Create schema and intial data..."
java -jar "$L2J_DEPLOY_DIR/$L2JCLI_DIR/l2jcli.jar" db install -sql "$L2J_DEPLOY_DIR/$srv_dir/sql" -db "$db_name" -u "$db_install_user" -p "$db_install_pass" -m FULL -t "$srv_component" -c -mods -url "jdbc:mariadb://$db_host:$db_port"
status=$?
if [ $status -ne 0 ]; then
  return 1
fi

echo "Ensure user '$db_user' exists..."
mysql -h "$db_host" -P "$db_port" -u "$db_install_user" -p"$db_install_pass" -e "CREATE OR REPLACE USER '$db_user'@'%' IDENTIFIED BY '$db_pass';"
status=$?
if [ $status -ne 0 ]; then
  return 1
fi

echo "Grant privileges to '$db_user'..."
mysql -h "$db_host" -P "$db_port" -u "$db_install_user" -p"$db_install_pass" -e "GRANT ALL PRIVILEGES ON ``$db_name``.* TO '$db_user'@'%' IDENTIFIED BY '$db_pass';"
status=$?
if [ $status -ne 0 ]; then
  return 1
fi

echo "Flush privileges..."
mysql -h "$db_host" -P "$db_port" -u "$db_install_user" -p"$db_install_pass" -e "FLUSH PRIVILEGES;"
status=$?
if [ $status -ne 0 ]; then
  return 1
fi
