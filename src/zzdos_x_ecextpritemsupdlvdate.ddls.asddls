@AbapCatalog.sqlViewAppendName: 'ZZDOSXECEXPRISDD'
@EndUserText.label: 'DLWR Open Source - Suppl. Delivery Date'
extend view E_PrmtHbRpldPurchaseReqnItem with ZZDOS_X_ECEXTPRITEMSupDlvDate
{
  Persistence.zzdos_suppl_dlv_date_pri as ZZDOS_SupplDlvDate_PRI
}
