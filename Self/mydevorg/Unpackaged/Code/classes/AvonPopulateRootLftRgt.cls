global with sharing class AvonPopulateRootLftRgt implements 
    Database.Batchable<sObject>{
 
     //we want the list to be reset after every batch. This list is used only during the duration of the single batch execution
      //stores the list of genealogy instances to be updated
   static List <Avon_Genealogy__c> genealogyListToBeUpdated=new List<Avon_Genealogy__c>();
   global final String Query;
   
   global AvonPopulateRootLftRgt(String q){
   	  Query=q;
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
   	  return Database.getQueryLocator(query);
   }
   
   global void execute(
                Database.BatchableContext BC, 
                List<sObject> scope){ 
         
         for(sObject sObj:scope){
         	Avon_Genealogy__c genInstance=(Avon_Genealogy__c)sObj;
         	genInstance.LFT_ND_ID__c=1;
         	genInstance.RGT_ND_ID__c=(genInstance.Number_of_Children__c + 1)*2;
         	genealogyListToBeUpdated.add(genInstance);
         }
         
         //execute the update operation on the genealogy objects for the current batch
      try{
      	update genealogyListToBeUpdated;
      }
      catch(Exception e){
      	//TODO: Handle appropriate exception and report error to the end user.
      }
                
    }

global void finish(Database.BatchableContext BC){
   }
}