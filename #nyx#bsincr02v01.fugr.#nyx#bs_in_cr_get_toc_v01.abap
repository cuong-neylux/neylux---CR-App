FUNCTION /nyx/bs_in_cr_get_toc_v01.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     VALUE(ET_REQUESTS) TYPE  /NYX/BS_IN_CR_TT_01_V01
*"----------------------------------------------------------------------

  DATA: lt_e070v TYPE TABLE OF e070v.
  DATA: lt_requests TYPE /nyx/bs_in_cr_tt_01_v01.

  SELECT * FROM e070v INTO TABLE lt_e070v                 "#EC CI_SUBRC
    WHERE trfunction = 'T' AND
          trstatus = 'R' AND
          as4user <> 'SAP' AND
          strkorr = '' AND
          as4text LIKE '%/NYX/%'.

  MOVE-CORRESPONDING lt_e070v TO lt_requests.

  et_requests = lt_requests.

ENDFUNCTION.
