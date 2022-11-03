/**This dataset was obtained from Kaggle.com and contains data from the housing market in Nashville, Tennessee

In this project, I construct an array of queries to effectively clean the data and ensure it's accuracy including removing duplicates, breaking important data into distinct columns, and more.**/

--Querying all the data in the table to get a general sense of the information it contains

SELECT *
From [master].[dbo].[Nashville Housing Data for Data Cleaning]


--Formatting the Sale Date to Only Include Year, Month, & Day 

UPDATE [Nashville Housing Data for Data Cleaning]
SET SaleDate = CONVERT(Date,SaleDate)

SELECT SaleDateConverted, CONVERT(Date,SaleDate)
From [master].[dbo].[Nashville Housing Data for Data Cleaning]


/**Adding Information to Rows with No Property Address Information**/
--I first show there are several rows with Null values. 

Select PropertyAddress
From [master].[dbo].[Nashville Housing Data for Data Cleaning]
Where PropertyAddress is null

--Upon looking more closely at the data, I see there are several rows that have identical ParcelId's.  

Select *
From [master].[dbo].[Nashville Housing Data for Data Cleaning]
order by ParcelID

--Start by joining the table to itself on ParcelId and then specifying that the UniqueIDs are not the same to show where the Null PropertyAddress values are 

Select T1.ParcelID, T1.PropertyAddress, T2.ParcelID, T2.PropertyAddress, ISNULL(T1.PropertyAddress,T2.PropertyAddress)
From [master].[dbo].[Nashville Housing Data for Data Cleaning] T1
JOIN [master].[dbo].[Nashville Housing Data for Data Cleaning] T2
	on T1.ParcelID = T2.ParcelID
	AND T1.[UniqueID ] <> T2.[UniqueID ]
Where T1.PropertyAddress is null

--Next, I populate the rows with null PropertyAddress values that share a common ParcelId with the corresponding PropertyAddress.

Update T1
SET PropertyAddress = ISNULL(T1.PropertyAddress,T2.PropertyAddress)
From [master].[dbo].[Nashville Housing Data for Data Cleaning] T1
JOIN [master].[dbo].[Nashville Housing Data for Data Cleaning] T2
	on T1.ParcelID = T2.ParcelID
	AND T1.[UniqueID ] <> T2.[UniqueID ]
Where T1.PropertyAddress is null


/**Separating Out the PropertyAddress Variable Into 2 Distinct Columns (Address, City)**/
--First, we see that there are addresses followed by a comma to denoting a city

Select PropertyAddress
From [master].[dbo].[Nashville Housing Data for Data Cleaning]

--Next, we search within the PropertyAddress starting at the first character and ending at the the comma using Charindex. 

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) as Address
From [master].[dbo].[Nashville Housing Data for Data Cleaning]

--The query above contains the comma in the output so to remove it, I enter -1 to only display characters before the placement of the comma.
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
From [master].[dbo].[Nashville Housing Data for Data Cleaning]

--Next, I want to start after the comma to capture the city so I enter +1.
--Since the length of each address is different, I also add LEN to specify where it needs to end

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address
From [master].[dbo].[Nashville Housing Data for Data Cleaning]

--To split these two PropertyAddress columns into Address and City, I alter the table and set the newly added columns to the two substrings I created in the previous query for Address and City

ALTER TABLE [master].[dbo].[Nashville Housing Data for Data Cleaning]
Add PropertySplitAddress Nvarchar(255);

Update [master].[dbo].[Nashville Housing Data for Data Cleaning]
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


ALTER TABLE [master].[dbo].[Nashville Housing Data for Data Cleaning]
Add PropertySplitCity Nvarchar(255);

Update [master].[dbo].[Nashville Housing Data for Data Cleaning]
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))

--Output now shows two new columns for Address and City

SELECT *
From [master].[dbo].[Nashville Housing Data for Data Cleaning]



/**Separating Out the OwnerAddress Variable Into 3 Distinct Columns (Address, City, State)**/
--Similar to queries above, but instead of using substring function, I use the ParseName function which is helpful for delimited data.

Select OwnerAddress
From [master].[dbo].[Nashville Housing Data for Data Cleaning]

--Using ParseName, I specify the order of the "first" period
--Note: ParseName looks for periods so I replace the commas in the OwnerAddress column with periods to ensure it works correctly

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
From [master].[dbo].[Nashville Housing Data for Data Cleaning]

--In the above query, ParseName starts from the right hand side of the data so the "first" thing shown is the state. I reverse the order so it reads address, city, then state by flipping the numbers

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From [master].[dbo].[Nashville Housing Data for Data Cleaning]

--Now, I add the columns to the table along with the corresponding values

ALTER TABLE [master].[dbo].[Nashville Housing Data for Data Cleaning]
Add OwnerSplitAddress Nvarchar(255);

Update [master].[dbo].[Nashville Housing Data for Data Cleaning]
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE [master].[dbo].[Nashville Housing Data for Data Cleaning]
Add OwnerSplitCity Nvarchar(255);

Update [master].[dbo].[Nashville Housing Data for Data Cleaning]
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)


ALTER TABLE [master].[dbo].[Nashville Housing Data for Data Cleaning]
Add OwnerSplitState Nvarchar(255);

Update [master].[dbo].[Nashville Housing Data for Data Cleaning]
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

--Output now shows 3 new columns for address, city, and state

Select *
From [master].[dbo].[Nashville Housing Data for Data Cleaning]


/**Creating consistency in Yes and No Values in SoldAsVacant Field Using a Case Statement**/
--First, I display the distinct values for the SoldAsVacant which shows both Yes and Y, and No and N. I want to modify this so I only see Yes and No in this column

Select Distinct(SoldAsVacant)
From [master].[dbo].[Nashville Housing Data for Data Cleaning]

--Next, I show the total counts of all values so I have a sense of what my final count will be once they're combined into two categories

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From [master].[dbo].[Nashville Housing Data for Data Cleaning]
Group by SoldAsVacant
order by 2

--Then, I use a Case statement to convert the Y's into Yes and N's into No

Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From [master].[dbo].[Nashville Housing Data for Data Cleaning]

--Finally, I update my table to reflect the new changes and confirm the correct changes were made

Update [master].[dbo].[Nashville Housing Data for Data Cleaning]
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From [master].[dbo].[Nashville Housing Data for Data Cleaning]
Group by SoldAsVacant
order by 2


/**Further Clean Data By Removing Duplicates**/
--With duplicate data, there will be multiple rows of the same info and I need a way to differentiate between them so I use the row_number qualifier
--I create a CTE to remove duplicates
--I partition the data on info that should be common among entries and then order it by the UniqueID


Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From [master].[dbo].[Nashville Housing Data for Data Cleaning]


--I then create the CTE and then query off of it to show the duplicate rows using RowNumCTE
--From this, I see there are a little more than 100 duplicate rows

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From [master].[dbo].[Nashville Housing Data for Data Cleaning]
)
Select *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

--I can then use the following query to delete the duplicate rows from the CTE
--Note: I am NOT deleting these rows from my raw data; instead, I'm removing them from the CTE I created

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From [master].[dbo].[Nashville Housing Data for Data Cleaning]
)

Delete
FROM RowNumCTE
WHERE row_num > 1


/**Final Step Of Cleaning In Which I Remove Columns That Are Not Helpful**/
--Earlier, I created new columns for OwnerAddress including Address, City, & State which are much more helpful than the initial column that included all of this information in a single column
--As a result, I want to remove the original column. 
--I also want to remove the TaxDistrict column as it doesn't include any helpful info

Select *
From [master].[dbo].[Nashville Housing Data for Data Cleaning]

ALTER TABLE [master].[dbo].[Nashville Housing Data for Data Cleaning]
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress
