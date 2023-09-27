# MFA Status Report Script

This PowerShell script is designed to retrieve Multi-Factor Authentication (MFA) status information for each user within an organization. It ensures the user has the necessary administrative privileges, connects to Azure AD, and exports the MFA status report.

## Table of Contents

* [Features](#features)
* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
* [Output](#output)
* [Contributing](#contributing)
* [License](#license)

## Features

* Checks for Administrator privileges and prompts for elevation if necessary.
* Displays a warning message regarding script's capabilities.
* Checks for and installs missing required modules.
* Initializes log file with timestamps for tracking actions.
* Retrieves information for multiple accounts, with the option to specify email address or label for each export.
* Exports MFA Status Report containing details like UserPrincipalName, DisplayName, MFAStatus, PreferredMFA, PhoneNumber, MainEmailAddress, and EmailAliases.

## Requirements

* PowerShell
* Administrator Privileges
* Required Modules: AzureAD, MSOnline

## Installation

1. **Clone the Repository**
    
    ```sh
    git clone https://github.com/username/repository-name.git
    ```
    
2. **Navigate to Project Directory**
    
    ```sh
    cd repository-name
    ```
    

## Usage

1. **Run the Script**
    
    ```sh
    .\ScriptName.ps1
    ```
    
2. **Follow the Prompts**
    * The script will check for administrator privileges and required modules, prompting you for actions as necessary.
    * Enter the email address or label for the export when prompted.
    * Respond to any additional prompts to retrieve information for another account or to handle exceptions.

## Output

The script will generate a CSV file named `{Email}_MFAStatusReport.csv` in the `export` directory within the script’s location. The report contains details such as UserPrincipalName, DisplayName, MFAStatus, PreferredMFA, PhoneNumber, MainEmailAddress, and EmailAliases.

## Contributing

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/NewFeature`)
3. Commit your Changes (`git commit -m 'Add some NewFeature'`)
4. Push to the Branch (`git push origin feature/NewFeature`)
5. Open a Pull Request

## License

Distributed under the License. See [LICENSE](LICENSE) for more information.
