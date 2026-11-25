FUNCTION /nyx/bs_in_cr_sendemail_v01.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IT_KEY_VALUES) TYPE  /NYX/SC_MA_KEY_VAL_TT
*"     REFERENCE(IT_BODY_FINAL) TYPE  SOLI_TAB
*"     REFERENCE(IS_SUBJECT) TYPE  /NYX/SC_MA_02
*"  EXPORTING
*"     REFERENCE(EV_SUCCESS) TYPE  BOOLE_D
*"----------------------------------------------------------------------

*   Local data
  DATA lv_language TYPE spras.
  DATA lv_email_emp1 TYPE comm_id_long.
  DATA lv_email_cc TYPE comm_id_long.
  DATA lr_send_request TYPE REF TO cl_bcs VALUE IS INITIAL.
  DATA lr_document TYPE REF TO cl_document_bcs VALUE IS INITIAL.
  DATA lr_sender TYPE REF TO if_sender_bcs.
  DATA lr_recipient TYPE REF TO if_recipient_bcs VALUE IS INITIAL.
  DATA lr_recipient_cc TYPE REF TO if_recipient_bcs VALUE IS INITIAL.
  DATA lv_is_ok TYPE os_boolean.
  DATA lv_subject_short TYPE so_obj_des.
  DATA lv_subject_string TYPE string.
  DATA ls_subject TYPE /nyx/sc_ma_02.
  DATA lt_body TYPE soli_tab.
  DATA ls_body TYPE soli.
  DATA lt_body_final TYPE soli_tab.
  DATA lr_bcs_exception TYPE REF TO cx_bcs.
  DATA lv_ncid TYPE /nyx/sc_ncid .
  DATA lv_mailtype TYPE /nyx/sc_mailtype.
  DATA lv_sender_usrid TYPE uname.
  DATA ls_kv TYPE /nyx/sc_key_val_s.

  CLEAR ev_success.


  LOOP AT it_key_values INTO ls_kv.
    CASE ls_kv-skey.
      WHEN '@NC_ID@'.
        lv_ncid = ls_kv-svalue.
      WHEN '@MAIL_TYPE@'.
        lv_mailtype = ls_kv-svalue.
      WHEN '@SENDER_USRID@'.
        lv_sender_usrid = ls_kv-svalue.
      WHEN '@EMAIL_EMP1@'.
        lv_email_emp1 = ls_kv-svalue.
      WHEN '@LANGUAGE@'.
        lv_language = ls_kv-svalue.
      WHEN '@CC@'.
        lv_email_cc = ls_kv-svalue.
      WHEN OTHERS.
    ENDCASE.
  ENDLOOP.

*   Set locale
  IF lv_language IS INITIAL.
    IF sy-langu = 'D'.
      lv_language = 'D'.
    ELSE.
      lv_language = 'E'.
    ENDIF.
  ENDIF.
  SET LOCALE LANGUAGE lv_language.
* Set variable
  lv_subject_short = is_subject-subject.
  lv_subject_string = is_subject-subject.
  lt_body_final = it_body_final.

*   Create mail object
  TRY.
*       Create persistent send request
      lr_send_request = cl_bcs=>create_persistent( ).

*       Create lo_document from internal table
      lr_document = cl_document_bcs=>create_document(
*        i_type         = 'RAW'                         "For Editor Text
        i_type         = 'HTM'                        "For HTML Text
        i_subject      = lv_subject_short
        i_language     = lv_language
        i_text         = lt_body_final ).
*        i_importance   = lv_priority ).

*       Set document
      CALL METHOD lr_send_request->set_document( lr_document ).

*       Set long subject
      CALL METHOD lr_send_request->set_message_subject
        EXPORTING
          ip_subject = lv_subject_string.

*       Set sender
      IF lv_sender_usrid  IS NOT INITIAL.
        lr_sender = cl_sapuser_bcs=>create( lv_sender_usrid  ).
      ELSE.
        lr_sender = cl_sapuser_bcs=>create( sy-uname ).
      ENDIF.
      CALL METHOD lr_send_request->set_sender
        EXPORTING
          i_sender = lr_sender.


*       Set recipients
      IF lv_email_emp1 IS NOT INITIAL.
        lr_recipient = cl_cam_address_bcs=>create_internet_address( lv_email_emp1 ).
        CALL METHOD lr_send_request->add_recipient(
          EXPORTING
            i_recipient = lr_recipient
            i_express   = 'X'
        ).
      ENDIF.

      IF lv_email_cc IS NOT INITIAL.
        lr_recipient_cc = cl_cam_address_bcs=>create_internet_address( lv_email_cc ).
        CALL METHOD lr_send_request->add_recipient(
          EXPORTING
            i_recipient = lr_recipient_cc
            i_copy      = 'X' ).
      ENDIF.
      lr_send_request->set_document( lr_document ).

*       Send document
      lr_send_request->send(
      EXPORTING
       i_with_error_screen = 'X'
       RECEIVING
         result = lv_is_ok ).

      IF lv_is_ok EQ abap_true.
        COMMIT WORK AND WAIT.
      ENDIF.

      ev_success = abap_true.
*       Exception handling
    CATCH cx_bcs INTO lr_bcs_exception.
      ev_success = abap_false.
  ENDTRY.


ENDFUNCTION.
