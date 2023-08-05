-- Data Cleaning Project in SQL with Nashville Housing Dataset


/***************************************************************************/

-- Take a look at the dataset

SELECT * FROM [dbo].[Nashville_Data]

/***************************************************************************/

-- Change the date into a standard date type 

SELECT 
	SaleDate,
	CAST(SaleDate AS Date) AS New_SaleDate
FROM [dbo].[Nashville_Data]


ALTER TABLE Nashville_Data
ADD New_SaleDate Date;

UPDATE Nashville_Data
SET New_SaleDate = CAST(SaleDate AS Date)


/***************************************************************************/

-- Populate Property Address column that have NULL values
-- We'll have to use a self join to see address with the same ParcelID

SELECT 
	tab1.ParcelID, 
	tab1.PropertyAddress, 
	tab2.ParcelID, 
	tab2.PropertyAddress,
	ISNULL(tab1.PropertyAddress, tab2.PropertyAddress) AS Replaced_Null_Values
FROM [dbo].[Nashville_Data] AS tab1
	JOIN [dbo].[Nashville_Data] AS tab2
		ON tab1.ParcelID = tab2.ParcelID
		AND tab1.[UniqueID ] != tab2.[UniqueID ]
WHERE tab1.PropertyAddress IS NULL 


UPDATE tab1
SET PropertyAddress = ISNULL(tab1.PropertyAddress, tab2.PropertyAddress)
FROM [dbo].[Nashville_Data] AS tab1
	JOIN [dbo].[Nashville_Data] AS tab2
		ON tab1.ParcelID = tab2.ParcelID
		AND tab1.[UniqueID ] != tab2.[UniqueID ]
WHERE tab1.PropertyAddress IS NULL 

/***************************************************************************/

-- Splitting the PropertyAddress into two columns (Address, City)


SELECT 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM [dbo].[Nashville_Data]


ALTER TABLE Nashville_Data
ADD PropertySplitAddress nvarchar(255);

UPDATE Nashville_Data
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)


ALTER TABLE Nashville_Data
ADD PropertySplitCity nvarchar(255);

UPDATE Nashville_Data
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))



-- Splitting Owner Address into three columns (Address, City, State)


SELECT 
	OwnerAddress,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'),3) AS Address,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'),2) AS City,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'),1) AS State
FROM [dbo].[Nashville_Data]


ALTER TABLE Nashville_Data
ADD OwnerSplitAddress nvarchar(255);

UPDATE Nashville_Data
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)


ALTER TABLE Nashville_Data
ADD OwnerSplitCity nvarchar(255);

UPDATE Nashville_Data
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)

ALTER TABLE Nashville_Data
ADD OwnerSplitState nvarchar(255);

UPDATE Nashville_Data
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1) 


/***************************************************************************/

-- Replacing Y and N in the "Sold As Vacant" column with Yes and No

SELECT
	CASE
		WHEN SoldAsVacant = 'N' THEN 'No'
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		ELSE SoldAsVacant
	END AS Replaced
FROM [dbo].[Nashville_Data]



UPDATE Nashville_Data
SET SoldAsVacant = CASE
					WHEN SoldAsVacant = 'N' THEN 'No'
					WHEN SoldAsVacant = 'Y' THEN 'Yes'
					ELSE SoldAsVacant
				 END

/***************************************************************************/

-- Removing duplicate rows from our data

WITH cte_rownum AS (
SELECT 
	*,
	ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SalePrice, New_SaleDate, LegalReference			
					ORDER BY UniqueID) AS row_numb
FROM [dbo].[Nashville_Data]
)
DELETE * FROM cte_rownum
WHERE row_numb > 1

/***************************************************************************/

-- Removing irrelevant fields from table

ALTER TABLE Nashville_Data
DROP COLUMN PropertyAddress, SaleDate, OwnerAddress

/***************************************************************************/

-- Renaming some columns headers to more meaningful names

	EXEC sys.sp_rename 
    @objname = N'dbo.Nashville_Data.New_SaleDate', 
    @newname = 'SaleDate', 
    @objtype = 'COLUMN'

	EXEC sys.sp_rename 
    @objname = N'dbo.Nashville_Data.PropertySplitAddress', 
    @newname = 'PropertyAddress', 
    @objtype = 'COLUMN'

	EXEC sys.sp_rename 
    @objname = N'dbo.Nashville_Data.PropertySplitCity', 
    @newname = 'PropertyCity', 
    @objtype = 'COLUMN'

	EXEC sys.sp_rename 
    @objname = N'dbo.Nashville_Data.OwnerSplitAddress', 
    @newname = 'OwnerAddress', 
    @objtype = 'COLUMN'

	EXEC sys.sp_rename 
    @objname = N'dbo.Nashville_Data.OwnerSplitCity', 
    @newname = 'OwnerCity', 
    @objtype = 'COLUMN'

	EXEC sys.sp_rename 
    @objname = N'dbo.Nashville_Data.OwnerSplitState', 
    @newname = 'OwnerState', 
    @objtype = 'COLUMN'
