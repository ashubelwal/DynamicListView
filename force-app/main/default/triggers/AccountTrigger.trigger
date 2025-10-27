/**
 * Trigger for Account object
 * Handles list view creation and sharing when IsPartner becomes true
 */
trigger AccountTrigger on Account (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        AccountTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}

