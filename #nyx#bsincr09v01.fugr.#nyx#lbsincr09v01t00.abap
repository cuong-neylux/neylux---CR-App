*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: /NYX/BSINCR09V01................................*
DATA:  BEGIN OF STATUS_/NYX/BSINCR09V01              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_/NYX/BSINCR09V01              .
CONTROLS: TCTRL_/NYX/BSINCR09V01
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: */NYX/BSINCR09V01              .
TABLES: /NYX/BSINCR09V01               .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
