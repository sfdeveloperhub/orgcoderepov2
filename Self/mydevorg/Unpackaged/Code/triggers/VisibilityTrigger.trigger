trigger VisibilityTrigger on Visibility__c (before insert, before update) {
   for(Visibility__c visibilityInstance:Trigger.New){
   	 // visibilityInstance.Name=visibilityInstance.Establishment__r.Name;
   }
}