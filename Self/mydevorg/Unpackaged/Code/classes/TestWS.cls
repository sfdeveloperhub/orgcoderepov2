global Class TestWS{
webService static boolean checkCreate() {
  Schema.DescribeSObjectResult r = Account.sObjectType.getDescribe();
  return r.isCreateable();
}
}