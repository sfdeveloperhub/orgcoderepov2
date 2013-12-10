trigger PopulateKoachContentParams on Koach_Call_Focus__c (after update) {
   List<Koach_Content_Params__c> koachContentParamList=new List<Koach_Content_Params__c>();
   
   
   for(Koach_Call_Focus__c focusInstance:Trigger.new){
     
      //construct the content param external id
      String contentParamIdentifier=focusInstance.Name + focusInstance.Sequence__c;
       //Create an instance of Koach Content Param
      Koach_Content_Params__c koachContentParamInstance=new Koach_Content_Params__c(ContentParamIdentifier__c=contentParamIdentifier
                                                                                  , Koach_Brand__c=focusInstance.Koach_Brand__c
                                                                                  , Koach_Segmentation__c=focusInstance.Koach_Segmentation__c
                                                                                  , Koach_Call_Focus__c =focusInstance.Id
                                                                                  );
      koachContentParamList.add(koachContentParamInstance);
   }
   
   upsert koachContentParamList ContentParamIdentifier__c;
}