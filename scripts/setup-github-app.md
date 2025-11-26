# GitHub App Setup Guide

This guide walks through creating a GitHub App for authenticating ARC (Actions Runner Controller) with your GitHub organization.

## Step 1: Create the GitHub App

1. Navigate to your organization's settings:
   - Go to https://github.com/organizations/infiquetra/settings
   - Or: GitHub → Your Organization → Settings

2. Go to **Developer settings** → **GitHub Apps**

3. Click **New GitHub App**

4. Fill in the basic information:
   - **GitHub App name:** `infiquetra-arc-runners`
   - **Homepage URL:** `https://github.com/infiquetra/github-actions-runners`
   - **Webhook:** Uncheck "Active" (not needed for ARC)

## Step 2: Configure Permissions

Under **Permissions**, set the following:

### Repository Permissions

| Permission | Access |
|------------|--------|
| Actions | Read-only |
| Administration | Read and write |
| Checks | Read-only |
| Metadata | Read-only |

### Organization Permissions

| Permission | Access |
|------------|--------|
| Self-hosted runners | Read and write |

## Step 3: Create the App

1. Under "Where can this GitHub App be installed?", select **Only on this account**

2. Click **Create GitHub App**

3. **Note the App ID** displayed on the app's settings page (you'll need this)

## Step 4: Generate Private Key

1. On the app's settings page, scroll down to **Private keys**

2. Click **Generate a private key**

3. A `.pem` file will be downloaded - **keep this secure!**

## Step 5: Install the App

1. In the left sidebar, click **Install App**

2. Click **Install** next to your organization (infiquetra)

3. Choose repository access:
   - **All repositories** (recommended for org-wide runners)
   - Or select specific repositories

4. Click **Install**

5. **Note the Installation ID** from the URL:
   - URL format: `https://github.com/organizations/infiquetra/settings/installations/INSTALLATION_ID`
   - The number at the end is your Installation ID

## Step 6: Record Credentials

You should now have three pieces of information:

| Credential | Where to find it | Example |
|------------|------------------|---------|
| App ID | GitHub App settings page | `123456` |
| Installation ID | URL after installing app | `12345678` |
| Private Key | Downloaded .pem file | `-----BEGIN RSA PRIVATE KEY-----...` |

## Step 7: Store Credentials in Ansible Vault

1. Create the vault file:
   ```bash
   ansible-vault create ansible/group_vars/all/vault.yml
   ```

2. Add the credentials:
   ```yaml
   github_app_id: "123456"
   github_app_installation_id: "12345678"
   github_app_private_key: |
     -----BEGIN RSA PRIVATE KEY-----
     MIIEpAIBAAKCAQEA...
     ...your private key content...
     -----END RSA PRIVATE KEY-----
   ```

3. Save and close the file

4. Create a vault password file (add to .gitignore!):
   ```bash
   echo "your-secure-password" > ~/.vault_pass
   chmod 600 ~/.vault_pass
   ```

## Verification

After deploying ARC, verify the app is working:

1. Check the controller logs:
   ```bash
   kubectl logs -n arc-systems -l app.kubernetes.io/name=gha-runner-scale-set-controller
   ```

2. Look for successful authentication messages

3. Check GitHub: Organization Settings → Actions → Runners
   - You should see your runner scale set listed

## Troubleshooting

### "Bad credentials" error

- Verify the App ID is correct
- Check that the private key is the complete PEM content
- Ensure the app is installed to the organization

### "Resource not accessible" error

- Verify the Installation ID is correct
- Check that the app has the required permissions
- Ensure the app is installed with access to the needed repositories

### Runner not appearing in GitHub

- Check controller logs for errors
- Verify the `githubConfigUrl` in Helm values matches your org URL
- Ensure the app has "Self-hosted runners" permission at the organization level

## Security Best Practices

1. **Never commit the private key** to version control
2. Use **Ansible Vault** for credential storage
3. **Rotate the private key** periodically
4. **Limit repository access** if you don't need org-wide runners
5. Consider using a **dedicated GitHub account** for the app owner
