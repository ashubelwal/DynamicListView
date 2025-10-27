# List Views Manager Framework

## Overview

This framework provides an automated solution for creating and sharing dynamic list views in Salesforce when an Account becomes a Partner. It uses Custom Metadata Types for configuration and Salesforce Metadata API for list view creation and sharing.

## Architecture

### Components

1. **Custom Metadata Type**: `List_Views_Manager__mdt`
2. **Services**:
   - `GroupService` - Manages public group creation
   - `ListViewManagerService` - Creates list views from metadata
   - `ListViewSharingService` - Shares list views with groups
3. **Trigger & Handler**:
   - `AccountTrigger` - Fires on Account updates
   - `AccountTriggerHandler` - Orchestrates the entire workflow

## Setup Instructions

### 1. Deploy Components

Deploy all components to your Salesforce org:

```bash
sfdx force:source:deploy -p force-app/main/default
```

### 2. Create Custom Metadata Records

Create records in the `List_Views_Manager__mdt` Custom Metadata Type with the following fields:

#### Required Fields:
- **Label**: Display name (e.g., "Opportunity - Hot")
- **DeveloperName**: API name (e.g., "Opportunity_Hot")
- **Object_Name__c**: The Salesforce object (e.g., "Opportunity", "Account")
- **Columns_Fields__c**: Comma-separated list of fields to display
  ```
  Example: OPPORTUNITY.NAME,OPPORTUNITY.ACCOUNT_NAME,OPPORTUNITY.AMOUNT,OPPORTUNITY.CLOSE_DATE
  ```
- **Filter_Criteria_JSON__c**: JSON string defining filter criteria
  ```json
  Single Filter:
  {"field":"OPPORTUNITY.RATING","operation":"equals","value":"Hot"}
  
  Multiple Filters:
  [
    {"field":"OPPORTUNITY.RATING","operation":"equals","value":"Hot"},
    {"field":"OPPORTUNITY.STAGE_NAME","operation":"notEqual","value":"Closed Lost"}
  ]
  ```

### 3. Configure Remote Site Settings

Ensure the Metadata API endpoint is configured in Remote Site Settings:

```
Setup → Security → Remote Site Settings
Name: MetadataAPI
Remote Site URL: https://your-instance.salesforce.com
Active: Checked
```

## How It Works

### Workflow

1. **Trigger**: When an Account's `IsPartner` field changes from `false` to `true`:
   
2. **Group Creation**: 
   - Creates a public group named after the Account
   - If group already exists, uses existing group

3. **List View Creation & Sharing** (Single Step):
   - Queries all `List_Views_Manager__mdt` records
   - For each metadata record, creates a list view with:
     - **Label**: `{AccountName} - {MetadataLabel}`
     - **FullName**: `{ObjectName}.{SanitizedAccountName}_{MetadataDeveloperName}`
     - **SharedTo**: Automatically shared with the group at creation time
   - Uses columns and filters from metadata configuration
   - **Optimization**: Sharing is set during creation (not as a separate step)

### Example

**Account**: "Acme Corporation" becomes a Partner

**Metadata Record**:
- Label: "Opportunity - Hot"
- DeveloperName: "Opportunity_Hot"
- Object_Name__c: "Opportunity"

**Result**:
- Group Created: "Acme Corporation"
- List View Created: 
  - Label: "Acme Corporation - Opportunity - Hot"
  - API Name: "Opportunity.Acme_Corporation_Opportunity_Hot"
- List View Shared: With "Acme Corporation" group

## Sample Custom Metadata Records

Two sample records are included:

### 1. Opportunity - Hot
```xml
Label: Opportunity - Hot
Object: Opportunity
Columns: NAME, ACCOUNT_NAME, AMOUNT, CLOSE_DATE, STAGE_NAME, OWNER_ALIAS
Filter: Rating equals "Hot"
```

### 2. Account - Premium
```xml
Label: Account - Premium
Object: Account
Columns: NAME, SITE, PHONE, TYPE, RATING, INDUSTRY
Filter: Rating equals "Hot"
```

## Usage

### Automatic (via Trigger)

Simply update an Account's `IsPartner` field to `true`:

```apex
Account acc = [SELECT Id, IsPartner FROM Account LIMIT 1];
acc.IsPartner = true;
update acc;
```

### Manual Invocation

For testing or manual execution:

```apex
// Get account ID
Id accountId = [SELECT Id FROM Account WHERE Name = 'Acme Corporation' LIMIT 1].Id;

// Process asynchronously (recommended)
AccountTriggerHandler.processAccountAsync(accountId);
```

## Filter Operations

Supported filter operations in `Filter_Criteria_JSON__c`:

- `equals`
- `notEqual`
- `lessThan`
- `greaterThan`
- `lessOrEqual`
- `greaterOrEqual`
- `contains`
- `notContain`
- `startsWith`

## Field References

When specifying columns and filters, use Salesforce's list view field notation:

### Standard Objects:
- `ACCOUNT.NAME`, `ACCOUNT.PHONE1`, `ACCOUNT.RATING`
- `OPPORTUNITY.NAME`, `OPPORTUNITY.AMOUNT`, `OPPORTUNITY.CLOSE_DATE`
- `CORE.USERS.ALIAS`, `CORE.USERS.FIRST_NAME`

### Custom Objects:
- `CustomObject__c.CustomField__c`

## Limitations & Considerations

1. **Asynchronous Processing**: The framework uses `@future(callout=true)` to avoid mixed DML and callout limitations

2. **Governor Limits**: 
   - Maximum 100 Metadata API calls per transaction
   - Consider batching for large volumes

3. **Sharing Restrictions**: List view sharing requires the group to be a public group (not queue or role)

4. **API Name Length**: Account names are sanitized and truncated to 40 characters for API names

5. **Metadata API Access**: Ensure the running user has "Modify All Data" or "Customize Application" permission

## Troubleshooting

### List Views Not Created

**Check**:
1. Debug logs for errors
2. Metadata API remote site settings
3. SessionId validity
4. Custom Metadata records exist

### Sharing Fails

**Check**:
1. Group was created successfully
2. List view was created before sharing attempt
3. Group is of type "Regular" (public group)

### Trigger Not Firing

**Check**:
1. Trigger is active
2. `IsPartner` field actually changed from false to true
3. User has appropriate permissions

## Debug Logs

Enable debug logs to monitor execution:

```apex
System.debug('Processing partner account: ' + accountName);
System.debug('Group created with Id: ' + groupId);
System.debug('Created ' + createdListViews.size() + ' list views');
```

## Extending the Framework

### Add Custom Logic

Extend `AccountTriggerHandler` to add custom processing:

```apex
public static void processAccountAsync(Id accountId) {
    // Existing logic...
    
    // Add custom logic here
    sendNotificationEmail(accountId);
    updateRelatedRecords(accountId);
}
```

### Support Additional Objects

Simply create new Custom Metadata records with different `Object_Name__c` values.

### Complex Filters

Use JSON arrays for multiple filter conditions:

```json
[
  {"field":"OPPORTUNITY.AMOUNT","operation":"greaterThan","value":"100000"},
  {"field":"OPPORTUNITY.STAGE_NAME","operation":"notEqual","value":"Closed Lost"}
]
```

## Best Practices

1. **Test in Sandbox**: Always test in a sandbox environment first
2. **Monitor Limits**: Keep track of Metadata API usage
3. **Error Handling**: Implement custom error logging for production
4. **Naming Conventions**: Use clear, descriptive names for metadata records
5. **Documentation**: Document each Custom Metadata record's purpose

## Support & Maintenance

### Monitoring

Check for errors:
```apex
System.debug logs
Setup → Apex Jobs (for @future methods)
```

### Updating Metadata

To modify list views:
1. Update Custom Metadata records
2. Re-trigger the process by toggling `IsPartner` or calling manually

## Version History

- **v1.0** - Initial framework release
  - Custom Metadata Type creation
  - Dynamic list view generation
  - Automatic group creation and sharing
  - Account trigger integration

## Contact

For issues or enhancements, please review the code comments and test thoroughly before deploying to production.

