CLASS lsc_zdos_i_supdlvdays_s DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.
    METHODS save_modified    REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.



CLASS lsc_zdos_i_supdlvdays_s IMPLEMENTATION.
  METHOD save_modified ##NEEDED.
  ENDMETHOD.


  METHOD cleanup_finalize ##NEEDED.
  ENDMETHOD.
ENDCLASS.



CLASS lhc_rap_tdat_cts DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS get
      RETURNING VALUE(result) TYPE REF TO if_mbc_cp_rap_table_cts.

ENDCLASS.



CLASS lhc_rap_tdat_cts IMPLEMENTATION.
  METHOD get.
    result = mbc_cp_api=>rap_table_cts( table_entity_relations = VALUE #(
                                            ( entity = 'SupplierDlvDays' table = 'ZDOS_SUPDLVDAYS' ) ) )
                                       ##NO_TEXT.
  ENDMETHOD.
ENDCLASS.



CLASS lhc_zdos_i_supdlvdays_s DEFINITION INHERITING FROM cl_abap_behavior_handler FINAL.
  PRIVATE SECTION.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING
                keys   REQUEST requested_features FOR SupplierDlvDaysAll
      RESULT    result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING
      REQUEST requested_authorizations FOR SupplierDlvDaysAll
      RESULT result.
ENDCLASS.



CLASS lhc_zdos_i_supdlvdays_s IMPLEMENTATION.
  METHOD get_instance_features.
    READ ENTITIES OF ZDOS_I_SupDlvDays_S IN LOCAL MODE
         ENTITY SupplierDlvDaysAll
         ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(all).

    result = VALUE #( ( %tky                    = all[ 1 ]-%tky
                        %action-edit            = if_abap_behv=>fc-o-enabled
                        %assoc-_SupplierDlvDays = if_abap_behv=>fc-o-enabled ) ).
  ENDMETHOD.


  METHOD get_global_authorizations.
    AUTHORITY-CHECK OBJECT 'S_TABU_NAM' ID 'TABLE' FIELD 'ZDOS_I_SUPDLVDAYS' ID 'ACTVT' FIELD '02'.
    DATA(is_authorized) = COND #( WHEN sy-subrc = 0
                                  THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized ).
    result-%update      = is_authorized.
    result-%action-Edit = is_authorized.
  ENDMETHOD.
ENDCLASS.



CLASS lhc_zdos_i_supdlvdays DEFINITION INHERITING FROM cl_abap_behavior_handler FINAL.
  PRIVATE SECTION.
    METHODS get_global_features FOR GLOBAL FEATURES
      IMPORTING
      REQUEST requested_features FOR SupplierDlvDays
      RESULT result.
    METHODS validateHolidayDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR SupplierDlvDays~validateHolidayDates.

    METHODS validateMaterial FOR VALIDATE ON SAVE
      IMPORTING keys FOR SupplierDlvDays~validateMaterial.

    METHODS validateMaterialGroup FOR VALIDATE ON SAVE
      IMPORTING keys FOR SupplierDlvDays~validateMaterialGroup.

    METHODS validateMatGrMaterial FOR VALIDATE ON SAVE
      IMPORTING keys FOR SupplierDlvDays~validateMatGrMaterial.

    METHODS validatePlant FOR VALIDATE ON SAVE
      IMPORTING keys FOR SupplierDlvDays~validatePlant.

    METHODS validatePlantMaterial FOR VALIDATE ON SAVE
      IMPORTING keys FOR SupplierDlvDays~validatePlantMaterial.

    METHODS validateSupplier FOR VALIDATE ON SAVE
      IMPORTING keys FOR SupplierDlvDays~validateSupplier.
ENDCLASS.



CLASS lhc_zdos_i_supdlvdays IMPLEMENTATION.
  METHOD get_global_features.
    result-%update = if_abap_behv=>fc-o-enabled.
    result-%delete = if_abap_behv=>fc-o-enabled.
  ENDMETHOD.


  METHOD validateHolidayDates.
  ENDMETHOD.


  METHOD validateMaterial.
    READ ENTITIES OF ZDOS_I_SupDlvDays_S IN LOCAL MODE
         ENTITY SupplierDlvDays
         FIELDS ( singletonid
                  SupplDlvDaysUUID
                  Material )
         WITH CORRESPONDING #( keys )
         RESULT DATA(entities).

    IF entities IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM i_product
      FIELDS product
      FOR ALL ENTRIES IN @entities
      WHERE product = @entities-material
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(existing_products).

    IF sy-subrc = 0.
      DELETE ADJACENT DUPLICATES FROM existing_products COMPARING product.
    ENDIF.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      APPEND VALUE #( %tky        = <entity>-%tky
                      %state_area = 'VALIDATE_MATERIAL' )
             TO reported-supplierdlvdays.

      IF <entity>-material IS INITIAL.
        APPEND VALUE #( %tky = <entity>-%tky ) TO failed-supplierdlvdays.
        APPEND VALUE #( %tky                     = <entity>-%tky
                        %msg                     = new_message( id       = 'ZDOS_MSG_SUPDLVDATE'
                                                                number   = '012'
                                                                severity = if_abap_behv_message=>severity-error )
                        %element-material        = if_abap_behv=>mk-on
                        %state_area              = 'VALIDATE_MATERIAL'
                        %path-supplierdlvdaysall = CORRESPONDING #( <entity> ) )
               TO reported-supplierdlvdays.
        CONTINUE.
      ENDIF.

      IF NOT line_exists( existing_products[ Product = <entity>-material ] ).
        APPEND VALUE #( %tky = <entity>-%tky ) TO failed-supplierdlvdays.
        APPEND VALUE #( %tky                     = <entity>-%tky
                        %msg                     = new_message( id       = 'VALIDATE_MATERIAL'
                                                                number   = '013'
                                                                severity = if_abap_behv_message=>severity-error
                                                                v1       = <entity>-material )
                        %element-material        = if_abap_behv=>mk-on
                        %state_area              = 'VALIDATE_MATERIAL'
                        %path-supplierdlvdaysall = CORRESPONDING #( <entity> ) )
               TO reported-supplierdlvdays.
        CONTINUE.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateMaterialGroup.
  ENDMETHOD.


  METHOD validateMatGrMaterial.
  ENDMETHOD.


  METHOD validatePlant.
    READ ENTITIES OF ZDOS_I_SupDlvDays_S IN LOCAL MODE
         ENTITY SupplierDlvDays
         FIELDS ( singletonid
                  SupplDlvDaysUUID
                  Plant )
         WITH CORRESPONDING #( keys )
         RESULT DATA(entities).

    IF entities IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM i_plant
      FIELDS plant
      FOR ALL ENTRIES IN @entities
      WHERE plant = @entities-plant
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(existing_plants).

    IF sy-subrc = 0.
      DELETE ADJACENT DUPLICATES FROM existing_plants COMPARING plant.
    ENDIF.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      APPEND VALUE #( %tky        = <entity>-%tky
                      %state_area = 'VALIDATE_PLANT' )
             TO reported-supplierdlvdays.

      IF <entity>-plant IS INITIAL.
        APPEND VALUE #( %tky = <entity>-%tky ) TO failed-supplierdlvdays.
        APPEND VALUE #( %tky                     = <entity>-%tky
                        %msg                     = new_message( id       = 'ZDOS_MSG_SUPDLVDATE'
                                                                number   = '010'
                                                                severity = if_abap_behv_message=>severity-error )
                        %element-plant           = if_abap_behv=>mk-on
                        %state_area              = 'VALIDATE_PLANT'
                        %path-supplierdlvdaysall = CORRESPONDING #( <entity> ) )
               TO reported-supplierdlvdays.
        CONTINUE.
      ENDIF.

      IF NOT line_exists( existing_plants[ plant = <entity>-plant ] ).
        APPEND VALUE #( %tky = <entity>-%tky ) TO failed-supplierdlvdays.
        APPEND VALUE #( %tky                     = <entity>-%tky
                        %msg                     = new_message( id       = 'ZDOS_MSG_SUPDLVDATE'
                                                                number   = '011'
                                                                severity = if_abap_behv_message=>severity-error
                                                                v1       = <entity>-plant )
                        %element-plant           = if_abap_behv=>mk-on
                        %state_area              = 'VALIDATE_PLANT'
                        %path-supplierdlvdaysall = CORRESPONDING #( <entity> ) )
               TO reported-supplierdlvdays.
        CONTINUE.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD validatePlantMaterial.
  ENDMETHOD.


  METHOD validateSupplier.
  ENDMETHOD.
ENDCLASS.
