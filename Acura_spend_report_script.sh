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


REPORT_NAME="Acura_Spend_Report_$YEAR-$MONTH.CSV"

SQL_COMMAND="use l2tmediaprod;
SELECT C.CliDealerCode, AC.ActiveClientsCliName, AC.ActiveClientsGrossBudget, AC.ActiveClientsNetBudget, SUM(SCR.SCSrcRepCost), AC.ActiveClientsProductName, SC.SubCampaignSrvBaseProduct, B.BudgetAmount
FROM SubCampaignSrcReport as SCR, SubCampaign as SC, DailyBudget as DB, Budget as B, Client as C,
(SELECT ActiveClientsCliName, ActiveClientsCampaignId, ActiveClientsGrossBudget, ActiveClientsNetBudget, ActiveClientsProductName, ActiveClientsCliId FROM ActiveClients WHERE ActiveClientsYear in ($YEAR) 
and ActiveClientsMonth in ($MONTH) and ActiveClientsProgramId in (15) and ActiveClientsProductId in (9)) as AC
WHERE SCR.CampaignID = SC.CampaignID 
and SCR.SubCampaignID = SC.SubCampaignID 
and AC.ActiveClientsCampaignID = SC.CampaignID 
and SCR.SCSrcRepSegmentType = 'DV'
and SCR.SCSrcRepDate >= '$YEAR-$MONTH-$START_DAY' 
and SCR.SCSrcRepDate <= '$YEAR-$MONTH-$END_DAY' 
and DB.DailyBudgetID = SC.DailyBudgetID 
and DB.BudgetId = B.BudgetId 
and AC.ActiveClientsCliId = C.CliId
group by AC.ActiveClientsCampaignID, SC.SubCampaignSrvBaseProduct order by AC.ActiveClientsCliName;"

mysql -h l2t-prod.c05stjy5a0lo.us-east-1.rds.amazonaws.com -u jtermaat -pl2tmapdb2017 -e "$SQL_COMMAND" \
| awk -F'\t' 'OFS=","{print $1,$2,$3,$4,$5,$6,$7,$8}' \
| awk -F',' 'OFS=","{if ($7 == "DDI") {print $1,$2,$3,$4,$8,$6,$7} else {print $1,$2,$3,$4,$5,$6,$7}}' \
| awk 'BEGIN {FS=OFS=","} \
NR==1 {print "Dealercode","Provider","Zone","Market","Account Name","Gross Budget","Net Budget","Spend","Search%","Display%","Dynamic Display%","Social Media%"} \
NR>1 \
{totalbudget[$1]+=$5;name[$1]=$2;grossbudget[$1]=$3;netbudget[$1]=$4;productname[$1]=$6;budgetforbaseproduct[$1$7]=$5;baseproductname[$1]=$7;a[$1]=$1} \
END \
{for (i in a) {print i,"L2TMedia","","",name[i],"$"grossbudget[i],"$"netbudget[i],"$"totalbudget[i],budgetforbaseproduct[i"PPC"]*100/totalbudget[i]"%",budgetforbaseproduct[i"DSP"]*100/totalbudget[i]"%",budgetforbaseproduct[i"DDI"]*100/totalbudget[i]"%",budgetforbaseproduct[i"SM"]*100/totalbudget[i]"%"} }' > $REPORT_NAME









