TYPE=VIEW
query=select `o`.`ONo` AS `Num_Commande`,cast(`o`.`End` as date) AS `Date_Fin_Commande`,date_format(`o`.`End`,\'%Y-%m\') AS `Mois`,timestampdiff(SECOND,`o`.`Start`,`o`.`End`) AS `Lead_Time_Total_Sec`,round(timestampdiff(SECOND,`o`.`Start`,`o`.`End`) / 60,1) AS `Lead_Time_Total_Min`,ifnull(sum(timestampdiff(SECOND,`fp`.`Start`,`fp`.`End`)),0) AS `Temps_Process_Sec`,case when timestampdiff(SECOND,`o`.`Start`,`o`.`End`) - ifnull(sum(timestampdiff(SECOND,`fp`.`Start`,`fp`.`End`)),0) < 0 then 0 else timestampdiff(SECOND,`o`.`Start`,`o`.`End`) - ifnull(sum(timestampdiff(SECOND,`fp`.`Start`,`fp`.`End`)),0) end AS `Temps_Attente_Sec` from (`mes4`.`tblorder` `o` left join `mes4`.`tblfinorderpos` `fp` on(`o`.`ONo` = `fp`.`ONo`)) where `o`.`Start` is not null and `o`.`End` is not null group by `o`.`ONo`
md5=af20dc2e7ac46ad97b25429a27aadc8d
updatable=0
algorithm=0
definer_user=root
definer_host=localhost
suid=2
with_check_option=0
timestamp=0001769793204685979
create-version=2
source=SELECT \n    o.ONo AS Num_Commande,\n    \n    \n    DATE(o.End) AS Date_Fin_Commande,\n    DATE_FORMAT(o.End, \'%Y-%m\') AS Mois,\n    \n    \n    \n    TIMESTAMPDIFF(SECOND, o.Start, o.End) AS Lead_Time_Total_Sec,\n    ROUND(TIMESTAMPDIFF(SECOND, o.Start, o.End) / 60, 1) AS Lead_Time_Total_Min,\n\n    \n    \n    \n    IFNULL(SUM(TIMESTAMPDIFF(SECOND, fp.Start, fp.End)), 0) AS Temps_Process_Sec,\n    \n    \n    \n    \n    CASE \n        WHEN (TIMESTAMPDIFF(SECOND, o.Start, o.End) - IFNULL(SUM(TIMESTAMPDIFF(SECOND, fp.Start, fp.End)), 0)) < 0 THEN 0\n        ELSE (TIMESTAMPDIFF(SECOND, o.Start, o.End) - IFNULL(SUM(TIMESTAMPDIFF(SECOND, fp.Start, fp.End)), 0))\n    END AS Temps_Attente_Sec\n\nFROM \n    `mes4`.`tblorder` o\n\nLEFT JOIN \n    `mes4`.`tblfinorderpos` fp ON o.ONo = fp.ONo\n\nWHERE \n    o.Start IS NOT NULL \n    AND o.End IS NOT NULL\n    \n    \n\nGROUP BY \n    o.ONo
client_cs_name=utf8mb3
connection_cl_name=utf8mb3_general_ci
view_body_utf8=select `o`.`ONo` AS `Num_Commande`,cast(`o`.`End` as date) AS `Date_Fin_Commande`,date_format(`o`.`End`,\'%Y-%m\') AS `Mois`,timestampdiff(SECOND,`o`.`Start`,`o`.`End`) AS `Lead_Time_Total_Sec`,round(timestampdiff(SECOND,`o`.`Start`,`o`.`End`) / 60,1) AS `Lead_Time_Total_Min`,ifnull(sum(timestampdiff(SECOND,`fp`.`Start`,`fp`.`End`)),0) AS `Temps_Process_Sec`,case when timestampdiff(SECOND,`o`.`Start`,`o`.`End`) - ifnull(sum(timestampdiff(SECOND,`fp`.`Start`,`fp`.`End`)),0) < 0 then 0 else timestampdiff(SECOND,`o`.`Start`,`o`.`End`) - ifnull(sum(timestampdiff(SECOND,`fp`.`Start`,`fp`.`End`)),0) end AS `Temps_Attente_Sec` from (`mes4`.`tblorder` `o` left join `mes4`.`tblfinorderpos` `fp` on(`o`.`ONo` = `fp`.`ONo`)) where `o`.`Start` is not null and `o`.`End` is not null group by `o`.`ONo`
mariadb-version=101115
