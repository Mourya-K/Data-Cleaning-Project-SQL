-- Data Cleaning Project Script
-- Purpose: This script performs data cleaning operations on the Nashville housing dataset.
-- Skills used: Substring, CharIndex, ParseName, Rank, CTEs, Joins, Window Functions, Aggregate Functions, Altering and updating columns

--------------------------------------------------------------------------------------------------------------------------------------

-- Load the NashvilleHousing dataset
SELECT *
FROM NashvilleHousing

-- Change column name of SaleDate_datetime

EXEC sp_rename 'NashvilleHousing.SaleDate_Datetime', 'SaleDate', 'COLUMN';


--------------------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format and alter data types of SalePrice and SoldAsVacant to avoid errors

ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate DATE;

ALTER TABLE NashvilleHousing
ALTER COLUMN SalePrice NVARCHAR(255);

ALTER TABLE NashvilleHousing
ALTER COLUMN SoldAsVacant NVARCHAR(255);

SELECT SaleDate 
FROM NashvilleHousing


--------------------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address Data

-- Identify and update NULL PropertyAddress values
SELECT *
FROM NashvilleHousing
-- where PropertyAddress is NULL
order by ParcelID

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
where a.PropertyAddress is NULL

UPDATE a
SET PropertyAddress =  ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
where a.PropertyAddress is NULL


--------------------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

-- Split PropertyAddress column into separate columns for Address and City

Select PropertyAddress
from NashvilleHousing

Select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as Address
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
Add PropertySplitAddress NVARCHAR(255)

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE NashvilleHousing
Add PropertySplitCity NVARCHAR(255)

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

SELECT PropertySplitAddress
from NashvilleHousing

Select PropertySplitCity
from NashvilleHousing


-- Split OwnerAddress column into separate columns for Address, City, and State
Select 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
from NashvilleHousing

ALTER TABLE NashvilleHousing
Add OwnerSplitAddress NVARCHAR(255)

ALTER TABLE NashvilleHousing
Add OwnerSplitCity NVARCHAR(255)

ALTER TABLE NashvilleHousing
Add OwnerSplitState NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

Select *
FROM NashvilleHousing


--------------------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold As Vacant" Field

-- Check distinct values of SoldAsVacant
SELECT Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

Select SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END
from NashvilleHousing

-- Update SoldAsVacant values to Yes or No
Update NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END


--------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

-- Use a CTE to identify and delete duplicate rows
WITH RowNumCTE AS (
    Select *, 
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID,
            PropertyAddress,
            SalePrice,
            SaleDate,
            LegalReference
            ORDER BY UniqueID
        ) as row_num
    from NashvilleHousing
    -- ORDER BY ParcelID
)

Delete 
from RowNumCTE
where row_num > 1
-- order by PropertyAddress


--------------------------------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

-- Check the dataset before deleting columns
Select * 
FROM NashvilleHousing

-- Drop columns that are no longer needed
ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

-- END OF SCRIPT