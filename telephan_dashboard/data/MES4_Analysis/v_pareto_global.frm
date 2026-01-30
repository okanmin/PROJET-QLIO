TYPE=VIEW
query=select `sous_requete`.`Categorie` AS `Categorie`,`sous_requete`.`Quantite` AS `Quantite`,sum(`sous_requete`.`Quantite`) over ( order by `sous_requete`.`Quantite` desc) AS `Cumul_Quantite`,sum(`sous_requete`.`Quantite`) over () AS `Total_General`,round(sum(`sous_requete`.`Quantite`) over ( order by `sous_requete`.`Quantite` desc) / sum(`sous_requete`.`Quantite`) over () * 100,2) AS `Pourcentage_Courbe` from (select case when `fp`.`Error` = 0 then \'Opération Conforme (OK)\' else `e`.`Description` end AS `Categorie`,count(0) AS `Quantite` from (`mes4`.`tblfinorderpos` `fp` left join `mes4`.`tblerrorcodes` `e` on(`fp`.`Error` = `e`.`ErrorId`)) group by case when `fp`.`Error` = 0 then \'Opération Conforme (OK)\' else `e`.`Description` end) `Sous_Requete` order by `sous_requete`.`Quantite` desc
md5=c68409e53609263454bd9d38f70cd1b0
updatable=0
algorithm=0
definer_user=root
definer_host=localhost
suid=2
with_check_option=0
timestamp=0001769797203050959
create-version=2
source=SELECT \n    Categorie,\n    Quantite,\n    \n    \n    SUM(Quantite) OVER (ORDER BY Quantite DESC) AS Cumul_Quantite,\n    \n    \n    SUM(Quantite) OVER () AS Total_General,\n    \n    \n    ROUND(\n        (SUM(Quantite) OVER (ORDER BY Quantite DESC) / SUM(Quantite) OVER ()) * 100, \n        2\n    ) AS Pourcentage_Courbe\n\nFROM (\n    \n    SELECT \n        CASE \n            WHEN fp.Error = 0 THEN \'Opération Conforme (OK)\'\n            ELSE e.Description\n        END AS Categorie,\n        COUNT(*) AS Quantite\n    FROM \n        `mes4`.`tblfinorderpos` fp\n    LEFT JOIN \n        `mes4`.`tblerrorcodes` e ON fp.Error = e.ErrorId\n    GROUP BY \n        CASE \n            WHEN fp.Error = 0 THEN \'Opération Conforme (OK)\'\n            ELSE e.Description\n        END\n    \n) AS Sous_Requete\n\nORDER BY \n    Quantite DESC
client_cs_name=utf8mb3
connection_cl_name=utf8mb3_general_ci
view_body_utf8=select `sous_requete`.`Categorie` AS `Categorie`,`sous_requete`.`Quantite` AS `Quantite`,sum(`sous_requete`.`Quantite`) over ( order by `sous_requete`.`Quantite` desc) AS `Cumul_Quantite`,sum(`sous_requete`.`Quantite`) over () AS `Total_General`,round(sum(`sous_requete`.`Quantite`) over ( order by `sous_requete`.`Quantite` desc) / sum(`sous_requete`.`Quantite`) over () * 100,2) AS `Pourcentage_Courbe` from (select case when `fp`.`Error` = 0 then \'Opération Conforme (OK)\' else `e`.`Description` end AS `Categorie`,count(0) AS `Quantite` from (`mes4`.`tblfinorderpos` `fp` left join `mes4`.`tblerrorcodes` `e` on(`fp`.`Error` = `e`.`ErrorId`)) group by case when `fp`.`Error` = 0 then \'Opération Conforme (OK)\' else `e`.`Description` end) `Sous_Requete` order by `sous_requete`.`Quantite` desc
mariadb-version=101115
