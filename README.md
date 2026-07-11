# Pharmacy Management System

A robust relational database system designed to manage and optimize pharmacy operations across multiple branches. This project demonstrates skills in SQL schema design, data integrity, and complex reporting.

## Features
- **Inventory Management:** Tracks stock levels across different branches and manages inventory batches.
- **Expiry Tracking:** Automated detection of near-expiry and expired medicinal batches.
- **Sales & Analytics:** Tracks daily transactions, revenue, and customer loyalty points.
- **Operational Reporting:** Generates insights on low-stock items, top-performing employees, and branch payroll.

## Database Structure
The system is built on a relational model consisting of 10 tables, including:
- `Branches`, `Employees`, `Medicines`, `Customers`, `Sales`, `Inventory_Batches`, and `Suppliers`.

## How to use
1. Run `schema.sql` in your MySQL environment to create the database and tables.
2. Run `seed_data.sql` to populate the system with sample data.
3. Use the queries in `queries.sql` to generate reports and system insights.

## Technologies Used
- MySQL
- Relational Database Design
- SQL (DDL, DML, DQL)