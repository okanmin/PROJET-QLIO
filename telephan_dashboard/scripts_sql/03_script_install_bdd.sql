DROP DATABASE IF EXISTS `MES4_Analysis`;
-- 1. Création de la base d'analyse
CREATE DATABASE IF NOT EXISTS `MES4_Analysis`;
USE `MES4_Analysis`;

-- ==============================================================================
-- VUE 1 (Version Complète) : PARETO GLOBAL (SUCCÈS + ERREURS)
-- Objectif : Classer tous les résultats (OK et KO) par volume.
-- ==============================================================================
CREATE OR REPLACE VIEW `V_Pareto_Global` AS
SELECT 
    Categorie,
    Quantite,
    
    -- Calcul du cumul progressif
    SUM(Quantite) OVER (ORDER BY Quantite DESC) AS Cumul_Quantite,
    
    -- Calcul du total général
    SUM(Quantite) OVER () AS Total_General,
    
    -- Calcul du pourcentage pour la courbe
    ROUND(
        (SUM(Quantite) OVER (ORDER BY Quantite DESC) / SUM(Quantite) OVER ()) * 100, 
        2
    ) AS Pourcentage_Courbe

FROM (
    -- DÉBUT DE LA SOUS-REQUÊTE (Remplace le WITH)
    SELECT 
        CASE 
            WHEN fp.Error = 0 THEN 'Opération Conforme (OK)'
            ELSE e.Description
        END AS Categorie,
        COUNT(*) AS Quantite
    FROM 
        `mes4`.`tblfinorderpos` fp
    LEFT JOIN 
        `mes4`.`tblerrorcodes` e ON fp.Error = e.ErrorId
    GROUP BY 
        CASE 
            WHEN fp.Error = 0 THEN 'Opération Conforme (OK)'
            ELSE e.Description
        END
    -- FIN DE LA SOUS-REQUÊTE
) AS Sous_Requete

ORDER BY 
    Quantite DESC;

USE `MES4_Analysis`;

-- ==============================================================================
-- VUE 2 (Finale) : CONSOMMATION ÉNERGÉTIQUE RÉELLE
-- Calcul : Temps de fonctionnement (Secondes) * Facteur de consommation (Table)
-- A RETRAVAILLER !!!!!!!
-- ==============================================================================
CREATE OR REPLACE VIEW `V_Conso_Energetique_Reelle` AS
SELECT 
    res.ResourceName AS Machine, -- On récupère le vrai nom de la machine (ex: Robotino, Station A)
    
    -- Temps total de fonctionnement en HEURES (Indicateur de charge)
    ROUND(SUM(TIMESTAMPDIFF(SECOND, fp.Start, fp.End)) / 3600, 2) AS Heures_Fonctionnement,
    
    -- 1. CONSOMMATION ÉLECTRIQUE
    -- Temps (en secondes) multiplié par la conso électrique spécifique de cette machine pour cette opération
    SUM(
        TIMESTAMPDIFF(SECOND, fp.Start, fp.End) * IFNULL(ro.ElectricEnergy, 0)
    ) AS Conso_Elec_Totale,
    
    -- 2. CONSOMMATION AIR COMPRIMÉ
    -- Temps (en secondes) multiplié par la conso pneumatique
    SUM(
        TIMESTAMPDIFF(SECOND, fp.Start, fp.End) * IFNULL(ro.CompressedAir, 0)
    ) AS Conso_Air_Total

FROM 
    `mes4`.`tblfinorderpos` fp
-- CHANGEMENT ICI : On joint la table des Ressources (Machines) au lieu des Opérations
JOIN 
    `mes4`.`tblresource` res ON fp.ResourceID = res.ResourceID
-- On garde cette jointure qui contient les paramètres énergétiques du couple (Machine + Opération)
LEFT JOIN 
    `mes4`.`tblresourceoperation` ro ON fp.OpNo = ro.OpNo AND fp.ResourceID = ro.ResourceID

WHERE 
    fp.Start IS NOT NULL AND fp.End IS NOT NULL
-- CHANGEMENT ICI : On groupe par le nom de la machine
GROUP BY 
    res.ResourceName
ORDER BY 
    Conso_Elec_Totale DESC;

USE `MES4_Analysis`;

-- ==============================================================================
-- VUE 3 : SYSTÈME D'ALERTE (KPI avec Seuils)
-- Objectif : Transformer les chiffres en un statut visuel (Vert/Orange/Rouge)
--            pour le tableau de bord de supervision.
-- ==============================================================================
CREATE OR REPLACE VIEW `V_Alerte_Supervision_Journaliere` AS
SELECT 
    sub.Date_Jour,
    sub.Machine,
    
    -- KPI 1 : Quantité (Base de l'alerte)
    COUNT(*) AS Nb_Micro_Arrets,
    
    -- KPI 2 : Temps perdu (Minutes)
    ROUND(SUM(sub.Duree_Arret_Sec)/60, 1) AS Minutes_Perdues,
    
    -- KPI 3 : NIVEAU D'ALERTE (Calculé par jour)
    CASE 
        WHEN COUNT(*) >= 15 THEN 'CRITIQUE 🔴'
        WHEN COUNT(*) >= 5 THEN 'ATTENTION 🟠'
        ELSE 'NORMAL 🟢'
    END AS Niveau_Alerte,
    
    -- Code couleur pour le conditionnel (3=Rouge, 2=Orange, 1=Vert)
    CASE 
        WHEN COUNT(*) >= 15 THEN 3
        WHEN COUNT(*) >= 5 THEN 2
        ELSE 1
    END AS Code_Couleur

FROM (
    -- Sous-requête : Calcul des "trous"
    SELECT 
        DATE(fp.Start) AS Date_Jour, -- On extrait la date
        op.Description AS Machine,
        TIMESTAMPDIFF(SECOND, 
            LAG(fp.End) OVER (PARTITION BY fp.OpNo ORDER BY fp.Start), 
            fp.Start
        ) AS Duree_Arret_Sec
    FROM 
        `mes4`.`tblfinorderpos` fp
    JOIN 
        `mes4`.`tbloperation` op ON fp.OpNo = op.OpNo
    WHERE 
        fp.Start IS NOT NULL AND fp.End IS NOT NULL
) AS sub

WHERE 
    sub.Duree_Arret_Sec > 0 AND sub.Duree_Arret_Sec < 300 -- < 5 min

-- GROUP BY : On regroupe maintenant par Date ET par Machine
GROUP BY 
    sub.Date_Jour, 
    sub.Machine

ORDER BY 
    sub.Date_Jour DESC, -- Les jours les plus récents en premier
    Nb_Micro_Arrets DESC;
    
USE `MES4_Analysis`;

-- ==============================================================================
-- VUE 4  : TAUX D'ARRÊT POUR PANNES (KPI MAINTENANCE)
-- Objectif : Part du temps total passé à gérer des erreurs vs temps de production.
-- Source : tblfinorderpos (Plus simple que les logs machine)
-- ==============================================================================
CREATE OR REPLACE VIEW `V_Taux_Panne_Par_Jour` AS
SELECT 
    -- 1. La Date (pour le graphique d'évolution)
    DATE(fp.Start) AS Date_Jour,
    
    -- 2. TEMPS DE PANNE (Numérateur)
    -- Somme des durées des opérations en erreur ce jour-là
    SUM(CASE 
        WHEN fp.Error > 0 THEN TIMESTAMPDIFF(SECOND, fp.Start, fp.End) 
        ELSE 0 
    END) AS Temps_Panne_Secondes,
    
    -- 3. TEMPS D'OUVERTURE (Dénominateur)
    -- Temps total d'activité machine ce jour-là
    SUM(TIMESTAMPDIFF(SECOND, fp.Start, fp.End)) AS Temps_Ouverture_Total_Secondes,
    
    -- 4. LE KPI : TAUX D'ARRÊT (%)
    -- Formule : (Temps Panne / Temps Total) * 100
    ROUND(
        (
            SUM(CASE WHEN fp.Error > 0 THEN TIMESTAMPDIFF(SECOND, fp.Start, fp.End) ELSE 0 END) 
            / 
            SUM(TIMESTAMPDIFF(SECOND, fp.Start, fp.End))
        ) * 100
    , 2) AS Taux_Arret_Panne_Pourcentage

FROM 
    `mes4`.`tblfinorderpos` fp
WHERE 
    fp.Start IS NOT NULL AND fp.End IS NOT NULL
GROUP BY 
    DATE(fp.Start) -- Regroupement par jour
ORDER BY 
    Date_Jour DESC; -- Les jours récents en premier

USE `MES4_Analysis`;

-- ==============================================================================
-- VUE 5 (Version Expert) : TRS DÉTAILLÉ (OEE)
-- Formule : TRS = Taux Dispo x Taux Perf x Taux Qualité
-- ==============================================================================
CREATE OR REPLACE VIEW `V_TRS_Detaille` AS
SELECT 
    -- 1. CALCUL DU TAUX DE DISPONIBILITÉ (A)
    -- Formule : Temps Réel / Temps Planifié
    -- Note : On s'assure que PlannedEnd > PlannedStart pour éviter division par zéro
    ROUND(
        SUM(TIMESTAMPDIFF(SECOND, fp.Start, fp.End)) 
        / 
        NULLIF(SUM(TIMESTAMPDIFF(SECOND, fp.PlannedStart, fp.PlannedEnd)), 0) * 100
    , 2) AS Taux_Disponibilite,

    -- 2. CALCUL DU TAUX DE PERFORMANCE (P)
    -- Formule : (Nb Pièces * Temps Cycle Standard) / Temps Réel
    -- Cela mesure si la machine est allée plus vite ou moins vite que le standard
    ROUND(
        SUM(IFNULL(ro.WorkingTime, 0)) 
        / 
        NULLIF(SUM(TIMESTAMPDIFF(SECOND, fp.Start, fp.End)), 0) * 100
    , 2) AS Taux_Performance,

    -- 3. CALCUL DU TAUX DE QUALITÉ (Q)
    -- Formule : (Total - Erreurs) / Total
    ROUND(
        SUM(CASE WHEN fp.Error = 0 THEN 1 ELSE 0 END) 
        / 
        COUNT(*) * 100
    , 2) AS Taux_Qualite,

    -- 4. TRS GLOBAL (A * P * Q)
    -- Multiplie les 3 ratios (ramenés à 1, puis x100 à la fin)
    ROUND(
        (
            (SUM(TIMESTAMPDIFF(SECOND, fp.Start, fp.End)) / NULLIF(SUM(TIMESTAMPDIFF(SECOND, fp.PlannedStart, fp.PlannedEnd)), 0))
            *
            (SUM(IFNULL(ro.WorkingTime, 0)) / NULLIF(SUM(TIMESTAMPDIFF(SECOND, fp.Start, fp.End)), 0))
            *
            (SUM(CASE WHEN fp.Error = 0 THEN 1 ELSE 0 END) / COUNT(*))
        ) * 100
    , 2) AS TRS_Final_Pourcentage

FROM 
    `mes4`.`tblfinorderpos` fp
LEFT JOIN 
    `mes4`.`tblresourceoperation` ro ON fp.OpNo = ro.OpNo AND fp.ResourceID = ro.ResourceID
WHERE 
    fp.Start IS NOT NULL 
    AND fp.End IS NOT NULL 
    AND fp.PlannedStart IS NOT NULL 
    AND fp.PlannedEnd IS NOT NULL;

-- ==============================================================================
-- VUE 6 (Version Expert) : TRS DÉTAILLÉ (OEE)
-- Formule : TRS = Taux Dispo x Taux Perf x Taux Qualité
-- Par jour
-- ==============================================================================

USE `MES4_Analysis`;

CREATE OR REPLACE VIEW `V_TRS_Evolution_Complet` AS
SELECT 
    DATE(fp.Start) AS Date_Jour,
    
    -- TRS Final pour la courbe principale
    ROUND(
        (
            SUM(CASE WHEN fp.Error = 0 THEN IFNULL(ro.WorkingTime, 0) ELSE 0 END) -- Temps Utile
            /
            NULLIF(SUM(TIMESTAMPDIFF(SECOND, fp.PlannedStart, fp.PlannedEnd)), 0) -- Temps Ouverture
        ) * 100
    , 2) AS TRS_Journalier,

    -- Composantes (pour analyse fine)
    ROUND(SUM(CASE WHEN fp.Error = 0 THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS Qualite_Jour,
    ROUND(SUM(IFNULL(ro.WorkingTime, 0)) / NULLIF(SUM(TIMESTAMPDIFF(SECOND, fp.Start, fp.End)), 0) * 100, 1) AS Performance_Jour

FROM 
    `mes4`.`tblfinorderpos` fp
LEFT JOIN 
    `mes4`.`tblresourceoperation` ro ON fp.OpNo = ro.OpNo AND fp.ResourceID = ro.ResourceID
WHERE 
    fp.Start IS NOT NULL 
    AND fp.End IS NOT NULL
GROUP BY 
    DATE(fp.Start)
ORDER BY 
    Date_Jour DESC;

USE `MES4_Analysis`;

-- ==============================================================================
-- VUE 7 : LEAD TIME & DÉCOMPOSITION (PROCESS vs ATTENTE)
-- Objectif : Mesurer le temps de traversée et isoler les temps morts.
-- Sources : tblorder (Début/Fin Commande) et tblfinorderpos (Détail Opérations)
-- ==============================================================================
CREATE OR REPLACE VIEW `V_Lead_Time_Decompose` AS
SELECT 
    o.ONo AS Num_Commande,
    
    -- Date de fin réelle (pour tri et graphiques)
    DATE(o.End) AS Date_Fin_Commande,
    DATE_FORMAT(o.End, '%Y-%m') AS Mois,
    
    -- 1. LEAD TIME TOTAL (Durée totale de la commande)
    -- Différence entre le Début (Start) et la Fin (End) de la commande
    TIMESTAMPDIFF(SECOND, o.Start, o.End) AS Lead_Time_Total_Sec,
    ROUND(TIMESTAMPDIFF(SECOND, o.Start, o.End) / 60, 1) AS Lead_Time_Total_Min,

    -- 2. TEMPS DE TRAITEMENT (Valeur Ajoutée)
    -- Somme des temps réels passés sur chaque machine pour cette commande
    -- On utilise IFNULL pour éviter les bugs si aucune opération n'est trouvée
    IFNULL(SUM(TIMESTAMPDIFF(SECOND, fp.Start, fp.End)), 0) AS Temps_Process_Sec,
    
    -- 3. TEMPS D'ATTENTE (Gaspillage / Stocks intermédiaires)
    -- Calcul : Temps Total Commande - Somme des Temps Machines
    -- Si le résultat est négatif (incohérence de données), on met 0
    CASE 
        WHEN (TIMESTAMPDIFF(SECOND, o.Start, o.End) - IFNULL(SUM(TIMESTAMPDIFF(SECOND, fp.Start, fp.End)), 0)) < 0 THEN 0
        ELSE (TIMESTAMPDIFF(SECOND, o.Start, o.End) - IFNULL(SUM(TIMESTAMPDIFF(SECOND, fp.Start, fp.End)), 0))
    END AS Temps_Attente_Sec

FROM 
    `mes4`.`tblorder` o
-- Jointure pour récupérer le détail des opérations machines
LEFT JOIN 
    `mes4`.`tblfinorderpos` fp ON o.ONo = fp.ONo

WHERE 
    o.Start IS NOT NULL 
    AND o.End IS NOT NULL
    -- Note : On retire "AND o.State = 'Finished'" car State est un entier (int).
    -- La présence d'une date de fin (o.End IS NOT NULL) suffit à prouver que la commande est finie.

GROUP BY 
    o.ONo;

USE `MES4_Analysis`;

-- ==============================================================================
-- VUE 8: ROTATION DE STOCK (GLOBAL) - CHIFFRE SPOT
-- Formule : (Stock Actuel * 30 jours) / Consommation 30 derniers jours
-- Unité : Jours de couverture
-- ==============================================================================
CREATE OR REPLACE VIEW `V_Rotation_Stock_Global` AS
WITH Stock_Actuel AS (
    -- On compte toutes les pièces actuellement stockées dans le magasin (Buffer)
    SELECT COUNT(*) AS Qte_Stock_Totale
    FROM `mes4`.`tblbufferpos`
    WHERE PNo > 0 -- On ignore les emplacements vides
),
Consommation_30J AS (
    -- On compte toutes les pièces sorties/produites ces 30 derniers jours
    SELECT COUNT(*) AS Qte_Conso_Mois
    FROM `mes4`.`tblfinorderpos`
    WHERE End >= DATE_SUB(NOW(), INTERVAL 30 DAY)
      AND Error = 0 -- On ne compte que les pièces bonnes
)
SELECT 
    s.Qte_Stock_Totale,
    c.Qte_Conso_Mois,
    
    -- LE KPI : COUVERTURE EN JOURS
    CASE 
        WHEN c.Qte_Conso_Mois = 0 THEN 999 -- Si aucune vente, le stock est "Dormant" (Infini)
        ELSE ROUND((s.Qte_Stock_Totale * 30) / c.Qte_Conso_Mois, 1)
    END AS Rotation_Stock_Jours,
    
    -- Indicateur textuel pour le tableau de bord
    CASE 
        WHEN c.Qte_Conso_Mois = 0 THEN 'Stock Dormant (Alerte)'
        WHEN (s.Qte_Stock_Totale * 30) / c.Qte_Conso_Mois < 5 THEN 'Stock Critique (< 5j)'
        WHEN (s.Qte_Stock_Totale * 30) / c.Qte_Conso_Mois > 45 THEN 'Sur-Stockage (> 45j)'
        ELSE 'Stock Sain'
    END AS Etat_Stock

FROM Stock_Actuel s
CROSS JOIN Consommation_30J c;

CREATE OR REPLACE VIEW `V_Rotation_Stock_Detail` AS
SELECT 
    bp.PNo AS Reference_Article,
    
    -- Stock Actuel de cet article
    COUNT(bp.PNo) AS Stock_Actuel,
    
    -- Consommation (Ventes/Prod) de cet article sur 30 jours
    (SELECT COUNT(*) 
     FROM `mes4`.`tblfinorderpos` fp 
     WHERE fp.PNo = bp.PNo 
       AND fp.End >= DATE_SUB(NOW(), INTERVAL 30 DAY)
       AND fp.Error = 0
    ) AS Conso_Mois,
    
    -- Calcul de la rotation
    ROUND(
        (COUNT(bp.PNo) * 30) 
        / 
        NULLIF((SELECT COUNT(*) FROM `mes4`.`tblfinorderpos` fp WHERE fp.PNo = bp.PNo AND fp.End >= DATE_SUB(NOW(), INTERVAL 30 DAY)), 0)
    , 1) AS Jours_Couverture

FROM 
    `mes4`.`tblbufferpos` bp
WHERE 
    bp.PNo > 0
GROUP BY 
    bp.PNo
ORDER BY 
    Jours_Couverture DESC; -- Les stocks dormants en premier