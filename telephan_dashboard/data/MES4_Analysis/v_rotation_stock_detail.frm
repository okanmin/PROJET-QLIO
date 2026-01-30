TYPE=VIEW
query=select `bp`.`PNo` AS `Reference_Article`,count(`bp`.`PNo`) AS `Stock_Actuel`,(select count(0) from `mes4`.`tblfinorderpos` `fp` where `fp`.`PNo` = `bp`.`PNo` and `fp`.`End` >= current_timestamp() - interval 30 day and `fp`.`Error` = 0) AS `Conso_Mois`,round(count(`bp`.`PNo`) * 30 / nullif((select count(0) from `mes4`.`tblfinorderpos` `fp` where `fp`.`PNo` = `bp`.`PNo` and `fp`.`End` >= current_timestamp() - interval 30 day),0),1) AS `Jours_Couverture` from `mes4`.`tblbufferpos` `bp` where `bp`.`PNo` > 0 group by `bp`.`PNo` order by round(count(`bp`.`PNo`) * 30 / nullif((select count(0) from `mes4`.`tblfinorderpos` `fp` where `fp`.`PNo` = `bp`.`PNo` and `fp`.`End` >= current_timestamp() - interval 30 day),0),1) desc
md5=6c7b7f34f45b835e98b7a84b4f7f8523
updatable=0
algorithm=0
definer_user=root
definer_host=localhost
suid=2
with_check_option=0
timestamp=0001769793204747742
create-version=2
source=SELECT \n    bp.PNo AS Reference_Article,\n    \n    \n    COUNT(bp.PNo) AS Stock_Actuel,\n    \n    \n    (SELECT COUNT(*) \n     FROM `mes4`.`tblfinorderpos` fp \n     WHERE fp.PNo = bp.PNo \n       AND fp.End >= DATE_SUB(NOW(), INTERVAL 30 DAY)\n       AND fp.Error = 0\n    ) AS Conso_Mois,\n    \n    \n    ROUND(\n        (COUNT(bp.PNo) * 30) \n        / \n        NULLIF((SELECT COUNT(*) FROM `mes4`.`tblfinorderpos` fp WHERE fp.PNo = bp.PNo AND fp.End >= DATE_SUB(NOW(), INTERVAL 30 DAY)), 0)\n    , 1) AS Jours_Couverture\n\nFROM \n    `mes4`.`tblbufferpos` bp\nWHERE \n    bp.PNo > 0\nGROUP BY \n    bp.PNo\nORDER BY \n    Jours_Couverture DESC
client_cs_name=utf8mb3
connection_cl_name=utf8mb3_general_ci
view_body_utf8=select `bp`.`PNo` AS `Reference_Article`,count(`bp`.`PNo`) AS `Stock_Actuel`,(select count(0) from `mes4`.`tblfinorderpos` `fp` where `fp`.`PNo` = `bp`.`PNo` and `fp`.`End` >= current_timestamp() - interval 30 day and `fp`.`Error` = 0) AS `Conso_Mois`,round(count(`bp`.`PNo`) * 30 / nullif((select count(0) from `mes4`.`tblfinorderpos` `fp` where `fp`.`PNo` = `bp`.`PNo` and `fp`.`End` >= current_timestamp() - interval 30 day),0),1) AS `Jours_Couverture` from `mes4`.`tblbufferpos` `bp` where `bp`.`PNo` > 0 group by `bp`.`PNo` order by round(count(`bp`.`PNo`) * 30 / nullif((select count(0) from `mes4`.`tblfinorderpos` `fp` where `fp`.`PNo` = `bp`.`PNo` and `fp`.`End` >= current_timestamp() - interval 30 day),0),1) desc
mariadb-version=101115
