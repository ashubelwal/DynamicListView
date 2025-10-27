/**
 * Invocable class for creating list views for accounts
 * Designed to be called from Process Builder or Flow
 */
public with sharing class CreateListViewsForAccounts {
    
    /**
     * Creates list views for multiple accounts (must be called asynchronously due to callout)
     * @param accountIds List of Account Ids
     */
    @InvocableMethod(label='Create List Views for Accounts' 
                     description='Creates list views for the specified accounts (requires callout context)'
                     category='Account')
    public static void execute(List<String> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            System.debug('No account Ids provided');
            return;
        }
        
        // Query accounts with group Id field
        List<Account> accounts = [
            SELECT Id, Name, List_View_Group__c
            FROM Account 
            WHERE Id IN :accountIds
        ];
        
        if (accounts.isEmpty()) {
            System.debug('No accounts found');
            return;
        }
        
        // Create list views in bulk - pass accounts directly
        try {
            List<String> createdListViews = ListViewManagerService.createListViewsFromMetadata(accounts);
            System.debug('Successfully created ' + createdListViews.size() + ' list views for ' + accounts.size() + ' accounts');
        } catch (Exception e) {
            System.debug('Error in bulk list view creation: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw e;
        }
    }
}

