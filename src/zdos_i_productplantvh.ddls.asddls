@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #NOT_REQUIRED

@Consumption.ranked: true

@EndUserText.label: 'Product-Plant Value Help'

@Metadata.ignorePropagatedAnnotations: false

@ObjectModel.usageType: { serviceQuality: #X, sizeCategory: #S, dataClass: #MIXED }

define view entity ZDOS_I_ProductPlantVH
  as select from I_ProductPlantStdVH

{
  key cast(Product as productnumber preserving type) as Product,
  key cast(Plant as werks_d preserving type)         as Plant,

      _Product._Text[1: left outer where Language = $session.system_language].ProductName,

      /* Associations */
      _Plant,
      _Product
}
