/**
 * HighNetWorthClientController.cls
 * Controller class to determine High Net Worth status based on opportunity amounts
 */
public with sharing class HighNetWorthClientController {
    
    private static final Decimal HIGH_NET_WORTH_THRESHOLD = 1000000;
    
    /**
     * Wrapper class to return high net worth status and total amount
     */
    public class HighNetWorthResult {
        @AuraEnabled
        public Boolean isHighNetWorth { get; set; }
        
        @AuraEnabled
        public Decimal totalAmount { get; set; }
        
        public HighNetWorthResult(Boolean isHighNetWorth, Decimal totalAmount) {
            this.isHighNetWorth = isHighNetWorth;
            this.totalAmount = totalAmount != null ? totalAmount : 0;
        }
    }
    
    /**
     * Check if an account is a High Net Worth client based on opportunity amounts
     * @param accountId The account ID to check
     * @return HighNetWorthResult containing status and total amount
     */
    @AuraEnabled(cacheable=true)
    public static HighNetWorthResult checkHighNetWorthStatus(Id accountId) {
        try {
            if (accountId == null) {
                return new HighNetWorthResult(false, 0);
            }
            
            // Query all non-closed opportunities for the account
            List<Opportunity> opportunities = [
                SELECT Id, Amount, StageName, IsClosed
                FROM Opportunity 
                WHERE AccountId = :accountId 
                AND IsClosed = false
                AND Amount != null
                WITH SECURITY_ENFORCED
            ];
            
            Decimal totalAmount = 0;
            
            // Calculate total amount from non-closed opportunities
            for (Opportunity opp : opportunities) {
                if (opp.Amount != null) {
                    totalAmount += opp.Amount;
                }
            }
            
            Boolean isHighNetWorth = totalAmount >= HIGH_NET_WORTH_THRESHOLD;
            
            return new HighNetWorthResult(isHighNetWorth, totalAmount);
            
        } catch (Exception e) {
            System.debug('Error in checkHighNetWorthStatus: ' + e.getMessage());
            throw new AuraHandledException('Error checking High Net Worth status: ' + e.getMessage());
        }
    }
    
    /**
     * Get High Net Worth threshold for display purposes
     * @return The threshold amount
     */
    @AuraEnabled(cacheable=true)
    public static Decimal getHighNetWorthThreshold() {
        return HIGH_NET_WORTH_THRESHOLD;
    }
    
    /**
     * Batch method to update High Net Worth status for multiple accounts
     * This can be used for data migration or bulk updates
     * @param accountIds List of account IDs to process
     * @return Map of account ID to HighNetWorthResult
     */
    @AuraEnabled
    public static Map<Id, HighNetWorthResult> checkMultipleAccountsHighNetWorthStatus(List<Id> accountIds) {
        Map<Id, HighNetWorthResult> results = new Map<Id, HighNetWorthResult>();
        
        try {
            if (accountIds == null || accountIds.isEmpty()) {
                return results;
            }
            
            // Query all non-closed opportunities for the accounts
            Map<Id, List<Opportunity>> accountOpportunityMap = new Map<Id, List<Opportunity>>();
            
            List<Opportunity> opportunities = [
                SELECT Id, AccountId, Amount, StageName, IsClosed
                FROM Opportunity 
                WHERE AccountId IN :accountIds 
                AND IsClosed = false
                AND Amount != null
                WITH SECURITY_ENFORCED
            ];
            
            // Group opportunities by account
            for (Opportunity opp : opportunities) {
                if (!accountOpportunityMap.containsKey(opp.AccountId)) {
                    accountOpportunityMap.put(opp.AccountId, new List<Opportunity>{opp}); 
                } else {
                    accountOpportunityMap.get(opp.AccountId).add(opp);
                }
            }
            
            // Calculate status for each account
            for (Id accountId : accountIds) {
                Decimal totalAmount = 0;
                
                if (accountOpportunityMap.containsKey(accountId)) {
                    for (Opportunity opp : accountOpportunityMap.get(accountId)) {
                        if (opp.Amount != null) {
                            totalAmount += opp.Amount;
                        }
                    }
                }
                
                Boolean isHighNetWorth = totalAmount >= HIGH_NET_WORTH_THRESHOLD;
                results.put(accountId, new HighNetWorthResult(isHighNetWorth, totalAmount));
            }
            
            return results;
            
        } catch (Exception e) {
            System.debug('Error in checkMultipleAccountsHighNetWorthStatus: ' + e.getMessage());
            throw new AuraHandledException('Error checking High Net Worth status for multiple accounts: ' + e.getMessage());
        }
    }
}