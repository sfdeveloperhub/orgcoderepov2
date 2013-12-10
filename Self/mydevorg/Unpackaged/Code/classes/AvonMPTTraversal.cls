/**
 *
 */
public with sharing class AvonMPTTraversal {
   
//update the root node and construct the query to read all the genealogy records as a batch.
 public PageReference traverseTree(){
 	 
 	//query the root genealogy instance
 	/*Avon_Genealogy__c rootGenealogyInstance=[select Id
 	                                              , LFT_ND_ID__c
 	                                              , RGT_ND_ID__c 
 	                                         from Avon_Genealogy__c 
 	                                         where Upline_Contact__c=null
 	                                         limit 1];
 	
 	//select the count of all the nodes in the object
 	Long genealogyCnt=[select count() from Avon_Genealogy__c];
 	rootGenealogyInstance.LFT_ND_ID__c=1;
 	rootGenealogyInstance.RGT_ND_ID__c=(2L*genealogyCnt);
 	update rootGenealogyInstance;*/
     Boolean populateAll=true;
    
    // Query for selecting all the records in the genealogy other than root
        String query = 'select Id , LFT_ND_ID__c , UPLN_GEN_INDX__c, RGT_ND_ID__c, Contact_Key__r.Name, Upline_Contact__c,Contact_Key__c from Avon_Genealogy__c order by ROOT_UPLN_ACC_NR__c,UPLN_GEN_INDX__c desc';
  
       //initialze the batch process
       AvonNbrOfChildrenVer2 avonpopulateIdValues = new AvonNbrOfChildrenVer2(query,populateAll);
      // Invoke the batch job.
      ID batchprocessid = Database.executeBatch(avonpopulateIdValues,2000);

 

 	return null;
 }
 
 //update the root node and construct the query to read all the genealogy records as a batch.
 public PageReference populateEmptyRecords(){
 	 
    // Query for selecting all the records in the genealogy other than root
        String query = 'select Id , LFT_ND_ID__c , UPLN_GEN_INDX__c, RGT_ND_ID__c, Number_of_Children__c, Contact_Key__r.Name, Upline_Contact__c,Contact_Key__c from Avon_Genealogy__c where Number_of_Children__c=null order by ROOT_UPLN_ACC_NR__c,UPLN_GEN_INDX__c desc';
  
        Boolean populateAll=false;
       //initialze the batch process
       AvonNbrOfChildrenVer2 avonpopulateIdValues = new AvonNbrOfChildrenVer2(query,populateAll);
      // Invoke the batch job.
      ID batchprocessid = Database.executeBatch(avonpopulateIdValues,2000);

 	return null;
 }
 
 public PageReference resetLftRghtData(){
 	// Query for selecting all the records in the data object
        String query = 'select Id , LFT_ND_ID__c, RGT_ND_ID__c from My_Business_And_Leadership_Data__c';
  
       //initialze the batch process
       AvonMPTTResetLeftRight restlftRghtValues = new AvonMPTTResetLeftRight(query,null);
      // Invoke the batch job.
      ID batchprocessid = Database.executeBatch(restlftRghtValues,2000);
    	return null;
 }
 
 public PageReference resetLftRghtGenealogy(){
 	// Query for selecting all the records in the data object
        String query = 'select Id , LFT_ND_ID__c, RGT_ND_ID__c from Avon_Genealogy__c';
  
       //initialze the batch process
       AvonMPTTResetLeftRight restlftRghtValues = new AvonMPTTResetLeftRight(query,'Genealogy');
      // Invoke the batch job.
      ID batchprocessid = Database.executeBatch(restlftRghtValues,2000);
    	return null;
 }
}