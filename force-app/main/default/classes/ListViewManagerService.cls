/**
 * Service class to handle dynamic list view creation from custom metadata
 */
public with sharing class ListViewManagerService {
    
    /**
     * BULK METHOD: Creates list views for multiple accounts
     * @param accounts List of Account records with List_View_Group__c populated
     * @return List of created list view full names
     */
    public static List<String> createListViewsFromMetadata(List<Account> accounts) {
        if (accounts == null || accounts.isEmpty()) {
            System.debug('No accounts provided');
            return new List<String>();
        }
        
        // Query all List Views Manager metadata records
        List<List_Views_Manager__mdt> metadataRecords = [
            SELECT Label, DeveloperName, Object_Name__c, 
                   Columns_Fields__c, Filter_Criteria_JSON__c
            FROM List_Views_Manager__mdt
            WHERE Object_Name__c != null
        ];
        
        if (metadataRecords.isEmpty()) {
            System.debug('No List Views Manager metadata records found');
            return new List<String>();
        }
        
        // Collect all group Ids from accounts
        Set<Id> groupIds = new Set<Id>();
        for (Account acc : accounts) {
            if (String.isNotBlank(acc.List_View_Group__c)) {
                groupIds.add(acc.List_View_Group__c);
            }
        }
        
        if (groupIds.isEmpty()) {
            System.debug('No group Ids found on accounts');
            return new List<String>();
        }
        
        // Query all group developer names in bulk
        Map<Id, String> groupIdToDevNameMap = new Map<Id, String>();
        List<Group> groups = [
            SELECT Id, DeveloperName 
            FROM Group 
            WHERE Id IN :groupIds
        ];
        
        for (Group g : groups) {
            groupIdToDevNameMap.put(g.Id, g.DeveloperName);
        }
        
        // Create metadata service
        MetadataService.MetadataPort service = MetadataServiceExamples.createService();
        
        List<MetadataService.Metadata> listViewsToCreate = new List<MetadataService.Metadata>();
        List<String> listViewFullNames = new List<String>();
        
        // For each metadata record, create list views for all accounts
        for (List_Views_Manager__mdt metaRecord : metadataRecords) {
            for (Account acc : accounts) {
                try {
                    // Skip if account doesn't have group Id
                    if (String.isBlank(acc.List_View_Group__c)) {
                        System.debug('Account ' + acc.Name + ' has no group Id, skipping');
                        continue;
                    }
                    
                    // Generate list view name from account name (max 39 chars)
                    String listViewName = acc.Name.length() > 39 ? acc.Name.substring(0, 39) : acc.Name;
                    
                    // Get group developer name
                    String groupDevName = groupIdToDevNameMap.get(acc.List_View_Group__c);
                    if (groupDevName == null) {
                        System.debug('Group developer name not found for groupId: ' + acc.List_View_Group__c);
                        continue;
                    }
                    
                    MetadataService.ListView listView = buildListView(
                        metaRecord, 
                        listViewName, 
                        groupDevName,
                        acc.Name
                    );
                    listViewsToCreate.add(listView);
                    listViewFullNames.add(listView.fullName);
                } catch (Exception e) {
                    System.debug('Error building list view for ' + acc.Name + ' - ' + metaRecord.DeveloperName + ': ' + e.getMessage());
                }
            }
        }
        
        if (listViewsToCreate.isEmpty()) {
            return new List<String>();
        }
        
        // Create list views via Metadata API
        try {
            List<MetadataService.SaveResult> results = 
                service.createMetadata(listViewsToCreate);
            
            List<String> successfulListViews = new List<String>();
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].success) {
                    System.debug('List View created successfully: ' + listViewFullNames[i]);
                    successfulListViews.add(listViewFullNames[i]);
                } else if (results[i].errors != null && results[i].errors.size() > 0) {
                    System.debug('Error creating list view ' + listViewFullNames[i] + ': ' + 
                                results[i].errors[0].message);
                }
            }
            return successfulListViews;
        } catch (Exception e) {
            System.debug('Error in metadata deployment: ' + e.getMessage());
            throw new ListViewManagerException('Failed to create list views: ' + e.getMessage());
        }
    }
    
    /**
     * Builds a list view metadata object from custom metadata record
     */
    private static MetadataService.ListView buildListView(
        List_Views_Manager__mdt metaRecord, 
        String listViewName,
        String groupDeveloperName,
        String accountName
    ) {
        MetadataService.ListView listView = new MetadataService.ListView();
        
        // Set label: List View Name - Metadata Label
        listView.label = listViewName + ' - ' + metaRecord.Label;
        
        // Set fullName: ObjectName.SanitizedListViewName_MetadataDeveloperName
        String sanitizedName = sanitizeForApiName(metaRecord.DeveloperName + '_' + listViewName);
        listView.fullName = metaRecord.Object_Name__c + '.' + 
                           sanitizedName;
        
        // Set filter scope (default to Mine, can be customized)
        listView.filterScope = 'Everything';
        
        // Parse and set columns
        if (String.isNotBlank(metaRecord.Columns_Fields__c)) {
            listView.columns = parseColumns(metaRecord.Columns_Fields__c);
        }
        
        // Parse and set filters (from metadata + account filter)
        List<MetadataService.ListViewFilter> allFilters = new List<MetadataService.ListViewFilter>();
        
        // Add filters from metadata
        if (String.isNotBlank(metaRecord.Filter_Criteria_JSON__c)) {
            allFilters.addAll(parseFilters(metaRecord.Filter_Criteria_JSON__c));
        }
        
        // Add account name filter if provided
        if (String.isNotBlank(accountName)) {
            MetadataService.ListViewFilter accountFilter = new MetadataService.ListViewFilter();
            // For Account object, use NAME field; for other objects, use ACCOUNT_NAME
            if (metaRecord.Object_Name__c.equalsIgnoreCase('Account')) {
                accountFilter.field = 'NAME';
            } else {
                accountFilter.field = 'ACCOUNT.NAME';
            }
            accountFilter.operation = 'equals';
            accountFilter.value = accountName;
            allFilters.add(accountFilter);
            System.debug('Added account filter: ' + accountFilter.field + ' = ' + accountName);
        }
        
        if (!allFilters.isEmpty()) {
            listView.filters = allFilters;
        }
        
        // Set sharing if group provided
        if (String.isNotBlank(groupDeveloperName)) {
            MetadataService.SharedTo sharedTo = new MetadataService.SharedTo();
            sharedTo.group_x = new String[] { groupDeveloperName };
            listView.sharedTo = sharedTo;
            System.debug('List view will be shared with group: ' + groupDeveloperName);
        }
        
        return listView;
    }
    
    /**
     * Parses comma-separated column fields
     */
    private static String[] parseColumns(String columnsString) {
        List<String> columns = new List<String>();
        for (String column : columnsString.split(',')) {
            String trimmedColumn = column.trim();
            if (String.isNotBlank(trimmedColumn)) {
                columns.add(trimmedColumn);
            }
        }
        return columns;
    }
    
    /**
     * Parses filter criteria JSON and creates filter objects
     * Supports both single filter object and array of filters
     */
    private static MetadataService.ListViewFilter[] parseFilters(String filterJson) {
        List<MetadataService.ListViewFilter> filters = new List<MetadataService.ListViewFilter>();
        
        try {
            // Try to parse as array first
            if (filterJson.trim().startsWith('[')) {
                List<Object> filterList = (List<Object>) JSON.deserializeUntyped(filterJson);
                for (Object filterObj : filterList) {
                    Map<String, Object> filterMap = (Map<String, Object>) filterObj;
                    filters.add(createFilter(filterMap));
                }
            } else {
                // Parse as single object
                Map<String, Object> filterMap = (Map<String, Object>) JSON.deserializeUntyped(filterJson);
                filters.add(createFilter(filterMap));
            }
        } catch (Exception e) {
            System.debug('Error parsing filter JSON: ' + e.getMessage());
            throw new ListViewManagerException('Invalid filter JSON format: ' + e.getMessage());
        }
        
        return filters;
    }
    
    /**
     * Creates a ListViewFilter from a map
     */
    private static MetadataService.ListViewFilter createFilter(Map<String, Object> filterMap) {
        MetadataService.ListViewFilter filter = new MetadataService.ListViewFilter();
        filter.field = (String) filterMap.get('field');
        filter.operation = (String) filterMap.get('operation');
        filter.value = (String) filterMap.get('value');
        return filter;
    }
    
    /**
     * Sanitizes a string to be used in API names
     * Removes special characters, replaces spaces with underscores
     */
    private static String sanitizeForApiName(String input) {
        String sanitized = input.replaceAll('[^a-zA-Z0-9]', '_');
        sanitized = sanitized.replaceAll('_+', '_'); // Replace multiple underscores with single
        sanitized = sanitized.replaceAll('^_|_$', ''); // Remove leading/trailing underscores
        
        // Limit length to 40 characters
        if (sanitized.length() > 40) {
            sanitized = sanitized.substring(0, 40);
        }
        
        return sanitized;
    }
    
    /**
     * Custom exception class
     */
    public class ListViewManagerException extends Exception {}
}

