# JIRA-Story APPPLM-3965: As a Poultry manager I want to have additional product owner and product coordinator added to our machine codes

## Project Goal
Automated import procedure to add new Product Owners (PO) and Product Coordinators (PC) to machine codes based on Jira ticket specifications
see [JIRA Story](https://marel-tp.atlassian.net/browse/APPPLM-3965)

## Requirements
- **Python**: >= 3.14: [Download](https://www.python.org/downloads/)
- **Package Manager**: [uv](https://docs.astral.sh/uv/getting-started/installation/)
- **Database Access**: 
  1. Copy `db_secrets.example.ini` to `.db_secrets.ini`.
  2. Enter your credentials in the new `.db_secrets.ini` file.
  3. The `.db_secrets.ini` file is listed in the `.gitignore` file and therefore not shared with this repo.
- **Input Data**: 
  1. Download the latest Excel file from Jira ticket APPPLM-3965.
  2. Save it as `data.xlsx` in the `/excel/` subdirectory.
  3. Excel must have new Product Owners being highlighted with a yellow `#FFFF00`background as only those will be processed.

## Functionality
### Core Features
- **DRY_RUN MODE**: The `DRY_RUN`-Mode allows you to simulate the changes that will be applied to the database. 
- **Normalization**: Cleans and formats person names for database consistency.
- **Smart Insert**: Adds yellow-highlighted POs and all PCME2/PCME3 coordinators to `T_MC_PERSON`.
- **Smart Assignment**: Adds the new inserted POs and PCs to their MCODE specific `Z_<MCODE>` or `Y_<MCODE>` User Group in `T_GRP_USR`.
- **Audit Trail**: Automatically creates history entries for every new record.
- **Backup**: Generates CSV copies of all inserted data for backtracking and verification.
- **Deletion**: This script will `DELETE` the demoted former Product Owners from the `T_MC_PERSON` as well as remove their records from `T_GRP_USR`.

### Out of Scope
- **No User Confirmation**: 
> ⚠️ **Warning:** This script will write directly into the table `T_MC_PERSON`, `T_MC_HIS` and `T_GRP_USR` without any further request of confirmation. Therefore you might want to backup these tables first or use the created BACKUP .csv files to rollback any changes.

## Project Structure
```
APPPLM-3965/
├── dal/
├── Data/                   <-- Output directory for CSV files
|   ├── BACKUP/             <-- Backup Files to restore changes
├── Excel/                  <-- Place data.xlsx here
├── util/             
├── .db_secrets.ini         <-- Your credentials (to be created from Template File)
├── db_secrets.example.ini  <-- Credential Template File
├── main.py
└── README.md
```

## Confluence Documentation
Find the documentation of both a `DRY_RUN` and the run to update `PQE Environment` in the [Confluence Story Documentation](https://marel-tp.atlassian.net/wiki/spaces/TEAM/pages/2770337801/Story+Documentation+APPPLM-3965)

## Version History
| Date | Version | Author | Changes |
| :--- | :--- | :--- | :--- |
| 31-12-2025 | V1.0.0 | Jesco Wurm (ICP) | Initial Version |
| 15-01-2026 | V1.0.1 | Jesco Wurm (ICP) | Implementation of History Entry Insertion for new records |
| 16-01-2026 | V1.0.2 | Jesco Wurm (ICP) | Implementation of User to Group Assignment for new records |
| 17-01-2026 | V1.0.3 | Jesco Wurm (ICP) | Implementation of additional BACKUPs |
| 18-01-2026 | V1.0.4 | Jesco Wurm (ICP) | Implementation of the DRY_RUN Mode |
| 19-01-2026 | V1.0.5 | Jesco Wurm (ICP) | Implementation of the Deletion of former DEF_OWNERS |
| 22-01-2026 | V1.0.6 | Jesco Wurm (ICP) | Bugfix for new created records in tables `T_MC_PERSON` and `T_GRP_USR` |
| 06-02-2026 | V1.0.7 | Jesco Wurm (ICP) | New Feature: Previous Default Owners will also be removed from their Z_ Groups |

## Running the Program
1. Open a Terminal
2. Navigate to the project directory: `cd path/to/APPPLM-3965`
3. Run the script: `uv run main.py`
4. Chose **DRY_RUN** mode firs
5. Select Environment to update by typing the environmend name [PROD/QS/PQE/BLD] when prompted.
6. When running in **NORMAL** mode, confirm you have moved previously created output files to a save location.