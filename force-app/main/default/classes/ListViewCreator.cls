public class ListViewCreator {
    public static void createAccountListView() {
        MetadataService.MetadataPort service = MetadataServiceExamples.createService();

        MetadataService.ListView listView = new MetadataService.ListView();
        listView.fullName = 'Account.Test_From_Apex';
        listView.label = 'Test From Apex';
        listView.filterScope = 'Mine';
        
        listView.columns = new String[] {
            'ACCOUNT.NAME',
            'ACCOUNT.SITE',
            'ACCOUNT.ADDRESS1_STATE_CODE',
            'ACCOUNT.PHONE1',
            'ACCOUNT.TYPE',
            'CORE.USERS.ALIAS',
            'CORE.USERS.FIRST_NAME',
            'CORE.USERS.LAST_NAME',
            'ACCOUNT.RATING',
            'ACCOUNT.INDUSTRY'
        };
        
        MetadataService.ListViewFilter filter = new MetadataService.ListViewFilter();
        filter.field = 'ACCOUNT.RATING';
        filter.operation = 'equals';
        filter.value = 'Hot';
        listView.filters = new MetadataService.ListViewFilter[] { filter };
        
        List<MetadataService.SaveResult> results = 
            service.createMetadata(new MetadataService.Metadata[] { listView });
        
        if (results != null && results[0].success) {
            System.debug('List View created successfully!');
        } else {
            System.debug('Error: ' + results[0].errors[0].message);
        }
    }
}