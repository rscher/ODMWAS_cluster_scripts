connect reset;
create DB DCDB;
connect to DCDB;
CREATE BUFFERPOOL BP32K SIZE 2000 PAGESIZE 32K;
CREATE TABLESPACE RESDWTS PAGESIZE 32K BUFFERPOOL BP32K;
CREATE SYSTEM TEMPORARY TABLESPACE RESDWTMPTS PAGESIZE 32K BUFFERPOOL BP32K;
-- db2 GRANT BINDADD,CONNECT,CREATETAB,CREATE_EXTERNAL_ROUTINE,CREATE_NOT_FENCED_ROUTINE,IMPLICIT_SCHEMA,DBADM,LOAD,QUIESCE_CONNECT,SECADM ON DATABASE TO USER root
-- db2 GRANT BINDADD,CONNECT,CREATETAB,CREATE_EXTERNAL_ROUTINE,CREATE_NOT_FENCED_ROUTINE,IMPLICIT_SCHEMA,DBADM,LOAD,QUIESCE_CONNECT,SECADM ON DATABASE TO USER oracle 
connect reset;
