SELECT *
FROM HousingProject.dbo.NashvilleHousing


-- Removing time stamp from the SaleDate column. 
SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM HousingProject.dbo.NashvilleHousing

ALTER TABLE HousingProject.dbo.NashvilleHousing
ADD SaleDateConverted Date;

UPDATE HousingProject.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

-- Using self JOIN to match PropertyAddress to ParcelID, and replace NULL values with the address that matches the ParcelID.

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, isNULL(a.PropertyAddress, b.PropertyAddress)
FROM HousingProject.dbo.NashvilleHousing a
JOIN HousingProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS null

UPDATE a
SET PropertyAddress = isNULL(a.PropertyAddress, b.PropertyAddress)
FROM HousingProject.dbo.NashvilleHousing a
JOIN HousingProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS null

-- Splitting the address and city data in the PropertyAddress column, and then putting that address and city data into two separate columns.
SELECT PropertyAddress
FROM HousingProject.dbo.NashvilleHousing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))
FROM HousingProject.dbo.NashvilleHousing

ALTER TABLE HousingProject.dbo.NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE HousingProject.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE HousingProject.dbo.NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

UPDATE HousingProject.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

-- A faster, but more complicated way to do the same as above.

SELECT OwnerAddress
FROM HousingProject.dbo.NashvilleHousing

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3),
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2),
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)
FROM HousingProject.dbo.NashvilleHousing

ALTER TABLE HousingProject.dbo.NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

ALTER TABLE HousingProject.dbo.NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

ALTER TABLE HousingProject.dbo.NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

UPDATE HousingProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3)

UPDATE HousingProject.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2)

UPDATE HousingProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)

-- Change Y and N to Yes and No in "Sold as Vacant" field using a CASE statement.

SELECT DISTINCT(SoldAsVacant), COUNT(SoldasVacant)
FROM HousingProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldasVacant,
CASE 
	WHEN SoldasVacant = 'Y' THEN 'Yes'
	WHEN SoldasVacant = 'N' THEN 'No'
	ELSE SoldasVacant
END
FROM HousingProject.dbo.NashvilleHousing

UPDATE HousingProject.dbo.NashvilleHousing
SET SoldAsVacant = 
CASE 
	WHEN SoldasVacant = 'Y' THEN 'Yes'
	WHEN SoldasVacant = 'N' THEN 'No'
	ELSE SoldasVacant
END

-- Removing duplicates despite it not being standard practice. 
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM HousingProject.dbo.NashvilleHousing
--ORDER BY ParcelID
)

DELETE 
FROM RowNumCTE
WHERE row_num > 1

-- Deleting unused/redundant columns. 

ALTER TABLE HousingProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, SaleDate

-- Average sale price and total value in relation to city. 
SELECT PropertySplitCity,
	   AVG(SalePrice) AS AvgSalePrice, 
	   AVG(TotalValue) AS AvgTotalValue
FROM HousingProject..NashvilleHousing
WHERE TotalValue IS NOT null
GROUP BY PropertySplitCity

-- Finding all properties that are listed below the average price using a subquery.
SELECT DISTINCT(PropertyAddress), SalePrice
FROM HousingProject..NashvilleHousing
WHERE SalePrice < (SELECT AVG(SalePrice) AS AvgSalePrice
FROM HousingProject..NashvilleHousing)
ORDER BY SalePrice
