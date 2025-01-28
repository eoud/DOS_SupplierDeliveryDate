@AbapCatalog.sqlViewAppendName: 'ZZDOSXECEXPRISDD'
@EndUserText.label: 'DLWR Open Source - Suppl. Delivery Date'
extend view E_PrmtHbRpldPurchaseReqnItem with ZZDOS_X_ECEXTPRITEMSupDlvDate
{
  Persistence.zzdos_suppldlvdate_pri as ZZDOS_SupplDlvDate_PRI
}
