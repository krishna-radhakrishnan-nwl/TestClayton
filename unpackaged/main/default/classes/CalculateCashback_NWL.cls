/**
 * CalculateCashback_NWL
 * Purpose: Trigger executor to calculate line item cashback value
 * 	        BEFORE_INS_TRIGGER_CAT
 * 	        BEFORE_UPD_TRIGGER_CAT
 * 			Assumption : Campaign Registration Items will not be mass loaded
 *          across multiple campaigns
 * @author Harshal Gajare
 * @version 1.0 07-January-2017
 */
public class CalculateCashback_NWL implements Base_NWL.Executor{

	List<CampaignRegistrationItems__c> criList = new List<CampaignRegistrationItems__c>();
	Base_NWL.TriggerCategory tCat;

	public CalculateCashback_NWL( List<CampaignRegistrationItems__c> valList, Base_NWL.TriggerCategory cat){
		this.criList = valList;
		this.tCat = cat;
	}

	public void execute(){
		Map<Id, String> camRegIdToCurrMap = new Map<Id, String>();
		Map<String, Integer> conToCampRegItemMap = new Map<String, Integer>();

		List<CampaignRegistrationItems__c> conCriList = new List<CampaignRegistrationItems__c>();

		Set<Id> conIdSet = new Set<Id>();
		Set<Id> camIdSet = new Set<Id>();

		for( CampaignRegistrationItems__c cri : this.criList ){
			if( cri.CampaignType__c == 'Cashback' || cri.CampaignType__c == 'Total Cashback' ){
				// Check if Campaign Product Curency matches Campaign Registration Item Currency. If not give an error
				if( cri.CurrencyIsoCode != cri.CampaignProductCurrency__c ){
					cri.addError('Record currency : ' + cri.CurrencyIsoCode + ' does not match select campaign product currency : ' + cri.CampaignProductCurrency__c );
				}else{
					// Collect Campaign Registration id and corresponding currency code to update later.
					camRegIdToCurrMap.put( cri.CampaignRegistration__c, cri.CurrencyIsoCode );
					if (cri.CampaignType__c == 'Cashback') {
						Decimal percentageAmt = 0;
						Decimal fixedAmt = 0;
						if( cri.Quantity__c != null ){
							// Calculate the cashback amount based on cashback percentage
							if( cri.PricePaidPerUnit__c != null ){
								percentageAmt = ( cri.CampaignCashbackPercentage__c / 100 ) * cri.PricePaidPerUnit__c * cri.Quantity__c;
							}
							// Calculate the cashback amount based on cashback amount
							fixedAmt = cri.Quantity__c * cri.CampaignCashbackAmount__c;
						}
						System.debug('percentageAmt : ' + percentageAmt );
						System.debug('fixedAmt : ' + fixedAmt );
						System.debug('CashbackCalculationPreference__c : ' + cri.CashbackCalculationPreference__c );
						// Check if cashback percentage amount is to be used or Fied amount based on config
						if( cri.CashbackCalculationPreference__c == 'Percentage' ){
							if( ( percentageAmt > fixedAmt ) || percentageAmt != 0 ){
								cri.CashbackAmount__c = percentageAmt;
							}else{
								cri.CashbackAmount__c = fixedAmt;
							}
						}else if( cri.CashbackCalculationPreference__c == 'Fixed' ){
							if( ( percentageAmt > fixedAmt ) || percentageAmt == 0 ){
								cri.CashbackAmount__c = fixedAmt;
							}else{
								cri.CashbackAmount__c = percentageAmt;
							}
						}
					}
					// Update the Campaign Registration Header with the currency code
					List<CampaignRegistration__c> crList = [SELECT Id , CurrencyIsoCode
																FROM CampaignRegistration__c
																WHERE Id IN: camRegIdToCurrMap.keySet()];
					for( CampaignRegistration__c cr : crList ){
						cr.CurrencyIsoCode = camRegIdToCurrMap.get( cr.Id );
					}
					update crList;
				}
			}
			// Check if the Campaign is setup to enforce max registraitons per contact.
			if( cri.MaxRegistrationProductsPerContact__c > 0){
				String key = cri.ContactId__c + cri.CampaignId__c;
				Integer totalQty;
				// Build a map of the registration intems per contact and campaign
				if( conToCampRegItemMap.containsKey( key ) ){
					totalQty = conToCampRegItemMap.get(key);
				}else{
					totalQty = 0;
				}
				totalQty += Integer.valueOf(cri.Quantity__c);
				conToCampRegItemMap.put(key, totalQty);
				// Collect all contact ids
				conIdSet.add( Id.valueOf(cri.ContactId__c) );
				// collect all campaign ids
				camIdSet.add( Id.valueOf(cri.CampaignId__c) );
			}

		}

		Map<String, Integer> oldRegMap = new Map<String, Integer>();
		if( this.tCat == Base_NWL.BEFORE_INS_TRIGGER_CAT && conIdSet.size() > 0){
			// Get all the existing registraitons for the same contact in the same campaign.
			// This also includes registration items count for the current registration header
			for( CampaignRegistration__c oCri : [SELECT Id, Contact__c, Campaign__c, TotalRegistrationProductQuantity__c
													FROM CampaignRegistration__c
									                WHERE Contact__c IN :conIdSet
									                  AND Campaign__c IN :camIdSet
									                  AND PopStatus__c != 'Rejected'] ){
				String key = String.valueOf(oCri.Contact__c) + String.valueOf(oCri.Campaign__c);
				Integer i = 0;
				if( oldRegMap.containsKey(key) ){
					i = oldRegMap.get( key ) + Integer.valueOf(oCri.TotalRegistrationProductQuantity__c);
				}else{
					i = Integer.valueOf(oCri.TotalRegistrationProductQuantity__c);
				}
				oldRegMap.put(key, i);
			}

			Integer total;
			Set<String> keyAlreadyCheckedSet = new Set<String>();
			for( CampaignRegistrationItems__c cri : this.criList ){
				String key = cri.ContactId__c + cri.CampaignId__c;
				if( !keyAlreadyCheckedSet.contains(key)){
					total = 0;
					// Cehck Existing Registrations in the system for the currecnt contact/campaign combination
					if( oldRegMap.containsKey(key) ){
						total = oldRegMap.get(key);
					}
					// Cehck Current Registrations in the trigger for the currecnt contact/campaign combination
					if( conToCampRegItemMap.containsKey(key) ){
						total += conToCampRegItemMap.get(key);
					}
				}
				keyAlreadyCheckedSet.add(key);
				// Check if the contact exceeds the total number of registraitons for the campaign
				if( total > cri.MaxRegistrationProductsPerContact__c ){
					cri.addError( 'Contact has already regeistered for Maximum products allowed for this campaign' );
				}
			}
		}
	}

}
//*************************************************** END OF CLASS ***************************************************//