#!/bin/sh

#Set month to previous month.  Specify end day and proper year.
YEAR="$(date +%Y)"
MONTH_STRING="$(date +%m)"
MONTH=$(($MONTH_STRING-1))

if [ "$MONTH" = 0 ]
then	
YEAR=$(($YEAR-1))
MONTH=12
fi

START_DAY="01"
END_DAY=$(date -d "$(($MONTH%12+1))/1 - 1 days" +%d)

REPORT_NAME="Acura_Impression_Share_Report_$YEAR-$MONTH.CSV"

SQL_COMMAND="Use l2tmediaprod; SELECT C.CliDealerCode as DealerCode, AC.ActiveClientsCliName as ClientName, CSR.CliSrcRepAccImpressionShare as ImpressionShare, CSR.CliSrcRepAccBudgetLost as ImpressionShareLostToBudget, AC.ActiveClientsGrossBudget, AC.ActiveClientsNetBudget
FROM Client as C, 
ClientSrcReport as CSR,
(SELECT ActiveClientsCliName, ActiveClientsCliId, ActiveClientsGrossBudget, ActiveClientsNetBudget FROM ActiveClients WHERE ActiveClientsYear in ($YEAR) and ActiveClientsMonth in ($MONTH) and ActiveClientsProgramId in (15) and ActiveClientsProductId in (9)) as AC
WHERE AC.ActiveClientsCliId = C.CliId and C.CliId = CSR.CliId and CSR.CliSrcReportDate = '$YEAR-$MONTH-$END_DAY' group by C.CliId order by AC.ActiveClientsCliName;"

mysql -h l2t-prod.c05stjy5a0lo.us-east-1.rds.amazonaws.com -u jtermaat -pl2tmapdb2017 -e "$SQL_COMMAND" | awk -F'\t' 'OFS=","  {print $1,$2,$3"%",$4"%","$"$5,"$"$6}' > $REPORT_NAME



