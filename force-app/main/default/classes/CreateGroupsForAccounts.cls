/**
 * Invocable class for creating groups for accounts
 * Designed to be called from Process Builder or Flow
 */
public with sharing class CreateGroupsForAccounts {
    
    /**
     * Creates public groups for multiple accounts and stores group Ids on accounts
     * @param accountIds List of Account Ids
     */
    @InvocableMethod(label='Create Groups for Accounts' 
                     description='Creates public groups for the specified accounts and stores group Ids'
                     category='Account')
    public static void execute(List<String> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            System.debug('No account Ids provided');
            return;
        }
        
        List<Account> accounts = [
            SELECT Id, Name, List_View_Group__c
            FROM Account 
            WHERE Id IN :accountIds
        ];
        
        if (accounts.isEmpty()) {
            System.debug('No accounts found for provided Ids');
            return;
        }
        
        Set<String> groupNames = new Set<String>();
        for (Account acc : accounts) {
            groupNames.add(acc.Name);
        }
        
        try {
            Map<String, Id> groupNameToIdMap = GroupService.createPublicGroups(groupNames);
            System.debug('Successfully processed ' + groupNameToIdMap.size() + ' groups for ' + accounts.size() + ' accounts');
            
            List<Account> accountsToUpdate = new List<Account>();
            for (Account acc : accounts) {
                if (groupNameToIdMap.containsKey(acc.Name)) {
                    Id groupId = groupNameToIdMap.get(acc.Name);
                    acc.List_View_Group__c = groupId;
                    accountsToUpdate.add(acc);
                }
            }
            
            if (!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
                System.debug('Updated ' + accountsToUpdate.size() + ' accounts with group Ids');
            }
            
        } catch (Exception e) {
            System.debug('Error creating groups in bulk: ' + e.getMessage());
            throw e;
        }
    }
}

