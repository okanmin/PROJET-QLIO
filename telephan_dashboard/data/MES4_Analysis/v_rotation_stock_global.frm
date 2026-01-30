TYPE=VIEW
query=with Stock_Actuel as (select count(0) AS `Qte_Stock_Totale` from `mes4`.`tblbufferpos` where `mes4`.`tblbufferpos`.`PNo` > 0), Consommation_30J as (select count(0) AS `Qte_Conso_Mois` from `mes4`.`tblfinorderpos` where `mes4`.`tblfinorderpos`.`End` >= current_timestamp() - interval 30 day and `mes4`.`tblfinorderpos`.`Error` = 0)select `s`.`Qte_Stock_Totale` AS `Qte_Stock_Totale`,`c`.`Qte_Conso_Mois` AS `Qte_Conso_Mois`,case when `c`.`Qte_Conso_Mois` = 0 then 999 else round(`s`.`Qte_Stock_Totale` * 30 / `c`.`Qte_Conso_Mois`,1) end AS `Rotation_Stock_Jours`,case when `c`.`Qte_Conso_Mois` = 0 then \'Stock Dormant (Alerte)\' when `s`.`Qte_Stock_Totale` * 30 / `c`.`Qte_Conso_Mois` < 5 then \'Stock Critique (< 5j)\' when `s`.`Qte_Stock_Totale` * 30 / `c`.`Qte_Conso_Mois` > 45 then \'Sur-Stockage (> 45j)\' else \'Stock Sain\' end AS `Etat_Stock` from (`stock_actuel` `s` join `consommation_30j` `c`)
md5=049185a787f919cce5f788b81fb90f20
updatable=1
algorithm=0
definer_user=root
definer_host=localhost
suid=2
with_check_option=0
timestamp=0001769797203255919
create-version=2
source=WITH Stock_Actuel AS (\n    \n    SELECT COUNT(*) AS Qte_Stock_Totale\n    FROM `mes4`.`tblbufferpos`\n    WHERE PNo > 0 \n),\nConsommation_30J AS (\n    \n    SELECT COUNT(*) AS Qte_Conso_Mois\n    FROM `mes4`.`tblfinorderpos`\n    WHERE End >= DATE_SUB(NOW(), INTERVAL 30 DAY)\n      AND Error = 0 \n)\nSELECT \n    s.Qte_Stock_Totale,\n    c.Qte_Conso_Mois,\n    \n    \n    CASE \n        WHEN c.Qte_Conso_Mois = 0 THEN 999 \n        ELSE ROUND((s.Qte_Stock_Totale * 30) / c.Qte_Conso_Mois, 1)\n    END AS Rotation_Stock_Jours,\n    \n    \n    CASE \n        WHEN c.Qte_Conso_Mois = 0 THEN \'Stock Dormant (Alerte)\'\n        WHEN (s.Qte_Stock_Totale * 30) / c.Qte_Conso_Mois < 5 THEN \'Stock Critique (< 5j)\'\n        WHEN (s.Qte_Stock_Totale * 30) / c.Qte_Conso_Mois > 45 THEN \'Sur-Stockage (> 45j)\'\n        ELSE \'Stock Sain\'\n    END AS Etat_Stock\n\nFROM Stock_Actuel s\nCROSS JOIN Consommation_30J c
client_cs_name=utf8mb3
connection_cl_name=utf8mb3_general_ci
view_body_utf8=with Stock_Actuel as (select count(0) AS `Qte_Stock_Totale` from `mes4`.`tblbufferpos` where `mes4`.`tblbufferpos`.`PNo` > 0), Consommation_30J as (select count(0) AS `Qte_Conso_Mois` from `mes4`.`tblfinorderpos` where `mes4`.`tblfinorderpos`.`End` >= current_timestamp() - interval 30 day and `mes4`.`tblfinorderpos`.`Error` = 0)select `s`.`Qte_Stock_Totale` AS `Qte_Stock_Totale`,`c`.`Qte_Conso_Mois` AS `Qte_Conso_Mois`,case when `c`.`Qte_Conso_Mois` = 0 then 999 else round(`s`.`Qte_Stock_Totale` * 30 / `c`.`Qte_Conso_Mois`,1) end AS `Rotation_Stock_Jours`,case when `c`.`Qte_Conso_Mois` = 0 then \'Stock Dormant (Alerte)\' when `s`.`Qte_Stock_Totale` * 30 / `c`.`Qte_Conso_Mois` < 5 then \'Stock Critique (< 5j)\' when `s`.`Qte_Stock_Totale` * 30 / `c`.`Qte_Conso_Mois` > 45 then \'Sur-Stockage (> 45j)\' else \'Stock Sain\' end AS `Etat_Stock` from (`stock_actuel` `s` join `consommation_30j` `c`)
mariadb-version=101115
