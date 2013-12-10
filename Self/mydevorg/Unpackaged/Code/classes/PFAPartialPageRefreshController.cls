public with sharing class PFAPartialPageRefreshController {


    
    
    private final Lead ld;
    public Integer value { get; private set;}

    public PFAPartialPageRefreshController(ApexPages.StandardController stdCntrl) {
                this.ld = (Lead)stdCntrl.getRecord();
                value = 0;
        
    }


   public PageReference saveandnew() {
    
  //  Invoice_Statement__c inv = new Invoice_Statement__c(Description__c='My new invoice');
// Insert the invoice using DML.
//insert inv; 
    
     try { 
         insert ld; 
        } catch(System.DMLException e) {
            ApexPages.addMessages(e);
            return null;
        } 
        
        return null; 
    
   // stdCntrl.reset();
    
    } 

    
    // ApexPages.StandardSetController must be instantiated
    // for standard list controllers
    public ApexPages.StandardSetController setCon {
        get {
            if(setCon == null) {
                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(
                    [SELECT Name, Company, Status, City, CreatedDate FROM Lead ORDER BY CREATEDDATE DESC LIMIT 50]));
            }
            return setCon;
        }
        set;
    }

    // Initialize setCon and return a list of records
    public List<Lead> getleads() {
        return (List<Lead>) setCon.getRecords();
    }
    
    public PageReference doNothing() {
      value++;
      return null;
    }

}