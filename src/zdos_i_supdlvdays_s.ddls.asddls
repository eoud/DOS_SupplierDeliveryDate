@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Supplier Delivery Days Singleton'

@ObjectModel.usageType: { sizeCategory: #S, dataClass: #MASTER, serviceQuality: #C }

define root view entity ZDOS_I_SupDlvDays_S
  as select from    I_Language

    left outer join zdos_supdlvdays on 0 = 0

  composition [0..*] of ZDOS_I_SupDlvDays as _SupplierDlvDays

{
  key 1                                         as SingletonID,

      _SupplierDlvDays,
      max(zdos_supdlvdays.last_changed_at)      as LastChangedAtMax,
      cast('' as sxco_transport)                as TransportRequestID,
      cast('X' as abap_boolean preserving type) as HideTransport
}

where I_Language.Language = $session.system_language
