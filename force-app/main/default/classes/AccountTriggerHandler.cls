/**
 * Handler class for Account trigger
 * Orchestrates the creation of groups, list views, and sharing when IsPartner becomes true
 */
public with sharing class AccountTriggerHandler {
    public static Boolean isRecurrsive = false;
    /**
     * Handles after update logic for Account
     */
    public static void handleAfterUpdate(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        if(!AccountTriggerHandler.isRecurrsive) {
            AccountTriggerHandler.isRecurrsive = true;

            List<Account> accountsToProcess = new List<Account>();
            
            // Filter accounts where IsPartner changed to true
            for (Account acc : newAccounts) {
                Account oldAcc = oldAccountsMap.get(acc.Id);
                //if (acc.IsPartner == true && oldAcc.IsPartner == false) {
                    accountsToProcess.add(acc);
                //}
            }
            if(!accountsToProcess.isEmpty()) {
                AccountTriggerHelper.processListViewCreation(accountsToProcess);
            }
        }
    }
    
    
}

