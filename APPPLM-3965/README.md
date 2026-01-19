# JIRA-Story APPPLM-3965: As a Poultry manager I want to have additional product owner and product coordinator added to our machine codes

## Project Goal
Automated import procedure to add new Product Owners (PO) and Product Coordinators (PC) to machine codes based on Jira ticket specifications.

## Requirements
- **Python**: >= 3.14: [Download](https://www.python.org/downloads/)
- **Package Manager**: [uv](https://docs.astral.sh/uv/getting-started/installation/)
- **Database Access**: 
  1. Copy `db_secrets.example.ini` to `.db_secrets.ini`.
  2. Enter your credentials in the new `.db_secrets.ini` file.
- **Input Data**: 
  1. Download the latest Excel file from Jira ticket APPPLM-3965.
  2. Save it as `data.xlsx` in the `/excel/` subdirectory.

## Functionality
### Core Features
- **DRY_RUN MODE**: The `DRY_RUN`-Mode allows you to simulate the changes that will be applied to the database. 
- **Normalization**: Cleans and formats person names for database consistency.
- **Smart Insert**: Adds yellow-highlighted POs and all PCME2/PCME3 coordinators to `T_MC_PERSON`.
- **Smart Assignment**: Adds the new inserted POs and PCs to their MCODE specific `Z_MCODE` or `Y_MCODE` User Group in `T_GRP_USR`.
- **Audit Trail**: Automatically creates history entries for every new record.
- **Backup**: Generates CSV copies of all inserted data for backtracking and verification.
- **Deletion**: This gript will `DELETE` the demoted former Product Owners from the `T_MC_PERSON`

### Out of Scope
- **No Unassignment**: This script not remove demoted Product Owners from their former MCODE specific `Z_MCODE` or `Y_MCODE` User Group in `T_GRP_USR`.
- **No User Confirmation**: 
> ⚠️ **Warning:** This script will write directly into the table `T_MC_PERSON` and `T_MC_HIS` without a request of confirmation. Therefore you might want to backup these tables first or use the created CSV files to rollback any changes.

## Project Structure
```
APPPLM-3965/
├── dal/
├── Data/                   <-- Output directory for CSV files
├── Excel/                  <-- Place data.xlsx here
├── util/             
├── .db_secrets.ini         <-- Your credentials (to be created from Template File)
├── db_secrets.example.ini  <-- Credential Template File
├── main.py
└── README.md
```

## Version History
| Date | Version | Author | Changes |
| :--- | :--- | :--- | :--- |
| 31-12-2025 | V1.0.0 | Jesco Wurm (ICP) | Initial Version |
| 15-01-2026 | V1.0.1 | Jesco Wurm (ICP) | Implementation of History Entry Insertion for new records |
| 16-01-2026 | V1.0.2 | Jesco Wurm (ICP) | Implementation of User to Group Assignment for new records |
| 17-01-2026 | V1.0.3 | Jesco Wurm (ICP) | Implementation of additional BACKUPs |
| 18-01-2026 | V1.0.4 | Jesco Wurm (ICP) | Implementation of the DRY_RUN Mode |
| 19-01-2026 | V1.0.5 | Jesco Wurm (ICP) | Implementation of the Deletion of former DEF_OWNERS | 

## Running the Program
1. Open a Terminal
2. Navigate to the project directory: `cd path/to/APPPLM-3965`
3. Run the script: `uv run main.py`
4. Select Environment to update

