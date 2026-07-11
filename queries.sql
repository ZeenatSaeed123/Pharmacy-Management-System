-- SECTION 4: SYSTEM QUERY SCRIPTS (Q1 - Q13)


-- Q1. Active Stock Quantities Across System Catalog
SELECT m.MedicineName, m.GenericName, SUM(ib.StockQuantity) AS TotalStock
FROM Medicines m
JOIN Inventory_Batches ib ON m.MedicineID = ib.MedicineID
GROUP BY m.MedicineID, m.MedicineName, m.GenericName
ORDER BY TotalStock DESC;

-- Q2. Branch Wise Active Employee Headcounts & Salary Expenditures
SELECT b.BranchName, COUNT(e.EmployeeID) AS TotalStaff, SUM(e.Salary) AS MonthlyPayroll
FROM Branches b
LEFT JOIN Employees e ON b.BranchID = e.BranchID
GROUP BY b.BranchID, b.BranchName;

-- Q3. Identification of Low Stock Batches (Threshold under 50 Units)
SELECT b.BranchName, m.MedicineName, ib.BatchNumber, ib.StockQuantity
FROM Inventory_Batches ib
JOIN Medicines m ON ib.MedicineID = m.MedicineID
JOIN Branches b ON ib.BranchID = b.BranchID
WHERE ib.StockQuantity < 50
ORDER BY ib.StockQuantity ASC;

-- Q4. Critical Near-Expiry and Expired Batches Detection Ledger
SELECT b.BranchName, m.MedicineName, ib.BatchNumber, ib.ExpiryDate,
       DATEDIFF(ib.ExpiryDate, CURDATE()) AS DaysUntilExpiry
FROM Inventory_Batches ib
JOIN Medicines m ON ib.MedicineID = m.MedicineID
JOIN Branches b ON ib.BranchID = b.BranchID
WHERE ib.ExpiryDate <= DATE_ADD(CURDATE(), INTERVAL 90 DAY)
ORDER BY ib.ExpiryDate ASC;

-- Q5. Top 3 Revenue Contributing VIP Customers Profile
SELECT c.CustomerID, c.FirstName, c.LastName, SUM(s.NetAmount) AS LifetimeSpend, c.MembershipPoints
FROM Customers c
JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName, c.MembershipPoints
ORDER BY LifetimeSpend DESC
LIMIT 3;

-- Q6. Highest Performing Sales Employees Ledger
SELECT e.EmployeeID, CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName, 
       b.BranchName, COUNT(s.SaleID) AS TransactionsHandled, SUM(s.NetAmount) AS TotalRevenueGenerated
FROM Employees e
JOIN Sales s ON e.EmployeeID = s.EmployeeID
JOIN Branches b ON e.BranchID = b.BranchID
GROUP BY e.EmployeeID, e.FirstName, e.LastName, b.BranchName
ORDER BY TotalRevenueGenerated DESC;

-- Q7. Comprehensive Ticket Invoicing Summary Log
SELECT s.SaleID, s.SaleDate, b.BranchName, s.NetAmount, s.PaymentMethod,
       COALESCE(CONCAT(c.FirstName, ' ', c.LastName), 'Walk-in Customer') AS CustomerProfile
FROM Sales s
JOIN Branches b ON s.BranchID = b.BranchID
LEFT JOIN Customers c ON s.CustomerID = c.CustomerID
ORDER BY s.SaleDate DESC;

-- Q8. Detailed Prescription Vs Non-Prescription Sales Volumes
SELECT m.IsPrescriptionRequired, COUNT(sd.SaleDetailID) AS OrderLineItemsCount,
       SUM(sd.QuantitySold) AS TotalUnitsDisbursed, SUM(sd.Subtotal) AS AggregateRevenue
FROM Sale_Details sd
JOIN Inventory_Batches ib ON sd.BatchID = ib.BatchID
JOIN Medicines m ON ib.MedicineID = m.MedicineID
GROUP BY m.IsPrescriptionRequired;

-- Q9. Category-wise Medicine and Revenue Breakdown
SELECT
    cat.CategoryName,
    COUNT(DISTINCT m.MedicineID)           AS TotalMedicines,
    COUNT(DISTINCT sales_agg.SaleDetailID) AS TotalLineItemsSold,
    COALESCE(SUM(sales_agg.TotalUnits), 0) AS TotalUnitsSold,
    COALESCE(SUM(sales_agg.Revenue), 0)    AS TotalRevenue,
    ROUND(
        COALESCE(SUM(sales_agg.Revenue), 0) /
        NULLIF((SELECT SUM(Subtotal) FROM Sale_Details), 0) * 100
    , 2)                                   AS RevenueSharePct
FROM Categories cat
LEFT JOIN Medicines m ON m.CategoryID = cat.CategoryID
LEFT JOIN (
    SELECT 
        ib.MedicineID,
        sd.SaleDetailID,
        sd.QuantitySold AS TotalUnits,
        sd.Subtotal AS Revenue
    FROM Sale_Details sd
    JOIN Inventory_Batches ib ON sd.BatchID = ib.BatchID
) sales_agg ON sales_agg.MedicineID = m.MedicineID
GROUP BY cat.CategoryID, cat.CategoryName
ORDER BY TotalRevenue DESC;

-- Q10. Inventory Valuation Report Per Branch
SELECT
    b.BranchName,
    COUNT(DISTINCT ib.BatchID)              AS TotalBatches,
    COUNT(DISTINCT ib.MedicineID)          AS DistinctMedicines,
    SUM(ib.StockQuantity)                  AS TotalUnitsOnHand,
    ROUND(SUM(ib.StockQuantity * ib.CostPrice),   2) AS TotalCostValue,
    ROUND(SUM(ib.StockQuantity * ib.SellingPrice), 2) AS TotalSellingValue,
    ROUND(SUM(ib.StockQuantity * (ib.SellingPrice - ib.CostPrice)), 2) AS PotentialProfit
FROM Branches b
LEFT JOIN Inventory_Batches ib ON ib.BranchID = b.BranchID
GROUP BY b.BranchID, b.BranchName
ORDER BY TotalSellingValue DESC;

-- Q11. Medicines Never Sold (Dead Stock Alert)
SELECT
    m.MedicineName,
    m.GenericName,
    c.CategoryName,
    m.DosageForm,
    m.Strength,
    SUM(ib.StockQuantity)                  AS StockOnHand,
    ROUND(SUM(ib.StockQuantity * ib.CostPrice), 2) AS InvestedValue
FROM Medicines m
JOIN Categories        c  ON c.CategoryID  = m.CategoryID
JOIN Inventory_Batches ib ON ib.MedicineID = m.MedicineID
WHERE NOT EXISTS (
    SELECT 1
    FROM Sale_Details sd
    WHERE sd.BatchID = ib.BatchID
)
GROUP BY m.MedicineID, m.MedicineName, m.GenericName,
         c.CategoryName, m.DosageForm, m.Strength
HAVING StockOnHand > 0
ORDER BY InvestedValue DESC;

-- Q12. Payment Method Analysis
SELECT
    s.PaymentMethod,
    COUNT(s.SaleID)                        AS Transactions,
    SUM(s.NetAmount)                       AS TotalRevenue,
    ROUND(AVG(s.NetAmount), 2)             AS AvgOrderValue,
    ROUND(COUNT(s.SaleID) * 100.0 /
        (SELECT COUNT(*) FROM Sales), 2)   AS PctOfTransactions
FROM Sales s
WHERE s.PaymentMethod IS NOT NULL
GROUP BY s.PaymentMethod
ORDER BY TotalRevenue DESC;

-- Q13. Purchase Order Status Tracker
SELECT
    po.OrderID,
    sup.SupplierName,
    b.BranchName,
    po.OrderDate,
    po.ExpectedDate,
    po.ReceivedDate,
    po.Status,
    po.TotalCost,
    CONCAT(e.FirstName, ' ', e.LastName)   AS PlacedBy,
    CASE WHEN po.ReceivedDate IS NOT NULL
         THEN DATEDIFF(po.ReceivedDate, po.OrderDate)
         ELSE DATEDIFF(CURDATE(), po.OrderDate)
    END                                    AS DaysSinceOrder
FROM Purchase_Orders po
JOIN Suppliers  sup ON sup.SupplierID  = po.SupplierID
JOIN Branches   b   ON b.BranchID      = po.BranchID
JOIN Employees  e   ON e.EmployeeID    = po.PlacedByEmpID
ORDER BY po.OrderDate DESC;