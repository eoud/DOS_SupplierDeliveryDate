//@AbapCatalog.sqlViewName: 'ISCHEDTYPEVH'
//@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED

@Consumption.ranked: true

@EndUserText.label: 'Scheduling Type'

@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.dataCategory: #VALUE_HELP
@ObjectModel.representativeKey: 'SchedulingType'
@ObjectModel.resultSet.sizeCategory: #XS
@ObjectModel.supportedCapabilities: [ #VALUE_HELP_PROVIDER, #SEARCHABLE_ENTITY ]
@ObjectModel.usageType: { serviceQuality: #C, sizeCategory: #S, dataClass: #CUSTOMIZING }

@Search.searchable: true

@VDM.lifecycle.contract.type: #PUBLIC_LOCAL_API
@VDM.viewType: #BASIC

define view entity ZDOS_I_SchedulingTypeVH
  as select from I_SchedulingType

{
      @ObjectModel.text.association: '_Text'
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @Search.ranking: #HIGH
  key SchedulingType,

      // Association
      _Text
}

where SchedulingType = '1' // Forward
   or SchedulingType = '2' // Backward
   ;
