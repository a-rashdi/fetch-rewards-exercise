--Business Questions

--1. When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
SELECT 
    rewardsReceiptStatus,
    AVG(totalSpent) AS averageSpend
FROM [fetch].dbo.receipts
WHERE rewardsReceiptStatus IN ('ACCEPTED', 'REJECTED')
GROUP BY rewardsReceiptStatus;

-- 2. When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?

SELECT
    rewardsReceiptStatus,
    SUM(purchasedItemCount) as TotalCount
FROM [fetch].dbo.receipts
WHERE rewardsReceiptStatus IN ('ACCEPTED', 'REJECTED')
GROUP BY rewardsReceiptStatus;

-- 3. Which brand has the most spend among users who were created within the past 6 months?
WITH RecentUsers AS (
    SELECT userId
    FROM [fetch].dbo.users
    WHERE createdDate >= DATEADD(MONTH, -6, GETDATE())
),
BrandSpend AS (
    SELECT 
        b.name AS BrandName,
        SUM(ri.finalPrice) AS TotalSpend
    FROM [fetch].dbo.receipts r
    INNER JOIN RecentUsers u ON r.userId = u.userId
    INNER JOIN [fetch].dbo.receipt_items ri ON r.receiptId = ri.receiptId
    INNER JOIN [fetch].dbo.brands b ON ri.barcode = b.barcode
    GROUP BY b.name
)
SELECT TOP 1 
    BrandName,
    TotalSpend
FROM BrandSpend
ORDER BY TotalSpend DESC;


-- 4. Which brand has the most transactions among users who were created within the past 6 months?
WITH RecentUsers AS (
    SELECT userId
    FROM [fetch].dbo.users
    WHERE createdDate >= DATEADD(MONTH, -6, GETDATE())
),
BrandTransactions AS (
    SELECT 
        b.name AS BrandName,
        COUNT(r.receiptId) AS TransactionCount
    FROM [fetch].dbo.receipts r
    INNER JOIN RecentUsers u ON r.userId = u.userId
    INNER JOIN [fetch].dbo.receipt_items ri ON r.receiptId = ri.receiptId
    INNER JOIN [fetch].dbo.brands b ON ri.barcode = b.barcode
    GROUP BY b.name
)
SELECT TOP 1 
    BrandName,
    TransactionCount
FROM BrandTransactions
ORDER BY TransactionCount DESC;


-- 5. What are the top 5 brands by receipts scanned for most recent month?
SELECT TOP 5 
    b.name AS BrandName, 
    COUNT(DISTINCT r.receiptId) AS ReceiptCount
FROM [fetch].dbo.receipts r
INNER JOIN [fetch].dbo.receipt_items ri ON r.receiptId = ri.receiptId
INNER JOIN [fetch].dbo.brands b ON ri.barcode = b.barcode
WHERE 
    r.dateScanned >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0) -- Start last month
    AND r.dateScanned < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) -- Start of the current month
GROUP BY b.name
ORDER BY ReceiptCount DESC;

-- 6. How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?
WITH MonthlyBrandReceipts AS (
    SELECT 
        b.name AS BrandName,
        FORMAT(r.dateScanned, 'yyyy-MM') AS YearMonth,
        COUNT(DISTINCT r.receiptId) AS ReceiptCount
    FROM [fetch].dbo.receipts r
    INNER JOIN [fetch].dbo.receipt_items ri ON r.receiptId = ri.receiptId
    INNER JOIN [fetch].dbo.brands b ON ri.barcode = b.barcode
    WHERE 
        r.dateScanned >= DATEADD(MONTH, -2, DATEADD(DAY, 1 - DAY(GETDATE()), CAST(GETDATE() AS DATE))) -- Start 2 months back
        AND r.dateScanned < DATEADD(DAY, 1 - DAY(GETDATE()), CAST(GETDATE() AS DATE)) -- Start of current month
    GROUP BY b.name, FORMAT(r.dateScanned, 'yyyy-MM')
),
RankedBrands AS (
    SELECT 
        YearMonth,
        BrandName,
        ReceiptCount,
        RANK() OVER (PARTITION BY YearMonth ORDER BY ReceiptCount DESC) AS Rank -- Rank the brands partition by Year-Month
    FROM MonthlyBrandReceipts
)
SELECT 
    r1.BrandName,
    r1.YearMonth AS RecentMonth,
    r1.Rank AS RecentMonthRank,
    r2.YearMonth AS PreviousMonth,
    r2.Rank AS PreviousMonthRank
FROM 
    RankedBrands r1
LEFT JOIN RankedBrands r2 ON r1.BrandName = r2.BrandName AND r2.YearMonth = FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy-MM')
WHERE r1.YearMonth = FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy-MM')
ORDER BY RecentMonthRank, PreviousMonthRank;


