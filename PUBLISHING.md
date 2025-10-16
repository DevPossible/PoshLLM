# Publishing PoshLLM to PowerShell Gallery

This guide explains how to publish the PoshLLM module to the PowerShell Gallery.

## Prerequisites

Before publishing, ensure you have:

1. **PowerShell Gallery Account**: Create an account at [PowerShell Gallery](https://www.powershellgallery.com/)
2. **API Key**: Generate an API key from your PowerShell Gallery account settings
3. **PowerShell 7+**: Ensure you're using PowerShell 7 or later
4. **PowerShellGet Module**: Update to the latest version:
   ```powershell
   Install-Module -Name PowerShellGet -Force -AllowClobber
   ```

## Pre-Publication Checklist

Before publishing, verify the following:

- [x] Module manifest (PoshLLM.psd1) is valid and complete
- [x] LICENSE file exists
- [x] README.md is comprehensive and up-to-date
- [x] All functions are properly documented with comment-based help
- [x] Module version is correct in PoshLLM.psd1
- [ ] All tests pass successfully
- [ ] Module loads without errors

## Validation Steps

### 1. Test the Module Manifest

```powershell
Test-ModuleManifest -Path ".\PoshLLM.psd1"
```

This should return module information without errors.

### 2. Import and Test the Module

```powershell
# Import the module
Import-Module ".\PoshLLM.psd1" -Force

# Verify exported functions
Get-Command -Module PoshLLM

# Test basic functionality
Get-PoshLLMInfo
```

### 3. Run Any Available Tests

```powershell
# If you have Pester tests
Invoke-Pester -Path ".\Tests\"
```

## Automated Publishing with GitHub Actions

This repository includes a GitHub Actions workflow that automatically publishes the module to PowerShell Gallery when changes are pushed to the main branch.

### Setup GitHub Actions

1. **Get your PowerShell Gallery API Key**:
   - Visit https://www.powershellgallery.com/
   - Sign in to your account
   - Go to Account Settings → API Keys
   - Generate a new API key (if you don't have one)
   - Copy the key (you won't be able to see it again)

2. **Add API Key as GitHub Secret**:
   - Go to your GitHub repository
   - Navigate to Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `PSGALLERY_API_KEY`
   - Value: Paste your PowerShell Gallery API key
   - Click "Add secret"

3. **Workflow Triggers**:
   The workflow automatically runs when:
   - Changes are pushed to the `main` branch that affect:
     - Files in the `Source/` directory
     - The `PoshLLM.psd1` manifest file
   - You can also manually trigger it from the Actions tab

### Automated Workflow Features

The GitHub Actions workflow performs these steps:
- ✅ Validates the module manifest
- ✅ Imports and tests the module
- ✅ Checks if the version already exists on PowerShell Gallery
- ✅ Publishes to PowerShell Gallery (if version is new)
- ✅ Creates a summary with installation instructions

### Version Management with Automation

**IMPORTANT**: Before pushing to main, always increment the version in `PoshLLM.psd1`:

```powershell
ModuleVersion = '0.2.0'  # Must be greater than current gallery version
```

The workflow will fail if you try to publish a version that already exists. This prevents accidental overwrites.

### Workflow Status

Check the status of your publication:
- Go to the "Actions" tab in your GitHub repository
- Find the "Publish to PowerShell Gallery" workflow
- View logs and summaries for each run

## Manual Publishing to PowerShell Gallery

If you prefer to publish manually or need to publish outside of the automated workflow:

### First Time Publication

1. **Set your API Key** (replace with your actual API key):
   ```powershell
   $apiKey = "YOUR-API-KEY-HERE"
   ```

2. **Publish the module**:
   ```powershell
   Publish-Module -Path "." -NuGetApiKey $apiKey -Verbose
   ```

   Or if you need to specify the repository:
   ```powershell
   Publish-Module -Path "." -NuGetApiKey $apiKey -Repository PSGallery -Verbose
   ```

3. **Verify publication**:
   - Visit https://www.powershellgallery.com/packages/PoshLLM
   - Wait 5-10 minutes for indexing to complete
   - Search for the module: `Find-Module -Name PoshLLM`

## Publishing Updates

When publishing updates to the module:

1. **Update the version** in `PoshLLM.psd1`:
   ```powershell
   ModuleVersion = '0.2.0'  # Increment appropriately
   ```

2. **Update ReleaseNotes** in the PrivateData section:
   ```powershell
   ReleaseNotes = 'Version 0.2.0:
   - Added new feature X
   - Fixed bug Y
   - Improved performance of Z'
   ```

3. **Publish the updated module**:
   ```powershell
   Publish-Module -Path "." -NuGetApiKey $apiKey -Verbose
   ```

## Version Guidelines

Follow [Semantic Versioning](https://semver.org/):

- **Major version (1.0.0)**: Breaking changes or major new features
- **Minor version (0.1.0)**: New features, backward compatible
- **Patch version (0.0.1)**: Bug fixes, backward compatible

## Troubleshooting

### "Module already exists" Error

If you see an error about the module already existing, you need to increment the version number in `PoshLLM.psd1`.

### "Invalid manifest" Error

Run `Test-ModuleManifest -Path ".\PoshLLM.psd1"` to identify manifest issues.

### "Missing required fields" Error

Ensure your manifest includes:
- GUID
- Author
- Description
- PowerShellVersion
- FunctionsToExport
- LicenseUri (in PrivateData.PSData)
- ProjectUri (in PrivateData.PSData)

## Post-Publication

After successful publication:

1. **Test installation** on a clean system:
   ```powershell
   Install-Module -Name PoshLLM -Scope CurrentUser
   Import-Module PoshLLM
   Get-PoshLLMInfo
   ```

2. **Update documentation** if needed

3. **Create a GitHub release** matching the module version

4. **Announce the release** to your users

## Security Considerations

- Never commit your API key to version control
- Store API keys securely (e.g., in environment variables or secure vaults)
- Review all code before publishing
- Ensure no sensitive information is included in the module

## Additional Resources

- [PowerShell Gallery Publishing Guidelines](https://docs.microsoft.com/powershell/scripting/gallery/how-to/publishing-packages/publishing-a-package)
- [PowerShell Module Manifest](https://docs.microsoft.com/powershell/scripting/developer/module/how-to-write-a-powershell-module-manifest)
- [PowerShellGet Documentation](https://docs.microsoft.com/powershell/module/powershellget/)

## Recommended Workflow

### For Version Updates:

1. **Make your changes** to the module code
2. **Update the version** in `PoshLLM.psd1`
3. **Update ReleaseNotes** in the manifest
4. **Test locally**:
   ```powershell
   Test-ModuleManifest -Path ".\PoshLLM.psd1"
   Import-Module ".\PoshLLM.psd1" -Force
   ```
5. **Commit and push** to main branch
6. **GitHub Actions will automatically publish** to PowerShell Gallery
7. **Verify** on https://www.powershellgallery.com/packages/PoshLLM

### For Emergency Manual Publishing:

If the automated workflow fails or you need to publish manually:
```powershell
$apiKey = $env:PSGALLERY_API_KEY  # Or your secure method
Publish-Module -Path "." -NuGetApiKey $apiKey -Verbose
```

## Current Module Status

- **Version**: 0.1.0
- **Status**: Ready for initial publication
- **Automated Publishing**: ✅ Configured via GitHub Actions
- **Required Actions**: 
  - Add `PSGALLERY_API_KEY` to GitHub repository secrets
  - Push to main branch to trigger first publication
  - Monitor workflow in GitHub Actions tab

---

**Ready to Publish**: The module manifest has been updated with all required metadata for PowerShell Gallery publication, and automated publishing is configured via GitHub Actions.
