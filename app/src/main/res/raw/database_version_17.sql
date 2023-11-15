-- DB Tidy, redundant views
DROP VIEW IF EXISTS alldata;
DROP VIEW IF EXISTS alldatax;
DROP VIEW IF EXISTS budget;

-- Nested Categories
-- https://github.com/moneymanagerex/moneymanagerex/issues/1477
CREATE TABLE TEMP_RENAME_CATEGORY(SOURCE integer primary key, TARGET integer not null);

INSERT INTO TEMP_RENAME_CATEGORY(SOURCE, TARGET)
SELECT SOURCE, TARGET
FROM
    (
    SELECT S.CATEGID as SOURCE, T.CATEGID as TARGET
    FROM
        (
        SELECT C.CATEGID, D.CATEGNAME
        FROM 
            (
            SELECT CATEGNAME 
            FROM CATEGORY_V1 
            GROUP BY CATEGNAME 
            HAVING COUNT(*) > 1
            ) AS D 
            INNER JOIN CATEGORY_V1 AS C
        ON C.CATEGNAME = D.CATEGNAME
        ) AS S
        INNER JOIN CATEGORY_V1 AS T
        ON S.CATEGNAME = T.CATEGNAME AND
        S.CATEGID > T.CATEGID
        GROUP BY SOURCE
        );

UPDATE CHECKINGACCOUNT_V1 SET CATEGID = (SELECT TARGET FROM TEMP_RENAME_CATEGORY WHERE SOURCE = CATEGID) WHERE CATEGID IN (SELECT SOURCE FROM TEMP_RENAME_CATEGORY);
UPDATE BILLSDEPOSITS_V1 SET CATEGID = (SELECT TARGET FROM TEMP_RENAME_CATEGORY WHERE SOURCE = CATEGID) WHERE CATEGID IN (SELECT SOURCE FROM TEMP_RENAME_CATEGORY);
UPDATE BUDGETSPLITTRANSACTIONS_V1 SET CATEGID = (SELECT TARGET FROM TEMP_RENAME_CATEGORY WHERE SOURCE = CATEGID) WHERE CATEGID IN (SELECT SOURCE FROM TEMP_RENAME_CATEGORY);
UPDATE SPLITTRANSACTIONS_V1 SET CATEGID = (SELECT TARGET FROM TEMP_RENAME_CATEGORY WHERE SOURCE = CATEGID) WHERE CATEGID IN (SELECT SOURCE FROM TEMP_RENAME_CATEGORY);
UPDATE BUDGETTABLE_V1 SET CATEGID = (SELECT TARGET FROM TEMP_RENAME_CATEGORY WHERE SOURCE = CATEGID) WHERE CATEGID IN (SELECT SOURCE FROM TEMP_RENAME_CATEGORY);
UPDATE PAYEE_V1 SET CATEGID = (SELECT TARGET FROM TEMP_RENAME_CATEGORY WHERE SOURCE = CATEGID) WHERE CATEGID IN (SELECT SOURCE FROM TEMP_RENAME_CATEGORY);
UPDATE SUBCATEGORY_V1 SET CATEGID = (SELECT TARGET FROM TEMP_RENAME_CATEGORY WHERE SOURCE = CATEGID) WHERE CATEGID IN (SELECT SOURCE FROM TEMP_RENAME_CATEGORY);

DELETE FROM CATEGORY_V1 WHERE CATEGID IN (SELECT SOURCE FROM TEMP_RENAME_CATEGORY);
DROP TABLE TEMP_RENAME_CATEGORY;
	
CREATE TABLE TEMP_RENAME_SUBCATEGORY(SOURCE integer primary key, TARGET integer not null);

INSERT INTO TEMP_RENAME_SUBCATEGORY(SOURCE, TARGET) 
SELECT SOURCE, TARGET 
FROM
    (
    SELECT S.SUBCATEGID as SOURCE, T.SUBCATEGID as TARGET
    FROM
    	(
    	SELECT S.SUBCATEGID, S.SUBCATEGNAME, S.CATEGID
        FROM SUBCATEGORY_V1 AS S 
        INNER JOIN 
            (
            SELECT SUBCATEGNAME, CATEGID 
            FROM SUBCATEGORY_V1 
            GROUP BY SUBCATEGNAME, CATEGID 
            HAVING COUNT(*) > 1
            ) AS D 
        ON S.SUBCATEGNAME = D.SUBCATEGNAME AND S.CATEGID = D.CATEGID
    	) as S
    	INNER JOIN SUBCATEGORY_V1 AS T
    	ON S.SUBCATEGNAME = T.SUBCATEGNAME AND
    	S.CATEGID = T.CATEGID AND
    	S.SUBCATEGID > T.SUBCATEGID
        GROUP BY SOURCE
        );

UPDATE CHECKINGACCOUNT_V1 SET SUBCATEGID = (SELECT TARGET FROM TEMP_RENAME_SUBCATEGORY WHERE SOURCE = SUBCATEGID) WHERE SUBCATEGID IN (SELECT SOURCE FROM TEMP_RENAME_SUBCATEGORY);
UPDATE BILLSDEPOSITS_V1 SET SUBCATEGID = (SELECT TARGET FROM TEMP_RENAME_SUBCATEGORY WHERE SOURCE = SUBCATEGID) WHERE SUBCATEGID IN (SELECT SOURCE FROM TEMP_RENAME_SUBCATEGORY);
UPDATE BUDGETSPLITTRANSACTIONS_V1 SET SUBCATEGID = (SELECT TARGET FROM TEMP_RENAME_SUBCATEGORY WHERE SOURCE = SUBCATEGID) WHERE SUBCATEGID IN (SELECT SOURCE FROM TEMP_RENAME_SUBCATEGORY);
UPDATE SPLITTRANSACTIONS_V1 SET SUBCATEGID = (SELECT TARGET FROM TEMP_RENAME_SUBCATEGORY WHERE SOURCE = SUBCATEGID) WHERE SUBCATEGID IN (SELECT SOURCE FROM TEMP_RENAME_SUBCATEGORY);
UPDATE BUDGETTABLE_V1 SET SUBCATEGID = (SELECT TARGET FROM TEMP_RENAME_SUBCATEGORY WHERE SOURCE = SUBCATEGID) WHERE SUBCATEGID IN (SELECT SOURCE FROM TEMP_RENAME_SUBCATEGORY);
UPDATE PAYEE_V1 SET SUBCATEGID = (SELECT TARGET FROM TEMP_RENAME_SUBCATEGORY WHERE SOURCE = SUBCATEGID) WHERE SUBCATEGID IN (SELECT SOURCE FROM TEMP_RENAME_SUBCATEGORY);

DELETE FROM SUBCATEGORY_V1 WHERE SUBCATEGID IN (SELECT SOURCE FROM TEMP_RENAME_SUBCATEGORY);
DROP TABLE TEMP_RENAME_SUBCATEGORY;

CREATE TABLE CATEGORY_V1_TEMP
( CATEGID INTEGER PRIMARY KEY,
  CATEGNAME TEXT NOT NULL COLLATE NOCASE,
  ACTIVE INTEGER,
  PARENTID INTEGER,
  UNIQUE(CATEGNAME, PARENTID)
);

INSERT INTO CATEGORY_V1_TEMP (CATEGID, CATEGNAME, ACTIVE, PARENTID)
  SELECT CATEGID, CATEGNAME, ACTIVE, '-1'
  FROM CATEGORY_V1;

INSERT INTO CATEGORY_V1_TEMP (CATEGID, CATEGNAME, ACTIVE, PARENTID)
SELECT (SUBCATEGID + (SELECT MAX(CATEGID) FROM CATEGORY_V1_TEMP)), 
	SUBCATEGNAME, ACTIVE, CATEGID
FROM SUBCATEGORY_V1; 

UPDATE CHECKINGACCOUNT_V1 SET CATEGID = SUBCATEGID + (SELECT MAX(CATEGID) FROM CATEGORY_V1) WHERE SUBCATEGID <> -1;
UPDATE BILLSDEPOSITS_V1 SET CATEGID = SUBCATEGID + (SELECT MAX(CATEGID) FROM CATEGORY_V1) WHERE SUBCATEGID <> -1;
UPDATE BUDGETSPLITTRANSACTIONS_V1 SET CATEGID = SUBCATEGID + (SELECT MAX(CATEGID) FROM CATEGORY_V1) WHERE SUBCATEGID <> -1;
UPDATE SPLITTRANSACTIONS_V1 SET CATEGID = SUBCATEGID + (SELECT MAX(CATEGID) FROM CATEGORY_V1) WHERE SUBCATEGID <> -1;
UPDATE BUDGETTABLE_V1 SET CATEGID = SUBCATEGID + (SELECT MAX(CATEGID) FROM CATEGORY_V1) WHERE SUBCATEGID <> -1;
UPDATE PAYEE_V1 SET CATEGID = SUBCATEGID + (SELECT MAX(CATEGID) FROM CATEGORY_V1) WHERE SUBCATEGID <> -1;

DROP TABLE CATEGORY_V1;					   
ALTER TABLE CATEGORY_V1_TEMP RENAME TO CATEGORY_V1;
CREATE INDEX IF NOT EXISTS IDX_CATEGORY_CATEGNAME ON CATEGORY_V1(CATEGNAME);
CREATE INDEX IF NOT EXISTS IDX_CATEGORY_CATEGNAME_PARENTID ON CATEGORY_V1(CATEGNAME, PARENTID);																							   

ALTER TABLE BILLSDEPOSITS_V1 DROP COLUMN SUBCATEGID; 
ALTER TABLE BUDGETSPLITTRANSACTIONS_V1 DROP COLUMN SUBCATEGID; 
ALTER TABLE BUDGETTABLE_V1 DROP COLUMN SUBCATEGID; 
ALTER TABLE CHECKINGACCOUNT_V1 DROP COLUMN SUBCATEGID; 
ALTER TABLE PAYEE_V1 DROP COLUMN SUBCATEGID; 
ALTER TABLE SPLITTRANSACTIONS_V1 DROP COLUMN SUBCATEGID; 

-- DB Tidy, redundant tables
DROP TABLE IF EXISTS ASSETCLASS_V1;
DROP TABLE IF EXISTS ASSETCLASS_STOCK_V1;
DROP TABLE IF EXISTS SUBCATEGORY_V1;
