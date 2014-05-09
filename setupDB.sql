create user 'olio'@'%' identified by 'olio';
grant all privileges on *.* to 'olio'@'localhost' identified by 'olio' with grant option;
grant all privileges on *.* to 'olio'@'ip.address.of.frontend' identified by 'olio' with grant option;
create database olio;
use olio;
\. $FABAN_HOME/benchmarks/OlioDriver/bin/schema.sql
