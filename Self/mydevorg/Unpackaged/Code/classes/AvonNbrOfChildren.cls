global with sharing class AvonNbrOfChildren implements 
    Database.Batchable<sObject> {
 
   global final String Query;
   
   //variable to store the contact ids of the nodes in the current batch
    static Set<String> contactIds=new Set<String>();
    
    //we want the map to be reset after every batch. This map is used only during the duration of the single batch execution
      //stores the map between the node and number of children for that node
      static Map<String,Long> nodeChildCountMap=new Map<String,Long>();  
       
        //we want the map to be reset after every batch. This map is used only during the duration of the single batch execution
      //stores the map between the  node id and reference to the genealogy instance to update the values at the end of execute.
      static Map<String,Avon_Genealogy__c> avonGenealogyMap=new Map<String,Avon_Genealogy__c>();      
     
     //we want the map to be reset after every batch.
     static Map<String,List<Avon_Genealogy__c>> parentChildMap=new Map<String,List<Avon_Genealogy__c>>();
     //long value to compute the number of children
     static long noOfChildren;
     //we want the list to be reset after every batch. This list is used only during the duration of the single batch execution
      //stores the list of genealogy instances to be updated
      static List <Avon_Genealogy__c> genealogyListToBeUpdated=new List<Avon_Genealogy__c>();     
      //variable to store the genealogy instance being fetched from map. Used only during the life of a batch execution
      static Avon_Genealogy__c avonGenealogyInstance; 
   
   global AvonNbrOfChildren(String q){Query=q;

   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }
   
   global void execute(
                Database.BatchableContext BC, 
                List<sObject> scope){ 
      //get the list of all contact ids in the set
      for(sObject sObj : scope){
        contactIds.add((ID)sObj.get('Contact_Key__c'));
      }
      
      //store the map between the node id and the avon genealogy to perform the updates at the end of the execute method.
      for(Avon_Genealogy__c genealogyInstance : [SELECT   Id
                                                , Left_Value__c
                                                , Right_Value__c
                                                , Contact_Key__c  
                                                , Number_of_Children__c
                                         FROM Avon_Genealogy__c 
                                         where Contact_Key__c in :contactIds 
                                          ]){
           avonGenealogyMap.put(genealogyInstance.Contact_Key__c,genealogyInstance);                              	
      }
      
      
      for(Avon_Genealogy__c avonGenealogyInsVar:[select Id
                                                        , Left_Value__c
                                                        , Right_Value__c
                                                        , Contact_Key__c
                                                        , Upline_Contact__c
                                                        , Number_of_Children__c
                                                   from Avon_Genealogy__c
                                                   where Upline_Contact__c in :contactIds
                                                  ])  {
               //check if the parent has an entry in the map
               if(parentChildMap.get(avonGenealogyInsVar.Upline_Contact__c)!=null){
               	  parentChildMap.get(avonGenealogyInsVar.Upline_Contact__c).add(avonGenealogyInsVar);
               }            
               else{
               	  parentChildMap.put(avonGenealogyInsVar.Upline_Contact__c,new List<Avon_Genealogy__c>{avonGenealogyInsVar});
               }                  
          
          nodeChildCountMap.put( avonGenealogyInsVar.Upline_Contact__c, parentChildMap.get(avonGenealogyInsVar.Upline_Contact__c).size());     	
      }
      
      for(sObject sObj : scope){
      	//initialize number of children
      	noOfChildren=0;
      	String contactId=String.valueOf(sObj.get('Contact_Key__c'));
      	//check if the current node has any children. If it doesn't, we need not update the number of children field
      	if(nodeChildCountMap.get(contactId)!=null){
      		//fetch the list of all children for the give node
      		for(Avon_Genealogy__c genealogyInstance:parentChildMap.get(contactId)){
      			noOfChildren++;
      			//if the genealogy map in this batch has an entry for the child. Then the map is more recent than the DB. 
      			
      			if(avonGenealogyMap.get(genealogyInstance.Contact_Key__c)!=null && (avonGenealogyMap.get(genealogyInstance.Contact_Key__c).Number_of_Children__c)!=null){
      				noOfChildren+=avonGenealogyMap.get(genealogyInstance.Contact_Key__c).Number_of_Children__c.longValue();
      			}
      			else{
      				 if(genealogyInstance.Number_of_Children__c!=null){
      				  noOfChildren+=genealogyInstance.Number_of_Children__c.longValue();
      				 }
      			}
      		 	
      	    }
       	 }
       	 
       	 if((avonGenealogyInstance=avonGenealogyMap.get(contactId))!=null){
         			avonGenealogyInstance.Number_of_Children__c=noOfChildren;
         			System.debug(LoggingLevel.ERROR,'====contactId=====' + contactId);
         			System.debug(LoggingLevel.ERROR,'====noOfChildren=====' + noOfChildren);
         			genealogyListToBeUpdated.add(avonGenealogyInstance);
            }
      }
      
      System.debug(LoggingLevel.ERROR,'====genealogyListToBeUpdated=====' + genealogyListToBeUpdated);
      
      //execute the update operation on the genealogy objects for the current batch
      try{
      	update genealogyListToBeUpdated;
      }
      catch(Exception e){
      	//TODO: Handle appropriate exception and report error to the end user.
      }
          
   }

   global void finish(Database.BatchableContext BC){
   	
   	Avon_Genealogy__c rootGenealogyInstance=[select Id
 	                                              , Left_value__c
 	                                              , Right_Value__c 
 	                                              , Number_of_Children__c
 	                                         from Avon_Genealogy__c 
 	                                         where Upline_Contact__c=null
 	                                         limit 1];
 	
 	//select the count of all the nodes in the object
 	Long genealogyCnt=[select count() from Avon_Genealogy__c];
 	rootGenealogyInstance.left_value__c=1;
 	//total number of nodes multipled by two
 	rootGenealogyInstance.right_value__c=(rootGenealogyInstance.Number_of_Children__c + 1)*2;
 	update rootGenealogyInstance;
   	
   		// Query for selecting all the records in the genealogy other than root
        String query = 'select Id , Left_value__c , Right_Value__c, Number_of_Children__c, UPLN_GEN_INDX__c, Contact_Key__r.Name, Upline_Contact__c,Contact_Key__c from Avon_Genealogy__c where Upline_Contact__c!=null order by UPLN_GEN_INDX__c,Upline_Contact__c';
  
       //initialze the batch process
       AvonMPTTBatchVer avonMPTT = new AvonMPTTBatchVer(query);
      // Invoke the batch job.
      ID batchprocessid = Database.executeBatch(avonMPTT,2000);
   }
   
}