# List Views Manager Framework

An automated Salesforce framework for dynamically creating and sharing list views when Accounts become Partners.

## Features

- 🎯 **Metadata-Driven**: Configure list views using Custom Metadata Types
- 🔄 **Automatic Trigger**: Activates when Account's `IsPartner` field becomes true
- 👥 **Group Management**: Automatically creates and manages public groups
- 🔐 **Sharing**: Shares list views with designated groups
- 📊 **Flexible Filters**: Support for complex JSON-based filter criteria
- ⚡ **Asynchronous**: Handles Metadata API callouts efficiently

## Quick Start

### 1. Deploy to Org
```bash
sfdx force:source:deploy -p force-app/main/default
```

### 2. Create Metadata Records
Navigate to: **Setup → Custom Metadata Types → List Views Manager → Manage Records**

Create a record with:
- **Object Name**: `Opportunity`
- **Columns Fields**: `OPPORTUNITY.NAME,OPPORTUNITY.AMOUNT,OPPORTUNITY.STAGE_NAME`
- **Filter Criteria JSON**: `{"field":"OPPORTUNITY.RATING","operation":"equals","value":"Hot"}`

### 3. Test
```apex
Account acc = [SELECT Id FROM Account LIMIT 1];
acc.IsPartner = true;
update acc;
```

## Documentation

For complete documentation, see [FRAMEWORK_DOCUMENTATION.md](./FRAMEWORK_DOCUMENTATION.md)

## Components

- **Custom Metadata Type**: `List_Views_Manager__mdt`
- **Apex Classes**: 
  - `GroupService` - Group management
  - `ListViewManagerService` - List view creation
  - `ListViewSharingService` - List view sharing
  - `AccountTriggerHandler` - Business logic orchestration
- **Trigger**: `AccountTrigger` - Account update trigger

## Architecture

```
Account Update (IsPartner = true)
    ↓
AccountTrigger
    ↓
AccountTriggerHandler
    ↓
    ├─→ GroupService.createPublicGroup() → Returns groupId
    └─→ ListViewManagerService.createListViewsFromMetadata(accountName, groupId)
        Creates list views with sharing included (optimized single-step)
```

### Key Optimization
List views are created **with sharing already set** using the `sharedTo` property in the Metadata API. This eliminates the need for a separate sharing step, reducing API calls by 50%.

---

## Salesforce DX Resources

Now that you've created a Salesforce DX project, what's next? Here are some documentation resources to get you started.

## How Do You Plan to Deploy Your Changes?

Do you want to deploy a set of changes, or create a self-contained application? Choose a [development model](https://developer.salesforce.com/tools/vscode/en/user-guide/development-models).

## Configure Your Salesforce DX Project

The `sfdx-project.json` file contains useful configuration information for your project. See [Salesforce DX Project Configuration](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_config.htm) in the _Salesforce DX Developer Guide_ for details about this file.

## Read All About It

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)
