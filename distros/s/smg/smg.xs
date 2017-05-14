#ifdef __cplusplus
extern "C" {
#endif
#include <smgdef.h>
#include <descrip.h>
#include "smg.h"
#include <smg$routines.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif


MODULE = smg		PACKAGE = smg		

PROTOTYPES: DISABLE





int
initscr(KbId,PbId)
int KbId
int PbId
CODE:
{
   int Status;
   int SmgVideoAtt;
   int SmgFlags;
 
   if (!answer_ok((Status = smg$create_pasteboard(&PbId)))){
      RETVAL=0;
   }
   if (!answer_ok((Status = smg$create_virtual_keyboard(&KbId)))){
      RETVAL=0;
   }
   RETVAL=1;
}
OUTPUT:
KbId
PbId
RETVAL


int
crewin(Y,X,WinId,Attr)
int Y
int X
int WinId
char *Attr
CODE:
{
   int AttrId=0;
   char *Pnt;
   int Status;
   if (strlen(Attr)>0){
      Pnt=Attr;
      while(*Pnt){
	 switch(toupper(*Pnt)){
	  case 'L':
	    AttrId |= SMG$M_BORDER;
	    break;
	  case 'B':
	    AttrId |= SMG$M_BLOCK_BORDER;
	    break;
	  default:
	    break;
	 }
	 Pnt++;
      }
      
      if (!answer_ok((Status = smg$create_virtual_display(&Y,&X,&WinId,&AttrId)))){
	 RETVAL=0;
      }
   }
   else {
      if (!answer_ok((Status = smg$create_virtual_display(&Y,&X,&WinId)))){
	 RETVAL=0;
      }
   }
   RETVAL=1;
}
OUTPUT:
WinId
RETVAL





int
putwin(Y,X,WinId,PbId)
int Y
int X
int WinId
int PbId
CODE:
{
   int Status;
   if (!answer_ok((Status = smg$paste_virtual_display(&WinId,&PbId,&Y,&X)))){
      RETVAL=0;
   }
   RETVAL=1;
}
OUTPUT:
WinId
RETVAL


int
puthichars(WinId,SmgX,SmgY,SMGString,Attrib)
int WinId
int SmgX
int SmgY
char* SMGString
char* Attrib
CODE:
{
   int Status;
   struct dsc$descriptor *SmgStrDsc;
   int  Flags=0, Video=0;
   char *pnt;

   SmgStrDsc=malloc(sizeof(struct dsc$descriptor));
   SmgStrDsc->dsc$w_length  = strlen(SMGString);
   SmgStrDsc->dsc$b_dtype   = DSC$K_DTYPE_T;
   SmgStrDsc->dsc$a_pointer = SMGString;
   SmgStrDsc->dsc$b_class   = DSC$K_CLASS_S;

   pnt = Attrib;
   while(*pnt){
      switch(toupper(*(pnt))){
       case 'I': 
	 Video |= SMG$M_INVISIBLE;
	 break;
       case 'B': 
	 Video |= SMG$M_BOLD;
	 break;
       case 'R': 
	 Video |= SMG$M_REVERSE;
	 break;
       case 'U': 
	 Video |= SMG$M_UNDERLINE;
	 break;
       case 'F': 
	 Video |= SMG$M_BLINK;
	 break;
       case '1': 
	 Video |= SMG$M_USER1;
	 break;
       case '2': 
	 Video |= SMG$M_USER2;
	 break;
       case '3': 
	 Video |= SMG$M_USER3;
	 break;
       case '4': 
	 Video |= SMG$M_USER4;
	 break;
       case '5': 
	 Video |= SMG$M_USER5;
	 break;
       case '6': 
	 Video |= SMG$M_USER6;
	 break;
       case '7': 
	 Video |= SMG$M_USER7;
	 break;
       case '8': 
	 Video |= SMG$M_USER8;
	 break;
       default:
	 break;
      }
      pnt++;
   }
   
   
   Status=smg$put_chars_highwide(&WinId, SmgStrDsc, &SmgY, &SmgX, &Flags, &Video);
   free(SmgStrDsc);
   RETVAL=Status;
}
OUTPUT:
RETVAL



int
putfatchars(WinId,SmgX,SmgY,SMGString,Attrib)
int WinId
int SmgX
int SmgY
char* SMGString
char* Attrib
CODE:
{
   int Status;
   struct dsc$descriptor *SmgStrDsc;
   int  Flags=0, Video=0;
   char *pnt;

   SmgStrDsc=malloc(sizeof(struct dsc$descriptor));
   SmgStrDsc->dsc$w_length  = strlen(SMGString);
   SmgStrDsc->dsc$b_dtype   = DSC$K_DTYPE_T;
   SmgStrDsc->dsc$a_pointer = SMGString;
   SmgStrDsc->dsc$b_class   = DSC$K_CLASS_S;

   pnt = Attrib;
   while(*pnt){
      switch(toupper(*(pnt))){
       case 'I': 
	 Video |= SMG$M_INVISIBLE;
	 break;
       case 'B': 
	 Video |= SMG$M_BOLD;
	 break;
       case 'R': 
	 Video |= SMG$M_REVERSE;
	 break;
       case 'U': 
	 Video |= SMG$M_UNDERLINE;
	 break;
       case 'F': 
	 Video |= SMG$M_BLINK;
	 break;
       case '1': 
	 Video |= SMG$M_USER1;
	 break;
       case '2': 
	 Video |= SMG$M_USER2;
	 break;
       case '3': 
	 Video |= SMG$M_USER3;
	 break;
       case '4': 
	 Video |= SMG$M_USER4;
	 break;
       case '5': 
	 Video |= SMG$M_USER5;
	 break;
       case '6': 
	 Video |= SMG$M_USER6;
	 break;
       case '7': 
	 Video |= SMG$M_USER7;
	 break;
       case '8': 
	 Video |= SMG$M_USER8;
	 break;
       default:
	 break;
      }
      pnt++;
   }
   
   
   Status=smg$put_chars_wide(&WinId, SmgStrDsc, &SmgY, &SmgX, &Flags, &Video);
   free(SmgStrDsc);
   RETVAL=Status;
}
OUTPUT:
RETVAL




int
putchars(WinId,SmgX,SmgY,SMGString,Attrib)
int WinId
int SmgX
int SmgY
char* SMGString
char* Attrib
CODE:
{
   int Status;
   int  Flags=0, Video=0;
   char *pnt;
   struct dsc$descriptor *SmgStrDsc;

   SmgStrDsc=malloc(sizeof(struct dsc$descriptor));
   SmgStrDsc->dsc$w_length  = strlen(SMGString);
   SmgStrDsc->dsc$b_dtype   = DSC$K_DTYPE_T;
   SmgStrDsc->dsc$a_pointer = SMGString;
   SmgStrDsc->dsc$b_class   = DSC$K_CLASS_S;

   pnt = Attrib;
   while(*pnt){
      switch(toupper(*(pnt))){
       case 'I': 
	 Video |= SMG$M_INVISIBLE;
	 break;
       case 'B': 
	 Video |= SMG$M_BOLD;
	 break;
       case 'R': 
	 Video |= SMG$M_REVERSE;
	 break;
       case 'U': 
	 Video |= SMG$M_UNDERLINE;
	 break;
       case 'F': 
	 Video |= SMG$M_BLINK;
	 break;
       case '1': 
	 Video |= SMG$M_USER1;
	 break;
       case '2': 
	 Video |= SMG$M_USER2;
	 break;
       case '3': 
	 Video |= SMG$M_USER3;
	 break;
       case '4': 
	 Video |= SMG$M_USER4;
	 break;
       case '5': 
	 Video |= SMG$M_USER5;
	 break;
       case '6': 
	 Video |= SMG$M_USER6;
	 break;
       case '7': 
	 Video |= SMG$M_USER7;
	 break;
       case '8': 
	 Video |= SMG$M_USER8;
	 break;
       default:
	 break;
      }
      pnt++;
   }
   
   
   Status=smg$put_chars(&WinId, SmgStrDsc, &SmgY, &SmgX, &Flags, &Video);
   free(SmgStrDsc);
   RETVAL=Status;
}
OUTPUT:
RETVAL




int 
changewinattr(win ,Y ,X ,nbrows ,nbcols ,attr)
int win
int Y
int X
int nbrows
int nbcols
char *attr
CODE:
{
   int  Video=0;
   char *pnt;

   pnt = attr;
   while(*pnt){
      switch(toupper(*(pnt))){
       case 'I': 
	 Video |= SMG$M_INVISIBLE;
	 break;
       case 'B': 
	 Video |= SMG$M_BOLD;
	 break;
       case 'R': 
	 Video |= SMG$M_REVERSE;
	 break;
       case 'U': 
	 Video |= SMG$M_UNDERLINE;
	 break;
       case 'F': 
	 Video |= SMG$M_BLINK;
	 break;
       case '1': 
	 Video |= SMG$M_USER1;
	 break;
       case '2': 
	 Video |= SMG$M_USER2;
	 break;
       case '3': 
	 Video |= SMG$M_USER3;
	 break;
       case '4': 
	 Video |= SMG$M_USER4;
	 break;
       case '5': 
	 Video |= SMG$M_USER5;
	 break;
       case '6': 
	 Video |= SMG$M_USER6;
	 break;
       case '7': 
	 Video |= SMG$M_USER7;
	 break;
       case '8': 
	 Video |= SMG$M_USER8;
	 break;
       default:
	 break;
      }
      pnt++;
   }
   RETVAL=SMG$CHANGE_RENDITION  (&win ,&Y ,&X ,&nbrows ,&nbcols ,&Video );
}
OUTPUT:
RETVAL

int
changewinsize(win ,nbrows ,nbcols)
int win
int nbrows
int nbcols
CODE:
{
   
   RETVAL=SMG$CHANGE_VIRTUAL_DISPLAY  (&win ,&nbrows ,&nbcols);
}
OUTPUT:
RETVAL

int
cremenu(win ,choices ,option_size ,flags ,row ,attr)
int win
char *choices
int option_size
char *flags
int row
char *attr
CODE:
{
   int  Video=0;
   int Flags=0;
   int menu_type=0;
   char *pnt;
   perl_menu_desc *DChoices;
   DChoices= malloc(sizeof(perl_menu_desc));
   DChoices->dsc$w_length=option_size;	/* length of an array element in bytes */
   DChoices->dsc$b_dtype=DSC$K_DTYPE_T;	/* data type code */
   DChoices->dsc$b_class=DSC$K_CLASS_A;	/* descriptor class code = DSC$K_CLASS_A */
   DChoices->dsc$a_pointer=choices;	/* address of first actual byte of data storage */
   DChoices->dsc$b_scale=0;
   DChoices->dsc$b_digits=0;
   DChoices->dsc$b_flags=0;
   DChoices->dsc$b_dimct=1;
   DChoices->dsc$l_arsize=strlen(choices);	/* total size of array in bytes */
   pnt = attr;
   while(*pnt){
      switch(toupper(*(pnt))){
       case 'I': 
	 Video |= SMG$M_INVISIBLE;
	 break;
       case 'B': 
	 Video |= SMG$M_BOLD;
	 break;
       case 'R': 
	 Video |= SMG$M_REVERSE;
	 break;
       case 'U': 
	 Video |= SMG$M_UNDERLINE;
	 break;
       case 'F': 
	 Video |= SMG$M_BLINK;
	 break;
       case '1': 
	 Video |= SMG$M_USER1;
	 break;
       case '2': 
	 Video |= SMG$M_USER2;
	 break;
       case '3': 
	 Video |= SMG$M_USER3;
	 break;
       case '4': 
	 Video |= SMG$M_USER4;
	 break;
       case '5': 
	 Video |= SMG$M_USER5;
	 break;
       case '6': 
	 Video |= SMG$M_USER6;
	 break;
       case '7': 
	 Video |= SMG$M_USER7;
	 break;
       case '8': 
	 Video |= SMG$M_USER8;
	 break;
       default:
	 break;
      }
      pnt++;
   }
   pnt = flags;
   while(*pnt){
      switch(toupper(*(pnt))){
       case 'D': 
	 Flags |= SMG$M_DOUBLE_SPACE;
	 break;
       case 'F': 
	 Flags |= SMG$M_FIXED_FORMAT;
	 break;
       case 'W': 
	 Flags |= SMG$M_WIDE_MENU;
	 break;
       case 'B': 
	 menu_type |= SMG$K_BLOCK;
	 break;
       case 'V': 
	 menu_type |= SMG$K_VERTICAL;
	 break;
       case 'H': 
	 menu_type |= SMG$K_HORIZONTAL;
	 break;
       default:
	 break;
      }
      pnt++;
   }
   RETVAL=SMG$CREATE_MENU(&win ,DChoices ,&menu_type ,&Flags ,&row ,&Video);
   free(DChoices);
}
OUTPUT:
RETVAL

int
cresubwin(win ,Y ,X ,nbrows ,nbcols)
int win
int Y
int X
int nbrows
int nbcols
CODE:
{
   RETVAL=SMG$CREATE_VIEWPORT(&win ,&Y ,&X ,&nbrows ,&nbcols);
}
OUTPUT:
RETVAL

int
curcol(win)
int win
CODE:
{
   RETVAL=SMG$CURSOR_COLUMN(&win);
}
OUTPUT:
RETVAL
       

int
curline(win)
int win
CODE:
{
   RETVAL=SMG$CURSOR_ROW(&win);
}
OUTPUT:
RETVAL
       

int
delchars(win ,nbchars, Y, X)
int win
int nbchars
int Y
int X
CODE:
{
   RETVAL=SMG$DELETE_CHARS(&win ,&nbchars ,&Y, &X);
}
OUTPUT:
RETVAL



int
delline(win ,Y ,nbrows)
int win
int Y
int nbrows
CODE:
{
   RETVAL=SMG$DELETE_LINE(&win ,&Y ,&nbrows);
}
OUTPUT:
RETVAL


int
delmenu(win)
int win
CODE:
{
   RETVAL=SMG$DELETE_MENU(&win);
}
OUTPUT:
RETVAL

int
delwin(win)
int win
CODE:
{
   RETVAL=SMG$DELETE_VIRTUAL_DISPLAY(&win);
}
OUTPUT:
RETVAL

int
drawline(win ,Y0 ,X0 ,Y1 ,X1 ,attr)
int win
int Y0
int X0
int Y1
int X1
char *attr
CODE:
{
   int Video=0;
   char *pnt;
   pnt = attr;
   while(*pnt){
      switch(toupper(*(pnt))){
       case 'I': 
	 Video |= SMG$M_INVISIBLE;
	 break;
       case 'B': 
	 Video |= SMG$M_BOLD;
	 break;
       case 'R': 
	 Video |= SMG$M_REVERSE;
	 break;
       case 'U': 
	 Video |= SMG$M_UNDERLINE;
	 break;
       case 'F': 
	 Video |= SMG$M_BLINK;
	 break;
       case '1': 
	 Video |= SMG$M_USER1;
	 break;
       case '2': 
	 Video |= SMG$M_USER2;
	 break;
       case '3': 
	 Video |= SMG$M_USER3;
	 break;
       case '4': 
	 Video |= SMG$M_USER4;
	 break;
       case '5': 
	 Video |= SMG$M_USER5;
	 break;
       case '6': 
	 Video |= SMG$M_USER6;
	 break;
       case '7': 
	 Video |= SMG$M_USER7;
	 break;
       case '8': 
	 Video |= SMG$M_USER8;
	 break;
       default:
	 break;
      }
      pnt++;
   }
   RETVAL=SMG$DRAW_LINE(&win ,&Y0 ,&X0 ,&Y1 ,&X1 ,&Video);
}
OUTPUT:
RETVAL

                          
       
int
drawbox(win ,Y0 ,X0 ,Y1 ,X1 ,attr)
int win
int Y0
int X0
int Y1
int X1
char *attr
CODE:
{
   int Video=0;
   char *pnt;
   pnt = attr;
   while(*pnt){
      switch(toupper(*(pnt))){
       case 'I': 
	 Video |= SMG$M_INVISIBLE;
	 break;
       case 'B': 
	 Video |= SMG$M_BOLD;
	 break;
       case 'R': 
	 Video |= SMG$M_REVERSE;
	 break;
       case 'U': 
	 Video |= SMG$M_UNDERLINE;
	 break;
       case 'F': 
	 Video |= SMG$M_BLINK;
	 break;
       case '1': 
	 Video |= SMG$M_USER1;
	 break;
       case '2': 
	 Video |= SMG$M_USER2;
	 break;
       case '3': 
	 Video |= SMG$M_USER3;
	 break;
       case '4': 
	 Video |= SMG$M_USER4;
	 break;
       case '5': 
	 Video |= SMG$M_USER5;
	 break;
       case '6': 
	 Video |= SMG$M_USER6;
	 break;
       case '7': 
	 Video |= SMG$M_USER7;
	 break;
       case '8': 
	 Video |= SMG$M_USER8;
	 break;
       default:
	 break;
      }
      pnt++;
   }
   RETVAL=SMG$DRAW_RECTANGLE(&win ,&Y0 ,&X0 ,&Y1 ,&X1 ,&Video);
}
OUTPUT:
RETVAL

int
erasechars(win ,nbchars ,Y, X)
int win
int nbchars
int Y
int X
CODE:
{
   RETVAL=SMG$ERASE_CHARS(&win ,&nbchars ,&Y, &X);
}
OUTPUT:
RETVAL
       

int
erasecol(win ,Y0 ,X ,Y1 )
int win
int Y0
int X
int Y1
CODE:
{
   RETVAL=SMG$ERASE_COLUMN(&win ,&Y0 ,&X ,&Y1 );
}
OUTPUT:
RETVAL
	   
int
erasewin(win ,Y0 ,X0 ,Y1 ,X1)
int win
int Y0
int X0
int Y1
int X1
CODE:
{
   RETVAL=SMG$ERASE_DISPLAY(&win ,&Y0 ,&X0 ,&Y1 ,&X1);
}
OUTPUT:
RETVAL
       


int
eraseline(win ,Y ,X)
int win
int Y
int X
CODE:
{
   RETVAL=SMG$ERASE_LINE(&win ,&Y ,&X);
}
OUTPUT:
RETVAL
       
int
clearscreen(PbId)
int PbId
CODE:
{
   RETVAL=SMG$ERASE_PASTEBOARD(&PbId);
}
OUTPUT:
RETVAL
       


int
insertchars(win , string ,Y ,X ,attr)
int win
int string
int Y
int X
char *attr
CODE:
{
   int Video;
   char *pnt;
   pnt = attr;
   while(*pnt){
      switch(toupper(*(pnt))){
       case 'I': 
	 Video |= SMG$M_INVISIBLE;
	 break;
       case 'B': 
	 Video |= SMG$M_BOLD;
	 break;
       case 'R': 
	 Video |= SMG$M_REVERSE;
	 break;
       case 'U': 
	 Video |= SMG$M_UNDERLINE;
	 break;
       case 'F': 
	 Video |= SMG$M_BLINK;
	 break;
       case '1': 
	 Video |= SMG$M_USER1;
	 break;
       case '2': 
	 Video |= SMG$M_USER2;
	 break;
       case '3': 
	 Video |= SMG$M_USER3;
	 break;
       case '4': 
	 Video |= SMG$M_USER4;
	 break;
       case '5': 
	 Video |= SMG$M_USER5;
	 break;
       case '6': 
	 Video |= SMG$M_USER6;
	 break;
       case '7': 
	 Video |= SMG$M_USER7;
	 break;
       case '8': 
	 Video |= SMG$M_USER8;
	 break;
       default:
	 break;
      }
      pnt++;
   }
   RETVAL=SMG$INSERT_CHARS(&win,&string ,&Y ,&X ,&Video);
}
OUTPUT:
RETVAL
       

int
insertline(win ,Y , string ,direction ,attr)
int win
int Y
char *string
char *direction
char *attr
CODE:
{
   int Video=0, Direction=0;
   char *pnt;

   struct dsc$descriptor *SmgStrDsc;
   SmgStrDsc=malloc(sizeof(struct dsc$descriptor));
   SmgStrDsc->dsc$w_length  = strlen(string);
   SmgStrDsc->dsc$b_dtype   = DSC$K_DTYPE_T;
   SmgStrDsc->dsc$a_pointer = string;
   SmgStrDsc->dsc$b_class   = DSC$K_CLASS_S;

   switch(toupper(*(direction))){
    case 'U': 
      Direction |= SMG$M_UP;
      break;
    case 'D': 
      Direction |= SMG$M_DOWN;
      break;
    default:
      break;
   }
   
   pnt = attr;
   while(*pnt){
      switch(toupper(*(pnt))){
       case 'I': 
	 Video |= SMG$M_INVISIBLE;
	 break;
       case 'B': 
	 Video |= SMG$M_BOLD;
	 break;
       case 'R': 
	 Video |= SMG$M_REVERSE;
	 break;
       case 'U': 
	 Video |= SMG$M_UNDERLINE;
	 break;
       case 'F': 
	 Video |= SMG$M_BLINK;
	 break;
       case '1': 
	 Video |= SMG$M_USER1;
	 break;
       case '2': 
	 Video |= SMG$M_USER2;
	 break;
       case '3': 
	 Video |= SMG$M_USER3;
	 break;
       case '4': 
	 Video |= SMG$M_USER4;
	 break;
       case '5': 
	 Video |= SMG$M_USER5;
	 break;
       case '6': 
	 Video |= SMG$M_USER6;
	 break;
       case '7': 
	 Video |= SMG$M_USER7;
	 break;
       case '8': 
	 Video |= SMG$M_USER8;
	 break;
       default:
	 break;
      }
      pnt++;
   }
   RETVAL=SMG$INSERT_LINE(&win ,&Y , SmgStrDsc ,&Direction ,&Video);
   free(SmgStrDsc);
}
OUTPUT:
RETVAL

int
codetoname(code ,name)
int code
char *name
CODE:
{
   short int scode;
   struct dsc$descriptor *SmgStrDsc;
   name=malloc(sizeof(char)*30);
   scode=(short int)code;
   name[29]=0;
   SmgStrDsc=malloc(sizeof(struct dsc$descriptor));
   SmgStrDsc->dsc$w_length  = 30;
   SmgStrDsc->dsc$b_dtype   = DSC$K_DTYPE_T;
   SmgStrDsc->dsc$a_pointer = name;
   SmgStrDsc->dsc$b_class   = DSC$K_CLASS_S;

   RETVAL=SMG$KEYCODE_TO_NAME(&scode ,SmgStrDsc);
   name[(SmgStrDsc->dsc$w_length)-1]=0;
   free(SmgStrDsc);
}
OUTPUT:
name
RETVAL

       
int
labelwin(win ,text ,position ,offset ,attr )
int win
char *text
char *position
int offset
char *attr
CODE:
{  int Video=0, Position=0;
   char *pnt;
   struct dsc$descriptor *SmgStrDsc;
   SmgStrDsc=malloc(sizeof(struct dsc$descriptor));
   SmgStrDsc->dsc$w_length  = strlen(text);
   SmgStrDsc->dsc$b_dtype   = DSC$K_DTYPE_T;
   SmgStrDsc->dsc$a_pointer = text;
   SmgStrDsc->dsc$b_class   = DSC$K_CLASS_S;
   
   switch(toupper(*(position))){
    case 'T': 
      Position |= SMG$K_TOP;
      break;
    case 'B': 
      Position |= SMG$K_BOTTOM;
      break;
    case 'L': 
      Position |= SMG$K_LEFT;
      break;
    case 'R': 
      Position |= SMG$K_RIGHT;
      break;
    default:
      break;
   }
   
   pnt = attr;
   while(*pnt){
      switch(toupper(*(pnt))){
       case 'I': 
	 Video |= SMG$M_INVISIBLE;
	 break;
       case 'B': 
	 Video |= SMG$M_BOLD;
	 break;
       case 'R': 
	 Video |= SMG$M_REVERSE;
	 break;
       case 'U': 
	 Video |= SMG$M_UNDERLINE;
	 break;
       case 'F': 
	 Video |= SMG$M_BLINK;
	 break;
       case '1': 
	 Video |= SMG$M_USER1;
	 break;
       case '2': 
	 Video |= SMG$M_USER2;
	 break;
       case '3': 
	 Video |= SMG$M_USER3;
	 break;
       case '4': 
	 Video |= SMG$M_USER4;
	 break;
       case '5': 
	 Video |= SMG$M_USER5;
	 break;
       case '6': 
	 Video |= SMG$M_USER6;
	 break;
       case '7': 
	 Video |= SMG$M_USER7;
	 break;
       case '8': 
	 Video |= SMG$M_USER8;
	 break;
       default:
	 break;
      }
      pnt++;
   }
   RETVAL=SMG$LABEL_BORDER  (&win ,SmgStrDsc ,&Position ,&offset ,&Video );
   free(SmgStrDsc);
}
OUTPUT:
RETVAL

       
int
loadwin(win ,filespec)
int win
char *filespec
CODE:
{
   struct dsc$descriptor *SmgStrDsc;
   SmgStrDsc=malloc(sizeof(struct dsc$descriptor));
   SmgStrDsc->dsc$w_length  = strlen(filespec);
   SmgStrDsc->dsc$b_dtype   = DSC$K_DTYPE_T;
   SmgStrDsc->dsc$a_pointer = filespec;
   SmgStrDsc->dsc$b_class   = DSC$K_CLASS_S;
   
   RETVAL=SMG$LOAD_VIRTUAL_DISPLAY(&win ,SmgStrDsc);
   free(SmgStrDsc);
}
OUTPUT:
win
RETVAL
       
int
movearea(win ,Y0 ,X0 ,Y1 ,X1, towin, toY, toX, flags)
int win
int Y0
int X0
int Y1
int X1
int towin
int toY
int toX
char *flags
CODE:
{
   int Flags;
   char *pnt;
   
   pnt = flags;
   while(*pnt){
      switch(toupper(*(pnt))){
       case 'C': 
	 Flags |= SMG$M_TEXT_SAVE;
	 break;
       case 'T': 
	 Flags |= SMG$M_TEXT_ONLY;
	 break;
       default:
	 break;
      }
      pnt++;
   }
   RETVAL=SMG$MOVE_TEXT(&win ,&Y0 ,&X0 ,&Y1 ,&X1, &towin, &toY, &toX, &Flags);
}
OUTPUT:
RETVAL

       

int
movewin(win ,PbId, Y, X)
int win
int PbId
int Y
int X
CODE:
{
   RETVAL=SMG$MOVE_VIRTUAL_DISPLAY(&win ,&PbId, &Y, &X);
}
OUTPUT:
RETVAL


int
nametocode(name,code)
char *name
int code
CODE:
{
   short int scode;
   struct dsc$descriptor *SmgStrDsc;
   SmgStrDsc=malloc(sizeof(struct dsc$descriptor));
   SmgStrDsc->dsc$w_length  = strlen(name);
   SmgStrDsc->dsc$b_dtype   = DSC$K_DTYPE_T;
   SmgStrDsc->dsc$a_pointer = name;
   SmgStrDsc->dsc$b_class   = DSC$K_CLASS_S;

   RETVAL=SMG$NAME_TO_KEYCODE(SmgStrDsc,&scode);
   code=(int)scode;
   free(SmgStrDsc);
}
OUTPUT:
code
RETVAL

       
int
printscreen(PbId ,queue)
int PbId
char *queue
CODE:
{
   
   struct dsc$descriptor *SmgStrDsc;
   SmgStrDsc=malloc(sizeof(struct dsc$descriptor));
   SmgStrDsc->dsc$w_length  = strlen(queue);
   SmgStrDsc->dsc$b_dtype   = DSC$K_DTYPE_T;
   SmgStrDsc->dsc$a_pointer = queue;
   SmgStrDsc->dsc$b_class   = DSC$K_CLASS_S;

   RETVAL=SMG$PRINT_PASTEBOARD  (&PbId ,SmgStrDsc); 
   free(SmgStrDsc);
}
OUTPUT:
RETVAL
       

       
int
putline(win ,text ,advance ,attr)
int win
char *text
int advance
char *attr
CODE:
{
   int Video=0;
   char *pnt;
   struct dsc$descriptor *SmgStrDsc;
   SmgStrDsc=malloc(sizeof(struct dsc$descriptor));
   SmgStrDsc->dsc$w_length  = strlen(text);
   SmgStrDsc->dsc$b_dtype   = DSC$K_DTYPE_T;
   SmgStrDsc->dsc$a_pointer = text;
   SmgStrDsc->dsc$b_class   = DSC$K_CLASS_S;

   
   pnt = attr;
   while(*pnt){
      switch(toupper(*(pnt))){
       case 'I': 
	 Video |= SMG$M_INVISIBLE;
	 break;
       case 'B': 
	 Video |= SMG$M_BOLD;
	 break;
       case 'R': 
	 Video |= SMG$M_REVERSE;
	 break;
       case 'U': 
	 Video |= SMG$M_UNDERLINE;
	 break;
       case 'F': 
	 Video |= SMG$M_BLINK;
	 break;
       case '1': 
	 Video |= SMG$M_USER1;
	 break;
       case '2': 
	 Video |= SMG$M_USER2;
	 break;
       case '3': 
	 Video |= SMG$M_USER3;
	 break;
       case '4': 
	 Video |= SMG$M_USER4;
	 break;
       case '5': 
	 Video |= SMG$M_USER5;
	 break;
       case '6': 
	 Video |= SMG$M_USER6;
	 break;
       case '7': 
	 Video |= SMG$M_USER7;
	 break;
       case '8': 
	 Video |= SMG$M_USER8;
	 break;
       default:
	 break;
      }
      pnt++;
   }

   RETVAL=SMG$PUT_LINE(&win ,SmgStrDsc ,&advance ,&Video);
   free(SmgStrDsc);
}
OUTPUT:
RETVAL
       

int
readkey(KbId ,code)
int KbId
int code
CODE:
{
   short int scode;
   RETVAL=SMG$READ_KEYSTROKE(&KbId ,&scode);
   code=(int)scode;
}
OUTPUT:
code
RETVAL

int
readkeypt(KbId ,code ,prompt ,timeout ,win)
int KbId
int code
char *prompt
int timeout
int win
CODE:
{
   short int scode;
   struct dsc$descriptor *SmgStrDsc;
   SmgStrDsc=malloc(sizeof(struct dsc$descriptor));
   SmgStrDsc->dsc$w_length  = strlen(prompt);
   SmgStrDsc->dsc$b_dtype   = DSC$K_DTYPE_T;
   SmgStrDsc->dsc$a_pointer = prompt;
   SmgStrDsc->dsc$b_class   = DSC$K_CLASS_S;
   RETVAL=SMG$READ_KEYSTROKE(&KbId ,&scode ,SmgStrDsc ,&timeout ,&win);
   free(SmgStrDsc);
   code = (int)scode;
}
OUTPUT:
code
RETVAL
       
int
refresh(PbId)
int PbId
CODE:
{
   RETVAL=SMG$REPAINT_SCREEN(&PbId);
}
OUTPUT:
RETVAL
       

int
putwinagain(win ,PbId ,Y ,X)
int win
int PbId
int Y
int X
CODE:
{
   RETVAL=SMG$REPASTE_VIRTUAL_DISPLAY(&win ,&PbId ,&Y ,&X);
}
OUTPUT:
RETVAL


       
int
curpos(win ,Y ,X)
int win
int Y
int X
CODE:
{
   RETVAL=SMG$RETURN_CURSOR_POS(&win ,&Y ,&X);
}
OUTPUT:
Y
X
RETVAL

       
int
bell(win ,nbtimes)
int win
int nbtimes
CODE:
{
   RETVAL=SMG$RING_BELL(&win ,&nbtimes);
}
OUTPUT:
RETVAL
       

       
int
savewin(win ,filespec)
int win
char *filespec
CODE:
{
   struct dsc$descriptor *SmgStrDsc;
   SmgStrDsc=malloc(sizeof(struct dsc$descriptor));
   SmgStrDsc->dsc$w_length  = strlen(filespec);
   SmgStrDsc->dsc$b_dtype   = DSC$K_DTYPE_T;
   SmgStrDsc->dsc$a_pointer = filespec;
   SmgStrDsc->dsc$b_class   = DSC$K_CLASS_S;
   
   RETVAL=SMG$SAVE_VIRTUAL_DISPLAY(&win ,SmgStrDsc);
   free(SmgStrDsc);
}
OUTPUT:
RETVAL

       
int
scrollsubwin(win ,direction ,count)
int win
char *direction
int count
CODE:
{
   int Direction;

   switch(toupper(*(direction))){
    case 'U': 
      Direction |= SMG$M_UP;
      break;
    case 'D': 
      Direction |= SMG$M_DOWN;
      break;
    default:
      break;
   }
   RETVAL=SMG$SCROLL_VIEWPORT(&win ,&Direction ,&count);
}
OUTPUT:
RETVAL

       
int
selmenuopt(KbId ,win ,sel_nb ,def_sel ,flags ,hlp)
int KbId
int win
int sel_nb
int def_sel
char *flags
char *hlp
CODE:
{
   int Flags=0;
   short int ssel_nb, sdef_sel;
   char *pnt;
   struct dsc$descriptor *SmgStrDsc;
   SmgStrDsc=malloc(sizeof(struct dsc$descriptor));
   SmgStrDsc->dsc$w_length  = strlen(hlp);
   SmgStrDsc->dsc$b_dtype   = DSC$K_DTYPE_T;
   SmgStrDsc->dsc$a_pointer = hlp;
   SmgStrDsc->dsc$b_class   = DSC$K_CLASS_S;
   sdef_sel = (short int)def_sel;
   pnt = flags;
   while(*pnt){
      switch(toupper(*(pnt))){
       case 'I': 
	 Flags |= SMG$M_RETURN_IMMED;
	 break;
       case 'R': 
	 Flags |= SMG$M_REMOVE_ITEM;
	 break;
       default:
	 break;
      }
      pnt++;
   }
   RETVAL=SMG$SELECT_FROM_MENU(&KbId ,&win ,&ssel_nb ,&sdef_sel ,
			       &Flags ,SmgStrDsc);
   free(SmgStrDsc);
   sel_nb = (int)ssel_nb;
}
OUTPUT:
sel_nb
RETVAL

int
setcurpos(win ,Y ,X)
int win
int Y
int X
CODE:
{
   RETVAL=SMG$SET_CURSOR_ABS(&win ,&Y ,&X);
}
OUTPUT:
RETVAL

int
setcurmode(PbId ,flags)
int PbId
char *flags
CODE:
{
   char *pnt;
   int Flags=0;
   pnt = flags;
   while(*pnt){
      switch(toupper(*(pnt))){
       case '0': 
	 Flags |= SMG$M_CURSOR_OFF;
	 break;
       case '1': 
	 Flags |= SMG$M_CURSOR_ON;
	 break;
       case 'J': 
	 Flags |= SMG$M_SCROLL_JUMP;
	 break;
       case 'S': 
	 Flags |= SMG$M_SCROLL_SMOOTH;
	 break;
       default:
	 break;
      }
      pnt++;
   }
   RETVAL=SMG$SET_CURSOR_MODE(&PbId ,&Flags);
}
OUTPUT:
RETVAL

       
int
remwin(win ,PbId)
int win
int PbId
CODE:
{
   RETVAL=SMG$UNPASTE_VIRTUAL_DISPLAY(&win ,&PbId);
}
OUTPUT:
RETVAL



int
read_string(win,KbId,Str,Size)
int win
int KbId
char *Str
int Size
CODE:
{
   unsigned long int Status; 
   unsigned short int c;
   char *p;
   int NbChars;
   char OneByte[]="-";
   int GoOn=1;
   int y0, x0, y, x, Flags=0, Video=SMG$M_BOLD, Set=SMG$C_ASCII;
   struct dsc$descriptor *dOneByte;
   struct dsc$descriptor *SmgStrDsc;
   Str = malloc(sizeof(char)*(Size+1));
   Str[Size]=0;
   SmgStrDsc=malloc(sizeof(struct dsc$descriptor));
   SmgStrDsc->dsc$w_length  = Size;
   SmgStrDsc->dsc$b_dtype   = DSC$K_DTYPE_T;
   SmgStrDsc->dsc$a_pointer = Str;
   SmgStrDsc->dsc$b_class   = DSC$K_CLASS_S;
   dOneByte=malloc(sizeof(struct dsc$descriptor));
   dOneByte->dsc$w_length  = 1;
   dOneByte->dsc$b_dtype   = DSC$K_DTYPE_T;
   dOneByte->dsc$a_pointer = OneByte;
   dOneByte->dsc$b_class   = DSC$K_CLASS_S;
   p = OneByte;
   x0=x=smg$cursor_column(&win);
   y0=y=smg$cursor_row(&win);
   do{
      Status = smg$read_keystroke(&KbId, &c);

      switch ((unsigned short int)c) {
       case SMG$K_TRM_KP0 :
	 c=48;
	 break;
       case SMG$K_TRM_KP1 :
	 c=49;
	 break;
       case SMG$K_TRM_KP2 :
	 c=50;
	 break;
       case SMG$K_TRM_KP3 :
	 c=51;
	 break;
       case SMG$K_TRM_KP4 :
	 c=52;
	 break;
       case SMG$K_TRM_KP5 :
	 c=53;
	 break;
       case SMG$K_TRM_KP6 :
	 c=54;
	 break;
       case SMG$K_TRM_KP7 :
	 c=55;
	 break;
       case SMG$K_TRM_KP8 :
	 c=56;
	 break;
       case SMG$K_TRM_KP9 :
	 c=57;
	 break;
       default :
	 break;
      }
      
      if (((unsigned short int)c<255)&&((unsigned char)c!=13)&&((unsigned char)c!=26)){
	 if (isprint((unsigned char)c)&&((x-x0)<Size)){
	    *p = (unsigned char)c;
	    Status=smg$put_chars(&win, dOneByte, &y, &x, 
				 &Flags, &Video, &Flags, &Set);
	    x++;
	    Status = smg$set_cursor_abs(&win, &y, &x);
	 }
	 if(((unsigned char)c == SMG$K_TRM_DELETE)&&(x>x0)){
	    x--;
	    Status = smg$set_cursor_abs(&win, &y, &x);
	    NbChars = 1;
	    Status = smg$delete_chars(&win, &NbChars, &y, &x);
	 }
      }
      
      else{
	 switch ((unsigned short int)c) {
	  case SMG$K_TRM_LEFT :
	    if(x>x0){
	       x--;
	       Status = smg$set_cursor_abs(&win, &y, &x);
	    }
	    break;
	  case SMG$K_TRM_RIGHT :
	    if((x-x0)<Size){
	       x++;
	       Status = smg$set_cursor_abs(&win, &y, &x);
	    }
	    break;
	  default :
	    Status = smg$set_cursor_abs(&win, &y0, &x0);
	    Status = smg$read_from_display(&win,SmgStrDsc);
	    GoOn=0;
	 }
      }
      
   }while(GoOn &&((unsigned char)c!=13)&&((unsigned char)c!=26));

   free(dOneByte);
   free(SmgStrDsc);
   RETVAL= (int)(c);
}
OUTPUT:
Str
RETVAL


