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



CLASS lhc_zdos_i_supdlvdays_s DEFINITION INHERITING FROM cl_abap_behavior_handler FINAL.
  PRIVATE SECTION.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys   REQUEST requested_features FOR SupplierDlvDaysAll
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
    CONSTANTS custom_message_class TYPE symsgid VALUE 'ZDOS_MSG_SUPDLVDATE' ##NO_TEXT.

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
    METHODS validateDeliveryDays FOR VALIDATE ON SAVE
      IMPORTING keys FOR SupplierDlvDays~validateDeliveryDays.
    METHODS validateSchedulingType FOR VALIDATE ON SAVE
      IMPORTING keys FOR SupplierDlvDays~validateSchedulingType.
ENDCLASS.



CLASS lhc_zdos_i_supdlvdays IMPLEMENTATION.
  METHOD get_global_features.
    result-%update = if_abap_behv=>fc-o-enabled.
    result-%delete = if_abap_behv=>fc-o-enabled.
  ENDMETHOD.


  METHOD validateHolidayDates.
    CONSTANTS state_area_holidays TYPE symsgid VALUE 'VALIDATE_HOLIDAYS' ##NO_TEXT.

    READ ENTITIES OF ZDOS_I_SupDlvDays_S IN LOCAL MODE
         ENTITY SupplierDlvDays
         FIELDS ( singletonid
                  SupplDlvDaysUUID
                  HolidayStart
                  HolidayEnd )
         WITH CORRESPONDING #( keys )
         RESULT DATA(entities).

    IF entities IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      IF    <entity>-holidaystart IS INITIAL AND <entity>-holidayend IS INITIAL
         OR <entity>-holidayend >= <entity>-holidaystart.
        CONTINUE.
      ENDIF.

      " Invalidate state messages
      APPEND VALUE #( %tky        = <entity>-%tky
                      %state_area = state_area_holidays )
             TO reported-supplierdlvdays.

      " Add state message
      APPEND VALUE #( %tky = <entity>-%tky ) TO failed-supplierdlvdays.

      APPEND VALUE #( %tky                = <entity>-%tky
                      %state_area         = state_area_holidays
                      %msg                = new_message( id       = lhc_zdos_i_supdlvdays=>custom_message_class
                                                         number   = '003'
                                                         severity = if_abap_behv_message=>severity-error
                                                         v1       = <entity>-material )
                      %element-holidayend = if_abap_behv=>mk-on )
             TO reported-supplierdlvdays.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateMaterial.
    CONSTANTS state_area_material TYPE symsgid VALUE 'VALIDATE_MATERIAL' ##NO_TEXT.

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
      FIELDS DISTINCT product
      FOR ALL ENTRIES IN @entities
      WHERE product = @entities-material
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(existing_products).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      IF line_exists( existing_products[ Product = <entity>-material ] ). "#EC CI_STDSEQ
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky        = <entity>-%tky
                      %state_area = state_area_material )
             TO reported-supplierdlvdays.

      APPEND VALUE #( %tky = <entity>-%tky ) TO failed-supplierdlvdays.
      APPEND VALUE #( %tky                     = <entity>-%tky
                      %msg                     = new_message( id       = lhc_zdos_i_supdlvdays=>custom_message_class
                                                              number   = '013'
                                                              severity = if_abap_behv_message=>severity-error
                                                              v1       = <entity>-material )
                      %element-material        = if_abap_behv=>mk-on
                      %state_area              = state_area_material
                      %path-supplierdlvdaysall = CORRESPONDING #( <entity> ) )
             TO reported-supplierdlvdays.
      CONTINUE.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateMaterialGroup.
    CONSTANTS state_area_mat_group TYPE symsgid VALUE 'VALIDATE_MAT_GROUP' ##NO_TEXT.

    READ ENTITIES OF ZDOS_I_SupDlvDays_S IN LOCAL MODE
         ENTITY SupplierDlvDays
         FIELDS ( singletonid
                  SupplDlvDaysUUID
                  MaterialGroup )
         WITH CORRESPONDING #( keys )
         RESULT DATA(entities).

    IF entities IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM I_ProductGroup_2
      FIELDS DISTINCT ProductGroup
      FOR ALL ENTRIES IN @entities
      WHERE ProductGroup = @entities-MaterialGroup
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(existing_product_groups).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      APPEND VALUE #( %tky        = <entity>-%tky
                      %state_area = state_area_mat_group )
             TO reported-supplierdlvdays.

      IF line_exists( existing_product_groups[ ProductGroup = <entity>-MaterialGroup ] ). "#EC CI_STDSEQ
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky = <entity>-%tky ) TO failed-supplierdlvdays.
      APPEND VALUE #( %tky                     = <entity>-%tky
                      %msg                     = new_message( id       = lhc_zdos_i_supdlvdays=>custom_message_class
                                                              number   = '016'
                                                              severity = if_abap_behv_message=>severity-error
                                                              v1       = <entity>-MaterialGroup )
                      %element-MaterialGroup   = if_abap_behv=>mk-on
                      %state_area              = state_area_mat_group
                      %path-supplierdlvdaysall = CORRESPONDING #( <entity> ) )
             TO reported-supplierdlvdays.
      CONTINUE.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateMatGrMaterial.
    CONSTANTS state_area_matgr_matnr TYPE string VALUE 'VALIDATE_MATGR_MATNR' ##NO_TEXT.

    READ ENTITIES OF ZDOS_I_SupDlvDays_S IN LOCAL MODE
         ENTITY SupplierDlvDays
         FIELDS ( singletonid
                  SupplDlvDaysUUID
                  MaterialGroup
                  Material )
         WITH CORRESPONDING #( keys )
         RESULT DATA(entities).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      IF <entity>-Material IS INITIAL OR <entity>-MaterialGroup IS INITIAL.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky        = <entity>-%tky
                      %state_area = state_area_matgr_matnr )
             TO reported-supplierdlvdays.

      APPEND VALUE #( %tky = <entity>-%tky ) TO failed-supplierdlvdays.
      APPEND VALUE #( %tky                     = <entity>-%tky
                      %msg                     = new_message( id       = lhc_zdos_i_supdlvdays=>custom_message_class
                                                              number   = '004'
                                                              severity = if_abap_behv_message=>severity-error )
                      %element-MaterialGroup   = if_abap_behv=>mk-on
                      %state_area              = state_area_matgr_matnr
                      %path-supplierdlvdaysall = CORRESPONDING #( <entity> ) )
             TO reported-supplierdlvdays.
      CONTINUE.
    ENDLOOP.
  ENDMETHOD.


  METHOD validatePlant.
    CONSTANTS state_area_plant TYPE string VALUE 'VALIDATE_PLANT' ##NO_TEXT.

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
      FIELDS DISTINCT plant
      FOR ALL ENTRIES IN @entities
      WHERE plant = @entities-plant
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(existing_plants).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      APPEND VALUE #( %tky        = <entity>-%tky
                      %state_area = state_area_plant )
             TO reported-supplierdlvdays.

      IF line_exists( existing_plants[ plant = <entity>-plant ] ). "#EC CI_STDSEQ
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky = <entity>-%tky ) TO failed-supplierdlvdays.
      APPEND VALUE #( %tky                     = <entity>-%tky
                      %msg                     = new_message( id       = lhc_zdos_i_supdlvdays=>custom_message_class
                                                              number   = '011'
                                                              severity = if_abap_behv_message=>severity-error
                                                              v1       = <entity>-plant )
                      %element-plant           = if_abap_behv=>mk-on
                      %state_area              = state_area_plant
                      %path-supplierdlvdaysall = CORRESPONDING #( <entity> ) )
             TO reported-supplierdlvdays.
      CONTINUE.
    ENDLOOP.
  ENDMETHOD.


  METHOD validatePlantMaterial.
    CONSTANTS state_area_plant_matnr TYPE symsgid VALUE 'VALIDATE_PLANT_MATNR' ##NO_TEXT.

    READ ENTITIES OF ZDOS_I_SupDlvDays_S IN LOCAL MODE
         ENTITY SupplierDlvDays
         FIELDS ( singletonid
                  SupplDlvDaysUUID
                  Plant
                  Material )
         WITH CORRESPONDING #( keys )
         RESULT DATA(entities).

    IF entities IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM I_ProductPlantBasic
      FIELDS DISTINCT product,
                      plant
      FOR ALL ENTRIES IN @entities
      WHERE product = @entities-material
        AND plant   = @entities-plant
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(existing_products).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      IF line_exists( existing_products[ Product = <entity>-material
                                         Plant   = <entity>-plant ] ). "#EC CI_STDSEQ
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky        = <entity>-%tky
                      %state_area = state_area_plant_matnr )
             TO reported-supplierdlvdays.

      APPEND VALUE #( %tky = <entity>-%tky ) TO failed-supplierdlvdays.
      APPEND VALUE #( %tky                     = <entity>-%tky
                      %msg                     = new_message( id       = lhc_zdos_i_supdlvdays=>custom_message_class
                                                              number   = '009'
                                                              severity = if_abap_behv_message=>severity-error
                                                              v1       = <entity>-material
                                                              v2       = <entity>-plant )
                      %element-material        = if_abap_behv=>mk-on
                      %element-plant           = if_abap_behv=>mk-on
                      %state_area              = state_area_plant_matnr
                      %path-supplierdlvdaysall = CORRESPONDING #( <entity> ) )
             TO reported-supplierdlvdays.
      CONTINUE.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateSupplier.
    CONSTANTS state_area_supplier TYPE string VALUE 'VALIDATE_SUPPLIER' ##NO_TEXT.

    READ ENTITIES OF ZDOS_I_SupDlvDays_S IN LOCAL MODE
         ENTITY SupplierDlvDays
         FIELDS ( singletonid
                  SupplDlvDaysUUID
                  Supplier )
         WITH CORRESPONDING #( keys )
         RESULT DATA(entities).

    IF entities IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM I_Supplier
      FIELDS DISTINCT Supplier
      FOR ALL ENTRIES IN @entities
      WHERE Supplier = @entities-Supplier
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(existing_suppliers).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      APPEND VALUE #( %tky        = <entity>-%tky
                      %state_area = state_area_supplier )
             TO reported-supplierdlvdays.

      IF <entity>-Supplier IS INITIAL.
        APPEND VALUE #( %tky = <entity>-%tky ) TO failed-supplierdlvdays.
        APPEND VALUE #( %tky                     = <entity>-%tky
                        %msg                     = new_message( id       = lhc_zdos_i_supdlvdays=>custom_message_class
                                                                number   = '014'
                                                                severity = if_abap_behv_message=>severity-error )
                        %element-Supplier        = if_abap_behv=>mk-on
                        %state_area              = state_area_supplier
                        %path-supplierdlvdaysall = CORRESPONDING #( <entity> ) )
               TO reported-supplierdlvdays.
        CONTINUE.
      ENDIF.

      IF NOT line_exists( existing_suppliers[ Supplier = <entity>-Supplier ] ). "#EC CI_STDSEQ
        APPEND VALUE #( %tky = <entity>-%tky ) TO failed-supplierdlvdays.
        APPEND VALUE #( %tky                     = <entity>-%tky
                        %msg                     = new_message( id       = lhc_zdos_i_supdlvdays=>custom_message_class
                                                                number   = '015'
                                                                severity = if_abap_behv_message=>severity-error
                                                                v1       = <entity>-Supplier )
                        %element-Supplier        = if_abap_behv=>mk-on
                        %state_area              = state_area_supplier
                        %path-supplierdlvdaysall = CORRESPONDING #( <entity> ) )
               TO reported-supplierdlvdays.
        CONTINUE.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateDeliveryDays.
    CONSTANTS state_area_dlv_days TYPE symsgid VALUE 'VALIDATE_DLV_DAYS' ##NO_TEXT.

    READ ENTITIES OF ZDOS_I_SupDlvDays_S IN LOCAL MODE
         ENTITY SupplierDlvDays
         FIELDS ( singletonid
                  SupplDlvDaysUUID
                  Monday
                  Tuesday
                  Wednesday
                  Thursday
                  Friday
                  Saturday
                  Sunday )
         WITH CORRESPONDING #( keys )
         RESULT DATA(entities).

    IF entities IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      CASE abap_true.
        WHEN <entity>-Monday
          OR <entity>-Tuesday
          OR <entity>-Wednesday
          OR <entity>-Thursday
          OR <entity>-Friday
          OR <entity>-Saturday
          OR <entity>-Sunday.
          CONTINUE.
      ENDCASE.

      APPEND VALUE #( %tky        = <entity>-%tky
                      %state_area = state_area_dlv_days )
             TO reported-supplierdlvdays.

      APPEND VALUE #( %tky = <entity>-%tky ) TO failed-supplierdlvdays.

      APPEND VALUE #( %tky        = <entity>-%tky
                      %state_area = state_area_dlv_days
                      %msg        = new_message( id       = lhc_zdos_i_supdlvdays=>custom_message_class
                                                 number   = '017'
                                                 severity = if_abap_behv_message=>severity-error ) )
             TO reported-supplierdlvdays.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateSchedulingType.
    CONSTANTS state_area_sched_type TYPE symsgid VALUE 'VALIDATE_SCHED_TYPE' ##NO_TEXT.

    READ ENTITIES OF ZDOS_I_SupDlvDays_S IN LOCAL MODE
         ENTITY SupplierDlvDays
         FIELDS ( singletonid
                  SupplDlvDaysUUID
                  SchedulingType )
         WITH CORRESPONDING #( keys )
         RESULT DATA(entities).

    IF entities IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM ZDOS_I_SchedulingTypeVH
      FIELDS SchedulingType
      FOR ALL ENTRIES IN @entities
      WHERE SchedulingType = @entities-SchedulingType
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(allowed_scheduling_types).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      APPEND VALUE #( %tky        = <entity>-%tky
                      %state_area = state_area_sched_type )
             TO reported-supplierdlvdays.

      IF <entity>-Supplier IS INITIAL.
        APPEND VALUE #( %tky = <entity>-%tky ) TO failed-supplierdlvdays.
        APPEND VALUE #( %tky                     = <entity>-%tky
                        %msg                     = new_message( id       = lhc_zdos_i_supdlvdays=>custom_message_class
                                                                number   = '018'
                                                                severity = if_abap_behv_message=>severity-error )
                        %element-SchedulingType  = if_abap_behv=>mk-on
                        %state_area              = state_area_sched_type
                        %path-supplierdlvdaysall = CORRESPONDING #( <entity> ) )
               TO reported-supplierdlvdays.
        CONTINUE.
      ENDIF.

      IF NOT line_exists( allowed_scheduling_types[ SchedulingType = <entity>-SchedulingType ] ). "#EC CI_STDSEQ
        APPEND VALUE #( %tky = <entity>-%tky ) TO failed-supplierdlvdays.
        APPEND VALUE #( %tky                     = <entity>-%tky
                        %msg                     = new_message( id       = lhc_zdos_i_supdlvdays=>custom_message_class
                                                                number   = '019'
                                                                severity = if_abap_behv_message=>severity-error
                                                                v1       = <entity>-SchedulingType )
                        %element-SchedulingType  = if_abap_behv=>mk-on
                        %state_area              = state_area_sched_type
                        %path-supplierdlvdaysall = CORRESPONDING #( <entity> ) )
               TO reported-supplierdlvdays.
        CONTINUE.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
