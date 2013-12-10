global with sharing class AvonMPTTBatchVer2 implements 
    Database.Batchable<sObject>, Database.Stateful{
 
   global final String Query;
   
   global Long currentleftValue;
   global Long currentrightValue;
   global string lastVistedParent;
   global string lastrootUpline;
   
    //we want the map to be reset after every batch. This map is used only during the duration of the single batch execution
      //stores the map between the node and number of children for that node
      static Map<String,Long> nodeChildCountMap=new Map<String,Long>();          	
     
      //we want the map to be reset after every batch. This map is used only during the duration of the single batch execution
      //stores the map between the parent node id and its left identifier
      static Map<String,Long> parentLeftIdMap=new Map<String,Long>();  
      
       //we want the map to be reset after every batch. This map is used only during the duration of the single batch execution
      //stores the map between the  node id and reference to the genealogy instance to update the values at the end of execute.
      static Map<String,Avon_Genealogy__c> avonGenealogyMap=new Map<String,Avon_Genealogy__c>();          	
     
     
     //we want the map to be reset after every batch. This map is used only during the duration of the single batch execution
      //stores the map between the  node id and reference to the genealogy instance to update the values at the end of execute.
      static Map<String,My_Business_And_Leadership_Data__c> dataMap=new Map<String,My_Business_And_Leadership_Data__c>();          	
     
      //variable to store the contact ids of the nodes in the current batch
      static Set<String> contactIds=new Set<String>();
      //variable to store the parent contact ids of the nodes in the current batch
      static Set<String> parentIds=new Set<String>();
      
       //we want the list to be reset after every batch. This list is used only during the duration of the single batch execution
      //stores the list of genealogy instances to be updated
      static List <Avon_Genealogy__c> genealogyListToBeUpdated=new List<Avon_Genealogy__c>();          	
    
    
        //we want the list to be reset after every batch. This list is used only during the duration of the single batch execution
      //stores the list of genealogy instances to be updated
      static List <My_Business_And_Leadership_Data__c> dataObjectToBeUpdated=new List<My_Business_And_Leadership_Data__c>();          	
     
      //variable to store the number of children for every node. Used only during the life of a batch execution
      static Long numberOfChildren=0;
      
      //variable to store the genealogy instance being fetched from map. Used only during the life of a batch execution
      static Avon_Genealogy__c avonGenealogyInstance;
      
      //variable to store the data instance being fetched from map. Used only during the life of a batch execution
      static My_Business_And_Leadership_Data__c dataInstance;
   
   global AvonMPTTBatchVer2(String q){Query=q;

   }

   global Database.QueryLocator start(Database.BatchableContext BC){
   	  return Database.getQueryLocator(query);
   }
   
   global void execute(
                Database.BatchableContext BC, 
                List<sObject> scope){
     
     //initialize the map values
     parentLeftIdMap=new Map<String,Long>();
     nodeChildCountMap=new Map<String,Long>();          
      
      
      //get the list of all parent ids in the set
      for(sObject sObj : scope){
        contactIds.add((ID)sObj.get('Contact_Key__c'));
        parentIds.add((ID)sObj.get('Upline_Contact__c'));
      }    
      
   
        
      
       //get the non-null left value for every parent in the current scope and store the results in the map
      for(Avon_Genealogy__c genealogyInstance : [SELECT   LFT_ND_ID__c
                                                , Contact_Key__c  
                                         FROM Avon_Genealogy__c 
                                         where Contact_Key__c in :parentIds 
                                          ]){
           if(genealogyInstance!=null && genealogyInstance.LFT_ND_ID__c!=null){
             parentLeftIdMap.put(genealogyInstance.Contact_Key__c,genealogyInstance.LFT_ND_ID__c.longValue());           
           }                   	
      }
      
      //store the map between the node id and the avon genealogy to perform the updates at the end of the execute method.
      for(Avon_Genealogy__c genealogyInstance : [SELECT   Id
                                                , LFT_ND_ID__c
                                                , RGT_ND_ID__c
                                                , Contact_Key__c  
                                                , Number_of_Children__c
                                         FROM Avon_Genealogy__c 
                                         where Contact_Key__c in :contactIds 
                                          ]){
           avonGenealogyMap.put(genealogyInstance.Contact_Key__c,genealogyInstance);   
           nodeChildCountMap.put(genealogyInstance.Contact_Key__c,genealogyInstance.Number_of_Children__c.longValue());                           	
      }
      
       //store the map between the node id and the data object to perform the updates at the end of the execute method.
      for(My_Business_And_Leadership_Data__c dataInstanceVar : [SELECT   Id
                                                , LFT_ND_ID__c
                                                , RGT_ND_ID__c
                                                , MRKT_ACCT_KEY__c  
                                         FROM My_Business_And_Leadership_Data__c 
                                         where MRKT_ACCT_KEY__c in :contactIds 
                                          ]){
           dataMap.put(dataInstanceVar.MRKT_ACCT_KEY__c,dataInstanceVar);  
     }
                                             	
                	
      for(sObject s : scope){
         //Integer level=Integer.valueOf(s.get('UPLN_GEN_INDX__c')) + 1;
         String contactId=String.valueOf(s.get('Contact_Key__c'));
         String parentId=String.valueOf(s.get('Upline_Contact__c'));
         String rootUpline=String.valueOf(s.get('ROOT_UPLN_ACC_NR__c'));
         
         System.debug('====lastVistedParent====' + lastVistedParent);
         
         System.debug('====parentId====' + parentId);
         System.debug('====currentleftValue====' + currentleftValue);
        
        //if the last root upline is not null and is different than the current root upline, we are entering a new tree, reset the values
        if(lastrootUpline!=null && !(lastrootUpline.equalsIgnoreCase(rootUpline))){
        	lastrootUpline=null;
        	currentleftValue=null;
        	currentrightValue=null;
        	lastVistedParent=null;
        }
        
        if(lastVistedParent!=null && !(lastVistedParent.equalsIgnoreCase(parentId))){
        	 Long parentLeftValue=parentLeftIdMap.get(parentId);
             System.debug('====parentLeftValue parentLeftIdMap====' + parentLeftValue);
         
         	    //if the values were populated in this batch. That is more current than db. Update the variable value
         	    //else use the db value
         	 if(avonGenealogyMap.get(parentId)!=null){
         	      parentLeftValue=avonGenealogyMap.get(parentId).LFT_ND_ID__c.longValue();
         	 }
         	 System.debug('====parentLeftValue avonGenealogyMap====' + parentLeftValue);
         
         	 currentleftValue=parentLeftValue+1;
        }
         //first node being visited at level two. lowest left value is two
         else if(currentleftValue==null){
         		currentleftValue=2;
         }
         else{
         	currentleftValue=currentrightValue+1;
         }
         
         //fetch the number of children for the current node
         if((numberOfChildren=(nodeChildCountMap.get(contactId)))==null){
         			//TODO: throw exception and return
         			numberOfChildren=0;
         }
         
         currentrightValue=currentleftValue + (numberOfChildren*2) + 1;
         lastVistedParent=parentId;
         lastrootUpline=rootUpline;
          
         
         if( ((avonGenealogyInstance=avonGenealogyMap.get(contactId))!=null)
             && ((dataInstance=dataMap.get(contactId))!=null)
            ) {
         			avonGenealogyInstance.LFT_ND_ID__c=currentleftValue;
         			avonGenealogyInstance.RGT_ND_ID__c=currentrightValue;
         			
         			dataInstance.LFT_ND_ID__c=currentleftValue;
         			dataInstance.RGT_ND_ID__c=currentrightValue;
         			
         			System.debug('====avonGenealogyInstance=====' + avonGenealogyInstance);
         			
         		 	genealogyListToBeUpdated.add(avonGenealogyInstance);
         		 	
         		 	dataObjectToBeUpdated.add(dataInstance);
         }
      }
      
      System.debug(LoggingLevel.ERROR,'====genealogyListToBeUpdated=====' + genealogyListToBeUpdated);
      System.debug(LoggingLevel.ERROR,'====dataObjectToBeUpdated=====' + dataObjectToBeUpdated);
      
      //execute the update operation on the genealogy objects for the current batch
      try{
      	update genealogyListToBeUpdated;
      	update dataObjectToBeUpdated;
      }
      catch(Exception e){
      	//TODO: Handle appropriate exception and report error to the end user.
      }
   }

global void finish(Database.BatchableContext BC){
	    //query all the roots
 	    String query='select Id, LFT_ND_ID__c, RGT_ND_ID__c , Number_of_Children__c from Avon_Genealogy__c where Upline_Contact__c=null';
   	    //initialze the batch process
       AvonPopulateRootLftRgt avonRootLftRgt = new AvonPopulateRootLftRgt(query);
      // Invoke the batch job.
      ID batchprocessid = Database.executeBatch(avonRootLftRgt,2000);
   }
}