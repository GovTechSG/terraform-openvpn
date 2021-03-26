#!/bin/bash

set -eu
###
echo  '!!!!  INSTALL PACKAGES'
apt-get -y update && apt install -y awscli mysql-client libmysqlclient-dev jq

aws configure set default.region "${tf_aws_region}"

###
echo  '!!!!  SETUP VARS'
OPENVPN_HOSTNAME="${tf_openvpn_hostname}"
OPENVPN_POOL_IP="${tf_openvpn_pool_ip}"
DB_PASSWORD=$(/usr/bin/aws secretsmanager  get-secret-value --secret-id "${tf_rds_secret_arn}" | jq '.SecretString | fromjson.password' | sed -e 's/^"//' -e 's/"$//')
DB_USERNAME=$(/usr/bin/aws secretsmanager  get-secret-value --secret-id "${tf_rds_secret_arn}" | jq '.SecretString | fromjson.username' | sed -e 's/^"//' -e 's/"$//')
DB_FQND="${tf_rds_fqdn}"
MYSQL_PREF=/etc/.my.cnf
WEB_PORT="${tf_web_port}"
CONN_PORT="${tf_conn_port}"
PRIVATE_NETWORK_CIDRS="${tf_private_network_cidrs}"

###
echo  '!!!!  CONFIGURE MYSQL CLIENT PREFs FILE'
cat <<EOF > $${MYSQL_PREF}
[client]
user="$${DB_USERNAME}"
password="$${DB_PASSWORD}"
port=3306
host="$${DB_FQND}"
EOF

ln -s $${MYSQL_PREF} /root/.my.cnf

###
echo  '!!!!  CONFIGURE DATABASES'
systemctl stop openvpnas.service

pushd /usr/local/openvpn_as/scripts
for ITEM in certs user_prop config log cluster notification; do
  echo  "...  preparing $${ITEM} database and config"

  MYSQL_DB_NAME="as_$${ITEM}"
  LOCAL_DB_NAME=$(echo $${ITEM} | tr -d '_')
  LOCAL_DB_FILE="/usr/local/openvpn_as/etc/db/$${LOCAL_DB_NAME}.db"
  DB_KEY="$${ITEM}_db"

  #- set db configuration value
  sed -i "s|$${DB_KEY}=.*|$${DB_KEY}=mysql://$${DB_USERNAME}:$${DB_PASSWORD}@$${DB_FQND}/$${MYSQL_DB_NAME}|" /usr/local/openvpn_as/etc/as.conf

  #- create MySql DB
  mysql --defaults-file=$${MYSQL_PREF} -e "CREATE DATABASE IF NOT EXISTS $${MYSQL_DB_NAME};"

  if [ $ITEM != "cluster" ] && [ $ITEM != "notification" ]
  then
  #- import local DB schema into MySql if no tables exist
  mysql --defaults-file=$${MYSQL_PREF} --silent --skip-column-names \
  -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$${MYSQL_DB_NAME}';" \
  | grep -e ^0 -q \
  && ./dbcvt -t $${ITEM} -s sqlite:///$${LOCAL_DB_FILE} -d mysql://$${DB_FQND}/$${MYSQL_DB_NAME} -p $${MYSQL_PREF}
  fi
done
popd


### Cleanup unused softwares
echo  '!!!!  REMOVE UNUSED SOFTWARES'
apt-get remove -y awscli mysql-client jq

###
echo  '!!!!  RESTART OPENVPN'
systemctl restart openvpnas.service

###
echo  '!!!!  CONFIGURE OPENVPN DEFAULTS'
sleep 10
set -eux
pushd /usr/local/openvpn_as/scripts
./sacli --import GetActiveWebCerts
./sacli --key "host.name" --value "$${OPENVPN_HOSTNAME}" ConfigPut
./sacli --key "vpn.server.daemon.enable" --value "true" ConfigPut
./sacli --key "vpn.daemon.0.server.ip_address" --value "all" ConfigPut
./sacli --key "vpn.daemon.0.listen.ip_address" --value "all" ConfigPut
./sacli --key "vpn.server.daemon.udp.port" --value "1194" ConfigPut
./sacli --key "vpn.server.daemon.tcp.port" --value "$${CONN_PORT}" ConfigPut
./sacli --key "vpn.daemon.0.listen.protocol" --value "tcp" ConfigPut
./sacli --key "vpn.server.port_share.service" --value "client" ConfigPut
./sacli --key "vpn.server.daemon.tcp.n_daemons" --value "$(./sacli GetNCores)" ConfigPut
./sacli --key "vpn.server.daemon.udp.n_daemons" --value "$(./sacli GetNCores)" ConfigPut
./sacli --key "vpn.server.group_pool.0" --value "$${OPENVPN_POOL_IP}" ConfigPut
./sacli --key "vpn.server.google_auth.enable" --value "true" ConfigPut
./sacli --key "cs.https.ip_address" --value "all" ConfigPut
./sacli --key "cs.https.port" --value "$${WEB_PORT}" ConfigPut
./sacli --key "cs.tls_version_min" --value "1.2" ConfigPut
./sacli --key "vpn.server.tls_version_min" --value "1.2" ConfigPut

COUNT=0
IFS=', '
read -a strarr <<< "$PRIVATE_NETWORK_CIDRS"
for CIDR in "$${strarr[@]}"; do
printf -- "Adding private network cidr %s\n" "$${CIDR}"
./sacli --key "vpn.server.routing.private_network.$${COUNT}" --value "$${CIDR}" ConfigPut
COUNT=$((COUNT+1))
done

./sacli start
popd

###
echo  '!!!!  Finishing Touches'
rm /root/.my.cnf