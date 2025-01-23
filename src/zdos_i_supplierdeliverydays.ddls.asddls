@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Supplier Delivery Days'

@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.usageType: { serviceQuality: #X, sizeCategory: #S, dataClass: #MIXED }

define view entity ZDOS_I_SupplierDeliveryDays
  as select from zdos_supdlvdays

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
      created_by            as CreatedBy,
      created_at            as CreatedAt,
      last_changed_by       as LastChangedBy,
      last_changed_at       as LastChangedAt,
      local_last_changed_by as LocalLastChangedBy,
      local_last_changed_at as LocalLastChangedAt
}
