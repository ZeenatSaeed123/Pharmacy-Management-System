-- SECTION 1: DATABASE INITIALIZATION & CLEANUP

SET FOREIGN_KEY_CHECKS = 0;
DROP DATABASE IF EXISTS Pharmacy_Management_System;
CREATE DATABASE Pharmacy_Management_System;
USE Pharmacy_Management_System;
SET FOREIGN_KEY_CHECKS = 1;


-- SECTION 2: DDL SCRIPT - TABLE CREATION & DATA INTEGRITY CONSTRAINTS


-- Table 1: Branches 
CREATE TABLE Branches (
    BranchID INT AUTO_INCREMENT,
    BranchName VARCHAR(100) NOT NULL,
    Location VARCHAR(255) NOT NULL,
    PhoneNumber VARCHAR(20),
    CONSTRAINT PK_Branches PRIMARY KEY (BranchID),
    CONSTRAINT UQ_Branch_Name UNIQUE (BranchName)
);

-- Table 2: Employees 
CREATE TABLE Employees (
    EmployeeID INT AUTO_INCREMENT,
    BranchID INT NOT NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Role VARCHAR(50) NOT NULL,
    Salary DECIMAL(10, 2) NOT NULL,
    Email VARCHAR(100),
    HireDate DATE NOT NULL,
    CONSTRAINT PK_Employees PRIMARY KEY (EmployeeID),
    CONSTRAINT FK_Employees_Branches FOREIGN KEY (BranchID) REFERENCES Branches(BranchID) ON DELETE RESTRICT,
    CONSTRAINT CHK_Employee_Salary CHECK (Salary > 0)
);

-- Table 3: Categories 
CREATE TABLE Categories (
    CategoryID INT AUTO_INCREMENT,
    CategoryName VARCHAR(100) NOT NULL,
    Description TEXT,
    CONSTRAINT PK_Categories PRIMARY KEY (CategoryID),
    CONSTRAINT UQ_Category_Name UNIQUE (CategoryName)
);

-- Table 4: Medicines 
CREATE TABLE Medicines (
    MedicineID INT AUTO_INCREMENT,
    CategoryID INT NOT NULL,
    MedicineName VARCHAR(100) NOT NULL,
    GenericName VARCHAR(100) NOT NULL,
    DosageForm VARCHAR(50) NOT NULL, 
    Strength VARCHAR(20) NOT NULL,    
    IsPrescriptionRequired BOOLEAN DEFAULT FALSE,
    CONSTRAINT PK_Medicines PRIMARY KEY (MedicineID),
    CONSTRAINT FK_Medicines_Categories FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID) ON DELETE RESTRICT
);

-- Table 5: Inventory_Batches 
CREATE TABLE Inventory_Batches (
    BatchID INT AUTO_INCREMENT,
    MedicineID INT NOT NULL,
    BranchID INT NOT NULL,
    BatchNumber VARCHAR(50) NOT NULL,
    StockQuantity INT NOT NULL DEFAULT 0,
    CostPrice DECIMAL(10, 2) NOT NULL,
    SellingPrice DECIMAL(10, 2) NOT NULL,
    ManufactureDate DATE NOT NULL,
    ExpiryDate DATE NOT NULL,
    CONSTRAINT PK_Inventory_Batches PRIMARY KEY (BatchID),
    CONSTRAINT FK_Inventory_Medicines FOREIGN KEY (MedicineID) REFERENCES Medicines(MedicineID) ON DELETE CASCADE,
    CONSTRAINT FK_Inventory_Branches FOREIGN KEY (BranchID) REFERENCES Branches(BranchID) ON DELETE RESTRICT,
    CONSTRAINT UQ_Batch_Per_Branch UNIQUE (BatchNumber, BranchID),
    CONSTRAINT CHK_Inventory_Stock CHECK (StockQuantity >= 0),
    CONSTRAINT CHK_Inventory_Pricing CHECK (SellingPrice >= CostPrice),
    CONSTRAINT CHK_Inventory_Dates CHECK (ExpiryDate > ManufactureDate)
);

-- Table 6: Customers 
CREATE TABLE Customers (
    CustomerID INT AUTO_INCREMENT,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50),
    PhoneNumber VARCHAR(20),
    Email VARCHAR(100),
    MembershipPoints INT DEFAULT 0,
    CONSTRAINT PK_Customers PRIMARY KEY (CustomerID),
    CONSTRAINT CHK_Customer_Points CHECK (MembershipPoints >= 0)
);

-- Table 7: Sales 
CREATE TABLE Sales (
    SaleID INT AUTO_INCREMENT,
    BranchID INT NOT NULL,
    EmployeeID INT NOT NULL,
    CustomerID INT NULL,
    SaleDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    TotalAmount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    TaxAmount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    DiscountAmount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    NetAmount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    PaymentMethod VARCHAR(50) NOT NULL, 
    CONSTRAINT PK_Sales PRIMARY KEY (SaleID),
    CONSTRAINT FK_Sales_Branches FOREIGN KEY (BranchID) REFERENCES Branches(BranchID) ON DELETE RESTRICT,
    CONSTRAINT FK_Sales_Employees FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID) ON DELETE RESTRICT,
    CONSTRAINT FK_Sales_Customers FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON DELETE SET NULL,
    CONSTRAINT CHK_Sales_Net CHECK (ABS(NetAmount - (TotalAmount + TaxAmount - DiscountAmount)) < 0.01)
);

-- Table 8: Sale_Details 
CREATE TABLE Sale_Details (
    SaleDetailID INT AUTO_INCREMENT,
    SaleID INT NOT NULL,
    BatchID INT NOT NULL,
    QuantitySold INT NOT NULL,
    UnitPrice DECIMAL(10, 2) NOT NULL,
    Subtotal DECIMAL(10, 2) NOT NULL,
    CONSTRAINT PK_Sale_Details PRIMARY KEY (SaleDetailID),
    CONSTRAINT FK_Details_Sales FOREIGN KEY (SaleID) REFERENCES Sales(SaleID) ON DELETE CASCADE,
    CONSTRAINT FK_Details_Batches FOREIGN KEY (BatchID) REFERENCES Inventory_Batches(BatchID) ON DELETE RESTRICT,
    CONSTRAINT CHK_Details_Qty CHECK (QuantitySold > 0),
    CONSTRAINT CHK_Details_Subtotal CHECK (ABS(Subtotal - (QuantitySold * UnitPrice)) < 0.01)
);

-- Table 9: Suppliers 
CREATE TABLE Suppliers (
    SupplierID INT AUTO_INCREMENT,
    SupplierName VARCHAR(100) NOT NULL,
    ContactName VARCHAR(100),
    PhoneNumber VARCHAR(20),
    Email VARCHAR(100),
    Address VARCHAR(255),
    CONSTRAINT PK_Suppliers PRIMARY KEY (SupplierID),
    CONSTRAINT UQ_Supplier_Name UNIQUE (SupplierName)
);

-- Table 10: Purchase_Orders 
CREATE TABLE Purchase_Orders (
    OrderID INT AUTO_INCREMENT,
    SupplierID INT NOT NULL,
    BranchID INT NOT NULL,
    PlacedByEmpID INT NOT NULL,
    OrderDate DATE NOT NULL,
    ExpectedDate DATE,
    ReceivedDate DATE,
    TotalCost DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    Status VARCHAR(50) NOT NULL DEFAULT 'Pending', 
    CONSTRAINT PK_Purchase_Orders PRIMARY KEY (OrderID),
    CONSTRAINT FK_PO_Suppliers FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID) ON DELETE RESTRICT,
    CONSTRAINT FK_PO_Branches FOREIGN KEY (BranchID) REFERENCES Branches(BranchID) ON DELETE RESTRICT,
    CONSTRAINT FK_PO_Employees FOREIGN KEY (PlacedByEmpID) REFERENCES Employees(EmployeeID) ON DELETE RESTRICT,
    CONSTRAINT CHK_PO_Dates CHECK (ExpectedDate >= OrderDate)
);