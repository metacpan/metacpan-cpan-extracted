
#ifdef _WIN32

#include <windows.h>

#include <pTk/tkPort.h>
#include <pTk/tkInt.h>
#include "pTk/tkWinInt.h"
#include <pTk/tkVMacro.h>

#ifndef _TKCANVAS
#include "pTk/tkCanvas.h"
#endif

/*
 * One of the following structures is created to keep track of Winprint
 * output being generated.  It consists mostly of information provided on
 * the widget command line.
 */

typedef struct TkWinPrintInfo {
    int x, y, width, height;	/* Area to print, in canvas pixel
				 * coordinates. */
    int x2, y2;			/* x+width and y+height. */
    char *pageXString;		/* String value of "-pagex" option or NULL. */
    char *pageYString;		/* String value of "-pagey" option or NULL. */
    double pageX, pageY;	/* Printer coordinates (in pixels)
				 * corresponding to pageXString and
				 * pageYString. */
    char *pageWidthString;	/* Printed width of output. */
    char *pageHeightString;	/* Printed height of output. */
    double pageWidth, pageHeight;/* In Printer coordinates (pixels) */
    Tk_Anchor pageAnchor;	/* How to anchor bbox on Printer page. */
    int rotate;			/* Non-zero means output should be rotated
				 * on page (landscape mode). */
} TkWinPrintInfo;

/*
 * The table below provides a template that's used to process arguments
 * to the canvas "print" command and fill in TkWinPrintInfo
 * structures.
 */

static Tk_ConfigSpec configSpecs[] = {
    {TK_CONFIG_PIXELS, "-height", (char *) NULL, (char *) NULL,
	"", Tk_Offset(TkWinPrintInfo, height), 0},
    {TK_CONFIG_ANCHOR, "-pageanchor", (char *) NULL, (char *) NULL,
	"", Tk_Offset(TkWinPrintInfo, pageAnchor), 0},
    {TK_CONFIG_STRING, "-pageheight", (char *) NULL, (char *) NULL,
	"", Tk_Offset(TkWinPrintInfo, pageHeightString), 0},
    {TK_CONFIG_STRING, "-pagewidth", (char *) NULL, (char *) NULL,
	"", Tk_Offset(TkWinPrintInfo, pageWidthString), 0},
    {TK_CONFIG_STRING, "-pagex", (char *) NULL, (char *) NULL,
	"", Tk_Offset(TkWinPrintInfo, pageXString), 0},
    {TK_CONFIG_STRING, "-pagey", (char *) NULL, (char *) NULL,
	"", Tk_Offset(TkWinPrintInfo, pageYString), 0},
    {TK_CONFIG_BOOLEAN, "-rotate", (char *) NULL, (char *) NULL,
	"", Tk_Offset(TkWinPrintInfo, rotate), 0},
    {TK_CONFIG_PIXELS, "-width", (char *) NULL, (char *) NULL,
	"", Tk_Offset(TkWinPrintInfo, width), 0},
    {TK_CONFIG_PIXELS, "-x", (char *) NULL, (char *) NULL,
	"", Tk_Offset(TkWinPrintInfo, x), 0},
    {TK_CONFIG_PIXELS, "-y", (char *) NULL, (char *) NULL,
	"", Tk_Offset(TkWinPrintInfo, y), 0},
    {TK_CONFIG_END, (char *) NULL, (char *) NULL, (char *) NULL,
	(char *) NULL, 0, 0}
};


/*
 * Forward declarations for procedures defined later in this file:
 */

static int		GetPrinterPixels _ANSI_ARGS_((Tcl_Interp *interp,
			    char *string, double *doublePtr, double ptrPix ,double ptrMM));


/*
 *--------------------------------------------------------------
 * 
 * PrintCanvasCmd -- 
 *      When invoked with the correct args this will bring up a
 *      standard Windows print dialog box and then print the
 *	contence of the canvas.
 *
 * Results:
 *      Standard Tcl result.
 * 
 *--------------------------------------------------------------
 */


int
PrintCanvasCmd(canvasPtr, interp, argc, argv)
     TkCanvas *canvasPtr;		/* Information about canvas widget. */
     Tcl_Interp *interp;
          int argc;
	    Arg *argv;
{
    TkWinPrintInfo wpInfo;
    int result = TCL_OK;
    PRINTDLG pd;
    Tcl_CmdInfo canvCmd;
    TkWinDrawable *PrinterDrawable;
    Tk_Window tkwin = canvasPtr->tkwin;
    Tk_Item *itemPtr;
    Pixmap pixmap;
    HDC hDCpixmap;
    TkWinDCState pixmapState;
    DEVMODE dm;
    float Ptr_pixX,Ptr_pixY,Ptr_mmX,Ptr_mmY;
    float screen_pixX,screen_pixY,screen_mmX,screen_mmY;

    int page_Y_size, page_X_size;
    int tiles_wide,tiles_high;
    int tile_y, tile_x;
    DOCINFO *lpdi = malloc(sizeof(DOCINFO));
    int deltaX = 0, deltaY = 0;		/* Offset of lower-left corner of
					 * area to be marked up, measured
					 * in canvas units from the positioning
					 * point on the page (reflects
					 * anchor position).  Initial values
					 * needed only to stop compiler
					 * warnings. */
    DEVMODE *dm2;  /* devmode for forcing landscape or portrait */
    float VEx, VEy, V0x, V0y;  /* Viewport Extents X/Y and Origin X/Y */
    float WEx, WEy, W0x, W0y;  /* Window Extents X/Y and Origin X/Y */
    double YX_ratio;           /* Ratio of screen X/Y pixels, used to preserve aspect */
    
    float VEx_adj, VEy_adj;    /* Viewport Extents, adjusted for what we can actualy get to
                                  while maintaining the correct aspect ratio */
    double YX_ratioMM;         /* Ratio of screen X/Y MM*/
    double YX_Ptr_ratioMM;      /* Ratio of printer X/Y MM*/
    
    /*
     *----------------------------------------------------------------
     * Initialize the data structure describing Printer generation,
     * then process all the arguments to fill the data structure in.
     *----------------------------------------------------------------
     */
    wpInfo.x = canvasPtr->xOrigin;
    wpInfo.y = canvasPtr->yOrigin;
    wpInfo.width = -1;
    wpInfo.height = -1;
    wpInfo.pageXString = NULL;
    wpInfo.pageYString = NULL;
    wpInfo.pageX = -1;
    wpInfo.pageY = -1;
    wpInfo.pageWidthString = NULL;
    wpInfo.pageHeightString = NULL;
    wpInfo.pageAnchor = TK_ANCHOR_CENTER;
    wpInfo.rotate = -1;
    
    result = Tk_ConfigureWidget(interp, tkwin,
	    configSpecs, argc-2, argv+2, (char *) &wpInfo,
	    TK_CONFIG_ARGV_ONLY);
    if (result != TCL_OK) {
//fprintf(stderr, "Error processing args\n");
	goto cleanup;
    }
//fprintf(stderr, "  rotate = %d\n",wpInfo.rotate);

    if (wpInfo.width == -1) {
	wpInfo.width = Tk_Width(tkwin);
    }
    if (wpInfo.height == -1) {
	wpInfo.height = Tk_Height(tkwin);
    }
    wpInfo.x2 = wpInfo.x + wpInfo.width;
    wpInfo.y2 = wpInfo.y + wpInfo.height;

    memset(&dm,0,sizeof(DEVMODE));
    dm.dmSize = sizeof(DEVMODE);
    dm.dmScale = 500;

    memset(lpdi,0,sizeof(DOCINFO));
    lpdi->cbSize=sizeof(DOCINFO);
    lpdi->lpszDocName=malloc(255);
    sprintf((char*)lpdi->lpszDocName,"SN - Printing\0");
    lpdi->lpszOutput=NULL;

//fprintf(stderr, "tkwin=%d h=%d w=%d\n", tkwin, Tk_Height(tkwin), Tk_Width(tkwin));
    memset(&pd,0,sizeof( PRINTDLG ));
    pd.lStructSize  = sizeof( PRINTDLG );
    pd.hwndOwner    = NULL;
    pd.hDevMode	    = NULL;
    pd.hDevNames    = NULL;
    /* pd.hDC = */
    pd.Flags	    = PD_RETURNDC;

    /* Get printer details. */
    if (!PrintDlg(&pd)) {
	goto cleanup;
    }
    /* Forcibly set rotation if rotate set */
    if( wpInfo.rotate == 1){
	    dm2=(DEVMODE *)GlobalLock(pd.hDevMode);
	    dm2->dmOrientation=DMORIENT_LANDSCAPE;
	    ResetDC(pd.hDC,dm2);
	    GlobalUnlock(pd.hDevMode);
    }
    if( wpInfo.rotate == 0){
	    dm2=(DEVMODE *)GlobalLock(pd.hDevMode);
	    dm2->dmOrientation=DMORIENT_PORTRAIT;
	    ResetDC(pd.hDC,dm2);
	    GlobalUnlock(pd.hDevMode);
    }
    
//fprintf(stderr, "1\n");
    PrinterDrawable = (TkWinDrawable *) ckalloc(sizeof(TkWinDrawable));
    PrinterDrawable->type = TWD_WINDC;
    PrinterDrawable->winDC.hdc = pd.hDC;

//fprintf(stderr, "2\n");
    Ptr_pixX=(float)GetDeviceCaps(PrinterDrawable->winDC.hdc,HORZRES);
    Ptr_pixY=(float)GetDeviceCaps(PrinterDrawable->winDC.hdc,VERTRES);
    Ptr_mmX=(float)GetDeviceCaps(PrinterDrawable->winDC.hdc,HORZSIZE);
    Ptr_mmY=(float)GetDeviceCaps(PrinterDrawable->winDC.hdc,VERTSIZE);



    /* Get Screen Information */
    screen_pixX=(float)WidthOfScreen(Tk_Screen(tkwin));
    screen_pixY=(float)HeightOfScreen(Tk_Screen(tkwin));
    screen_mmX =(float)WidthMMOfScreen(Tk_Screen(tkwin));
    screen_mmY =(float)HeightMMOfScreen(Tk_Screen(tkwin));
    YX_ratio   = screen_pixY/screen_pixX;
    YX_ratioMM = screen_mmY/screen_mmX;
    YX_Ptr_ratioMM  =   Ptr_mmY / Ptr_mmX;
    
    /* ViewPort Extents are the printer extents */
    VEx = Ptr_pixX;
    VEy = Ptr_pixY;

    /* Calulate Viewport extents, based on what we can get do while
       maintaining the same aspect ratio */
    if( YX_Ptr_ratioMM > YX_ratioMM   ){
    	VEx_adj = VEx;
	VEy_adj = VEx * YX_ratioMM;
    }
    else{
    	VEy_adj = VEy;
	VEx_adj = VEy / YX_ratioMM;
    }
        
	
    	
 //fprintf(stderr," screen_pixX/Y = %f/%f\n", screen_pixX, screen_pixY);
 //fprintf(stderr," screen_mmX/Y = %f/%f\n",  screen_mmX,  screen_mmY);
       
    /* Set page-space extents to the same aspect ration as the screen, to preserve
       the same appearance on the screen */
       

 //fprintf(stderr," Ptr_pixX/Y = %f/%f\n", Ptr_pixX, Ptr_pixY);
 //fprintf(stderr," Ptr_mmX/Y = %f/%f\n",  Ptr_mmX,  Ptr_mmY);
 
   
    /* pageX/Y defaults to the center of the page */
    wpInfo.pageX = Ptr_pixX/2;
    wpInfo.pageY = Ptr_pixY/2;
    wpInfo.pageWidth = Ptr_pixX;
    wpInfo.pageHeight = Ptr_pixX;
    

    /* Setup other options */
    if (wpInfo.pageXString != NULL) {
	if (GetPrinterPixels(interp, wpInfo.pageXString,
		&wpInfo.pageX,Ptr_pixX, Ptr_mmX ) != TCL_OK) {
	    goto cleanup;
	}
    }
    if (wpInfo.pageYString != NULL) {
	if (GetPrinterPixels(interp, wpInfo.pageYString,
		&wpInfo.pageY, Ptr_pixY, Ptr_mmY) != TCL_OK) {
	    goto cleanup;
	}
    }
    if (wpInfo.pageWidthString != NULL) {
	if (GetPrinterPixels(interp, wpInfo.pageWidthString,
		&wpInfo.pageWidth, Ptr_pixX, Ptr_mmX) != TCL_OK) {
	    goto cleanup;
	}
	WEx = wpInfo.width/wpInfo.pageWidth * VEx_adj;
	WEy = WEx * YX_ratio;
    } else if (wpInfo.pageHeightString != NULL) {
	if (GetPrinterPixels(interp, wpInfo.pageHeightString,
		&wpInfo.pageHeight, Ptr_pixY, Ptr_mmY ) != TCL_OK) {
	    goto cleanup;
	}
//fprintf(stderr, "PageHeight = %f\n", wpInfo.pageHeight);
	WEy = wpInfo.height/wpInfo.pageHeight * VEy_adj;
	WEx = WEy / YX_ratio;
    } else {  /* Default scale is actual size on the canvas */
	WEx = screen_pixX/screen_mmX * VEx_adj * Ptr_mmX / Ptr_pixX;
	WEy = WEx * YX_ratio;
    }
    switch (wpInfo.pageAnchor) {
	case TK_ANCHOR_NW:
	case TK_ANCHOR_W:
	case TK_ANCHOR_SW:
	    deltaX = 0;
	    break;
	case TK_ANCHOR_N:
	case TK_ANCHOR_CENTER:
	case TK_ANCHOR_S:
	    deltaX = -wpInfo.width/2;
	    break;
	case TK_ANCHOR_NE:
	case TK_ANCHOR_E:
	case TK_ANCHOR_SE:
	    deltaX = -wpInfo.width;
	    break;
    }
    switch (wpInfo.pageAnchor) {
	case TK_ANCHOR_NW:
	case TK_ANCHOR_N:
	case TK_ANCHOR_NE:
	    deltaY = 0;
	    break;
	case TK_ANCHOR_W:
	case TK_ANCHOR_CENTER:
	case TK_ANCHOR_E:
	    deltaY = -wpInfo.height/2;
	    break;
	case TK_ANCHOR_SW:
	case TK_ANCHOR_S:
	case TK_ANCHOR_SE:
	    deltaY = - wpInfo.height;
	    break;
    }
 
    W0x = -deltaX;
    W0y = -deltaY;
    V0x = wpInfo.pageX;
    V0y = wpInfo.pageY;
//fprintf(stderr, "W0x/y WEx/y = %f/%f %f/%f\n", W0x, W0y, WEx, WEy); 
//fprintf(stderr, "V0x/y VEx/y = %f/%f %f/%f\n", V0x, V0y, VEx, VEy); 
    
    SetMapMode(PrinterDrawable->winDC.hdc,MM_ISOTROPIC);
    SetWindowExtEx(PrinterDrawable->winDC.hdc, WEx, WEy, NULL);
    SetWindowOrgEx(PrinterDrawable->winDC.hdc, W0x, W0y, NULL);
    SetViewportExtEx(PrinterDrawable->winDC.hdc,VEx, VEy, NULL);
    SetViewportOrgEx(PrinterDrawable->winDC.hdc,V0x, V0y, NULL);
 

    /* Calculate the number of tiles high */
    page_Y_size = Ptr_pixY;
    page_X_size = Ptr_pixX;

    tiles_high = ( wpInfo.height / page_Y_size ); /* start at zero */
    tiles_wide = ( wpInfo.width  / page_X_size ); /* start at zero */

 //fprintf(stderr," Tiles High/Wide = %d/%d\n",  tiles_high,  tiles_wide);

    StartDoc(pd.hDC,lpdi);

    for (tile_x = 0; tile_x <= tiles_wide;tile_x++) {
    for (tile_y = 0; tile_y <= tiles_high;tile_y++) {
	SetViewportOrgEx(pd.hDC,-(tile_x*Ptr_pixX)+V0x,-(tile_y*Ptr_pixY)+V0y,NULL);
        StartPage(pd.hDC);

 	for (itemPtr = canvasPtr->firstItemPtr; itemPtr != NULL;
		itemPtr = itemPtr->nextPtr) {
	    (*itemPtr->typePtr->displayProc)((Tk_Canvas) canvasPtr, itemPtr,
		    canvasPtr->display, (unsigned long) PrinterDrawable/*pixmap*/, wpInfo.x, wpInfo.y, wpInfo.width,
		    wpInfo.height);
	}
    
    EndPage(pd.hDC);
    }
    }
    EndDoc(pd.hDC);
//fprintf(stderr, "8\n");

    cleanup:
    if (wpInfo.pageXString != NULL) {
	ckfree(wpInfo.pageXString);
    }
    if (wpInfo.pageYString != NULL) {
	ckfree(wpInfo.pageYString);
    }
    if (wpInfo.pageWidthString != NULL) {
	ckfree(wpInfo.pageWidthString);
    }
    if (wpInfo.pageHeightString != NULL) {
	ckfree(wpInfo.pageHeightString);
    }
    return result;
}

/*
 *--------------------------------------------------------------
 *
 * GetPrinterPixels  --
 *
 *	Given a string and the page widthMM and width in Pixels,
 *      returns the printer pixels
 *	corresponding to that string.
 *
 * Results:
 *	The return value is a standard Tcl return result.  If
 *	TCL_OK is returned, then everything went well and the
 *	screen distance is stored at *doublePtr;  otherwise
 *	TCL_ERROR is returned and an error message is left in
 *	interp->result.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

static int
GetPrinterPixels(interp, string, doublePtr, ptrPix, ptrMM )
    Tcl_Interp *interp;		/* Use this for error reporting. */
    char *string;		/* String describing a screen distance. */
    double *doublePtr;		/* Place to store converted result. */
    double ptrPix;
    double ptrMM;
{
    char *end;
    double d;

    d = strtod(string, &end);
    if (end == string) {
	error:
	Tcl_AppendResult(interp, "bad distance \"", string,
		"\"", (char *) NULL);
	return TCL_ERROR;
    }
    while ((*end != '\0') && isspace(UCHAR(*end))) {
	end++;
    }
    switch (*end) {
	case 'c': /* String in centemeters */
	    d *= 10*ptrPix/ptrMM;
	    end++;
	    break;
	case 'i': /* Input in inches */
	    d *= 25.4*ptrPix/ptrMM;
	    end++;
	    break;
	case 'm': /* Input in mm */
	    d *= ptrPix/ptrMM;
	    end++;
	    break;
	case 0:
	    break;
	case 'p': /* Input in points */
	    d *= 25.4/72*ptrPix/ptrMM;
	    end++;
	    break;
	default:
	    goto error;
    }
    while ((*end != '\0') && isspace(UCHAR(*end))) {
	end++;
    }
    if (*end != 0) {
	goto error;
    }
    *doublePtr = d;
    return TCL_OK;
}


#endif /* _WIN32 */
