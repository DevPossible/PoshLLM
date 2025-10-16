# Quick Setup Guide for Automated Publishing

This guide will help you set up automated publishing to PowerShell Gallery via GitHub Actions.

## ✅ What's Already Done

The following are already configured and ready:
- ✅ Module manifest (PoshLLM.psd1) with all PowerShell Gallery metadata
- ✅ LICENSE file (MIT License)
- ✅ Comprehensive README.md
- ✅ GitHub Actions workflow (.github/workflows/publish-to-psgallery.yml)
- ✅ Publishing documentation (PUBLISHING.md)

## 🔧 What You Need to Do

### Step 1: Get PowerShell Gallery API Key

1. Go to https://www.powershellgallery.com/
2. Sign in or create an account
3. Navigate to **Account Settings** → **API Keys**
4. Click **Create** to generate a new API key
5. **Copy the key** (you won't be able to see it again!)

### Step 2: Add API Key to GitHub Secrets

1. Go to your GitHub repository: https://github.com/DevPossible/PoshLLM
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Enter the following:
   - **Name**: `PSGALLERY_API_KEY`
   - **Secret**: Paste your PowerShell Gallery API key
5. Click **Add secret**

### Step 3: Enable GitHub Actions (if not already enabled)

1. Go to the **Actions** tab in your repository
2. If prompted, click **Enable Actions**
3. Verify the workflow appears: "Publish to PowerShell Gallery"

## 🚀 How It Works

### Automatic Publishing

Once set up, the module will automatically publish to PowerShell Gallery when:
- You push changes to the `main` branch
- The changes affect files in `Source/` or `PoshLLM.psd1`

### Version Requirements

**CRITICAL**: Before each push to main, increment the version in `PoshLLM.psd1`:

```powershell
ModuleVersion = '0.2.0'  # Must be > current gallery version
```

The workflow will **fail** if you try to publish an existing version.

### Workflow Steps

The GitHub Actions workflow automatically:
1. ✅ Checks out the code
2. ✅ Tests the module manifest
3. ✅ Imports and validates the module
4. ✅ Verifies the version is new
5. ✅ Publishes to PowerShell Gallery
6. ✅ Creates a summary with installation instructions

## 📋 Publishing Checklist

Before pushing to main:

- [ ] Make your code changes
- [ ] Update `ModuleVersion` in PoshLLM.psd1
- [ ] Update `ReleaseNotes` in PoshLLM.psd1
- [ ] Test locally:
  ```powershell
  Test-ModuleManifest -Path ".\PoshLLM.psd1"
  Import-Module ".\PoshLLM.psd1" -Force
  Get-PoshLLMInfo
  ```
- [ ] Commit your changes
- [ ] Push to main branch
- [ ] Monitor the Actions tab for workflow status
- [ ] Verify publication at https://www.powershellgallery.com/packages/PoshLLM

## 🔍 Monitoring

### Check Workflow Status

1. Go to **Actions** tab in your repository
2. Click on the latest "Publish to PowerShell Gallery" workflow run
3. View the detailed logs and summary

### Verify Publication

After workflow completes (usually 2-3 minutes):
1. Visit https://www.powershellgallery.com/packages/PoshLLM
2. Verify the new version appears
3. Test installation:
   ```powershell
   Install-Module -Name PoshLLM -Force
   ```

## 🎯 First Publication

For your first publication:

1. Complete Steps 1-2 above (API key setup)
2. The current version is `0.1.0` - this is ready to publish
3. Push to main or manually trigger the workflow from the Actions tab
4. Wait 5-10 minutes for PowerShell Gallery indexing
5. Install and test:
   ```powershell
   Install-Module -Name PoshLLM -Scope CurrentUser
   Import-Module PoshLLM
   Get-PoshLLMInfo
   ```

## 🆘 Troubleshooting

### Workflow Fails: "API key is not set"
- Verify the secret name is exactly `PSGALLERY_API_KEY`
- Regenerate the API key if needed

### Workflow Fails: "Version already exists"
- Increment the version in `PoshLLM.psd1`
- Ensure version follows semantic versioning

### Workflow Fails: "Invalid manifest"
- Run `Test-ModuleManifest -Path ".\PoshLLM.psd1"`
- Fix any errors and push again

### Module Not Appearing on Gallery
- Wait 5-10 minutes for indexing
- Check workflow logs for actual publication success

## 📚 More Information

- Full publishing details: See [PUBLISHING.md](PUBLISHING.md)
- Module documentation: See [README.md](README.md)
- GitHub Actions docs: https://docs.github.com/actions

---

**Current Status**: Ready for automated publishing! Just add the API key to GitHub secrets and push to main.
