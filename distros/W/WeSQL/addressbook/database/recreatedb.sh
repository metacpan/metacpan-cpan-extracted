#!/bin/sh
# replace 'test' with the real password of the MySQL root account, or use another account and password
mysqladmin -ptest -uroot drop addressbook -f
mysqladmin -ptest -uroot create addressbook -f
cat recreate_tables.sql | mysql -ptest -uroot addressbook
cat startdata.sql | mysql -ptest -uroot addressbook
