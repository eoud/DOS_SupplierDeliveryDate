CLASS zdos_cl_supplier_dlv_date DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_status_pur_req_item,
             material                  TYPE matnr,
             plant                     TYPE ewerk,
             material_group            TYPE matkl,
             delivery_date             TYPE eindt,
             fixed_supplier            TYPE flief,
             purchasing_organization   TYPE ekorg,
             planned_delivery_days     TYPE plifz,
             zz_supplier_delivery_date TYPE zdos_suppl_delivery_date,
             scheduling_type           TYPE pph_termkz,
           END OF ty_status_pur_req_item.

    METHODS determine_delivery_date
      CHANGING cs_item TYPE zdos_cl_supplier_dlv_date=>ty_status_pur_req_item.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_supdlvdays_helper_type,
             monday         TYPE zdos_i_supplierdeliverydays-monday,
             tuesday        TYPE zdos_i_supplierdeliverydays-tuesday,
             wednesday      TYPE zdos_i_supplierdeliverydays-wednesday,
             thursday       TYPE zdos_i_supplierdeliverydays-thursday,
             friday         TYPE zdos_i_supplierdeliverydays-friday,
             saturday       TYPE zdos_i_supplierdeliverydays-saturday,
             sunday         TYPE zdos_i_supplierdeliverydays-sunday,
             holidaystart   TYPE zdos_i_supplierdeliverydays-holidaystart,
             holidayend     TYPE zdos_i_supplierdeliverydays-holidayend,
             schedulingtype TYPE zdos_i_supplierdeliverydays-schedulingtype,
           END OF ty_supdlvdays_helper_type.

    TYPES ty_range_dlv_day_numbers TYPE RANGE OF zdos_suppl_day_number.

    CONSTANTS forward_scheduling  TYPE I_SchedulingType-SchedulingType VALUE '1'.
    CONSTANTS backward_scheduling TYPE I_SchedulingType-SchedulingType VALUE '2'.

    METHODS build_range_dlv_day_numbers
      IMPORTING i_dlv_days_supplier TYPE zdos_cl_supplier_dlv_date=>ty_supdlvdays_helper_type
      RETURNING VALUE(results)      TYPE ty_range_dlv_day_numbers.

    METHODS check_customer_holiday
      IMPORTING i_dlv_days_supplier TYPE ZDOS_I_SupplierDeliveryDays
                i_factory_calendar  TYPE i_plant-FactoryCalendar
      CHANGING  c_check_date        TYPE sy-datum.

    METHODS check_delivery_date_samplmeqr
      IMPORTING i_plant                 TYPE i_plant-Plant
                i_factory_calendar      TYPE i_plant-FactoryCalendar
                i_planned_delivery_days TYPE plifz
      CHANGING  c_check_date            TYPE sy-datum.

    METHODS create_warning_message.

    METHODS get_supplier_delivery_days
      IMPORTING i_status_purch_req_item TYPE zdos_cl_supplier_dlv_date=>ty_status_pur_req_item
      RETURNING VALUE(result)           TYPE zdos_cl_supplier_dlv_date=>ty_supdlvdays_helper_type.

    METHODS is_delivery_day_allowed
      CHANGING cs_item                  TYPE zdos_cl_supplier_dlv_date=>ty_status_pur_req_item
               c_delivery_check_date    TYPE sy-datum
               c_supplier_delivery_days TYPE zdos_cl_supplier_dlv_date=>ty_supdlvdays_helper_type.

ENDCLASS.



CLASS zdos_cl_supplier_dlv_date IMPLEMENTATION.
  METHOD determine_delivery_date.
    DATA delivery_check_date      TYPE sy-datum.
    DATA planned_dlv_time_in_days TYPE plifz.

    IF NOT (    cs_item-zz_supplier_delivery_date IS INITIAL
             OR cs_item-zz_supplier_delivery_date  = cs_item-delivery_date ).
      RETURN.
    ENDIF.

    SELECT SINGLE FROM i_plant
      FIELDS FactoryCalendar
      WHERE Plant = @cs_item-plant
      INTO @DATA(factory_calendar).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    SELECT FROM ZDOS_C_PurInfoRecOrgPlantData
      FIELDS PlannedDeliveryDays
      WHERE PurchasingOrganization = @cs_item-purchasing_organization
        AND Material               = @cs_item-material
        AND Supplier               = @cs_item-fixed_supplier
      ORDER BY PurchasingInfoRecord,
               PurchasingOrganization,
               PurchasingInfoRecordCategory,
               Plant
      INTO @DATA(pir_planned_dlv_days)
      UP TO 1 ROWS.
    ENDSELECT.

    IF sy-subrc = 0.
      planned_dlv_time_in_days = pir_planned_dlv_days.
    ELSE.
      " Use PDT of Material Master
      planned_dlv_time_in_days = cs_item-planned_delivery_days.
    ENDIF.

    " Keep the original delivery date into the custom field to avoid recalculation later
    cs_item-zz_supplier_delivery_date = cs_item-delivery_date.

    " Check delivery date based on the plant, factory calendar key and planned delivery time
    " Check if the suggested delivery date is the same as in the item delivery date.
    " If not, then get the suggested delivery date as the item delivery date
    delivery_check_date = cs_item-delivery_date.

    check_delivery_date_samplmeqr( EXPORTING i_plant                 = cs_item-plant
                                             i_factory_calendar      = factory_calendar
                                             i_planned_delivery_days = planned_dlv_time_in_days
                                   CHANGING  c_check_date            = delivery_check_date ).

    DATA(supplier_delivery_days) = get_supplier_delivery_days( cs_item ).

    IF supplier_delivery_days IS INITIAL.
      " Set the delivery date to PDT + GRPT + PPT (as fallback when switching to a suppl w/o deldate records)
      cs_item-delivery_date = delivery_check_date.

      RETURN.
    ENDIF.

    " Check the day of the delivery date
    IF delivery_check_date IS NOT INITIAL.

      is_delivery_day_allowed( CHANGING cs_item                  = cs_item
                                        c_delivery_check_date    = delivery_check_date
                                        c_supplier_delivery_days = supplier_delivery_days ).
    ENDIF.

    " Check if customer has holiday. If yes, consider the holiday then proceed with the
    " assignment of the next possible day for delivery. Else, proceed with the
    " suggested delivery date.
    IF     supplier_delivery_days-holidayend   IS NOT INITIAL
       AND supplier_delivery_days-holidaystart IS NOT INITIAL.
      check_customer_holiday( EXPORTING i_dlv_days_supplier = CORRESPONDING #( supplier_delivery_days )
                                        i_factory_calendar  = factory_calendar
                              CHANGING  c_check_date        = delivery_check_date ).

    ENDIF.
  ENDMETHOD.


  METHOD is_delivery_day_allowed.
    DATA day_number              TYPE zdos_suppl_day_number.
    DATA temporary_delivery_date TYPE datum.

    TRY.
        cl_scal_api=>day_attributes_get( EXPORTING iv_factory_calendar = ' '
                                                   iv_holiday_calendar = ' '
                                                   iv_date_from        = c_delivery_check_date
                                                   iv_date_to          = c_delivery_check_date
                                                   iv_language         = 'E'
                                         IMPORTING et_day_attributes   = DATA(days_attributes) ).
      CATCH cx_scal.
        RETURN.
    ENDTRY.

    " Delivery date should always be at least today + 1 day
    FINAL(earliest_allowed_delivery_date) = cl_abap_context_info=>get_system_date( ) + 1.

    day_number = VALUE #( days_attributes[ 1 ]-weekday OPTIONAL ).

    " Check if the day of the delivery date is based on the days
    " specified in custom supplier delivery days-table.
    " If yes then take the date, else take the next possible date
    " based on the day specified in the table
    DATA(range_dlv_day_numbers) = build_range_dlv_day_numbers( c_supplier_delivery_days ).

    " First delivery date is compatible with delivery day of factory calendar
    IF day_number IN range_dlv_day_numbers.
      " No change in the delivery date
      cs_item-delivery_date = c_delivery_check_date.

    " Delivery date is not compatible with delivery day of factory calendar, calculation of new date (forward/backward selection)
    ELSE.
      temporary_delivery_date = cs_item-delivery_date.

      DO 10 TIMES. " Limit the number of attempts to 10 dates

        CASE day_number.
          WHEN 1.
            " Compare potential delivery day after end of holidays
            IF c_supplier_delivery_days-monday IS NOT INITIAL.
              c_delivery_check_date = temporary_delivery_date.
              EXIT.
            ENDIF.

          WHEN 2.
            IF c_supplier_delivery_days-tuesday IS NOT INITIAL.
              c_delivery_check_date = temporary_delivery_date.
              EXIT.
            ENDIF.

          WHEN 3.
            IF c_supplier_delivery_days-wednesday IS NOT INITIAL.
              c_delivery_check_date = temporary_delivery_date.
              EXIT.
            ENDIF.
          WHEN 4.
            IF c_supplier_delivery_days-thursday IS NOT INITIAL.
              c_delivery_check_date = temporary_delivery_date.
              EXIT.
            ENDIF.
          WHEN 5.
            IF c_supplier_delivery_days-friday IS NOT INITIAL.
              c_delivery_check_date = temporary_delivery_date.
              EXIT.
            ENDIF.
          WHEN 6.
            IF c_supplier_delivery_days-saturday IS NOT INITIAL.
              c_delivery_check_date = temporary_delivery_date.
              EXIT.
            ENDIF.
          WHEN 7.
            IF c_supplier_delivery_days-sunday IS NOT INITIAL.
              c_delivery_check_date = temporary_delivery_date.
              EXIT.
            ENDIF.
        ENDCASE.

        " Backward scheduling to go backward compared to initial delivery date
        IF c_supplier_delivery_days-schedulingtype = zdos_cl_supplier_dlv_date=>backward_scheduling.
          IF cs_item-delivery_date < earliest_allowed_delivery_date.
            " Change scheduling type as you can't deliver in the past (in our case before today + 1d)
            c_supplier_delivery_days-schedulingtype = zdos_cl_supplier_dlv_date=>forward_scheduling.
            temporary_delivery_date += 1.
            day_number += 1.
          ELSE.
            temporary_delivery_date -= 1.
            day_number -= 1.
          ENDIF.
        ENDIF.

        " Forward scheduling to go forward in the future compared to initial delivery date
        IF c_supplier_delivery_days-schedulingtype = zdos_cl_supplier_dlv_date=>forward_scheduling.
          temporary_delivery_date += 1.
          day_number += 1.
        ENDIF.

      ENDDO.

    ENDIF.
  ENDMETHOD.


  METHOD build_range_dlv_day_numbers.
    IF i_dlv_days_supplier-monday IS NOT INITIAL.
      APPEND VALUE #( sign   = 'I'
                      option = 'EQ'
                      low    = '1' ) TO results.
    ENDIF.
    IF i_dlv_days_supplier-tuesday IS NOT INITIAL.
      APPEND VALUE #( sign   = 'I'
                      option = 'EQ'
                      low    = '2' ) TO results.
    ENDIF.
    IF i_dlv_days_supplier-wednesday IS NOT INITIAL.
      APPEND VALUE #( sign   = 'I'
                      option = 'EQ'
                      low    = '3' ) TO results.
    ENDIF.
    IF i_dlv_days_supplier-thursday IS NOT INITIAL.
      APPEND VALUE #( sign   = 'I'
                      option = 'EQ'
                      low    = '4' ) TO results.
    ENDIF.
    IF i_dlv_days_supplier-friday IS NOT INITIAL.
      APPEND VALUE #( sign   = 'I'
                      option = 'EQ'
                      low    = '5' ) TO results.
    ENDIF.
    IF i_dlv_days_supplier-saturday IS NOT INITIAL.
      APPEND VALUE #( sign   = 'I'
                      option = 'EQ'
                      low    = '6' ) TO results.
    ENDIF.
    IF i_dlv_days_supplier-sunday IS NOT INITIAL.
      APPEND VALUE #( sign   = 'I'
                      option = 'EQ'
                      low    = '7' ) TO results.
    ENDIF.
  ENDMETHOD.


  METHOD get_supplier_delivery_days.
    SELECT FROM ZDOS_I_SupplierDeliveryDays
      FIELDS monday,
             tuesday,
             wednesday,
             thursday,
             friday,
             saturday,
             sunday,
             HolidayStart,
             HolidayEnd,
             SchedulingType
      WHERE supplier = @i_status_purch_req_item-fixed_supplier
        AND (
              ( plant = @i_status_purch_req_item-plant AND material = @i_status_purch_req_item-material )
              OR ( plant = @i_status_purch_req_item-plant AND material      IS NOT INITIAL AND materialgroup = @i_status_purch_req_item-material_group )
              OR ( plant = @i_status_purch_req_item-plant AND materialgroup  = @i_status_purch_req_item-material_group )
              OR ( plant = '' AND material = @i_status_purch_req_item-material )
              OR ( plant = @i_status_purch_req_item-plant AND materialgroup  = '' AND material = '' )
              OR ( plant = '' AND materialgroup = @i_status_purch_req_item-material_group )
              OR ( plant = '' AND materialgroup = '' AND material = '' ) )
      ORDER BY CASE WHEN material       = @i_status_purch_req_item-material
                    AND  plant         IS INITIAL
                    AND  materialgroup IS INITIAL
                THEN material END DESCENDING,
               CASE WHEN material       = @i_status_purch_req_item-material
                    AND  plant          = @i_status_purch_req_item-plant
                    AND  materialgroup IS INITIAL
                     THEN material END DESCENDING,
               CASE WHEN material      = @i_status_purch_req_item-material
                    AND  plant         = @i_status_purch_req_item-plant
                    AND  materialgroup = @i_status_purch_req_item-material_group
                     THEN material END DESCENDING,
               CASE WHEN material      IS INITIAL
                    AND  materialgroup  = @i_status_purch_req_item-material_group
                    AND  plant          = @i_status_purch_req_item-plant
                     THEN materialgroup END DESCENDING,
               CASE WHEN material      IS INITIAL
                    AND  materialgroup  = @i_status_purch_req_item-material_group
                    AND  plant         IS INITIAL
                     THEN materialgroup END DESCENDING,
               CASE WHEN material      IS INITIAL
                    AND  materialgroup IS INITIAL
                    AND  plant          = @i_status_purch_req_item-plant
                     THEN plant END DESCENDING,
               material DESCENDING

      INTO @result
      UP TO 1 ROWS.
    ENDSELECT.
  ENDMETHOD.


  METHOD check_customer_holiday.
    DATA weekday_number           TYPE cl_scal_api=>scalv_weekday_number.
    DATA temporary_check_date     TYPE cl_scal_api=>scalv_date.
    DATA is_compatible_check_date TYPE abap_boolean.

    " Delivery date should always be at least today + 1 day
    FINAL(earliest_allowed_delivery_date) = cl_abap_context_info=>get_system_date( ) + 1.

    DATA(scheduling_type) = i_dlv_days_supplier-schedulingtype.

    " If delivery date is during holidays, recalculate depending on scheduling type + setup of start date for new calculation
    IF c_check_date < i_dlv_days_supplier-holidaystart OR c_check_date > i_dlv_days_supplier-holidayend.
      RETURN.
    ENDIF.

    temporary_check_date = SWITCH #( scheduling_type
                                     WHEN zdos_cl_supplier_dlv_date=>backward_scheduling
                                     THEN i_dlv_days_supplier-holidaystart
                                     ELSE i_dlv_days_supplier-holidayend ).

    " Check for next/previous compatible day, taking into account holidays
    WHILE is_compatible_check_date = abap_false.
      " If delivery date becomes in the past, then change scheduling type to forward and set base date to holidayEnd
      IF temporary_check_date < earliest_allowed_delivery_date.
        scheduling_type = zdos_cl_supplier_dlv_date=>forward_scheduling.
        temporary_check_date = i_dlv_days_supplier-holidayend.
      ENDIF.

      CASE scheduling_type.
        WHEN zdos_cl_supplier_dlv_date=>backward_scheduling.
          temporary_check_date -= 1.
          weekday_number -= 1.
        WHEN zdos_cl_supplier_dlv_date=>forward_scheduling.
          temporary_check_date += 1.
          weekday_number += 1.
      ENDCASE.

      cl_scal_api=>date_compute_day( EXPORTING iv_date           = temporary_check_date
                                     IMPORTING ev_weekday_number = weekday_number ).

      " Compare potential delivery day after end of holidays
      IF i_dlv_days_supplier-monday IS NOT INITIAL AND weekday_number = 1.
        c_check_date = temporary_check_date.
        is_compatible_check_date = abap_true.
        EXIT.
      ENDIF.

      IF i_dlv_days_supplier-tuesday IS NOT INITIAL AND weekday_number = 2.
        c_check_date = temporary_check_date.
        is_compatible_check_date = abap_true.
        EXIT.
      ENDIF.

      IF i_dlv_days_supplier-wednesday IS NOT INITIAL AND weekday_number = 3.
        c_check_date = temporary_check_date.
        is_compatible_check_date = abap_true.
        EXIT.
      ENDIF.

      IF i_dlv_days_supplier-thursday IS NOT INITIAL AND weekday_number = 4.
        c_check_date = temporary_check_date.
        is_compatible_check_date = abap_true.
        EXIT.
      ENDIF.

      IF i_dlv_days_supplier-friday IS NOT INITIAL AND weekday_number = 5.
        c_check_date = temporary_check_date.
        is_compatible_check_date = abap_true.
        EXIT.
      ENDIF.

      IF i_dlv_days_supplier-saturday IS NOT INITIAL AND weekday_number = 6.
        c_check_date = temporary_check_date.
        is_compatible_check_date = abap_true.
        EXIT.
      ENDIF.

      IF i_dlv_days_supplier-sunday IS NOT INITIAL AND weekday_number = 7.
        c_check_date = temporary_check_date.
        is_compatible_check_date = abap_true.
        EXIT.
      ENDIF.
    ENDWHILE.

    TRY.
        cl_scal_api=>date_convert_to_factorydate( EXPORTING iv_correct_option   = '+'
                                                            iv_date             = c_check_date
                                                            iv_factory_calendar = i_factory_calendar
                                                  IMPORTING ev_date             = c_check_date ).

      CATCH cx_scal ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.


  METHOD check_delivery_date_samplmeqr.
    PERFORM check_delivery_date IN PROGRAM saplmeqr
      USING    i_plant
               i_factory_calendar
               i_planned_delivery_days
      CHANGING c_check_date.
  ENDMETHOD.


  METHOD create_warning_message.
    cl_message_mm=>create( EXPORTING  im_msgid         = 'ZDOS_MSG_SUPDLVDATE'
                                      im_msgty         = 'W'
                                      im_msgno         = 2
                                      im_force_collect = abap_true
                           EXCEPTIONS failure          = 1
                                      dialog           = 2
                                      OTHERS           = 3 ).

    IF sy-subrc = 1 OR sy-subrc = 2.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
