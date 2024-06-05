show views;
UPDATE STAGE_SALESHEADER_NEW
SET DATE = REPLACE(DATE, '0013', '2013')
WHERE DATE LIKE '0013%';


--we do this box the sales header had 0013 and dimdate had 2013,so unable to join

USE DATABASE IMT577_DW_HARDIKA_JAIN_DIMENSION;

-----------------------------------------------------------------------------------------------------------------

--CREATING PASS TROUGH VIEWS
-- Dimension Table Views


USE IMT577_DW_HARDIKA_JAIN_DIMENSION;
CREATE OR REPLACE SECURE VIEW vw_Dim_Product AS
SELECT DimProductID, ProductID, ProductTypeID, ProductCategoryID, ProductName, ProductType, ProductCategory, ProductRetailPrice, ProductWholesalePrice, ProductCost, ProductRetailProfit, ProductWholesaleUnitProfit, ProductProfitMarginUnitPercentage
FROM Dim_Product;

SELECT * FROM vw_Dim_Product;

CREATE OR REPLACE SECURE VIEW vw_Dim_Channel AS 
SELECT DimChannelID, ChannelID, ChannelCategoryID, ChannelName, ChannelCategory
FROM Dim_Channel;

SELECT * FROM vw_Dim_Channel;

CREATE OR REPLACE SECURE VIEW vw_Dim_Location AS
SELECT DimLocationID, Address, City, State_Province, PostalCode, Country  
FROM Dim_Location;

SELECT * FROM vw_Dim_Location;

CREATE OR REPLACE SECURE VIEW vw_Dim_Store AS
SELECT DimStoreID, DimLocationID, SourceStoreID, StoreNumber, StoreManager
FROM Dim_Store;

SELECT * FROM vw_Dim_Store;

CREATE OR REPLACE SECURE VIEW vw_Dim_Reseller AS
SELECT DimResellerID, DimLocationID, ResellerID, ResellerName, ContactName, PhoneNumber, Email
FROM Dim_Reseller;

SELECT * FROM vw_Dim_Reseller;

CREATE OR REPLACE SECURE VIEW vw_Dim_Customer AS
SELECT DimCustomerID, DimLocationID, CustomerID, CustomerFullName, CustomerFirstName, CustomerLastName, CustomerGender
FROM Dim_Customer;

SELECT * FROM vw_Dim_Customer;

CREATE OR REPLACE SECURE VIEW vw_Dim_Date AS
SELECT DimDateID, FullDate, DayNameOfWeek, DayNumberOfMonth, MonthName, MonthNumberOfYear, CalendarYear
FROM Dim_Date;

SELECT * FROM vw_Dim_Date;

-- Fact Table Views
CREATE OR REPLACE SECURE VIEW vw_Fact_ProductSalesTarget AS
SELECT DimProductID, DimTargetDateID, ProductTargetSalesQuantity
FROM Fact_ProductSalesTarget;

SELECT * FROM vw_Fact_ProductSalesTarget;

CREATE OR REPLACE SECURE VIEW vw_Fact_SalesActual AS
SELECT DimProductID, DimStoreID, DimResellerID, DimCustomerID, DimChannelID, DimSaleDateID, DimLocationID, SalesHeaderID, SalesDetailID, SaleAmount, SaleQuantity, SaleUnitPrice, SaleExtendedCost, SaleTotalProfit
FROM Fact_SalesActual;

SELECT * FROM vw_Fact_SalesActual;

CREATE OR REPLACE SECURE VIEW vw_Fact_SRCSalesTarget AS
SELECT DimStoreID, DimChannelID, DimResellerID, DimTargetDateID, SalesTargetAmount
FROM Fact_SRCSalesTarget;

SELECT * FROM vw_Fact_SRCSalesTarget;

--------------------------------------------------------------------------------------------------------
--CUSTOM VIEWS
--INSIGHT1:
--Give an overall assessment of stores number 5 and 8’s sales.
--How are they performing compared to target? Will they meet their 2014 target?
--Should either store be closed? Why or why not?


-- VIEW 1: CHECKING THE MONTH WISE SALES AND TARGET FOR STORES 5 AND 8 IN THE YEAR 2014
CREATE OR REPLACE SECURE VIEW Q1 AS
WITH StoreSalesData AS (
    SELECT
        ds.StoreNumber,
        dd.MonthNumberOfYear,
        dd.MonthName,
        dd.CalendarYear,
        SUM(fsa.SaleAmount) AS TotalSalesAmount
    FROM
        Fact_SalesActual fsa
        JOIN Dim_Store ds ON fsa.DimStoreID = ds.DimStoreID
        JOIN Dim_Date dd ON fsa.DimSaleDateID = dd.DimDateID
    WHERE
        ds.StoreNumber IN (5, 8)
        AND dd.CalendarYear = 2014
    GROUP BY
        ds.StoreNumber,
        dd.MonthNumberOfYear,
        dd.MonthName,
        dd.CalendarYear
),
StoreTargetData AS (
    SELECT
        ds.StoreNumber,
        dd.MonthNumberOfYear,
        SUM(fst.SalesTargetAmount) AS TotalTargetSales
    FROM
        Fact_SRCSalesTarget fst
        JOIN Dim_Store ds ON fst.DimStoreID = ds.DimStoreID
        JOIN Dim_Date dd ON fst.DimTargetDateID = dd.DimDateID
    WHERE
        ds.StoreNumber IN (5, 8)
        AND dd.CalendarYear = 2014
    GROUP BY
        ds.StoreNumber,
        dd.MonthNumberOfYear
)
SELECT
    ssd.StoreNumber,
    ssd.MonthName,
    ssd.CalendarYear,
    ssd.TotalSalesAmount,
    std.TotalTargetSales,
    std.TotalTargetSales - ssd.TotalSalesAmount as deviation
FROM
    StoreSalesData ssd
    JOIN StoreTargetData std ON ssd.StoreNumber = std.StoreNumber AND ssd.MonthNumberOfYear = std.MonthNumberOfYear
ORDER BY
    ssd.StoreNumber,
    ssd.MonthNumberOfYear;

select * from Q1;



------
/* Recommend separate 2013 and 2014 bonus amounts for each store if the total bonus pool for 2013 is $500,000 and the total bonus pool for 2014 is $400,000. Base your recommendation on how well the stores are selling Product Types of Men’s Casual and Women’s Casual.*/


CREATE OR REPLACE SECURE VIEW Q2 AS
WITH SalesData AS (
    SELECT 
        s.StoreNumber,
        p.ProductType,
        d.calendaryear AS Year,
        SUM(f.SaleAmount) AS TotalSales,
        SUM(f.SaleTotalProfit) AS TotalProfit
    FROM 
        Fact_SalesActual f
    JOIN 
        Dim_Store s ON f.DimStoreID = s.DimStoreID
    JOIN 
        Dim_Product p ON f.DimProductID = p.DimProductID
    JOIN 
        Dim_Date d ON f.DimSaleDateID = d.DIMDATEID
    WHERE 
        p.ProductType IN ('Men\'s Casual', 'Women\'s Casual')
        AND s.StoreNumber IN (5, 8)
        AND d.calendaryear IN (2013, 2014)
    GROUP BY 
        s.StoreNumber,
        p.ProductType,
        d.calendaryear
),
OverallSalesData AS (
    SELECT 
        p.ProductType,
        d.calendaryear AS Year,
        SUM(f.SaleAmount) AS overallTotalSales,
        SUM(f.SaleTotalProfit) AS overallTotalProfit
    FROM 
        Fact_SalesActual f
    JOIN 
        Dim_Product p ON f.DimProductID = p.DimProductID
    JOIN 
        Dim_Date d ON f.DimSaleDateID = d.DIMDATEID
    WHERE 
        p.ProductType IN ('Men\'s Casual', 'Women\'s Casual')
        AND d.calendaryear IN (2013, 2014)
    GROUP BY 
        p.ProductType,
        d.calendaryear
)

SELECT 
    sd.StoreNumber,
    sd.ProductType,
    sd.Year,
    sd.TotalSales,
    sd.TotalProfit,
    osd.overallTotalSales,
    osd.overallTotalProfit
FROM 
    SalesData sd
JOIN 
    OverallSalesData osd ON sd.ProductType = osd.ProductType AND sd.Year = osd.Year;
    
select * from Q2;

-----------------------------------------------------------------------------------------------------------------

/* INSIGHT 3 
Assess product sales by day of the week at stores 5 and 8. What can we learn about sales trends?
 Create or replace the view to securely aggregate sales data by day of the week for stores 5 and 8*/

CREATE OR REPLACE secure VIEW Q3 AS
SELECT
    ds.StoreNumber,
    dd.DayNameOfWeek,
    SUM(fsa.SaleAmount) AS TotalSalesAmount,
    SUM(fsa.SaleQuantity) AS TotalSalesQuantity
FROM
    Fact_SalesActual fsa
    JOIN Dim_Date dd ON fsa.DimSaleDateID = dd.DimDateID
    JOIN Dim_Store ds ON fsa.DimStoreID = ds.DimStoreID
WHERE
    ds.StoreNumber IN (5, 8)
GROUP BY
    ds.StoreNumber,
    dd.DayNameOfWeek
ORDER BY
    ds.StoreNumber,
    dd.DayNameOfWeek;

SELECT * FROM Q3;


--------------------------------------------------------------------------------------------------------

--INSIGHT 4
/*Compare the performance of all stores located in states that have more than one store to all stores that are the only store in the state. What can we learn about having more than one store in a state?*/

CREATE OR REPLACE SECURE VIEW Q4 AS
WITH cte_StoresByState AS (
    SELECT 
        dl.State_Province,
        ds.DimStoreID,
        COUNT(*) OVER (PARTITION BY dl.State_Province) AS NumStoresInState
    FROM 
        Dim_Store ds
        JOIN Dim_Location dl ON ds.DimLocationID = dl.DimLocationID
)
SELECT
    CASE 
        WHEN NumStoresInState > 1 THEN 'Multiple Stores in State'
        ELSE 'Single Store in State'
    END AS StoreGrouping,
    ds.StoreNumber,
    SUM(fsa.SaleAmount) AS TotalSalesAmount,
    SUM(fsa.SaleQuantity) AS TotalSalesQuantity
FROM
    cte_StoresByState cte
    JOIN Dim_Store ds ON cte.DimStoreID = ds.DimStoreID
    JOIN Fact_SalesActual fsa ON ds.DimStoreID = fsa.DimStoreID
GROUP BY
    CASE WHEN NumStoresInState > 1 THEN 'Multiple Stores in State' ELSE 'Single Store in State' END,
    ds.StoreNumber
ORDER BY
    StoreGrouping,
    ds.StoreNumber;

SELECT * FROM Q4; 

-----
--STATEWISE SALES
CREATE SECURE VIEW Q4_a AS
SELECT
    l.State_Province,
    CASE
        WHEN multiple.StoreCount > 1 THEN 'Multiple Stores'
        ELSE 'Single Store'
    END AS StateType,
    SUM(f.SaleAmount) AS TotalSales,
    SUM(f.SaleQuantity) AS TotalSalesQuantity,
    SUM(f.SaleTotalProfit) AS TotalSalesProfit,
    COUNT(DISTINCT s.DimStoreID) AS NumberOfStores,
    SUM(t.SalesTargetAmount) AS TotalSalesTargetAmount
FROM
    Fact_SalesActual f
JOIN
    Dim_Store s ON f.DimStoreID = s.DimStoreID
JOIN
    Dim_Location l ON s.DimLocationID = l.DimLocationID
LEFT JOIN
    (SELECT
        l.State_Province,
        COUNT(s.DimStoreID) AS StoreCount
    FROM
        Dim_Store s
    JOIN
        Dim_Location l ON s.DimLocationID = l.DimLocationID
    GROUP BY
        l.State_Province
    HAVING
        COUNT(s.DimStoreID) > 1) multiple ON l.State_Province = multiple.State_Province
LEFT JOIN
    Fact_SRCSalesTarget t ON f.DimStoreID = t.DimStoreID AND f.DimResellerID = t.DimResellerID AND f.DimChannelID = t.DimChannelID AND f.DimSaleDateID = t.DimTargetDateID
GROUP BY
    l.State_Province,
    CASE
        WHEN multiple.StoreCount > 1 THEN 'Multiple Stores'
        ELSE 'Single Store'
    END
ORDER BY
    StateType,
    l.State_Province;

SELECT * FROM Q4_a;
