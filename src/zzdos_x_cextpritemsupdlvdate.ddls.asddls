@AbapCatalog.sqlViewAppendName: 'ZZDOSXCEXPRISDD'
@EndUserText.label: 'DLWR Open Source - Suppl. Delivery Date'
extend view C_ExtPurchaseRequisitionItem with ZZDOS_X_CEXTPRITEMSupDlvDate
{
    _PrmtHbRpldPurchaseReqnItem.ZZDOS_SupplDlvDate_PRI as ZZDOS_SupplDlvDate_PRI
}
