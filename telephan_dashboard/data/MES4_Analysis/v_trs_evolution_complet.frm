TYPE=VIEW
query=select cast(`fp`.`Start` as date) AS `Date_Jour`,round(sum(case when `fp`.`Error` = 0 then ifnull(`ro`.`WorkingTime`,0) else 0 end) / nullif(sum(timestampdiff(SECOND,`fp`.`PlannedStart`,`fp`.`PlannedEnd`)),0) * 100,2) AS `TRS_Journalier`,round(sum(case when `fp`.`Error` = 0 then 1 else 0 end) / count(0) * 100,1) AS `Qualite_Jour`,round(sum(ifnull(`ro`.`WorkingTime`,0)) / nullif(sum(timestampdiff(SECOND,`fp`.`Start`,`fp`.`End`)),0) * 100,1) AS `Performance_Jour` from (`mes4`.`tblfinorderpos` `fp` left join `mes4`.`tblresourceoperation` `ro` on(`fp`.`OpNo` = `ro`.`OpNo` and `fp`.`ResourceID` = `ro`.`ResourceID`)) where `fp`.`Start` is not null and `fp`.`End` is not null group by cast(`fp`.`Start` as date) order by cast(`fp`.`Start` as date) desc
md5=692f70b8aed5bb73e82760e8fef096b0
updatable=0
algorithm=0
definer_user=root
definer_host=localhost
suid=2
with_check_option=0
timestamp=0001769793204656193
create-version=2
source=SELECT \n    DATE(fp.Start) AS Date_Jour,\n    \n    \n    ROUND(\n        (\n            SUM(CASE WHEN fp.Error = 0 THEN IFNULL(ro.WorkingTime, 0) ELSE 0 END) \n            /\n            NULLIF(SUM(TIMESTAMPDIFF(SECOND, fp.PlannedStart, fp.PlannedEnd)), 0) \n        ) * 100\n    , 2) AS TRS_Journalier,\n\n    \n    ROUND(SUM(CASE WHEN fp.Error = 0 THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS Qualite_Jour,\n    ROUND(SUM(IFNULL(ro.WorkingTime, 0)) / NULLIF(SUM(TIMESTAMPDIFF(SECOND, fp.Start, fp.End)), 0) * 100, 1) AS Performance_Jour\n\nFROM \n    `mes4`.`tblfinorderpos` fp\nLEFT JOIN \n    `mes4`.`tblresourceoperation` ro ON fp.OpNo = ro.OpNo AND fp.ResourceID = ro.ResourceID\nWHERE \n    fp.Start IS NOT NULL \n    AND fp.End IS NOT NULL\nGROUP BY \n    DATE(fp.Start)\nORDER BY \n    Date_Jour DESC
client_cs_name=utf8mb3
connection_cl_name=utf8mb3_general_ci
view_body_utf8=select cast(`fp`.`Start` as date) AS `Date_Jour`,round(sum(case when `fp`.`Error` = 0 then ifnull(`ro`.`WorkingTime`,0) else 0 end) / nullif(sum(timestampdiff(SECOND,`fp`.`PlannedStart`,`fp`.`PlannedEnd`)),0) * 100,2) AS `TRS_Journalier`,round(sum(case when `fp`.`Error` = 0 then 1 else 0 end) / count(0) * 100,1) AS `Qualite_Jour`,round(sum(ifnull(`ro`.`WorkingTime`,0)) / nullif(sum(timestampdiff(SECOND,`fp`.`Start`,`fp`.`End`)),0) * 100,1) AS `Performance_Jour` from (`mes4`.`tblfinorderpos` `fp` left join `mes4`.`tblresourceoperation` `ro` on(`fp`.`OpNo` = `ro`.`OpNo` and `fp`.`ResourceID` = `ro`.`ResourceID`)) where `fp`.`Start` is not null and `fp`.`End` is not null group by cast(`fp`.`Start` as date) order by cast(`fp`.`Start` as date) desc
mariadb-version=101115
