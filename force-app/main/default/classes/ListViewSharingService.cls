/**
 * Service class to handle sharing list views with groups
 * Note: List View sharing is done through SharedTo field in the ListView metadata
 */
public with sharing class ListViewSharingService {
    
    /**
     * Shares list views with a specific group
     * @param listViewFullNames List of list view full names (e.g., 'Account.MyListView')
     * @param groupId The Id of the group to share with
     * @return List of successfully shared list views
     */
    public static List<String> shareListViewsWithGroup(List<String> listViewFullNames, Id groupId) {
        if (listViewFullNames == null || listViewFullNames.isEmpty()) {
            System.debug('No list views to share');
            return new List<String>();
        }
        
        if (groupId == null) {
            throw new IllegalArgumentException('Group Id cannot be null');
        }
        
        // Get group name for sharing
        Group groupRecord = [SELECT Id, DeveloperName FROM Group WHERE Id = :groupId LIMIT 1];
        
        // Create metadata service
        MetadataService.MetadataPort service = MetadataServiceExamples.createService();
        
        List<String> successfulShares = new List<String>();
        
        // Process each list view
        for (String listViewFullName : listViewFullNames) {
            try {
                // Read the existing list view
                MetadataService.IReadResult readResult = 
                    service.readMetadata('ListView', new String[] { listViewFullName });
                MetadataService.Metadata[] existingListViews = readResult.getRecords();
                
                if (existingListViews != null && existingListViews.size() > 0) {
                    MetadataService.ListView listView = (MetadataService.ListView) existingListViews[0];
                    
                    // Initialize or update SharedTo
                    if (listView.sharedTo == null) {
                        listView.sharedTo = new MetadataService.SharedTo();
                    }
                    
                    // Add group to shared groups
                    if (listView.sharedTo.group_x == null) {
                        listView.sharedTo.group_x = new String[] { groupRecord.DeveloperName };
                    } else {
                        // Add to existing groups array
                        List<String> groupsList = new List<String>();
                        groupsList.addAll(listView.sharedTo.group_x);
                        if (!groupsList.contains(groupRecord.DeveloperName)) {
                            groupsList.add(groupRecord.DeveloperName);
                        }
                        listView.sharedTo.group_x = groupsList;
                    }
                    
                    // Update the list view
                    List<MetadataService.SaveResult> results = 
                        service.updateMetadata(new MetadataService.Metadata[] { listView });
                    
                    if (results != null && results[0].success) {
                        System.debug('List View shared successfully: ' + listViewFullName);
                        successfulShares.add(listViewFullName);
                    } else if (results != null && results[0].errors != null) {
                        System.debug('Error sharing list view ' + listViewFullName + ': ' + 
                                    results[0].errors[0].message);
                    }
                }
            } catch (Exception e) {
                System.debug('Error sharing list view ' + listViewFullName + ': ' + e.getMessage());
            }
        }
        
        return successfulShares;
    }
    
    /**
     * Alternative approach: Share via ListViewShare (if available in org)
     * Note: This is a placeholder for future implementation
     * Currently, list view sharing is primarily done through metadata
     */
    @future
    public static void shareListViewsAsync(Set<String> listViewFullNames, Id groupId) {
        shareListViewsWithGroup(new List<String>(listViewFullNames), groupId);
    }
    
    /**
     * Custom exception class
     */
    public class ListViewSharingException extends Exception {}
}

