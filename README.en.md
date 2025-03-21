# SQLPROJECTS Repository [![en](https://img.shields.io/badge/lang-en-red.svg)]

This repository contains a collection of PL/SQL projects (SQL scripts) in the Oracle dialect, each associated with specific JIRA stories or customer-assigned story identifiers. Each subfolder represents a project and includes all related PL/SQL scripts along with supplementary documentation or auxiliary files.

## Repository Structure

- **Subfolders:**  
  Each subfolder corresponds to a specific JIRA story, enabling you to directly associate the contents with the corresponding story.

- **Files:**  
  In addition to the PL/SQL scripts, subfolders may also contain documentation, examples, or other relevant files.

## Naming Convention for PL/SQL Files

All PL/SQL files in this repository follow the naming convention:

`<StoryNumber>-JW_<Short_Description_With_Underscores>.sql`

**Example:**  
`DEV-1234-JW_Update_User_Table.sql`

- **<StoryNumber>**: The unique JIRA story identifier  
- **JW**: A fixed component in the file name  
- **<Short_Description_With_Underscores>**: A brief, concise description of the content or function of the PL/SQL script (spaces are replaced with underscores)

## Prerequisites

- **Oracle Database:**  
  The scripts in this repository are designed for the Oracle dialect (PL/SQL). An Oracle database is required to execute the scripts.

## Usage and Execution

- **Executing PL/SQL Scripts:**  
  Run the scripts using an Oracle-compatible database client such as Oracle SQL Developer or another suitable tool.

- **Additional Information:**  
  In the respective subfolders, you will find additional documentation or helper files that explain the purpose and functionality of the PL/SQL scripts.

## Contributions and Version Control

- **Branching and Pull Requests:**  
  Changes and enhancements should be made in separate branches and merged into the main branch via pull requests. Please use meaningful commit messages.

- **Internal Use:**  
  This repository is intended for internal management and tracking of the PL/SQL projects directly associated with the corresponding JIRA stories.

## Dependencies & License

- **Dependencies:**  
  This repository contains only PL/SQL scripts and does not require any additional external libraries.

- **License:**  
  Copyright (c) 2025 [ICP Solution GmbH]

  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and the associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

  For more information, please visit the official website:  
  **[ICP Solution GmbH](https://www.icpsolution.com)**

## Contact & Support

If you have any questions, suggestions, or issues, please contact us via email:  
📩 **[raptile.bytez@gmail.com](mailto:raptile.bytez@gmail.com)**