# List Views Manager - Quick Reference Card

## Custom Metadata Record Structure

### List_Views_Manager__mdt

| Field | Type | Required | Example |
|-------|------|----------|---------|
| Label | Text | Yes | "Opportunity - Hot" |
| DeveloperName | Text | Yes | "Opportunity_Hot" |
| Object_Name__c | Text | Yes | "Opportunity" or "Account" |
| Columns_Fields__c | Long Text | No | "OPPORTUNITY.NAME,OPPORTUNITY.AMOUNT" |
| Filter_Criteria_JSON__c | Long Text | No | `{"field":"OPPORTUNITY.RATING","operation":"equals","value":"Hot"}` |

## Filter JSON Format

### Single Filter
```json
{
  "field": "OPPORTUNITY.RATING",
  "operation": "equals",
  "value": "Hot"
}
```

### Multiple Filters
```json
[
  {
    "field": "OPPORTUNITY.AMOUNT",
    "operation": "greaterThan",
    "value": "100000"
  },
  {
    "field": "OPPORTUNITY.STAGE_NAME",
    "operation": "notEqual",
    "value": "Closed Lost"
  }
]
```

## Filter Operations

| Operation | Description | Example Value |
|-----------|-------------|---------------|
| `equals` | Exact match | "Hot" |
| `notEqual` | Not equal to | "Cold" |
| `lessThan` | Less than | "100" |
| `greaterThan` | Greater than | "1000" |
| `lessOrEqual` | Less than or equal | "500" |
| `greaterOrEqual` | Greater than or equal | "200" |
| `contains` | Contains text | "Corp" |
| `notContain` | Doesn't contain | "Test" |
| `startsWith` | Starts with | "A" |

## Common Field References

### Account Fields
```
ACCOUNT.NAME
ACCOUNT.SITE
ACCOUNT.PHONE1
ACCOUNT.TYPE
ACCOUNT.RATING
ACCOUNT.INDUSTRY
ACCOUNT.OWNER_ALIAS
ACCOUNT.ADDRESS1_STATE_CODE
```

### Opportunity Fields
```
OPPORTUNITY.NAME
OPPORTUNITY.ACCOUNT_NAME
OPPORTUNITY.AMOUNT
OPPORTUNITY.CLOSE_DATE
OPPORTUNITY.STAGE_NAME
OPPORTUNITY.PROBABILITY
OPPORTUNITY.TYPE
OPPORTUNITY.LEAD_SOURCE
```

### User Fields
```
CORE.USERS.ALIAS
CORE.USERS.FIRST_NAME
CORE.USERS.LAST_NAME
CORE.USERS.EMAIL
```

### Custom Fields
```
CustomObject__c.CustomField__c
Account.CustomField__c
```

## Naming Convention

### List View Naming
- **Label**: `{AccountName} - {MetadataLabel}`
- **API Name**: `{ObjectName}.{SanitizedAccountName}_{MetadataDeveloperName}`

### Example
- Account Name: "Acme Corporation"
- Metadata Label: "Opportunity - Hot"
- Metadata DeveloperName: "Opportunity_Hot"

**Result**:
- List View Label: "Acme Corporation - Opportunity - Hot"
- List View API Name: "Opportunity.Acme_Corporation_Opportunity_Hot"

## API Reference

### Manual Invocation

#### Process Single Account (Async)
```apex
AccountTriggerHandler.processAccountAsync(accountId);
```

#### Create Group Only
```apex
Id groupId = GroupService.createPublicGroup('Group Name');
```

#### Create List Views Only
```apex
List<String> listViewNames = ListViewManagerService.createListViewsFromMetadata('Account Name');
```

#### Share List Views
```apex
List<String> sharedViews = ListViewSharingService.shareListViewsWithGroup(listViewNames, groupId);
```

## Trigger Behavior

### When Trigger Fires
- **Event**: Account Update
- **Condition**: `IsPartner` changes from `false` to `true`
- **Context**: After Update

### What Happens
1. ✅ Creates public group named after Account
2. ✅ Queries all List_Views_Manager__mdt records
3. ✅ Creates one list view per metadata record
4. ✅ Shares all list views with the group
5. ✅ Logs all actions to debug logs

## Testing Commands

### Anonymous Apex

#### Test Group Creation
```apex
Id groupId = GroupService.createPublicGroup('Test Group');
System.debug('Group Id: ' + groupId);
```

#### Test List View Creation
```apex
List<String> listViews = ListViewManagerService.createListViewsFromMetadata('Test Account');
System.debug('Created: ' + listViews);
```

#### Test Complete Flow
```apex
Account testAccount = new Account(Name='Test Partner Account', IsPartner=false);
insert testAccount;

testAccount.IsPartner = true;
update testAccount;
// Check debug logs for progress
```

#### Manual Process
```apex
Id accId = [SELECT Id FROM Account WHERE Name='Test Partner Account' LIMIT 1].Id;
AccountTriggerHandler.processAccountAsync(accId);
```

## Debug Checklist

### List Views Not Created?
- [ ] Check Custom Metadata records exist
- [ ] Verify Object_Name__c is correct
- [ ] Check Metadata API remote site settings
- [ ] Review debug logs for errors
- [ ] Verify SessionId is valid

### Sharing Failed?
- [ ] Confirm group was created
- [ ] Verify list views were created first
- [ ] Check group type is "Regular"
- [ ] Review sharing permissions

### Trigger Not Firing?
- [ ] Verify `IsPartner` actually changed from false→true
- [ ] Check trigger is Active
- [ ] Confirm user has edit access
- [ ] Review trigger handler logic

## Governor Limits

| Operation | Limit | Impact |
|-----------|-------|--------|
| Metadata API Calls | 100/transaction | Batch large operations |
| SOQL Queries | 100/transaction | Efficient queries used |
| DML Statements | 150/transaction | Groups inserted individually |
| Future Methods | 50/transaction | One per account update |

## Best Practices

1. ✅ Test in Sandbox first
2. ✅ Use meaningful metadata record names
3. ✅ Document filter criteria
4. ✅ Monitor API usage
5. ✅ Keep field lists concise
6. ✅ Use bulk-safe patterns
7. ✅ Enable debug logging for troubleshooting

## Common Errors & Solutions

### "Invalid Session ID"
**Solution**: Check Remote Site Settings for Metadata API

### "Object not found"
**Solution**: Verify Object_Name__c spelling and case

### "Field not found"
**Solution**: Use correct field API names (e.g., ACCOUNT.NAME not Account.Name)

### "Group already exists"
**Solution**: Framework handles this automatically, reuses existing group

### "Insufficient privileges"
**Solution**: User needs "Modify All Data" or "Customize Application" permission

## Support

- Review [FRAMEWORK_DOCUMENTATION.md](./FRAMEWORK_DOCUMENTATION.md) for detailed information
- Check debug logs for execution details
- Enable "Finest" logging level for Apex classes during troubleshooting

