TYPE=VIEW
query=select `op`.`Description` AS `Machine`,round(sum(timestampdiff(SECOND,`fp`.`Start`,`fp`.`End`)) / 3600,2) AS `Heures_Fonctionnement`,sum(timestampdiff(SECOND,`fp`.`Start`,`fp`.`End`) * ifnull(`ro`.`ElectricEnergy`,0)) AS `Conso_Elec_Totale`,sum(timestampdiff(SECOND,`fp`.`Start`,`fp`.`End`) * ifnull(`ro`.`CompressedAir`,0)) AS `Conso_Air_Total` from ((`mes4`.`tblfinorderpos` `fp` join `mes4`.`tbloperation` `op` on(`fp`.`OpNo` = `op`.`OpNo`)) left join `mes4`.`tblresourceoperation` `ro` on(`fp`.`OpNo` = `ro`.`OpNo` and `fp`.`ResourceID` = `ro`.`ResourceID`)) where `fp`.`Start` is not null and `fp`.`End` is not null group by `op`.`Description` order by sum(timestampdiff(SECOND,`fp`.`Start`,`fp`.`End`) * ifnull(`ro`.`ElectricEnergy`,0)) desc
md5=cdbbbfc44ab31c3e763c145d15c443a6
updatable=0
algorithm=0
definer_user=root
definer_host=localhost
suid=2
with_check_option=0
timestamp=0001769797203079805
create-version=2
source=SELECT \n    op.Description AS Machine,\n    \n    \n    ROUND(SUM(TIMESTAMPDIFF(SECOND, fp.Start, fp.End)) / 3600, 2) AS Heures_Fonctionnement,\n    \n    \n    \n    SUM(\n        TIMESTAMPDIFF(SECOND, fp.Start, fp.End) * IFNULL(ro.ElectricEnergy, 0)\n    ) AS Conso_Elec_Totale,\n    \n    \n    \n    SUM(\n        TIMESTAMPDIFF(SECOND, fp.Start, fp.End) * IFNULL(ro.CompressedAir, 0)\n    ) AS Conso_Air_Total\n\nFROM \n    `mes4`.`tblfinorderpos` fp\nJOIN \n    `mes4`.`tbloperation` op ON fp.OpNo = op.OpNo\n\nLEFT JOIN \n    `mes4`.`tblresourceoperation` ro ON fp.OpNo = ro.OpNo AND fp.ResourceID = ro.ResourceID\n\nWHERE \n    fp.Start IS NOT NULL AND fp.End IS NOT NULL\nGROUP BY \n    op.Description\nORDER BY \n    Conso_Elec_Totale DESC
client_cs_name=utf8mb3
connection_cl_name=utf8mb3_general_ci
view_body_utf8=select `op`.`Description` AS `Machine`,round(sum(timestampdiff(SECOND,`fp`.`Start`,`fp`.`End`)) / 3600,2) AS `Heures_Fonctionnement`,sum(timestampdiff(SECOND,`fp`.`Start`,`fp`.`End`) * ifnull(`ro`.`ElectricEnergy`,0)) AS `Conso_Elec_Totale`,sum(timestampdiff(SECOND,`fp`.`Start`,`fp`.`End`) * ifnull(`ro`.`CompressedAir`,0)) AS `Conso_Air_Total` from ((`mes4`.`tblfinorderpos` `fp` join `mes4`.`tbloperation` `op` on(`fp`.`OpNo` = `op`.`OpNo`)) left join `mes4`.`tblresourceoperation` `ro` on(`fp`.`OpNo` = `ro`.`OpNo` and `fp`.`ResourceID` = `ro`.`ResourceID`)) where `fp`.`Start` is not null and `fp`.`End` is not null group by `op`.`Description` order by sum(timestampdiff(SECOND,`fp`.`Start`,`fp`.`End`) * ifnull(`ro`.`ElectricEnergy`,0)) desc
mariadb-version=101115
