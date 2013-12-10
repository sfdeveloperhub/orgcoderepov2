/**
 * Class to display the establishments based on visibility settings
 *
 */

public with sharing class EsTabsDisplay {

  Account accountInstance;
  
  List<String> userIds;
  
  
  public EsTabsDisplay(Apexpages.standardcontroller accountController){
  	  accountInstance=(Account)accountController.getRecord();
  	  userIds=new List<String>();
  	  if(accountInstance!=null){
	  	  for(AccountTeamMember teamMemberInstance:[select Id, AccountId, UserId from AccountTeamMember where AccountId=:accountInstance.id]){
	  	  	  userIds.add(teamMemberInstance.UserId);
	  	  }
	  	  userIds.add(accountInstance.OwnerId);
	  	  //userIds.add(Userinfo.getUserId());
  	  }
  }

  public List<Visibility__c> getEstablishments(){
  	
  	System.debug('====in getEstablishments Method====' + userIds);
  	
  	Map<Id,Visibility__c> retVisibilityMap=new Map<Id,Visibility__c>();
  	
  	for(Visibility__c visibilityInstance :[select Id
  	                                            , Establishment__c
  	                                            , Establishment__r.Name
  	                                            , Establishment__r.City_Name__c
  	                                            , Establishment__r.Account__c
  	                                            , Establishment__r.Source_System_ID__c
  	                                           , User__c 
  	                                       from Visibility__c
  	                                       where User__c =:userIds
  	                                       and Account__c=:accountInstance.id]){
  	                                                          	
  	          retVisibilityMap.put(visibilityInstance.Establishment__c,visibilityInstance);
  	 }
  	  
  	  /*hasEstabs=(retVisibilityMap.size()>0);
  	  
  	  System.debug('====hasEstabs====' + hasEstabs);
  	  
  	  if(retVisibilityMap.size()>0){
  	  	ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'No eligible establishments found for ' + accountInstance.name));
  	  }*/
  	  
  	  return   retVisibilityMap.values();                                                      	
  }
  
}