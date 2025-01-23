@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Maintain Supplier Delivery Days Singleto'

@Metadata.allowExtensions: true

@ObjectModel.usageType: { sizeCategory: #S, dataClass: #MASTER, serviceQuality: #C }

@ObjectModel.semanticKey: [ 'SingletonID' ]

define root view entity ZDOS_C_SupDlvDays_S
  provider contract transactional_query
  as projection on ZDOS_I_SupDlvDays_S

{
  key SingletonID,

      LastChangedAtMax,
      TransportRequestID,
      HideTransport,
      _SupplierDlvDays : redirected to composition child ZDOS_C_SupDlvDays
}
