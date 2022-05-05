public class CacheManagerUtility_NWL{
    private Boolean sessionCacheEnabled;
    private Boolean orgCacheEnabled;

	public CacheManagerUtility_NWL(Boolean session , Boolean org){
		sessionCacheEnabled = session;
		orgCacheEnabled = org;
	}

    public Boolean toggleSessionCache(){ // Use for testing misses
        sessionCacheEnabled = !sessionCacheEnabled;
        return sessionCacheEnabled;
    }

    public Boolean toggleOrgCache(){ // Use for testing misses
        orgCacheEnabled = !orgCacheEnabled;
        return orgCacheEnabled;
    }

    public Object getSessionValue(String key){
        Object res;
        if(sessionCacheEnabled == true){
	        res = Cache.Session.get(key);
	        if(res != null){
				System.debug(LoggingLevel.DEBUG, 'Session Cache get for key : ' + key);
	        }
        }
        return res;
    }

    public void putSessionValue(String key, Object value, Integer ttlsec){
        if(sessionCacheEnabled == true){
        	Cache.Session.put(key, value, ttlsec);
	        // for redundancy, save to DB
	        System.debug(LoggingLevel.DEBUG, 'Session Cache put for key : ' + key);
    	}
    }

    public Boolean removeSessionValue(String key){
        Boolean res = false;
        if(sessionCacheEnabled == true){
        	res = Cache.Session.remove(key);
            System.debug(LoggingLevel.DEBUG, 'Session Cache remove for key : ' + key + ' :: ' + res );
        }
		return res;
    }

    public Object getOrgValue(String key){
        Object res;
        if(orgCacheEnabled == true){
	        res = Cache.Org.get(key);
	        if(res != null){
				System.debug(LoggingLevel.DEBUG, 'Org Cache get for key : ' + key);
	        }
        }
        return res;
    }

    public void putOrgValue(String key, Object value, Integer ttlsec){
		// maximum is 172,800 seconds (48 hours).
		// minimum value is 300 seconds or 5 minutes.
		// default value is 86,400 seconds (24 hours).
    	if( ttlsec < 300 ){ ttlsec = Cache.Org.MAX_TTL_SECS;}
        if(orgCacheEnabled == true){
        	Cache.Org.put(key, value, ttlsec);
	        // for redundancy, save to DB
	        System.debug(LoggingLevel.DEBUG, 'Org Cache put for key : ' + key);
    	}
    }

    public Boolean removeOrgValue(String key){
        Boolean res = false;
        if(orgCacheEnabled == true){
        	res = Cache.Org.remove(key);
            System.debug(LoggingLevel.DEBUG, 'Org Cache remove for key : ' + key + ' :: ' + res );
        }
		return res;
    }

    public class BusinessHoursCache implements Cache.CacheBuilder{
    	public Object doLoad(String s){
            Map<String, Id> bhMap = new Map<String, Id>();
    		//List<BusinessHours> bhList = new List<BusinessHours>();
    		//bhList = (List<BusinessHours>)[SELECT Id, Name FROM BusinessHours WHERE IsActive = true];
            for( BusinessHours bh : (List<BusinessHours>)[SELECT Id, Name FROM BusinessHours WHERE IsActive = true] ){
                bhMap.put(bh.Name, bh.Id);
            }
    		return bhMap;
    	}
    }

    
    public class RecordTypeNameToIdCache implements Cache.CacheBuilder{
        public Object doLoad(String sObj){
            Map<String, Id> rMap = new Map<String, Id>();
            List<String> slist =  sObj.split('-');
            for (RecordType r : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType =: slist[0] ] ){
                rMap.put( r.DeveloperName, r.Id );
            }
            return rMap;
        }
    }
    
    public class RecTyIdSettingMapCache implements Cache.CacheBuilder{
        public Object doLoad(String sObj){
             Map<Id, Record_Type_Settings_NWL__c> rtsMap = new Map<Id, Record_Type_Settings_NWL__c>();
            List<String> slist =  sObj.split('-');
             Map<String, Id> rtIdMap = Utility_NWL.getRecordTyNameToIdMap( slist[0]  );
            // Get all the settings for record types by object
            for( Record_Type_Settings_NWL__c r : [SELECT Name, Object__c, Record_Type__c, Is_Risk__c, GenerateSurveyURL__c, DC_Plant_User_Order_Type__c
                                                  FROM Record_Type_Settings_NWL__c
                                                  WHERE Object__c =: slist[0] ]){
                                                      rtsMap.put( rtIdMap.get( r.Record_Type__c ), r );
            }
            return rtsMap;
        }
    }
        
    public class RecTyIdCsNameMapCache implements Cache.CacheBuilder{
        public Object doLoad(String sObj){
            Map<Id, String> rtsMap = new Map<Id, String>();
            List<String> slist =  sObj.split('-');
            
            //if( Utility_NWL.isObjNameValidSobj( objectName ) == true ){
            // Get Ids for all record Types by object
            Map<String, Id> rtIdMap = Utility_NWL.getRecordTyNameToIdMap( slist[0] );
            System.debug(Logginglevel.FINE, 'rtIdMap : ' + rtIdMap );
            // Get all the settings for record types by object
            for( Record_Type_Settings_NWL__c r : [SELECT Name, Record_Type__c
                                                  FROM Record_Type_Settings_NWL__c
                                                  WHERE Object__c =: slist[0] ] ){
                                                      System.debug(Logginglevel.FINER, 'r.Record_Type__c : ' + r.Record_Type__c );
                                                      System.debug(Logginglevel.FINER, 'r.Name : ' + r.Name );
                                                      System.debug(Logginglevel.FINEST, 'rtIdMap.get( r.Record_Type__c ) : ' + rtIdMap.get( r.Record_Type__c ) );
                                                      rtsMap.put( rtIdMap.get( r.Record_Type__c ), r.Name );
                                                  }
            return rtsMap;
        }
    }
}