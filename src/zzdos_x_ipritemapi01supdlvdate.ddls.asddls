@AbapCatalog.sqlViewAppendName: 'ZZDOSXIPRITEASDD'
@EndUserText.label: 'DLWR Open Source - Suppl. Delivery Date'
extend view I_PurchaseRequisition_Api01 with ZZDOS_X_IPRITEMAPI01SupDlvDate
{
    _Extension.ZZDOS_SupplDlvDate_PRI as ZZDOS_SupplDlvDate_PRI
}
