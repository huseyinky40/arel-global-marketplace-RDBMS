# Arel Global Market Place - RDBMS 🛒🌍

## Overview
This project implements a robust relational database system for a global e-commerce marketplace using **MySQL**. Developed as part of the Computer Engineering curriculum at Arel University, the system models complex real-world workflows including user localization, multi-currency transactions, hierarchical product categorization, and automated logistics tracking.

## Key Features
* **Multi-Currency Engine**: Supports customer-facing prices in local currencies while maintaining vendor base prices in original currencies through dynamic FX rate mapping.
* **Business Logic Automation**: Utilizes 20+ SQL Triggers to enforce strict rules, such as preventing under-18 users from placing orders and ensuring reviews are only posted for delivered items.
* **Data Integrity**: Implements comprehensive foreign key policies (CASCADE/RESTRICT/SET NULL) and check constraints to ensure a consistent and reliable data state.
* **Advanced Analytics**: Includes a suite of complex queries for market share analysis, financial loss reporting (refund risks), and logistics performance tracking.

## Database Schema
The database consists of **14 tables** organized into logical layers:
1.  **User Layer**: Profile management with JSON-based contact storage.
2.  **Localization Layer**: Country-to-currency mapping and exchange rates.
3.  **Catalog Layer**: Vendors, Brands, and Hierarchical Categories.
4.  **Product Layer**: SKU-based products and sellable variants (SCU).
5.  **Transaction Layer**: Orders, Order Items, and Payment/Refund processing.
6.  **Logistics Layer**: Carrier management and shipment tracking.

## Technical Implementation
* **Database Engine**: MySQL (InnoDB).
* **Automation**: Trigger-based stock control, automatic total amount calculation, and verified purchase validation.
* **Data Format**: JSON support for flexible telephone number storage.

## File Structure
* `CREATE-CONSTRAINT.sql`: DDL scripts for table structures and relationships.
* `INSERT.sql`: Comprehensive sample data for testing.
* `TRIGGERS.sql`: Procedural logic for automated business rules.
* `QUERY.sql`: Practical reporting and analytical SQL scripts.
* `proposal.pdf`: Detailed project documentation and system design.

## Future Enhancements
* Integration of a pre-order shopping cart mechanism.
* Support for discount coupons and promotional campaign tables.
* Multilingual product descriptions and detailed auditing logs.
