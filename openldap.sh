#!/usr/bin/env bash

sudo -s

## Install openldap

yum -y install openldap compat-openldap openldap-clients openldap-servers openldap-servers-sql openldap-devel
systemctl start slapd.service
systemctl enable slapd.service

cd /etc/openldap/

## Configure Openldap -- db.ldif

echo "dn: olcDatabase={2}hdb,cn=config" >> db.ldif
echo "changetype: modify" >> db.ldif
echo "replace: olcSuffix" >> db.ldif
echo "olcSuffix: dc=KingsLanding,dc=Westeros,dc=com" >> db.ldif
echo "" >> db.ldif
echo "dn: olcDatabase={2}hdb,cn=config" >> db.ldif
echo "changetype: modify" >> db.ldif
echo "replace: olcRootDN" >> db.ldif
echo "olcRootDN: cn=ldapadm,dc=KingsLanding,dc=Westeros,dc=com" >> db.ldif
echo "" >> db.ldif
echo "dn: olcDatabase={2}hdb,cn=config" >> db.ldif
echo "changetype: modify" >> db.ldif
echo "replace: olcRootPW" >> db.ldif
password=$(slappasswd -s WinterIsComing)
echo "olcRootPW: $password" >> db.ldif

## Configure Openldap -- base.ldif

echo "dn: dc=KingsLanding,dc=Westeros,dc=com"  >> base.ldif
echo "dc: KingsLanding" >> base.ldif
echo "objectClass: top" >> base.ldif
echo "objectClass: domain" >> base.ldif
echo ""  >> base.ldif
echo "dn: cn=ldapadm,dc=KingsLanding,dc=Westeros,dc=com" >> base.ldif
echo "objectClass: organizationalRole" >> base.ldif
echo "cn: ldapadm" >> base.ldif
echo "description: LDAP Manager" >> base.ldif
echo ""  >> base.ldif
echo "dn: ou=People,dc=KingsLanding,dc=Westeros,dc=com" >> base.ldif
echo "objectClass: organizationalUnit" >> base.ldif
echo "ou: People" >> base.ldif
echo "" >> base.ldif
echo "dn: ou=Group,dc=KingsLanding,dc=Westeros,dc=com" >> base.ldif
echo "objectClass: organizationalUnit" >> base.ldif
echo "ou: Group" >> base.ldif


## Configuure Openldap -- groups.ldif

echo "dn: cn=admin,ou=Group,dc=KingsLanding, dc=Westeros, dc=com" >> groups.ldif
echo "objectClass: top" >> groups.ldif
echo "objectClass: posixGroup" >> groups.ldif
echo "gidNumber: 1001" >> groups.ldif
echo "" >> groups.ldif
echo "dn: cn=oper,ou=Group,dc=KingsLanding, dc=Westeros, dc=com" >> groups.ldif
echo "objectClass: top" >> groups.ldif
echo "objectClass: posixGroup" >> groups.ldif
echo "gidNumber: 1002" >> groups.ldif

## Configure Openldap -- users.ldif

echo "dn: uid=Robert,ou=People,dc=KingsLanding, dc=Westeros, dc=com" >> users.ldif
echo "objectClass: top" >> users.ldif
echo "objectClass: person" >> users.ldif
echo "objectClass: shadowAccount" >> users.ldif
echo "cn: Robert" >> users.ldif
echo "sn: Baratheon" >> users.ldif
echo "uid: Robert" >> users.ldif
password=$(slappasswd -s Robert123)
echo "userPassword: $password" >> users.ldif
echo ""  >> users.ldif
echo "dn: uid=Theon,ou=People,dc=KingsLanding, dc=Westeros, dc=com" >> users.ldif
echo "objectClass: top" >> users.ldif
echo "objectClass: person" >> users.ldif
echo "objectClass: shadowAccount" >> users.ldif
echo "cn: Theon" >> users.ldif
echo "sn: Greyjoy" >> users.ldif
echo "uid: Theon" >> users.ldif
password=$(slappasswd -s Theon123)
echo "userPassword: $password" >> users.ldif

## Configure OpenLdap -- add users to groups

echo "dn: cn=admin,ou=Group,dc=KingsLanding,dc=Westeros,dc=com" >> userGroups.ldif
echo "changetype: modify" >> userGroups.ldif
echo "add: memberUid" >> userGroups.ldif
echo "memberUid: uid=Robert,ou=People,dc=KingsLanding,dc=Westeros,dc=com" >> userGroups.ldif
echo ""  >> userGroups.ldif
echo "dn: cn=oper,ou=Group,dc=KingsLanding,dc=Westeros,dc=com" >> userGroups.ldif
echo "changetype: modify" >> userGroups.ldif
echo "add: memberUid" >> userGroups.ldif
echo "memberUid: uid=Theon,ou=People,dc=KingsLanding,dc=Westeros,dc=com" >> userGroups.ldif

## Apply files to openldap config

ldapmodify -Y EXTERNAL -H ldapi:/// -f db.ldif
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown -R ldap:ldap /var/lib/ldap

ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
ldapadd -x -w WinterIsComing -D "cn=ldapadm,dc=KingsLanding,dc=Westeros,dc=com" -f base.ldif
ldapadd -x -w WinterIsComing -D "cn=ldapadm,dc=KingsLanding,dc=Westeros,dc=com" -f users.ldif
ldapadd -x -w WinterIsComing -D "cn=ldapadm,dc=KingsLanding,dc=Westeros,dc=com" -f groups.ldif
ldapadd -x -w WinterIsComing -D "cn=ldapadm,dc=KingsLanding,dc=Westeros,dc=com" -f userGroups.ldif


# Edit openldap acls 

echo "dn: olcDatabase={2}hdb,cn=config" >> access.ldif
echo "changetype: modify" >> access.ldif
echo "replace: olcAccess" >> access.ldif
echo "olcAccess: {0}to * by dn.base="dc=KingsLanding,dc=Westeros,dc=com" manage by * break" >> access.ldif
echo "olcAccess: {1}to attrs=userPassword by self write by anonymous auth" >> access.ldif
echo "olcAccess: {2}to dn.subtree="ou=People,dc=KingsLanding,dc=Westeros,dc=com" by self write by users read" >> access.ldif

ldapmodify -Y EXTERNAL -H ldapi:/// -f access.ldif
