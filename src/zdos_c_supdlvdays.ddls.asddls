@AccessControl.authorizationCheck: #CHECK

@EndUserText.label: 'Maintain Supplier Delivery Days'

@Metadata.allowExtensions: true

@ObjectModel.usageType: { sizeCategory: #M, dataClass: #MASTER, serviceQuality: #C }

define view entity ZDOS_C_SupDlvDays
  as projection on ZDOS_I_SupDlvDays

{
  key SupplDlvDaysUUID,

      Supplier,
      Plant,
      MaterialGroup,
      Material,
      Monday,
      Tuesday,
      Wednesday,
      Thursday,
      Friday,
      Saturday,
      Sunday,
      HolidayStart,
      HolidayEnd,
      SchedulingType,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,

      @Consumption.hidden: true
      LocalLastChangedBy,

      @Consumption.hidden: true
      LocalLastChangedAt,

      @Consumption.hidden: true
      SingletonID,

      _SupplierDlvDaysAll : redirected to parent ZDOS_C_SupDlvDays_S
}
