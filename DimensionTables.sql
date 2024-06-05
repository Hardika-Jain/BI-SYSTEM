CREATE DATABASE IMT577_DW_HARDIKA_JAIN_DIMENSION;
USE IMT577_DW_HARDIKA_JAIN_DIMENSION;
SHOW TABLES;
--PRODUCT DIMENSION:IMT577_DW_HARDIKA_JAIN_STAGE


CREATE OR REPLACE TABLE DIM_PRODUCT(
DimProductID INT IDENTITY(1,1) CONSTRAINT PK_DimProductID PRIMARY KEY NOT NULL, 
-- Surrogate Key(Identity key autoincremets it by one step size)
--Surrogate keys are artificial keys created for database tables, typically used as primary keys. They are unique identifiers that do not carry any business meaning but serve as a means to uniquely identify each record in a table. 
    ProductID	INT,
    ProductTypeID	INT,
    ProductCategoryID INT,
    ProductName VARCHAR(255),
    ProductType VARCHAR(255),
    ProductCategory VARCHAR(255),
    ProductRetailPrice FLOAT(10), 
    ProductWholesalePrice FLOAT(10),
    ProductCost FLOAT(10),
    ProductRetailProfit FLOAT(10),
    ProductWholesaleUnitProfit FLOAT(10),
    ProductProfitMarginUnitPercentage FLOAT(10)
);


INSERT INTO DIM_PRODUCT(
    ProductID,
    ProductTypeID,
    ProductCategoryID,
    ProductName,
    ProductType,
    ProductCategory,
    ProductRetailPrice, 
    ProductWholesalePrice,
    ProductCost,
    ProductRetailProfit,
    ProductWholesaleUnitProfit,
    ProductProfitMarginUnitPercentage
)
    SELECT 
        CAST(pro.ProductID AS INT) AS ProductID,-- the inital data had these as character dataype hence typecasting to integer
        CAST(protyp.PRODUCTTYPEID AS INT) AS ProductTypeID,
        CAST(procat.PRODUCTCATEGORYID AS INT) AS ProductCategoryID,
        pro.Product,
        protyp.PRODUCTTYPE,
        procat.PRODUCTCATEGORY,
        Price,
        WholesalePrice,
        Cost,
        Price - Cost AS ProductRetailProfit,
        WholesalePrice - Cost AS ProductWholesaleProfit,
        ROUND(COALESCE((((COALESCE(pro.Price - pro.Cost, 0) / COALESCE(pro.Price, 1)) * 100) + ((COALESCE(pro.WholesalePrice - pro.Cost, 0) / COALESCE(pro.WholesalePrice, 1)) * 100)) / 2, -1), 2) AS ProductProfitMarginUnitPercentage


    FROM
        STAGE_PRODUCT pro
        LEFT JOIN STAGE_PRODUCTTYPE protyp ON pro.ProductTypeID = protyp.PRODUCTTYPEID
        LEFT JOIN STAGE_PRODUCTCATEGORY procat ON protyp.PRODUCTCATEGORYID = procat.PRODUCTCATEGORYID;
-- inserting unknowns       
INSERT INTO DIM_PRODUCT
(
    DimProductID,
    ProductID,
    ProductTypeID,
    ProductCategoryID,
    ProductName,
    ProductType,
    ProductCategory,
    ProductRetailPrice, 
    ProductWholesalePrice,
    ProductCost,
    ProductRetailProfit,
    ProductWholesaleUnitProfit,
    ProductProfitMarginUnitPercentage
)
VALUES
( 
    -1, --int
    -1,
    -1,
    -1,
    'Unknown',--varchar
    'Unknown',
    'Unknown',
    -1.0,--float
    -1.0,
    -1.0,
    -1.0,
    -1.0,
    -1.0
   
);
/*we are creating the unknows in all these tables because we will be referring to these tables in our fact table and fact tables cannot have unknowns, hence if there is any value that is unknown in our initial excel files, we will replace it with these unknown values.
When designing a data warehouse, particularly in a star schema that includes dimension tables and fact tables, it is common practice to insert a row of "unknowns" into dimension tables. This row typically has default or placeholder values and serves several important purposes, especially when dealing with referential integrity and handling missing or unknown data in fact tables.
There might be cases where the data for a particular dimension is not available at the time of data loading. For instance, if a fact record is received but the associated dimension data is missing, inserting a row of unknowns ensures that the fact record can still be loaded.
Fact tables often have foreign keys that reference primary keys in dimension tables. If a dimension key is not available when a fact record is being inserted, having an "unknown" row ensures that the foreign key constraint is not violated.
*/

SELECT * FROM DIM_PRODUCT;

--CHANNEL DIMENSION:

CREATE OR REPLACE TABLE DIM_CHANNEL(
DimChannelID INT IDENTITY(1,1) CONSTRAINT PK_DimPChannelID PRIMARY KEY NOT NULL, 
-- Surrogate Key(Identity key autoincremets it by one step size)
    ChannelID INT,
    ChannelCategoryID	INT,
    ChannelName VARCHAR(255),
    ChannelCategory VARCHAR(255)
   
);


INSERT INTO DIM_CHANNEL(
    ChannelID,
    ChannelCategoryID,
    ChannelName,
    ChannelCategory
)
    SELECT 
        CAST(c.ChannelID AS INT) AS ChannelID,-- the inital data had these as character dataype hence typecasting to integer
        CAST(c.ChannelCategoryID AS INT) AS ChannelCategoryID,
        c.Channel,
        ccat.ChannelCategory,  
    FROM
        STAGE_CHANNEL c
        LEFT JOIN STAGE_CHANNELCATEGORY ccat ON c.CHANNELCATEGORYID = ccat.CHANNELCATEGORYID;
        
INSERT INTO DIM_CHANNEL
(
    DimChannelID,
    ChannelID,
    ChannelCategoryID,
    ChannelName,
    ChannelCategory
)
VALUES
( 
    -1,
    -1,
    -1,
    'Unknown',
    'Unknown'
    
);

SELECT * FROM DIM_CHANNEL;


--creating location table: Here we are trying to dump all the location-related data from all the that have location feild into this one location table which we will use to further join  with other tables based on the location match found.

CREATE OR REPLACE TABLE DIM_LOCATION(
    DimLocationID  INT AUTOINCREMENT PRIMARY KEY,
    Address VARCHAR(255),
    City VARCHAR(255),
    State_Province VARCHAR(255),
    PostalCode VARCHAR(255),
    Country VARCHAR(255)
);

INSERT INTO DIM_LOCATION(
    Address,
    City,
    State_Province,
    PostalCode,
    Country
) 
    SELECT 
        r.Address AS Address,
        r.City AS City,
        r.StateProvince AS State_Province,
        r.PostalCode AS PostalCode,
        r.Country AS Country
    FROM
        STAGE_RESELLER r

    UNION

    SELECT 
        c.Address AS Address,
        c.City AS City,
        c.StateProvince AS State_Province,
        c.PostalCode AS PostalCode,
        c.Country AS Country
    FROM
        STAGE_CUSTOMER c

    UNION

    SELECT 
        s.Address AS Address,
        s.City AS City,
        s.StateProvince AS State_Province,
        s.PostalCode AS PostalCode,
        s.Country AS Country
    FROM 
        STAGE_STORE s;
SELECT * FROM DIM_LOCATION;


-- Creating the store table

CREATE OR REPLACE TABLE DIM_STORE(
    DimStoreID INT IDENTITY(1,1) CONSTRAINT PK_DimStoreID PRIMARY KEY NOT NULL,
    DimLocationID INT,
    SourceStoreID INT,
    StoreNumber INT,
    StoreManager VARCHAR(255),
    CONSTRAINT FK_Store_Location FOREIGN KEY (DimLocationID) REFERENCES DIM_LOCATION(DimLocationID)

);

INSERT INTO Dim_Store (
    DimLocationID,
    SourceStoreID,
    StoreNumber,
    StoreManager
)
SELECT
    l.DimLocationID,
    CAST(s.STOREID AS INT) AS SourceStoreID,
    CAST(s.STORENUMBER AS INT),
    s.STOREMANAGER
FROM
    STAGE_STORE s
JOIN
    Dim_Location l ON s.ADDRESS = l.Address
                  AND s.CITY = l.City
                  AND s.POSTALCODE = l.PostalCode
                  AND s.STATEPROVINCE = l.State_Province
                  AND s.COUNTRY = l.Country;
                  
SELECT * FROM DIM_STORE;

INSERT INTO DIM_STORE

(
    DimStoreID,
    DimLocationID,
    SourceStoreID,
    StoreNumber,
    StoreManager
)
VALUES
( 
    -1,
    -1,
    -1,
    -1,
    'Unknown'
    
);
SELECT * FROM DIM_STORE;

-- CREATING THE RESELLER TABLE;

CREATE OR REPLACE TABLE Dim_Reseller(
    DimResellerID INT IDENTITY(1,1) CONSTRAINT PK_DimResellerID PRIMARY KEY NOT NULL,
    DimLocationID	INT,
    ResellerID VARCHAR(255),
    ResellerName VARCHAR(255),
    ContactName VARCHAR(255),
    PhoneNumber VARCHAR(255),
    Email VARCHAR(255),
    CONSTRAINT FK_Reseler_Location FOREIGN KEY (DimLocationID) REFERENCES DIM_LOCATION(DimLocationID)
);
INSERT INTO Dim_Reseller (
    DimLocationID,
    ResellerID,
    ResellerName,
    ContactName,
    PhoneNumber,
    Email
)
SELECT
    l.DimLocationID,
    r.RESELLERID,
    r.RESELLERNAME,
    r.CONTACT AS ContactName,
    r.PHONENUMBER AS PhoneNumber, 
	r.EMAILADDRESS AS Email
FROM
    STAGE_RESELLER r
JOIN
    Dim_Location l ON r.ADDRESS = l.Address
                  AND r.CITY = l.City
                  AND r.POSTALCODE = l.PostalCode
                  AND r.STATEPROVINCE = l.State_Province
                  AND r.COUNTRY = l.Country;
SELECT * FROM DIM_RESELLER;

INSERT INTO DIM_RESELLER

(
    DimResellerID,
    DimLocationID,
    ResellerID,
    ResellerName,
    ContactName,
    PhoneNumber,
    Email
)
VALUES
( 
    -1,
    -1,
    'Unknown',
    'Unknown',
    'Unknown',
    'Unknown',
    'Unknown'
    
);


--CREATING CUSTOMER TABLE;
CREATE OR REPLACE TABLE DIM_CUSTOMER(
    DimCustomerID INT IDENTITY(1,1) CONSTRAINT PK_DimCustomerID PRIMARY KEY NOT NULL,
    DimLocationID INT,
    CUSTOMERID	VARCHAR(255),
    CustomerFullName VARCHAR(255),
    CustomerFirstName VARCHAR(255),
    CustomerLastName VARCHAR(255),
    CustomerGender VARCHAR(255),
    CONSTRAINT FK_Customer_Location FOREIGN KEY (DimLocationID) REFERENCES DIM_LOCATION(DimLocationID)
        
    
);
INSERT INTO DIM_CUSTOMER (
    DimLocationID,
    CUSTOMERID,
    CustomerFullName,
    CustomerFirstName,
    CustomerLastName,
    CustomerGender
    
)
SELECT
    COALESCE(CAST(L.DimLocationID AS INT), -1) AS DimLocationID,-- Use -1 if DimLocationID is missing
    C.CUSTOMERID,
    CONCAT(C.FIRSTNAME, ' ', C.LASTNAME) AS CustomerFullName,
    C.FIRSTNAME AS CustomerFirstName,
    C.LASTNAME AS CustomerLastName,
    C.GENDER AS CustomerGender,
    
FROM
    STAGE_CUSTOMER C
LEFT JOIN
    DIM_LOCATION L ON C.ADDRESS = L.Address
                    AND C.CITY = L.City
                    AND C.POSTALCODE = L.PostalCode
                    AND C.STATEPROVINCE = L.State_Province
                    AND C.COUNTRY = L.Country;
SELECT * FROM DIM_CUSTOMER;

INSERT INTO DIM_CUSTOMER 
(
    DimCustomerID,
    DimLocationID,
    CUSTOMERID,
    CustomerFullName,
    CustomerFirstName,
    CustomerLastName,
    CustomerGender
    
)
VALUES
( 
    -1,
    -1,
    'Unknown',
    'Unknown',
    'Unknown',
    'Unknown',
    'Unknown'
    
);

--CREATING THE DATE TABLE
create or replace table DIM_DATE (
	DimDateID				number(9) PRIMARY KEY,
	FullDate					date not null,
	DayNameOfWeek			varchar(10) not null,
	DayNumberOfMonth		number(2) not null,
	MonthName				varchar(10) not null,
	MonthNumberOfYear		number(2) not null,
	CalendarYear					number(5) not null
);
insert into DIM_DATE
select DimDateID,
       FullDate,
       DayNameOfWeek,
       DayNumberOfMonth,
       MonthName,
       MonthNumberOfYear,
       CalendarYear
from 
    ( select to_date('2012-12-31 23:59:59','YYYY-MM-DD HH24:MI:SS') as DD,
             seq1() as Sl, row_number() over (order by Sl) as row_numbers,
             dateadd(day, row_numbers, DD) as V_DATE,
             case when date_part(dd, V_DATE) < 10 and date_part(mm, V_DATE) > 9 then
                 date_part(year, V_DATE) || date_part(mm, V_DATE) || '0' || date_part(dd, V_DATE)
              when date_part(dd, V_DATE) < 10 and date_part(mm, V_DATE) < 10 then 
                 date_part(year, V_DATE) || '0' || date_part(mm, V_DATE) || '0' || date_part(dd, V_DATE)
              when date_part(dd, V_DATE) > 9 and date_part(mm, V_DATE) < 10 then
                 date_part(year, V_DATE) || '0' || date_part(mm, V_DATE) || date_part(dd, V_DATE)
              when date_part(dd, V_DATE) > 9 and date_part(mm, V_DATE) > 9 then
                 date_part(year, V_DATE) || date_part(mm, V_DATE) || date_part(dd, V_DATE) 
             end as DimDateID,
             V_DATE as FullDate,
             dateadd(day, row_numbers, DD) as V_DATE_1,
             case 
                when dayname(V_DATE_1) = 'Mon' then 'Monday'
                when dayname(V_DATE_1) = 'Tue' then 'Tuesday'
                when dayname(V_DATE_1) = 'Wed' then 'Wednesday'
                when dayname(V_DATE_1) = 'Thu' then 'Thursday'
                when dayname(V_DATE_1) = 'Fri' then 'Friday'
                when dayname(V_DATE_1) = 'Sat' then 'Saturday'
                when dayname(V_DATE_1) = 'Sun' then 'Sunday'
             end as DayNameOfWeek,
             date_part(dd, V_DATE_1) as DayNumberOfMonth,
             case 
                when monthname(V_DATE_1) = 'Jan' then 'January'
                when monthname(V_DATE_1) = 'Feb' then 'February'
                when monthname(V_DATE_1) = 'Mar' then 'March'
                when monthname(V_DATE_1) = 'Apr' then 'April'
                when monthname(V_DATE_1) = 'May' then 'May'
                when monthname(V_DATE_1) = 'Jun' then 'June'
                when monthname(V_DATE_1) = 'Jul' then 'July'
                when monthname(V_DATE_1) = 'Aug' then 'August'
                when monthname(V_DATE_1) = 'Sep' then 'September'
                when monthname(V_DATE_1) = 'Oct' then 'October'
                when monthname(V_DATE_1) = 'Nov' then 'November'
                when monthname(V_DATE_1) = 'Dec' then 'December' 
             end as MonthName,
             month(V_DATE_1) as MonthNumberOfYear,
             year(V_DATE_1) as CalendarYear  -- Added year() function for CalendarYear
      	from table(generator(rowcount => 730))-- /<< Set to generate 20 years. Modify rowcount to increase or decrease size/
    );
INSERT INTO DIM_DATE
(
    DimDateID,
	FullDate,
	DayNameOfWeek,
	DayNumberOfMonth,
	MonthName,
	MonthNumberOfYear,
	CalendarYear
)
VALUES
(
    -1,
    '0001-01-01',
    'unknown',
    -1,
    'unknown',
    -1,
    -1
);

SELECT * FROM DIM_DATE;
