@AbapCatalog.sqlViewAppendName: 'ZZDOSXEPRITEMSDD'
@EndUserText.label: 'DLWR Open Source - Suppl. Delivery Date'
extend view E_Purchaserequisitionitem with ZZDOS_X_EPRITEMSupDlvDate
{
  Persistence.ZZDOS_SUPPLDLVDATE_PRI as ZZDOS_SupplDlvDate_PRI
}
