public with sharing class AccountTriggerHelper {
    public static void processListViewCreation(List<Account> accountsToProcess) {
        
        
        if (accountsToProcess.isEmpty()) {
            return;
        }
        
        Set<String> groupNames = new Set<String>();
        for (Account acc : accountsToProcess) {
            groupNames.add(acc.Name);
        }
        
        Map<String, Id> groupNameToIdMap = GroupService.createPublicGroups(groupNames);
        System.debug('Groups created/found in bulk: ' + groupNameToIdMap.size());

        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : accountsToProcess) {
            if (groupNameToIdMap.containsKey(acc.Name)) {
                
                Id groupId = groupNameToIdMap.get(acc.Name);

                accountsToUpdate.add(
                    new Account(Id = acc.Id,
                        List_View_Group__c = groupId,
                        Name = acc.Name));
                System.debug('Account ' + acc.Name + ' → Group Id: ' + groupId);
            } else {
                System.debug('Group not found for account: ' + acc.Name);
            }
        }
        
        if (!accountsToUpdate.isEmpty()) {
            System.enqueueJob(new ListViewCreationQueueable(accountsToUpdate));
        }
    }

    /**
     * Inner Queueable class for creating list views asynchronously with callout capability
     */
    public class ListViewCreationQueueable implements Queueable, Database.AllowsCallouts {
        
        private List<Account> accounts;
        
        /**
         * Constructor
         * @param accounts List of Account records with List_View_Group__c populated
         */
        public ListViewCreationQueueable(List<Account> accounts) {
            this.accounts = accounts;
        }
        
        /**
         * Execute method called by the queue
         * @param context Queueable context
         */
        public void execute(QueueableContext context) {
            AccountTriggerHandler.isRecurrsive = true;
            
            try {
                System.debug('Processing ' + accounts.size() + ' partner accounts in queueable');
                
                List<String> createdListViews = ListViewManagerService.createListViewsFromMetadata(accounts);
                System.debug('Successfully created ' + createdListViews.size() + ' list views for ' + accounts.size() + ' accounts');
                
                update accounts;
                
            } catch (Exception e) {
                System.debug('Error processing accounts in queueable: ' + e.getMessage());
                System.debug('Stack trace: ' + e.getStackTraceString());
            }
        }
    }
}