USE IMT577_DW_HARDIKA_JAIN_DIMENSION;
SHOW TABLES;

--creating fact product sales target


CREATE OR REPLACE TABLE Fact_ProductSalesTarget (
    DimProductID INT,
    DimTargetDateID Number(9,0),
    ProductTargetSalesQuantity FLOAT,
    CONSTRAINT Dim_ProductID_FactProductSalesTarget FOREIGN KEY (DimProductID) REFERENCES Dim_Product(DimProductID),
    CONSTRAINT Dim_TargetDateID_FactProductSalesTarget FOREIGN KEY (DimTargetDateID) REFERENCES Dim_Date(DIMDATEID)
);

INSERT INTO Fact_ProductSalesTarget 
(DimProductID, 
 DimTargetDateID,
 ProductTargetSalesQuantity)
 
SELECT
    COALESCE(dpro.DIMPRODUCTID,-1) AS DimProductID,
    COALESCE(dd.DIMDATEID ,-1)AS DimTargetDateID,
    stpro.SALESQUANTITYTARGET / 365 AS ProductTargetSalesQuantity 
    -- in the stage or original Excel file of product sales target, the target is given yearly, we need daily targets hence dividing it by 365
FROM
    STAGE_TARGET_DATA_PRODUCT stpro
LEFT JOIN
    DIM_PRODUCT dpro ON stpro.PRODUCTID = dpro.PRODUCTID
LEFT JOIN
    DIM_DATE dd ON stpro.YEAR = dd.CALENDARYEAR;
--  Matches each year (stpro.YEAR) from the staging table with its corresponding CALENDARYEAR in the DIM_DATE table, we need granular data for all days of the year, hence joining on year and left join.
--here we are inserting the product id and data and amount from the stage tables on matching product and date ID's from the dimension tables

SELECT * FROM Fact_ProductSalesTarget;



-- Create the Fact_SalesActual table

CREATE OR REPLACE TABLE Fact_SalesActual 
(
    
    DimProductID INT REFERENCES Dim_Product(DimProductID),
    DimStoreID INT REFERENCES Dim_Store(DimStoreID),
    DimResellerID INT REFERENCES Dim_Reseller(DimResellerID),
    DimCustomerID INT REFERENCES Dim_Customer(DimCustomerID),
    DimChannelID INT REFERENCES Dim_Channel(DimChannelID),
    DimSaleDateID number(9) REFERENCES Dim_Date(DimDateID),
    DimLocationID INT REFERENCES Dim_Location(DimLocationID),
    SalesHeaderID INT,
    SalesDetailID INT,
    SaleAmount FLOAT,
    SaleQuantity INT,
    SaleUnitPrice FLOAT,
    SaleExtendedCost FLOAT,
    SaleTotalProfit FLOAT
);

INSERT INTO FACT_SALESACTUAL
(
    DimProductID,
    DimStoreID,
    DimResellerID,
    DimCustomerID,
    DimChannelID,
    DimSaleDateID,
    DimLocationID,
    SalesHeaderID,
    SalesDetailID,
    SaleAmount,
    SaleQuantity,
    SaleUnitPrice,
    SaleExtendedCost,
    SaleTotalProfit
)

SELECT
    COALESCE(dp.DimProductID, -1),--all these are foreign keys, if there are null values, then replace it by -1
    COALESCE(ds.DimStoreID, -1),
    COALESCE(drs.DimResellerID, -1),
    COALESCE(dc.DimCustomerID, -1),
    COALESCE(dchannel.DimChannelID, -1),
    COALESCE(dd.DIMDATEID,-1) AS DimSaleDateID,
    COALESCE(dl.DimLocationID,-1),
    sd.SALESDETAILID,
    shn.SALESHEADERID,
    sd.SALESAMOUNT,
    sd.SALESQUANTITY,
    sd.SALESAMOUNT / sd.SALESQUANTITY AS SaleUnitPrice,
    dp.ProductCost *sd.SalesQuantity AS SaleExtendedCost,
    (sd.SalesAmount)-(dp.ProductCost *sd.SalesQuantity) AS SaleTotalProfit

    
FROM
STAGE_SALESHEADER_NEW shn join STAGE_SALESDETAILS sd
on shn.SALESHEADERID = sd.SALESHEADERID
LEFT JOIN
    Dim_Product dp ON sd.PRODUCTID = dp.ProductID
LEFT JOIN
    Dim_Store ds ON shn.STOREID = ds.SourceStoreID
LEFT JOIN
    Dim_Reseller drs ON shn.RESELLERID = drs.ResellerID
LEFT JOIN
    Dim_Customer dc ON shn.CUSTOMERID = dc.CustomerID
LEFT JOIN
    Dim_Channel dchannel ON shn.CHANNELID = dchannel.ChannelID
LEFT JOIN
    Dim_Location dl ON ds.DimLocationID = dl.DimLocationID
LEFT JOIN
    Dim_Date dd ON shn.DATE = dd.fulldate;

SELECT * FROM Fact_SalesActual;



--creating fact SRC sales target


CREATE OR REPLACE TABLE Fact_SRCSalesTarget (
    DimStoreID INT,
    DimChannelID INT,
    DimResellerID INT,
    DimTargetDateID Number(9,0),
    SalesTargetAmount FLOAT,
    CONSTRAINT Dim_StoreID_FactSRCSalesTarget FOREIGN KEY (DimStoreID) REFERENCES Dim_Store(DimStoreID),
    CONSTRAINT Dim_ResellerID_FactSRCSalesTarget FOREIGN KEY (DimResellerID) REFERENCES Dim_Reseller(DimResellerID),
    CONSTRAINT Dim_Channel_FactSRCSalesTarget FOREIGN KEY (DimChannelID) REFERENCES Dim_Channel(DimChannelID),
    CONSTRAINT Dim_TargetDateID_FactSRCSalesTarget FOREIGN KEY (DimTargetDateID) REFERENCES Dim_Date(DIMDATEID)
);


INSERT INTO Fact_SRCSalesTarget 
(
 DimStoreID, 
 DimChannelID,
 DimResellerID,
 DimTargetDateID,
 SalesTargetAmount
 )
 
SELECT
    COALESCE(s.DIMSTOREID,-1) AS DimStoreID,
    COALESCE(c.DIMCHANNELID,-1) AS DimChannelID,
    COALESCE(r.DIMRESELLERID,-1) AS DimResllerID,
    COALESCE(d.DIMDATEID,-1) AS DimTargetDateID,
    tdcsr.TargetSalesAmount / 365 AS SalesTargetAmount
FROM
    STAGE_TARGETDATA_CHANNEL_RESELLER_AND_STORE tdcsr
LEFT JOIN
    DIM_CHANNEL c ON tdcsr.ChannelName = c.CHANNELNAME
LEFT JOIN
    Dim_Store s ON (CASE  
		WHEN tdcsr.TargetName = 'Store Number 5'  
		THEN CAST('5' AS INT)
		WHEN tdcsr.TargetName = 'Store Number 8'  
		THEN CAST('8' AS INT)
		WHEN tdcsr.TargetName = 'Store Number 10'  
		THEN CAST('10' AS INT)
		WHEN tdcsr.TargetName = 'Store Number 21'  
		THEN CAST('21' AS INT)
		WHEN tdcsr.TargetName = 'Store Number 34'  
		THEN CAST('34' AS INT)
		WHEN tdcsr.TargetName = 'Store Number 39'  
		THEN CAST('39' AS INT)
		WHEN tdcsr.TargetName = 'Store Number 39'  
		THEN CAST('39' AS INT)
		ELSE -1
	END) = s.StoreNumber
    
--the store number in the store table is in the form of 5,8,11, and in the stage target table its store number 34, hence changing names.

LEFT JOIN Dim_Reseller r ON
	r.ResellerName = tdcsr.TargetName
LEFT JOIN
    DIM_DATE d ON tdcsr.Year = d.CALENDARYEAR;

select * from Fact_SRCSalesTarget;
