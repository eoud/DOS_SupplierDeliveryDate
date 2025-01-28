@AbapCatalog.sqlViewAppendName: 'ZZDOSXIPRITMASDD'
@EndUserText.label: 'DLWR Open Source - Suppl. Delivery Date'
extend view I_PurchaseRequisitionItemAPI01 with ZZDOS_X_IPRITMAPI01SupDlvDate
{
    _Extension.ZZDOS_SUPPLDLVDATE_PRI as ZZDOS_SupplDlvDate_PRI
}
