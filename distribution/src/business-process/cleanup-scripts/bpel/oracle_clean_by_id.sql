--
-- Important : Before you run this script, configure instance id, instance states and Data retention time period in STMT2 (line 44).
--
SET AUTOCOMMIT OFF;
SET SERVEROUTPUT ON
CREATE OR REPLACE
PROCEDURE CLEANINSTANCE AUTHID CURRENT_USER
IS
  STMT1  VARCHAR2(2048);
  STMT2  VARCHAR2(2048);
  STMT3  VARCHAR2(2048);
  STMT4  VARCHAR2(2048);
  STMT5  VARCHAR2(2048);
  STMT6  VARCHAR2(2048);
  STMT7  VARCHAR2(2048);
  STMT8  VARCHAR2(2048);
  STMT9  VARCHAR2(2048);
  STMT10 VARCHAR2(2048);
  STMT11 VARCHAR2(2048);
  STMT12 VARCHAR2(2048);
  STMT13 VARCHAR2(2048);
  STMT14 VARCHAR2(2048);
  STMT15 VARCHAR2(2048);
  STMT16 VARCHAR2(2048);
  STMT17 VARCHAR2(2048);
BEGIN
  DBMS_OUTPUT.PUT_LINE (' Start deleting instance data ');
  STMT1 := 'CREATE TABLE TEMP_CLEANUP(ID NUMBER)';
  EXECUTE IMMEDIATE STMT1;
  --
  -- stmt2 : Configure Followings before executing this script.
  --
  --      * Instance ID : Instance to be removed (ex: ID = 0)
  --      * Instance states : List of instance states, which need to be cleaned from the database. Followings are the instance states in BPS engine.
  --                           20  - Active.
  --                           30  - Completed.
  --                           40  - Completed with Fault.
  --                           50  - Suspended.
  --                           60  - Terminated.
  --      * Last Active Time : Last active time of the instances, which need to be cleaned from the database. .
  --                            Eg: (SYSTIMESTAMP - 1) will filter instances which are older than 1 day.
  --                            Eg: (SYSTIMESTAMP - 7) will filter instances which are older than 7 days.
  --
  STMT2 := 'INSERT INTO TEMP_CLEANUP(ID) SELECT ID FROM ODE_PROCESS_INSTANCE WHERE ID = 0 AND INSTANCE_STATE IN (30 , 40 , 60) AND LAST_ACTIVE_TIME < (SYSTIMESTAMP - 1)';
  EXECUTE IMMEDIATE STMT2;
  ---
  ----------------------------ODE_XML_DATA_LOBS---------------------------------------------------
  DBMS_OUTPUT.PUT_LINE (' Start cleanup of ODE_XML_DATA BLOBS ');
  EXECUTE IMMEDIATE 'ALTER TABLE "ODE_XML_DATA" ENABLE ROW MOVEMENT';
  DBMS_OUTPUT.PUT_LINE (' Set ODE_XML_DATA LOBs to null ');
  STMT3 := 'UPDATE ODE_XML_DATA SET ODE_XML_DATA.DATA = NULL WHERE SCOPE_ID IN (SELECT os.SCOPE_ID FROM ODE_SCOPE os WHERE os.PROCESS_INSTANCE_ID IN (SELECT ID FROM TEMP_CLEANUP))';
  EXECUTE IMMEDIATE STMT3;
  DBMS_OUTPUT.PUT_LINE (' Deleting from ODE_XML_DATA ');
  STMT4 := 'DELETE FROM ODE_XML_DATA WHERE SCOPE_ID IN (SELECT os.SCOPE_ID FROM ODE_SCOPE os WHERE os.PROCESS_INSTANCE_ID IN (SELECT ID FROM TEMP_CLEANUP))';
  EXECUTE IMMEDIATE STMT4;
  DBMS_OUTPUT.PUT_LINE (' Shrinking ODE_XML_DATA table');
  EXECUTE IMMEDIATE 'ALTER TABLE "ODE_XML_DATA" SHRINK SPACE CASCADE';
  --------------------------------------ODE_MESSAGE_LOBS---------------------------------------------------
  DBMS_OUTPUT.PUT_LINE (' Start cleanup of ODE_MESSAGE BLOBS ');
  EXECUTE IMMEDIATE 'ALTER TABLE "ODE_MESSAGE" ENABLE ROW MOVEMENT';
    DBMS_OUTPUT.PUT_LINE (' Set ODE_MESSAGE LOBs to null ');
  STMT5 := 'UPDATE ODE_MESSAGE SET ODE_MESSAGE.DATA = NULL, ODE_MESSAGE.HEADER = NULL WHERE MESSAGE_EXCHANGE_ID IN (SELECT mex.MESSAGE_EXCHANGE_ID FROM ODE_MESSAGE_EXCHANGE mex WHERE mex.PROCESS_INSTANCE_ID IN (SELECT ID FROM TEMP_CLEANUP))';
  EXECUTE IMMEDIATE STMT5;
  DBMS_OUTPUT.PUT_LINE (' Deleting from ODE_MESSAGE ');
  STMT6 := 'DELETE FROM ODE_MESSAGE WHERE MESSAGE_EXCHANGE_ID IN (SELECT mex.MESSAGE_EXCHANGE_ID FROM ODE_MESSAGE_EXCHANGE mex WHERE mex.PROCESS_INSTANCE_ID IN (SELECT ID FROM TEMP_CLEANUP))';
  EXECUTE IMMEDIATE STMT6;
  DBMS_OUTPUT.PUT_LINE (' Shrinking ODE_MESSAGE table');
  EXECUTE IMMEDIATE 'ALTER TABLE "ODE_MESSAGE" SHRINK SPACE CASCADE';
  ----------------------------------------------------ODE Events---------------------------------
  EXECUTE IMMEDIATE 'ALTER TABLE "ODE_EVENT" ENABLE ROW MOVEMENT';
  STMT7 :='DELETE FROM ODE_EVENT WHERE INSTANCE_ID IN (SELECT ID FROM TEMP_CLEANUP)';
  EXECUTE IMMEDIATE 'ALTER TABLE "ODE_EVENT" SHRINK SPACE CASCADE';
  ----------------------------------------------------OTHER---------------------------------
  EXECUTE IMMEDIATE STMT7;
  STMT8 :='DELETE FROM ODE_CORSET_PROP WHERE CORRSET_ID IN (SELECT cs.CORRELATION_SET_ID FROM ODE_CORRELATION_SET cs WHERE cs.SCOPE_ID IN (SELECT os.SCOPE_ID FROM ODE_SCOPE os WHERE  os.PROCESS_INSTANCE_ID IN (SELECT ID FROM TEMP_CLEANUP)))';
  EXECUTE IMMEDIATE STMT8;
  STMT9 :='DELETE FROM ODE_CORRELATION_SET WHERE SCOPE_ID IN (SELECT os.SCOPE_ID FROM ODE_SCOPE os WHERE os.PROCESS_INSTANCE_ID IN (SELECT ID FROM TEMP_CLEANUP))';
  EXECUTE IMMEDIATE STMT9;
  STMT10 := 'DELETE FROM ODE_PARTNER_LINK WHERE SCOPE_ID IN (SELECT os.SCOPE_ID FROM ODE_SCOPE os WHERE os.PROCESS_INSTANCE_ID IN (SELECT ID FROM TEMP_CLEANUP))';
  EXECUTE IMMEDIATE STMT10;
  STMT11 :='DELETE FROM ODE_XML_DATA_PROP WHERE XML_DATA_ID IN (SELECT xd.XML_DATA_ID FROM ODE_XML_DATA xd WHERE xd.SCOPE_ID IN (SELECT os.SCOPE_ID FROM ODE_SCOPE os WHERE os.PROCESS_INSTANCE_ID IN (SELECT ID FROM TEMP_CLEANUP)))';
  EXECUTE IMMEDIATE STMT11;
  STMT12 := 'DELETE FROM ODE_SCOPE WHERE PROCESS_INSTANCE_ID IN (SELECT ID FROM TEMP_CLEANUP)';
  EXECUTE IMMEDIATE STMT12;
  STMT13 := 'DELETE FROM ODE_MEX_PROP WHERE MEX_ID IN (SELECT mex.MESSAGE_EXCHANGE_ID FROM ODE_MESSAGE_EXCHANGE mex WHERE mex.PROCESS_INSTANCE_ID IN (SELECT ID FROM TEMP_CLEANUP))';
  EXECUTE IMMEDIATE STMT13;
  STMT14 := 'DELETE FROM ODE_MESSAGE_EXCHANGE WHERE PROCESS_INSTANCE_ID IN (SELECT ID FROM TEMP_CLEANUP)';
  EXECUTE IMMEDIATE STMT14;
  STMT15 := 'DELETE FROM ODE_MESSAGE_ROUTE WHERE PROCESS_INSTANCE_ID IN (SELECT ID FROM TEMP_CLEANUP)';
  EXECUTE IMMEDIATE STMT15;
  STMT16 := 'DELETE FROM ODE_PROCESS_INSTANCE WHERE ID IN (SELECT ID FROM TEMP_CLEANUP)';
  EXECUTE IMMEDIATE STMT16;
  DBMS_OUTPUT.PUT_LINE (' End deleting instance data ');
  STMT17 := 'DROP TABLE TEMP_CLEANUP';
  EXECUTE IMMEDIATE STMT17;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE (' Triggered Exception sequence. ');
    STMT17 := 'DROP TABLE TEMP_CLEANUP';
    EXECUTE IMMEDIATE STMT17;
    COMMIT;
END;
/
SET AUTOCOMMIT OFF;
BEGIN
  DBMS_OUTPUT.PUT_LINE (' Starting cleanInstance procedure');
  CLEANINSTANCE();
  DBMS_OUTPUT.PUT_LINE (' Ending cleanInstance procedure');
END;
/
SET AUTOCOMMIT ON;
