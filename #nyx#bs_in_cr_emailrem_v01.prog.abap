*&---------------------------------------------------------------------*
*& Report /NYX/BS_IN_CR_EMAILREM_V01
*&---------------------------------------------------------------------*
***********************************************************************
* Created By:            neylux Gmbh
* Created On:            09/2023
* Trans Code:            NA
* Program Descr:         The report performs two functions
*                         1. Check the change request with idle time longer than a particular period of time
*                         2. Send email reminder to processor to take action
*______________________________________________________________________
*                         Modification Log
*_______________________________________________________________________
* Programmer : Dinh Cuong Luc;  Issue:   Date: 26/09/2023   ; Chg Req. :70 Description: Send Automatic Email Reminder
*_______________________________________________________________________
*
**********************************************************************
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT /nyx/bs_in_cr_emailrem_v01.

DATA: gt_cr TYPE TABLE OF /nyx/bsincr01v01.

*SELECTION SCREEN
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
PARAMETERS p_days TYPE n LENGTH 3 DEFAULT 7 OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
PARAMETERS p_test AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b2.

*START OF SELECTION
START-OF-SELECTION.

  PERFORM fetch_data.
  IF p_test IS INITIAL.
    PERFORM send_reminder.
  ELSE.
    PERFORM print_output.
  ENDIF.

*&---------------------------------------------------------------------*
*&      Form  FETCH_DATA
*&---------------------------------------------------------------------*
*       Fetch data from databse tables to internal tables
*----------------------------------------------------------------------*
FORM fetch_data .
  DATA: lt_cr TYPE TABLE OF /nyx/bsincr01v01.
  DATA: ls_cr TYPE /nyx/bsincr01v01 VALUE IS INITIAL.
  DATA: lv_current_timestamp TYPE timestamp.
  DATA: lv_consider_timestamp TYPE timestamp.

  GET TIME STAMP FIELD lv_current_timestamp.
  CALL FUNCTION 'TIMESTAMP_DURATION_SUB'
    EXPORTING
      timestamp_in    = lv_current_timestamp
      timezone        = 'UTC'
      duration        = p_days
      unit            = 'TAG'
    IMPORTING
      timestamp_out   = lv_consider_timestamp
    EXCEPTIONS
      timestamp_error = 1
      OTHERS          = 2.

  IF sy-subrc <> 0.
    MESSAGE ID '/NYX/BSINCRMCV0' TYPE 'E' NUMBER 048.
  ENDIF.

  SELECT * FROM /nyx/bsincr01v01 INTO TABLE lt_cr
    WHERE status <> /nyx/cl_bs_in_cr_util_v01=>gc_status_closed AND status <> /nyx/cl_bs_in_cr_util_v01=>gc_status_draft AND status <> /nyx/cl_bs_in_cr_util_v01=>gc_status_onhold.

  IF sy-subrc <> 0.
    WRITE: TEXT-004.
    RETURN.
  ENDIF.

  CLEAR: ls_cr.
  LOOP AT lt_cr INTO ls_cr.
    IF ls_cr-email_reminder_log IS INITIAL.                                                                                     " Never sent reminder
      IF ls_cr-last_processed_timestamp < lv_consider_timestamp.
        APPEND ls_cr TO gt_cr.
      ENDIF.
    ELSE.
      IF ls_cr-email_reminder_log < lv_consider_timestamp.
        APPEND ls_cr TO gt_cr.
      ENDIF.
    ENDIF.
  ENDLOOP.

  IF gt_cr IS INITIAL.
    WRITE: TEXT-004.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SEND_REMINDER
*&---------------------------------------------------------------------*
*       Send reminder to processors
*----------------------------------------------------------------------*
FORM send_reminder .
  DATA: ls_cr TYPE /nyx/bsincr01v01.
  DATA: lv_success TYPE wdy_boolean.
  DATA: lv_timestamp TYPE timestamp.

  CLEAR: ls_cr.
  GET TIME STAMP FIELD lv_timestamp.
  LOOP AT gt_cr INTO ls_cr.
    lv_success = /nyx/cl_bs_in_cr_util_v01=>send_reminder( is_cr = ls_cr ).
    IF lv_success = abap_true.
      ls_cr-email_reminder_log = lv_timestamp.
* Update data in database
      UPDATE /nyx/bsincr01v01 FROM ls_cr.
      IF sy-subrc NE 0.
        MESSAGE ID '/NYX/BSINCRMCV0' TYPE 'I' NUMBER 027.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  PRINT_OUTPUT
*&---------------------------------------------------------------------*
*       Print list of CRs that possibly
*----------------------------------------------------------------------*
FORM print_output .
  IF gt_cr IS NOT INITIAL.
    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_structure_name = '/nyx/bsincr01v01'
        i_grid_title     = TEXT-003
      TABLES
        t_outtab         = gt_cr
      EXCEPTIONS
        program_error    = 1
        OTHERS           = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.
  ENDIF.

ENDFORM.
