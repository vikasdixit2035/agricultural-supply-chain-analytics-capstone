# Validation Report — Agricultural Supply Chain Analytics

Validated on 2026-10-06.

## Passed checks
- All 15 Clean Reference CSV files load successfully.
- Critical dimension/transaction identifiers were checked for uniqueness where applicable.
- Farm → product → harvest lot → inbound shipment → warehouse and customer order → allocation → lot relationships were checked; critical foreign-key chains returned zero broken references.
- Raw defects were redesigned to be recoverable. The intended cleaning transformations were independently applied and matched the Clean Reference values for the injected issues with zero mismatches.
- The Python solution notebook was executed again from scratch against the packaged Clean Reference data. It completed with zero execution-error cells.
- All CSV/JSON files in `07_Solution_Outputs` were opened successfully.
- `Data_Dictionary_KPI_Catalog.xlsx`, the learner opportunity model and the completed opportunity model were imported and inspected with the spreadsheet engine. Formula-error scans returned zero `#REF!`, `#DIV/0!`, `#VALUE!`, `#NAME?` or `#N/A` matches.
- Learner Brief, Power BI Reference and Instructor Solution PDFs passed PDF structural inspection.
- DOCX files passed ZIP/container integrity checks.
- `03_SQL/04_Solution_Queries_50.sql` now contains a complete Q01–Q50 reference set. Earlier partial placeholders for forecasting, safety stock, reorder point and intervention ranking were replaced with full PostgreSQL reference queries.

## PostgreSQL runtime note
This execution environment does not contain a PostgreSQL server/client (`psql`), so the SQL scripts could not be executed against a live PostgreSQL instance here. The schema, CSV column names, table relationships and query references were cross-checked against the packaged data, and the raw-to-clean transformations were independently reproduced in validation code.

## Distribution recommendation
If learners should receive the answers, send `Agricultural_Supply_Chain_Analytics_LEARNER_WITH_SOLUTIONS_VALIDATED.zip` or the refreshed `Agricultural_Supply_Chain_Analytics_COMPLETE.zip`.
