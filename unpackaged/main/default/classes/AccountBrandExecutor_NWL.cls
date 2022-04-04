/**
 * OpportunityLineItem trigger to evaluate Distributor added to Opportunity and add to End User Distributor junction object if not already there
 *
 * * Should be called from the @see Base_NWL.Executor implementation.
 *
 * @author: Syed Jaffar
 */
public class AccountBrandExecutor_NWL implements Base_NWL.Executor {

//  MAP for Opportunity
    private Map<ID,OpportunityLineItem> newOpportunityLineItem;
    private Map<ID,OpportunityLineItem> oldOpportunityLineItem;

//  Constructor
    public AccountBrandExecutor_NWL(Map<ID,OpportunityLineItem> newOpportunityLineItem, 
                                    Map<ID,OpportunityLineItem> oldOpportunityLineItem) {
        
        this.newOpportunityLineItem = newOpportunityLineItem;
        this.oldOpportunityLineItem = oldOpportunityLineItem;
    }

//  execute Method
    public void execute(){  

        MAP<String, Account_Brand__c> accountBrandMap = new MAP<String, Account_Brand__c>();
        List<Account_Brand__c> insertAccountBrand = new List<Account_Brand__c>();
        Set<Id> targetOpportunity = new Set<Id>();
        Set<Id> targetAccount = new Set<Id>();

        for (OpportunityLineItem oli : newOpportunityLineItem.values() ) {
            targetOpportunity.add(oli.OpportunityId);
        }

        System.debug('--->> AccountBrandExecutor_NWL::execute::targetOpportunity [' + targetOpportunity +']');
        if (targetOpportunity != null) {   
            Map<ID, Opportunity> opportunityMap = new Map<ID, Opportunity>([SELECT Id, AccountId FROM Opportunity WHERE Id IN: targetOpportunity]);
            for(Opportunity o:opportunityMap.values()){
                targetAccount.add(o.AccountId);  
            }
            
            System.debug('--->> AccountBrandExecutor_NWL::execute::targetAccount [' + targetAccount +']');
            List<Account_Brand__c> accountBrand = [SELECT Id, Opportunity_Account__c, Opportunity_Sub_Segment__c
                                                        FROM Account_Brand__c 
                                                        WHERE Opportunity_Account__c IN: targetAccount];
            for(Account_Brand__c ab:accountBrand){
                String accountSegment =  ab.Opportunity_Account__c + ab.Opportunity_Sub_Segment__c;
                accountBrandMap.put(accountSegment, ab);
                List<Account_Brand__c> accountBrand = [SELECT Id, Opportunity_Account__c, Opportunity_Sub_Segment__c
                                                        FROM Account_Brand__c 
                                                        WHERE Id = :ab.Id];
            }

            System.debug('--->> AccountBrandExecutor_NWL::execute::accountBrandMap::before [' + accountBrandMap +']');
            for (OpportunityLineItem oli : newOpportunityLineItem.values() ) {
                Opportunity o = opportunityMap.get(oli.OpportunityId);
                String accountSegment =  o.AccountId + oli.Sub_Segment__c;
                Account_Brand__c aBrand = accountBrandMap.get(accountSegment);
                if (aBrand == null) {
                    Account_Brand__c ab = new Account_Brand__c(Opportunity_Account__c = o.AccountId,
                                                                Opportunity_Sub_Segment__c = oli.Sub_Segment__c);
                    insertAccountBrand.add( ab );
                    String newAccountSegment =  o.AccountId + oli.Sub_Segment__c;
                    accountBrandMap.put(newAccountSegment, ab);
                }
            }

            System.debug('--->> AccountBrandExecutor_NWL::execute::insertAccountBrand [' + insertAccountBrand +']');
            if (insertAccountBrand != null) {
                try{
                    upsert insertAccountBrand;
                }catch(System.DmlException ex) {
                    for (Integer i = 0; i < ex.getNumDml(); i++) {
                        System.debug(ex.getDmlMessage(i)); 
                    }
                }
            }
        }
    }
}
