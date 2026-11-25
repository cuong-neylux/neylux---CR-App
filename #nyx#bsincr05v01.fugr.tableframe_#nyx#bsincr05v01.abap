*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_/NYX/BSINCR05V01
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_/NYX/BSINCR05V01   .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
