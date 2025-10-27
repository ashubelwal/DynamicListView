/**
 * Service class to handle Public Group operations
 */
public with sharing class GroupService {
    
    /**
     * BULK METHOD: Creates public groups for multiple names
     * @param groupNames Set of group names to create
     * @return Map of group name to group Id (includes both new and existing groups)
     */
    public static Map<String, Id> createPublicGroups(Set<String> groupNames) {
        Map<String, Id> groupNameToIdMap = new Map<String, Id>();
        
        if (groupNames == null || groupNames.isEmpty()) {
            System.debug('No group names provided');
            return groupNameToIdMap;
        }
        
        // Remove blank names
        Set<String> validNames = new Set<String>();
        for (String name : groupNames) {
            if (String.isNotBlank(name)) {
                validNames.add(name);
            }
        }
        
        if (validNames.isEmpty()) {
            return groupNameToIdMap;
        }
        
        // Check for existing groups
        List<Group> existingGroups = [
            SELECT Id, Name 
            FROM Group 
            WHERE Name IN :validNames 
            AND Type = 'Regular'
        ];
        
        for (Group g : existingGroups) {
            groupNameToIdMap.put(g.Name, g.Id);
            System.debug('Found existing group: ' + g.Name);
        }
        
        // Determine which groups need to be created
        Set<String> namesToCreate = new Set<String>();
        for (String name : validNames) {
            if (!groupNameToIdMap.containsKey(name)) {
                namesToCreate.add(name);
            }
        }
        
        if (namesToCreate.isEmpty()) {
            System.debug('All groups already exist');
            return groupNameToIdMap;
        }
        
        // Create new groups
        List<Group> newGroups = new List<Group>();
        for (String name : namesToCreate) {
            Group newGroup = new Group();
            newGroup.Name = name;
            newGroup.DeveloperName = generateDeveloperName(name);
            newGroup.Type = 'Regular';
            newGroups.add(newGroup);
        }
        
        try {
            insert newGroups;
            System.debug('Successfully created ' + newGroups.size() + ' groups');
            
            // Add newly created groups to result map
            for (Group g : newGroups) {
                groupNameToIdMap.put(g.Name, g.Id);
            }
        } catch (DmlException e) {
            System.debug('Error creating groups: ' + e.getMessage());
            throw new GroupServiceException('Failed to create groups: ' + e.getMessage());
        }
        
        return groupNameToIdMap;
    }
    
    /**
     * Creates a single public group with the given name (wrapper for bulk method)
     * @param groupName The name of the group to create
     * @return The Id of the created group, or existing group Id if already exists
     */
    public static Id createPublicGroup(String groupName) {
        if (String.isBlank(groupName)) {
            throw new IllegalArgumentException('Group name cannot be blank');
        }
        
        Set<String> groupNames = new Set<String>{groupName};
        Map<String, Id> result = createPublicGroups(groupNames);
        
        return result.get(groupName);
    }
    
    /**
     * Generates a valid developer name from a group name
     * Removes special characters and spaces, limits to 40 characters
     */
    private static String generateDeveloperName(String name) {
        String devName = name.replaceAll('[^a-zA-Z0-9]', '_');
        if (devName.length() > 40) {
            devName = devName.substring(0, 40);
        }
        // Ensure it doesn't end with underscore
        devName = devName.replaceAll('_+$', '');
        return devName;
    }
    
    /**
     * Custom exception class for GroupService
     */
    public class GroupServiceException extends Exception {}
}

