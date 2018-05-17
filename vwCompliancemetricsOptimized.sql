/****** Object:  View [dbo].[vwPLTComplianceMetrics]    Script Date: 07-05-2018 18:40:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* ===================================================================================================================================
Project Name: Power BI PLT
Module Name: vwPLTComplianceMetrics
Purpose:    
Get the project names and their PLT Compliance metrics.

-------------------------------------------------------------------------------------------------------------------------------------*/
/*====================================================================================================================================
       BUSINESS RULES
======================================================================================================================================
              1. Outputs
                     a.Project Name, count of reports, count of reports above threshold, max PLT, min PLT, PLT Compliance and Last executed On
-------------------------------------------------------------------------------------------------------------------------------------*/
/*====================================================================================================================================

Return Info
   ON Success: 0
   ON Error: @ErrorNum
 
Test Scripts
   SELECT ProjectName, PLTCompliance
   FROM [dbo].[vwPLTComplianceMetrics]

Revision History:
Date                      Author    Description					Performance
=======================================================================================================================================
April 26                  Amit Bh     Created					0s
=======================================================================================================================================*/
CREATE
	

 VIEW [dbo].[vwPLTComplianceMetrics]
AS
WITH CTELastExecutedOn
AS (
	SELECT P.Id AS Id
		,MAX(O.DATE) AS LastExecutedOnProject
	FROM dbo.InputPLT AS I
	INNER JOIN dbo.Project AS P ON P.Id = I.ProjectID
	INNER JOIN dbo.OutputPLT AS O ON O.InputID = I.Id
	WHERE P.IsVisible = 1
		AND I.IsActive = 1
		AND O.LoadInstance = 1
	GROUP BY P.Id
	)
	,CTELastExecutedOnReports
AS (
	SELECT P.Id AS Id
		,I.Id AS ReportId
		,MAX(O.DATE) AS LastExecutedOnReport
	FROM dbo.InputPLT AS I
	INNER JOIN dbo.Project AS P ON P.Id = I.ProjectID
	INNER JOIN dbo.OutputPLT AS O ON O.InputID = I.Id
	WHERE P.IsVisible = 1
		AND I.IsActive = 1
		AND O.LoadInstance = 1
	GROUP BY P.Id
		,I.Id
	)
	,CTEReportsCount
AS (
	SELECT P.Id AS Id
		,COUNT(DISTINCT (O.InputID)) AS ReportsCount
	FROM dbo.inputPLT AS I
	INNER JOIN dbo.project AS P ON P.Id = I.ProjectID
	INNER JOIN dbo.outputPLT AS O ON O.InputID = I.Id
	WHERE P.IsVisible = 1
		AND I.IsActive = 1
		AND O.LoadInstance = 1
	GROUP BY P.Id
	)
	,CTEReportsAboveThreshold
AS (
	SELECT P.Id AS Id
		,COUNT(DISTINCT (O.InputID)) AS ReportsAboveThreshold
	FROM CTELastExecutedOnReports AS CER
	INNER JOIN dbo.project AS P ON P.Id = CER.Id
	INNER JOIN dbo.InputPLT AS I ON I.Id = CER.ReportId
	INNER JOIN dbo.outputPLT AS O ON O.InputID = I.Id
	WHERE P.IsVisible = 1
		AND I.IsActive = 1
		AND O.LoadInstance = 1
		AND O.LoadTime_Seconds > O.LoadTimeThreshold
		AND O.DATE >= CER.LastExecutedOnReport
	GROUP BY P.Id
	)
	,CTEMaxMinPLT
AS (
	SELECT P.Id AS Id
		,MAX(O.LoadTime_Seconds) AS MaxPLT
		,MIN(O.LoadTime_Seconds) AS MinPLT
	FROM CTELastExecutedOnReports AS CER
	INNER JOIN dbo.project AS P ON P.Id = CER.Id
	INNER JOIN dbo.InputPLT AS I ON I.Id = CER.ReportId
	INNER JOIN dbo.outputPLT AS O ON O.InputID = I.Id
	WHERE P.IsVisible = 1
		AND I.IsActive = 1
		AND O.LoadInstance = 1
		AND O.DATE >= CER.LastExecutedOnReport
	GROUP BY P.Id
	)
SELECT P.Id AS ProjectId
	,P.Name AS ProjectName
	,CASE 
		WHEN CR.ReportsCount IS NULL
			THEN 0
		WHEN CRT.ReportsAboveThreshold IS NULL
			THEN 1
		ELSE (CR.ReportsCount - CRT.ReportsAboveThreshold) / CR.ReportsCount
		END AS PLTCompliance
	,CASE 
		WHEN CR.ReportsCount IS NULL
			THEN 0
		ELSE CR.ReportsCount
		END AS CountOfReports
	,CASE 
		WHEN CRT.ReportsAboveThreshold IS NULL
			THEN 0
		ELSE CRT.ReportsAboveThreshold
		END AS ReportsAboveThreshold
	,CP.MinPLT AS MinPLT
	,CP.MaxPLT AS MaxPLT
	,CE.LastExecutedOnProject AS LastExecutedOn
FROM CTELastExecutedOn AS CE
LEFT JOIN dbo.Project AS P ON P.Id = CE.Id
LEFT JOIN CTEReportsCount AS CR ON CE.Id = CR.Id
LEFT JOIN CTEReportsAboveThreshold AS CRT ON CE.Id = CRT.Id
LEFT JOIN CTEMaxMinPLT AS CP ON CP.ID = CE.Id
GO


