# SharpPS.Extension Chocolatey Package

SharpPS.Extension is a Chocolatey package designed to help developers quickly set up tools for creating and building Visual Studio solutions efficiently.

## Features
- Simplifies the setup for Visual Studio solution creation.
- Integrates with build tools to streamline the development process.
- Lightweight and easy to use.

## Installation

To install SharpPS.Extension via Chocolatey, run the following command in an elevated command prompt or PowerShell:

```powershell
choco install sharpps.extension
```

Ensure you have [Chocolatey](https://chocolatey.org/install) installed before running the above command.

## Usage

Once installed, you can use SharpPS.Extension to:
1. Create a new Visual Studio solution.
2. Build Visual Studio solutions efficiently using command-line tools.

### Commands

#### Create a New Solution for Sitecore
```powershell
New-SharpPSSitecore `
            -SolutionName  sitecore104 `
            -Version 10.4 `
            -TargetDirectory C:\Projects `
            -Url https:\\sitecore.x4.dev `
            -SitecorePath C:\inetpub\wwwroot\sitecore.x4.dev
```
This command creates a new Visual Studio solution named `sitecore104` in the specified path.

#### Build an Existing Solution
```powershell
 Invoke-SharpPSBuild `
            -Verbose `
            -Path VSSolution.sln `
            -Targets Restore, Rebuild
```
This command builds the specified Visual Studio solution file.

## Requirements
- Windows operating system.
- Visual Studio installed (optional).

## Uninstallation

To uninstall SharpPS.Extension, run the following command:

```powershell
choco uninstall sharpps.extension
```

## Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request on the [GitHub repository](https://github.com/your-repo/sharpps.extension).

## License

SharpPS.Extension is licensed under the MIT License. See the [LICENSE](./tools/LICENSE.txt) file for details.

---

Enjoy using SharpPS.Extension to streamline your Visual Studio solution creation and build processes!

