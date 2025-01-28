@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Product Group Value Help'

@Metadata.ignorePropagatedAnnotations: false

@ObjectModel.usageType: { serviceQuality: #X, sizeCategory: #S, dataClass: #MIXED }

define view entity ZDOS_I_ProductGroupVH
  as select from I_ProductGroupVH

{
  key ProductGroup,

      /* Associations */
      _ProductGroupText[1: left outer where Language = $session.system_language].ProductGroupName
}
