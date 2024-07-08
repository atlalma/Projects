CREATE TABLE NashvilleHousing (
	UniqueID int,
	ParcelID varchar(255),
	LandUse varchar (255),
	PropertyAddress varchar(255),
	SaleDate date,
	SalePrice int,
	LegalReference varchar(255),
	SoldAsVacant boolean,
	OwnerName varchar(255),
	OwnerAddress varchar(255),
	Acreage numeric,
	TaxDistrict varchar(255),
	LandValue int,
	BuildingValue int,
	TotalValue int,
	YearBuilt int,
	Bedrooms int,
	FullBath int,
	HalfBath int);
	
-- IMPORT ERROR: saleprice contains ',' i.e 26,000

ALTER TABLE NashvilleHousing
ALTER COLUMN saleprice TYPE varchar(255);
SELECT *
FROM NashvilleHousing;

-----------------------------------------------------------------
-- Standardize Date Format
-- Changed data type when creating table to remove timestamp in excel on SaleDate
SELECT SaleDate
FROM NashvilleHousing

---------------------------------------------------------------------
-- Populate Property Address data
Select *
From NashvilleHousing
Where PropertyAddress is null;
-- find propertyaddress
-- ParcelID = propertyaddress, create self-join

Select ParcelID, PropertyAddress, b.P
From NashvilleHousing
Order by ParcelID;

-- find address where parcelID matches and Unique ID different, populate propertyaddress
SELECT a.ParcelID, a.propertyaddress, b.ParcelID, b.PropertyAddress, COALESCE(a.PropertyAddress, b.PropertyAddress) AS RealPropertyAddress
-- coalesce returns b.propertyaddress values when a.propertyaddress is null
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE NashvilleHousing a
SET PropertyAddress = b.PropertyAddress
From NashvilleHousing b
Where a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
	AND a.PropertyAddress IS NULL; 
	
---------------------------------------------------------------------	
--Breaking out Address into Individual Columns (Address, City)
--- METHOD 1: SUBSTRING
SELECT *
FROM NashvilleHousing;

-- extracting substring up to the first comma
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress varchar(255),
ADD PropertySplitCity varchar(255);

UPDATE NashvilleHousing
SET 
	PropertySplitAddress = CASE
		WHEN POSITION(',' IN PropertyAddress) > 0
		THEN SUBSTRING(PropertyAddress FROM 1 FOR POSITION(',' IN PropertyAddress)-1)
		ELSE PropertyAddress
	END,

-- extracting substring after comma

	PropertySplitCity = CASE
		WHEN POSITION(',' IN PropertyAddress) > 0
		THEN SUBSTRING(PropertyAddress FROM POSITION(',' IN PropertyAddress)+1)
		ELSE ''
	END;

SELECT PropertyAddress,PropertySplitAddress,PropertySplitCity
FROM NashvilleHousing;
ALTER TABLE NashvilleHousing
DROP PropertyAddress;

--- METHOD 2: SPLIT_PART
ALTER TABLE NashvilleHousing
ADD COLUMN OwnerSplitAddress varchar(255),
ADD COLUMN OwnerSplitState varchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = SPLIT_PART(OwnerAddress,',',1),
	OwnerSplitState = SPLIT_PART(OwnerAddress,',',2);
ALTER TABLE NashvilleHousing
DROP OwnerAddress;

----------------------------------------------------------------------
-- Change 'Sold as Vacant' column to Yes and No
-- datatype set as boolean -> create new column with text values and drop boolean column
Select SoldAsVacant, Count(SoldAsVacant) AS Count
From NashvilleHousing
Group by SoldAsVacant
order by Count;

ALTER TABLE NashvilleHousing
ADD COLUMN SoldAsVacant_Text TEXT;

SELECT 
	CASE
		WHEN SoldAsVacant = true THEN 'Yes'
		WHEN SoldAsVacant = false THEN 'No'
	END AS SoldAsVacant
	Count(*) As Count
From NashvilleHousing
Group by SoldAsVacant
order by Count;

UPDATE NashvilleHousing
SET SoldAsVacant_text = CASE
		WHEN SoldAsVacant = true THEN 'Yes'
		WHEN SoldAsVacant = false THEN 'No'
	END;
	
ALTER TABLE NashvilleHousing
DROP SoldAsVacant;
	
ALTER TABLE NashvilleHousing
Rename Column SoldAsVacant_text TO SoldAsVacant;

---------------------------------------------------------
--Remove Duplicates *DO NOT DO TO RAW DATA*
-- row_number gives unique value to partitions based on specified columns, if columns are duplicates they will be >1
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION By ParcelID,
		PropertySplitAddress,
		SalePrice,
		SaleDate,
		LegalReference

		ORDER by
			UNIQUEID
		) row_num
FROM NASHVILLEHOUSING)
--ORDER BY ParcelID
DELETE FROM NashvilleHousing
WHERE UNIQUEID IN(
	SELECT UNIQUEID
	From RowNumCTE
Where row_num > 1);
--ORDER BY PropertySplitAddress;
-- 104 duplicates found
-- CHECK
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION By ParcelID,
		PropertySplitAddress,
		SalePrice,
		SaleDate,
		LegalReference

		ORDER by
			UNIQUEID
		) row_num
FROM NASHVILLEHOUSING)
SELECT *
From RowNumCTE
Where row_num >1 
Order by PropertySplitAddress;
---- DELETE unused columns
ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate, Tax District

Select *
From NashvilleHousing