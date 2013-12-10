global with sharing class AvonMPTTBatchVer implements 
    Database.Batchable<sObject>, Database.Stateful{
 
   global final String Query;
   
   global Long currentleftValue;
   global Long currentrightValue;
   global string lastVistedParent;
   
    //we want the map to be reset after every batch. This map is used only during the duration of the single batch execution
      //stores the map between the node and number of children for that node
      static Map<String,Long> nodeChildCountMap=new Map<String,Long>();          	
     
      //we want the map to be reset after every batch. This map is used only during the duration of the single batch execution
      //stores the map between the parent node id and its left identifier
      static Map<String,Long> parentLeftIdMap=new Map<String,Long>();  
      
       //we want the map to be reset after every batch. This map is used only during the duration of the single batch execution
      //stores the map between the  node id and reference to the genealogy instance to update the values at the end of execute.
      static Map<String,Avon_Genealogy__c> avonGenealogyMap=new Map<String,Avon_Genealogy__c>();          	
     
      //variable to store the contact ids of the nodes in the current batch
      static Set<String> contactIds=new Set<String>();
      //variable to store the parent contact ids of the nodes in the current batch
      static Set<String> parentIds=new Set<String>();
      
       //we want the list to be reset after every batch. This list is used only during the duration of the single batch execution
      //stores the list of genealogy instances to be updated
      static List <Avon_Genealogy__c> genealogyListToBeUpdated=new List<Avon_Genealogy__c>();          	
     
      //variable to store the number of children for every node. Used only during the life of a batch execution
      static Long numberOfChildren=0;
      
      //variable to store the genealogy instance being fetched from map. Used only during the life of a batch execution
      static Avon_Genealogy__c avonGenealogyInstance;
   
   global AvonMPTTBatchVer(String q){Query=q;

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
      for(Avon_Genealogy__c genealogyInstance : [SELECT   Left_Value__c
                                                , Contact_Key__c  
                                         FROM Avon_Genealogy__c 
                                         where Contact_Key__c in :parentIds 
                                          ]){
           if(genealogyInstance!=null && genealogyInstance.left_value__c!=null){
             parentLeftIdMap.put(genealogyInstance.Contact_Key__c,genealogyInstance.left_value__c.longValue());           
           }                   	
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
           nodeChildCountMap.put(genealogyInstance.Contact_Key__c,genealogyInstance.Number_of_Children__c.longValue());                           	
      }
                                             	
                	
      for(sObject s : scope){
         //Integer level=Integer.valueOf(s.get('UPLN_GEN_INDX__c')) + 1;
         String contactId=String.valueOf(s.get('Contact_Key__c'));
         String parentId=String.valueOf(s.get('Upline_Contact__c'));
         
        
        if(lastVistedParent!=null && !(lastVistedParent.equalsIgnoreCase(parentId))){
        	 Long parentLeftValue=parentLeftIdMap.get(parentId);
         	    //if the values were populated in this batch. That is more current than db. Update the variable value
         	    //else use the db value
         	 if(avonGenealogyMap.get(parentId)!=null){
         	      parentLeftValue=avonGenealogyMap.get(parentId).Left_Value__c.longValue();
         	 }
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
         
         
      
        /*  if(level==2){
         	//the first node in level 2 is being read
         	if(currentleftValue==null){
         		currentleftValue=2;
         		//fetch the number of children in a single query.
         		if((numberOfChildren=(nodeChildCountMap.get(contactId)))==null){
         			//TODO: throw exception and return
         			numberOfChildren=0;
         		}
         		
         		currentrightValue=currentleftValue + (numberOfChildren*2) + 1;
         		lastVistedParent=parentId;
          	}
         	//its not the first node being visited.
         	else{
         		//left is always the previous right + 1 for level '2', as they all belong to the same parent
         		currentleftValue=currentrightValue+1;
         		//fetch the number of children in a single query.
         		if((numberOfChildren=(nodeChildCountMap.get(contactId)))==null){
         			//TODO: throw exception and return
         			numberOfChildren=0;
         		}
         		currentrightValue=currentleftValue + (numberOfChildren*2) + 1;
         		lastVistedParent=parentId;
         		
         		
         	}
         	
         }
         //we are working with level 3 or greater. All nodes in level 2 have the ID values populated.
         else{
         	//check if the parent is different than last visited node's parent
         	if(lastVistedParent!=null && !(lastVistedParent.equalsIgnoreCase(parentId))){
         	    //different parent fetch the left value of the current parent
         	  //  System.debug('====parentLeftIdMap keys======' + parentLeftIdMap.keySet());
         	  //  System.debug('====parentLeftIdMap keys======' + parentLeftIdMap.keySet());
         	  //  System.debug('====parentId======' + parentId);
         	  //  System.debug('====parentLeftIdMap======' + parentLeftIdMap.get(parentId));
         	    
         	    Long parentLeftValue=parentLeftIdMap.get(parentId);
         	    //if the entry is not in the DB, the values were populated in this batch
         	    if(avonGenealogyMap.get(parentId)!=null){
         	      parentLeftValue=avonGenealogyMap.get(parentId).Left_Value__c.longValue();
         	    }
         		//fetch the number of children in a single query.
         		if((numberOfChildren=(nodeChildCountMap.get(contactId)))==null){
         			//TODO: throw exception and return
         			numberOfChildren=0;
         		}
         		if(parentLeftValue==null){
         			//TODO: THROW EXCEPTION AND RETURN
         		}
         	//	System.debug('====parentLeftValue======'+ parentLeftValue);
         		System.debug('====numberOfChildren======'+ numberOfChildren);
         		
         		currentleftValue=parentLeftValue+1;
         	//	System.debug('====currentleftValue======'+ currentleftValue);
         		currentrightValue=currentleftValue + (numberOfChildren*2) + 1;
         		lastVistedParent=parentId;
         	}
         	//parent of the current is the same as the previous node
         	else{
         		//fetch the number of children in a single query.
         		if((numberOfChildren=(nodeChildCountMap.get(contactId)))==null){
         			//TODO: throw exception and return
         			numberOfChildren=0;
         		}
         		currentleftValue=currentrightValue+1;
         		currentrightValue=currentleftValue + (numberOfChildren*2) + 1;
         		lastVistedParent=parentId;
         	}
        }*/
         
         if((avonGenealogyInstance=avonGenealogyMap.get(contactId))!=null){
         			avonGenealogyInstance.Left_value__c=currentleftValue;
         			avonGenealogyInstance.Right_Value__c=currentrightValue;
         			System.debug(LoggingLevel.ERROR,'====currentleftValue=====' + currentleftValue);
         			System.debug(LoggingLevel.ERROR,'====currentrightValue=====' + currentrightValue);
         			System.debug(LoggingLevel.ERROR,'====contactId=====' + contactId);
         		 	System.debug(LoggingLevel.ERROR,'====lastVistedParent=====' + lastVistedParent);
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
   }
}