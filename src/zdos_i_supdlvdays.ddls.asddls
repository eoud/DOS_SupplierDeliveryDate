@AccessControl.authorizationCheck: #CHECK

@EndUserText.label: 'Supplier Delivery Days'

@ObjectModel.usageType: { sizeCategory: #M, dataClass: #MASTER, serviceQuality: #C }

define view entity ZDOS_I_SupDlvDays
  as select from zdos_supdlvdays

  association to parent ZDOS_I_SupDlvDays_S as _SupplierDlvDaysAll on $projection.SingletonID = _SupplierDlvDaysAll.SingletonID

{
  key suppl_dlv_days_uuid   as SupplDlvDaysUUID,

      supplier              as Supplier,
      plant                 as Plant,
      material_group        as MaterialGroup,
      material              as Material,
      monday                as Monday,
      tuesday               as Tuesday,
      wednesday             as Wednesday,
      thursday              as Thursday,
      friday                as Friday,
      saturday              as Saturday,
      sunday                as Sunday,
      holiday_start         as HolidayStart,
      holiday_end           as HolidayEnd,
      scheduling_type       as SchedulingType,

      @Semantics.user.createdBy: true
      created_by            as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,

      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      1                     as SingletonID,

      _SupplierDlvDaysAll
}
