CLASS zdos_cl_bi_mm_suppl_dlv_date DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_badi_interface.
    INTERFACES if_mm_pur_s4_pr_modify_item.

  PRIVATE SECTION.

ENDCLASS.



CLASS zdos_cl_bi_mm_suppl_dlv_date IMPLEMENTATION.
  METHOD if_mm_pur_s4_pr_modify_item~modify_item.
    DATA(supplier_dlv_date) = NEW zdos_cl_supplier_dlv_date( ).

    DATA pur_req_item TYPE zdos_cl_supplier_dlv_date=>ty_status_pur_req_item.

    IF purchaserequisitionitem-fixedsupplier IS NOT INITIAL.
      pur_req_item = VALUE #( material                  = purchaserequisitionitem-material
                              plant                     = purchaserequisitionitem-plant
                              material_group            = purchaserequisitionitem-materialgroup
                              delivery_date             = purchaserequisitionitem-deliverydate
                              fixed_supplier            = purchaserequisitionitem-fixedsupplier
                              purchasing_organization   = purchaserequisitionitem-purchasingorganization
                              planned_delivery_days     = purchaserequisitionitem-materialplanneddeliverydurn
                              zz_supplier_delivery_date = purchaserequisitionitem-zzdos_suppl_dlv_date_pri ).

      IF     pur_req_item-delivery_date  IS NOT INITIAL
         AND pur_req_item-plant          IS NOT INITIAL
         AND pur_req_item-fixed_supplier IS NOT INITIAL
         AND pur_req_item-material       IS NOT INITIAL.

        supplier_dlv_date->determine_delivery_date( CHANGING cs_item = pur_req_item ).

        IF purchaserequisitionitem-zzdos_suppl_dlv_date_pri <> pur_req_item-zz_supplier_delivery_date.
          purchaserequisitionitemchange-zzdos_suppl_dlv_date_pri = pur_req_item-zz_supplier_delivery_date.
        ENDIF.

        IF purchaserequisitionitem-deliverydate <> pur_req_item-delivery_date.
          purchaserequisitionitemchange-deliverydate = pur_req_item-delivery_date.
        ENDIF.
      ENDIF.

    ELSEIF purchaserequisitionitem-supplier IS NOT INITIAL.
      pur_req_item = VALUE #( material                  = purchaserequisitionitem-material
                              plant                     = purchaserequisitionitem-plant
                              material_group            = purchaserequisitionitem-materialgroup
                              delivery_date             = purchaserequisitionitem-deliverydate
                              fixed_supplier            = purchaserequisitionitem-supplier
                              purchasing_organization   = purchaserequisitionitem-purchasingorganization
                              planned_delivery_days     = purchaserequisitionitem-materialplanneddeliverydurn
                              zz_supplier_delivery_date = purchaserequisitionitem-zzdos_suppl_dlv_date_pri ).

      IF     pur_req_item-delivery_date IS NOT INITIAL
         AND pur_req_item-plant         IS NOT INITIAL
         AND pur_req_item-material      IS NOT INITIAL.

        supplier_dlv_date->determine_delivery_date( CHANGING cs_item = pur_req_item ).

        IF purchaserequisitionitem-zzdos_suppl_dlv_date_pri <> pur_req_item-zz_supplier_delivery_date.
          purchaserequisitionitemchange-zzdos_suppl_dlv_date_pri = pur_req_item-zz_supplier_delivery_date.
        ENDIF.

        IF purchaserequisitionitem-deliverydate <> pur_req_item-delivery_date.
          purchaserequisitionitemchange-deliverydate = pur_req_item-delivery_date.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
