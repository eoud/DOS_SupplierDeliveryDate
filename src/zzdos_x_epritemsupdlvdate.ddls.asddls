@AbapCatalog.sqlViewAppendName: 'ZZDOSXEPRITEMSDD'
@EndUserText.label: 'DLWR Open Source - Suppl. Delivery Date'
extend view E_Purchaserequisitionitem with ZZDOS_X_EPRITEMSupDlvDate
{
  Persistence.zzdos_suppl_dlv_date_pri as ZZDOS_SupplDlvDate_PRI
}
