/**
 * HighNetWorthClientControllerTest.cls
 * Test class for HighNetWorthClientController
 */
@isTest
public class HighNetWorthClientControllerTest {
    
    private static final Decimal HIGH_NET_WORTH_THRESHOLD = 1000000;
    
    /**
     * Setup test data
     */
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>();
        
        // High Net Worth Account
        Account highNetWorthAccount = new Account(
            Name = 'High Net Worth Test Account',
            Industry = 'Technology',
            Type = 'Customer - Direct'
        );
        testAccounts.add(highNetWorthAccount);
        
        // Standard Account
        Account standardAccount = new Account(
            Name = 'Standard Test Account',
            Industry = 'Manufacturing',
            Type = 'Prospect'
        );
        testAccounts.add(standardAccount);
        
        // Account with no opportunities
        Account noOpportunityAccount = new Account(
            Name = 'No Opportunity Test Account',
            Industry = 'Healthcare',
            Type = 'Customer - Direct'
        );
        testAccounts.add(noOpportunityAccount);
        
        insert testAccounts;
        
        // Create opportunities for High Net Worth Account
        List<Opportunity> highNetWorthOpportunities = new List<Opportunity>();
        
        Opportunity opp1 = new Opportunity(
            Name = 'Large Deal 1',
            AccountId = testAccounts[0].Id,
            Amount = 600000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        highNetWorthOpportunities.add(opp1);
        
        Opportunity opp2 = new Opportunity(
            Name = 'Large Deal 2',
            AccountId = testAccounts[0].Id,
            Amount = 500000,
            StageName = 'Negotiation/Review',
            CloseDate = Date.today().addDays(60)
        );
        highNetWorthOpportunities.add(opp2);
        
        // Create opportunities for Standard Account (below threshold)
        Opportunity opp3 = new Opportunity(
            Name = 'Small Deal 1',
            AccountId = testAccounts[1].Id,
            Amount = 50000,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(45)
        );
        highNetWorthOpportunities.add(opp3);
        
        Opportunity opp4 = new Opportunity(
            Name = 'Small Deal 2',
            AccountId = testAccounts[1].Id,
            Amount = 75000,
            StageName = 'Proposal/Price Quote',
            CloseDate = Date.today().addDays(90)
        );
        highNetWorthOpportunities.add(opp4);
        
        // Create a closed opportunity (should not be counted)
        Opportunity closedOpp = new Opportunity(
            Name = 'Closed Deal',
            AccountId = testAccounts[0].Id,
            Amount = 2000000,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-30)
        );
        highNetWorthOpportunities.add(closedOpp);
        
        insert highNetWorthOpportunities;
    }
    
    /**
     * Test High Net Worth account identification
     */
    @isTest
    static void testHighNetWorthAccountIdentification() {
        // Get test account
        Account highNetWorthAccount = [SELECT Id FROM Account WHERE Name = 'High Net Worth Test Account' LIMIT 1];
        
        Test.startTest();
        
        // Test the method
        HighNetWorthClientController.HighNetWorthResult result = 
            HighNetWorthClientController.checkHighNetWorthStatus(highNetWorthAccount.Id);
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.isHighNetWorth, 'Account should be identified as High Net Worth');
        System.assertEquals(1100000, result.totalAmount, 'Total amount should be 1,100,000 (600k + 500k)');
    }
    
    /**
     * Test Standard account identification
     */
    @isTest
    static void testStandardAccountIdentification() {
        // Get test account
        Account standardAccount = [SELECT Id FROM Account WHERE Name = 'Standard Test Account' LIMIT 1];
        
        Test.startTest();
        
        // Test the method
        HighNetWorthClientController.HighNetWorthResult result = 
            HighNetWorthClientController.checkHighNetWorthStatus(standardAccount.Id);
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(false, result.isHighNetWorth, 'Account should not be identified as High Net Worth');
        System.assertEquals(125000, result.totalAmount, 'Total amount should be 125,000 (50k + 75k)');
    }
    
    /**
     * Test account with no opportunities
     */
    @isTest
    static void testAccountWithNoOpportunities() {
        // Get test account
        Account noOpportunityAccount = [SELECT Id FROM Account WHERE Name = 'No Opportunity Test Account' LIMIT 1];
        
        Test.startTest();
        
        // Test the method
        HighNetWorthClientController.HighNetWorthResult result = 
            HighNetWorthClientController.checkHighNetWorthStatus(noOpportunityAccount.Id);
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(false, result.isHighNetWorth, 'Account should not be identified as High Net Worth');
        System.assertEquals(0, result.totalAmount, 'Total amount should be 0');
    }
    
    /**
     * Test with null account ID
     */
    @isTest
    static void testNullAccountId() {
        Test.startTest();
        
        // Test the method with null ID
        HighNetWorthClientController.HighNetWorthResult result = 
            HighNetWorthClientController.checkHighNetWorthStatus(null);
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(false, result.isHighNetWorth, 'Null account should not be High Net Worth');
        System.assertEquals(0, result.totalAmount, 'Total amount should be 0 for null account');
    }
    
    /**
     * Test getHighNetWorthThreshold method
     */
    @isTest
    static void testGetHighNetWorthThreshold() {
        Test.startTest();
        
        Decimal threshold = HighNetWorthClientController.getHighNetWorthThreshold();
        
        Test.stopTest();
        
        // Assertions
        System.assertEquals(HIGH_NET_WORTH_THRESHOLD, threshold, 'Threshold should match expected value');
    }
    
    /**
     * Test multiple accounts check
     */
    @isTest
    static void testCheckMultipleAccountsHighNetWorthStatus() {
        // Get test accounts
        List<Account> testAccounts = [SELECT Id, Name FROM Account ORDER BY Name];
        List<Id> accountIds = new List<Id>();
        
        for (Account acc : testAccounts) {
            accountIds.add(acc.Id);
        }
        
        Test.startTest();
        
        // Test the method
        Map<Id, HighNetWorthClientController.HighNetWorthResult> results = 
            HighNetWorthClientController.checkMultipleAccountsHighNetWorthStatus(accountIds);
        
        Test.stopTest();
        
        // Assertions
        System.assertEquals(3, results.size(), 'Should return results for all 3 accounts');
        
        // Check High Net Worth account
        Account highNetWorthAccount = null;
        Account standardAccount = null;
        Account noOpportunityAccount = null;
        
        for (Account acc : testAccounts) {
            if (acc.Name == 'High Net Worth Test Account') {
                highNetWorthAccount = acc;
            } else if (acc.Name == 'Standard Test Account') {
                standardAccount = acc;
            } else if (acc.Name == 'No Opportunity Test Account') {
                noOpportunityAccount = acc;
            }
        }
        
        System.assertEquals(true, results.get(highNetWorthAccount.Id).isHighNetWorth, 
                           'High Net Worth account should be identified correctly');
        System.assertEquals(false, results.get(standardAccount.Id).isHighNetWorth, 
                           'Standard account should be identified correctly');
        System.assertEquals(false, results.get(noOpportunityAccount.Id).isHighNetWorth, 
                           'No opportunity account should be identified correctly');
    }
    
    /**
     * Test multiple accounts check with empty list
     */
    @isTest
    static void testCheckMultipleAccountsWithEmptyList() {
        Test.startTest();
        
        // Test with empty list
        Map<Id, HighNetWorthClientController.HighNetWorthResult> results = 
            HighNetWorthClientController.checkMultipleAccountsHighNetWorthStatus(new List<Id>());
        
        Test.stopTest();
        
        // Assertions
        System.assertEquals(0, results.size(), 'Should return empty map for empty input');
    }
    
    /**
     * Test multiple accounts check with null list
     */
    @isTest
    static void testCheckMultipleAccountsWithNullList() {
        Test.startTest();
        
        // Test with null list
        Map<Id, HighNetWorthClientController.HighNetWorthResult> results = 
            HighNetWorthClientController.checkMultipleAccountsHighNetWorthStatus(null);
        
        Test.stopTest();
        
        // Assertions
        System.assertEquals(0, results.size(), 'Should return empty map for null input');
    }
    
    /**
     * Test that closed opportunities are excluded from calculation
     */
    @isTest
    static void testClosedOpportunitiesExcluded() {
        // Create account with only closed opportunities
        Account testAccount = new Account(
            Name = 'Closed Opportunity Test Account',
            Industry = 'Finance',
            Type = 'Customer - Direct'
        );
        insert testAccount;
        
        // Create closed opportunities totaling over threshold
        List<Opportunity> closedOpportunities = new List<Opportunity>();
        
        Opportunity closedOpp1 = new Opportunity(
            Name = 'Closed Large Deal 1',
            AccountId = testAccount.Id,
            Amount = 800000,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-30)
        );
        closedOpportunities.add(closedOpp1);
        
        Opportunity closedOpp2 = new Opportunity(
            Name = 'Closed Large Deal 2',
            AccountId = testAccount.Id,
            Amount = 700000,
            StageName = 'Closed Lost',
            CloseDate = Date.today().addDays(-60)
        );
        closedOpportunities.add(closedOpp2);
        
        insert closedOpportunities;
        
        Test.startTest();
        
        // Test the method
        HighNetWorthClientController.HighNetWorthResult result = 
            HighNetWorthClientController.checkHighNetWorthStatus(testAccount.Id);
        
        Test.stopTest();
        
        // Assertions - should not be high net worth because all opportunities are closed
        System.assertEquals(false, result.isHighNetWorth, 'Account should not be High Net Worth (closed opportunities excluded)');
        System.assertEquals(0, result.totalAmount, 'Total amount should be 0 (closed opportunities excluded)');
    }
    
    /**
     * Test boundary condition - exactly at threshold
     */
    @isTest
    static void testBoundaryConditionAtThreshold() {
        // Create account with opportunities totaling exactly 1M
        Account testAccount = new Account(
            Name = 'Boundary Test Account',
            Industry = 'Retail',
            Type = 'Customer - Direct'
        );
        insert testAccount;
        
        Opportunity boundaryOpp = new Opportunity(
            Name = 'Boundary Deal',
            AccountId = testAccount.Id,
            Amount = 1000000, // Exactly at threshold
            StageName = 'Negotiation/Review',
            CloseDate = Date.today().addDays(30)
        );
        insert boundaryOpp;
        
        Test.startTest();
        
        // Test the method
        HighNetWorthClientController.HighNetWorthResult result = 
            HighNetWorthClientController.checkHighNetWorthStatus(testAccount.Id);
        
        Test.stopTest();
        
        // Assertions - should be high net worth at exactly threshold
        System.assertEquals(true, result.isHighNetWorth, 'Account should be High Net Worth at exactly threshold');
        System.assertEquals(1000000, result.totalAmount, 'Total amount should be exactly 1,000,000');
    }
}