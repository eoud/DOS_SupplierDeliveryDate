@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #CHECK

@EndUserText.label: 'Purchase Info Record Org. Plant Data'

@Metadata.ignorePropagatedAnnotations: false

@ObjectModel.usageType: { serviceQuality: #X, sizeCategory: #S, dataClass: #MIXED }

define view entity ZDOS_C_PurInfoRecOrgPlantData
  as select from I_PurchasingInfoRecordApi01

{
  key cast(_PurgInfoRecdOrgPlntDataApi01.PurchasingInfoRecord as infnr preserving type)   as PurchasingInfoRecord,
  key cast(_PurgInfoRecdOrgPlntDataApi01.PurchasingOrganization as ekorg preserving type) as PurchasingOrganization,
  key _PurgInfoRecdOrgPlntDataApi01.PurchasingInfoRecordCategory                          as PurchasingInfoRecordCategory,
  key cast(_PurgInfoRecdOrgPlntDataApi01.Plant as ewerk preserving type)                  as Plant,

      _PurgInfoRecdOrgPlntDataApi01.MaterialPlannedDeliveryDurn                           as PlannedDeliveryDays,
      _PurgInfoRecdOrgPlntDataApi01.CreatedByUser                                         as CreatedBy,
      CreationDate                                                                        as CreatedAt,
      cast(Material as matnr preserving type)                                             as Material,
      cast(Supplier as elifn preserving type)                                             as Supplier
}
