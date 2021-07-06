/* Data Cleaning on Nashville Housing Data
	using Microsoft SQL Server 2019 */

--------------------------------------------------

/* 1. Standardize Date Format */

-- Create new column SaleDateConverted
ALTER TABLE NashvilleHousing
ADD SaleDateConverted date
;

-- Fill in converted values to new column
UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)
;

--------------------------------------------------

/* 2. Populate Property Address Data */ 

-- Join table with itself and get the NULL property addresses with the same parcel ID
SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM NashvilleHousing AS A
JOIN NashvilleHousing AS B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL
;

-- Fill values of NULL property addresses
UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM NashvilleHousing AS A
JOIN NashvilleHousing AS B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL
;

--------------------------------------------------

/* 3. Breaking Property and Owner Address into Individual Columns (Address, City, State) */

-- Create new columns for split PropertyAddress
ALTER TABLE NashvilleHousing
ADD PropertyAddressSplit nvarchar(255),
	PropertyCity nvarchar(255)
;

-- Assign values to new columns using SUBSTRING
UPDATE NashvilleHousing
SET PropertyAddressSplit = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
	PropertyCity = SUBSTRING(PropertyAddress, (CHARINDEX(',', PropertyAddress) + 1), LEN(PropertyAddress))
;

-- Create new columns for split OwnerAddress
ALTER TABLE NashvilleHousing
ADD OwnerAddressSplit nvarchar(255),
	OwnerCity nvarchar(255),
	OwnerState nvarchar(255)
;

-- Assign values to new columns using PARSENAME and REPLACE
UPDATE NashvilleHousing
SET OwnerAddressSplit = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
;

--------------------------------------------------

/* 4. Change Y and N to Yes and No in "Sold as Vacant" column */

--  Change Y to Yes and N to No using CASE statements
UPDATE NashvilleHousing
SET SoldAsVacant = 
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
;

--------------------------------------------------

/* 5. Remove Duplicates */

-- Create CTE and delete duplicate rows using ROW_NUMBER and PARTITION BY
WITH RowNuMCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
	ORDER BY UniqueID
	) AS Row_Num
FROM NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE Row_Num > 1
;

-- View CTE
WITH RowNuMCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
	ORDER BY UniqueID
	) AS Row_Num
FROM NashvilleHousing
)
SELECT *
FROM RowNumCTE
;

--------------------------------------------------

/* 6. Delete Unused Columns */

-- Delete the following columns
ALTER TABLE NashvilleHousing
DROP COLUMN
	OwnerAddress,
	TaxDistrict,
	PropertyAddress,
	SaleDate
;