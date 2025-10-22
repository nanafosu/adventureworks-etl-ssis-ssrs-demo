# AdventureWorks ETL + SSRS Demo

**Goal:** Build a mini demo that extracts sales data from AdventureWorks, loads it into a warehouse, and publishes a pixel-perfect SSRS report.

## Quick Start
1. Install SQL Server Developer + SSMS.
2. Restore AdventureWorks.
3. Run /src/sql scripts to create DW tables.
4. Run SSIS packages to load data.
5. Open SSRS project and preview reports.

## Structure
- /docs  architecture, screenshots, walkthroughs
- /src/sql  DW DDL & validation
- /src/ssis  SSIS solution + packages
- /src/ssrs  SSRS solution + reports
