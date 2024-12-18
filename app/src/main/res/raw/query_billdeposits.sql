WITH RECURSIVE categories(categid, categname, parentid) AS
    (SELECT a.categid, a.categname, a.parentid FROM category_v1 a WHERE parentid = '-1'
        UNION ALL
     SELECT c.categid, r.categname || ':' || c.categname, c.parentid
     FROM categories r, category_v1 c
	 WHERE r.categid = c.parentid
	 )
SELECT
    BILLSDEPOSITS_V1.BDID,
    BILLSDEPOSITS_V1.PAYEEID,
    PAYEE_V1.PAYEENAME,
    BILLSDEPOSITS_V1.TOACCOUNTID,
    TOACCOUNT.ACCOUNTNAME AS TOACCOUNTNAME,
    BILLSDEPOSITS_V1.ACCOUNTID,
    ACCOUNTLIST_V1.ACCOUNTNAME,
    ACCOUNTLIST_V1.CURRENCYID,
    NULL AS SUBCATEGNAME,
    categories.CATEGNAME AS CATEGNAME,
    BILLSDEPOSITS_V1.TRANSCODE,
    BILLSDEPOSITS_V1.TRANSAMOUNT,
    BILLSDEPOSITS_V1.NEXTOCCURRENCEDATE,
    BILLSDEPOSITS_V1.REPEATS,
    julianday(BILLSDEPOSITS_V1.NEXTOCCURRENCEDATE) - julianday(date('now')) AS DAYSLEFT,
    BILLSDEPOSITS_V1.NOTES,
    BILLSDEPOSITS_V1.STATUS,
    BILLSDEPOSITS_V1.NUMOCCURRENCES,
    BILLSDEPOSITS_V1.TOTRANSAMOUNT,
    BILLSDEPOSITS_V1.TRANSACTIONNUMBER,
    BILLSDEPOSITS_V1.TRANSDATE,
    ATT.ATTACHMENTCOUNT AS ATTACHMENTCOUNT,
    ( CASE BILLSDEPOSITS_V1.TRANSCODE WHEN 'Withdrawal' THEN -1 ELSE 1 END ) * BILLSDEPOSITS_V1.TRANSAMOUNT AS AMOUNT,
    Tags.Tags as TAGS
FROM BILLSDEPOSITS_V1 
    JOIN ACCOUNTLIST_V1 ON BILLSDEPOSITS_V1.ACCOUNTID = ACCOUNTLIST_V1.ACCOUNTID
    LEFT OUTER JOIN PAYEE_V1 ON BILLSDEPOSITS_V1.PAYEEID = PAYEE_V1.PAYEEID
    LEFT OUTER JOIN ACCOUNTLIST_V1 TOACCOUNT ON BILLSDEPOSITS_V1.TOACCOUNTID = TOACCOUNT.ACCOUNTID
    LEFT OUTER JOIN categories ON BILLSDEPOSITS_V1.CATEGID = categories.CATEGID
    LEFT JOIN (
        select REFID, count(*) as ATTACHMENTCOUNT
        from ATTACHMENT_V1
        where REFTYPE = 'RecurringTransaction'
        group by REFID
    ) AS ATT on BILLSDEPOSITS_V1.BDID = ATT.REFID
    LEFT JOIN (
        select Transid, Tags from (
        SELECT TRANSACTIONID as Transid,
               group_concat(TAGNAME) AS Tags
        FROM (SELECT TAGLINK_V1.REFID as TRANSACTIONID, TAG_V1.TAGNAME
              FROM TAGLINK_V1 inner join TAG_V1 on TAGLINK_V1.TAGID = TAG_V1.TAGID
              where REFTYPE = "RecurringTransaction" and ACTIVE = 1
              ORDER BY REFID, TAGNAME)
        GROUP BY TRANSACTIONID)
    ) as TAGS on BILLSDEPOSITS_V1.BDID = TAGS.Transid
