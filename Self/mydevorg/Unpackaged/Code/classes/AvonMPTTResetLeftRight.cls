global with sharing class AvonMPTTResetLeftRight implements 
    Database.Batchable<sObject>{
 
   global final String Query;
   global final String objectName;
   
   static List<My_Business_And_Leadership_Data__c> leadershipDataList=new List<My_Business_And_Leadership_Data__c>();
   static List<Sobject> sObjectList=new List<Sobject>();
   
    
   global AvonMPTTResetLeftRight(String q,String objName){Query=q;objectName=objName;

   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }
   
   global void execute(
                Database.BatchableContext BC, 
                List<sObject> scope){
     
      for(Sobject sObjInstance:scope){
      	if(objectName!=null && objectName.equalsIgnoreCase('Genealogy')){
      		Avon_Genealogy__c dataInstance=(Avon_Genealogy__c)sObjInstance;
      		dataInstance.LFT_ND_ID__c=null;
            dataInstance.RGT_ND_ID__c=null;
            sObjectList.add(dataInstance);
      	}
      	else{
      	  My_Business_And_Leadership_Data__c dataInstance=(My_Business_And_Leadership_Data__c)sObjInstance;
      	  dataInstance.LFT_ND_ID__c=null;
          dataInstance.RGT_ND_ID__c=null;
          sObjectList.add(dataInstance);
      	}
        
      }
      
      try{
      	update sObjectList;
      }
      catch(Exception e){
      	//TODO: Add exception handling.
      }
   }

global void finish(Database.BatchableContext BC){
   }
}