#ifndef PERLFORMS_H
#define PERLFORMS_H
/*   PerlForms.h - An extension to PERL to access XForms functions.
#    Copyright (C) 1996-1997  Martin Bartlett
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

/*
 * Buffer size for arbritary string buffers. Only used by fl_get_resource
 * and my version of croak
 */
#define RESBUF  1024
char *	temp_str_buf = NULL;		/* Temporary String Buffer */
int	temp_str_buf_size = 0;		/* and its size */

/*
 * Constants for callback mechanism
 */
#define CB_FALSE	0
#define CB_RET_INT	1
#define CB_RET_STR	2

/*
 * The five Xforms-specific blessed objects
 */
typedef FL_FORM         FLForm;
typedef FL_OBJECT       FLObject;
typedef FL_IOPT 	FLOpt;
typedef FD_FSELECTOR 	FDFselector;
typedef FD_CMDLOG 	FDCmdlog;
typedef FL_EditKeymap 	FLEditKeymap;

/*
 * Mirror of FL_IOPT sturcture that gives the integers as an array
 * - obviously pretty vulnerable to changes!!!
 */

typedef struct
{
    float rgamma, ggamma, bgamma;
    int opt_int[23];
    char *rgbfile;		/* where RGB file is     */
    char vname[24];
} FL_IOPT_ARRAY;

/*
 * Mirror of FD_FSELECTOR sturcture that gives the objects as an array
 * - obviously pretty vulnerable to changes!!!
 */
typedef struct
{
    void *fsel_ob[11];
    FL_OBJECT *appbutt[3];
} FD_FSEL_ARRAY;

/*
 * Mirror of FD_CMDLOG sturcture that gives the objects as an array
 * - obviously pretty vulnerable to changes!!!
 */
typedef struct
{
    void *cmd_ob[4];
} FD_CMD_ARRAY;

/*
 * Mirror of FL_EditKeymap sturcture that gives the mappings as an array
 * - obviously pretty vulnerable to changes!!!
 */
typedef struct
{
	long	keymap_long[27];
} FL_KEYMAP_ARRAY;

/*
 * Mirror of FL_FORM structure that gives fields as arrays
 * - obviously pretty vulnerable to changes!!!
 */

typedef struct 
{
    void *fdui;			/* for fdesign              */
    void *u_vdata;		/* for application          */
#if FL_INCLUDE_VERSION >= 87
	char *u_cdata;
#endif
    long u_ldata;

    char *label;		/* window title             */
    unsigned long window;	/* X resource ID for window */
    FL_Coord	flf_flc[6];
    /* FL_Coord x, y, w, h;	/* current geometry info    */
    /* FL_Coord hotx, hoty;	/* hot-spot of the form     */

    FL_OBJECT *flf_flo[3];
    /*struct flobjs_ *first;
    struct flobjs_ *last;
    struct flobjs_ *focusobj;*/

    FL_FORMCALLBACKPTR form_callback;
    FL_FORM_ATACTIVATE activate_callback;
    FL_FORM_ATDEACTIVATE deactivate_callback;
    void *form_cb_data, *activate_data, *deactivate_data;

    FL_RAW_CALLBACK key_callback;
    FL_RAW_CALLBACK push_callback;
    FL_RAW_CALLBACK crossing_callback;
    FL_RAW_CALLBACK motion_callback;
    FL_RAW_CALLBACK all_callback;

    unsigned long compress_mask;
    unsigned long evmask;

    /* WM_DELETE_WINDOW message handler */
    FL_FORM_ATCLOSE close_callback;
    void *close_data;

    void *flpixmap;		/* back buffer             */

    unsigned long icon_pixmap;
    unsigned long icon_mask;

    /* interaction and other flags */
    int flf_int[10];
/*    int vmode;			/* current X visual class  */
/*    int deactivated;		/* true if sensitive       */
/*    int use_pixmap;		/* true if dbl buffering   */
/*    int frozen;			/* true if sync change     */
/*    int visible;		/* true if mapped          */
/*    int wm_border;		/* window manager info     */
/*    unsigned int prop;		/* other attributes        */
/*    int has_auto;		/*	*/
/*    int top;			/*	*/
/*    int sort_of_modal;		/* internal use.           */
#if FL_INCLUDE_VERSION >= 87
    struct forms_ *parent;
    struct forms_ *child;
    struct flobjs_ *parent_obj;
    int reserved[10];           /* future use              */
#else
    int reserved[12];           /* future use              */
#endif
} FLF_ARRAY;

/*
 * Mirror of FL_OBJECT structure that gives fields as arrays
 * - obviously pretty vulnerable to changes!!!
 */

typedef struct
{
    struct forms_ *form;	/* the form this object belong        */
    void *u_vdata;		/* anything user likes                */
#if FL_INCLUDE_VERSION >= 87
	char *u_cdata;
#endif
    long u_ldata;		/* anything user lines                */

    int flo_int2[3];
/*    int objclass;		/* class of object, button, slider etc */
/*    int type;			/* type within the class              */
/*    int boxtype;		/* what kind of box type              */
    FL_Coord flo_flc[5];
/*    FL_Coord x, y, w, h;	/* obj. location and size             */
/*    FL_Coord bw;*/
    FL_COLOR col1, col2;	/* colors of obj                      */
    char *label;		/* object label                       */
    FL_COLOR lcol;		/* label color                        */
    int flo_int1[3];
/*    int align;*/
/*    int lsize, lstyle;		/* label size and style               */
    long *shortcut;

    int (*handle) (struct flobjs_ *, int, FL_Coord, FL_Coord, int, void *);
    void (*object_callback) (struct flobjs_ *, long);
    long argument;
    void *spec;			/* instantiation                      */

    int (*prehandle) (struct flobjs_ *, int, FL_Coord, FL_Coord, int, void *);
    int (*posthandle) (struct flobjs_ *, int, FL_Coord, FL_Coord, int, void *);

    /* re-configure preference */
    unsigned int flo_ui[3];
/*    unsigned int resize;	/* what to do if WM resizes the FORM     */
/*    unsigned int nwgravity;	/* how to re-position top-left corner    */
/*    unsigned int segravity;	/* how to re-position lower-right corner */

	struct flobjs_ *flo_obj[5];
/*    struct flobjs_ *prev;	/* prev. obj in form                  */
/*    struct flobjs_ *next;	/* next. obj in form                  */

/*    struct flobjs_ *parent;	*/
/*    struct flobjs_ *child;	*/
/*    struct flobjs_ *nc;		*/


    int is_child;

    void *flpixmap;		/* pixmap double buffering stateinfo   */
    int	flo_int[13];
/*    int use_pixmap;		/* true to use pixmap double buffering */

    /* some interaction flags */
/*    int double_buffer;		/* only used by mesa/gl canvas         */
/*    int pushed;*/
/*    int focus;*/
/*    int belowmouse;*/
/*    int active;			/* if accept event */
/*    int input;*/
/*    int wantkey;*/
/*    int radio;*/
/*    int automatic;*/
/*    int redraw;*/
/*    int visible;*/
/*    int clip;*/
    unsigned long click_timeout;
    void *c_vdata;		/* for class use  */
#if FL_INCLUDE_VERSION >= 87
	char *c_cdata;		/* for class use  */
#endif
    long c_ldata;		/* for class use  */
#if FL_INCLUDE_VERSION >= 87
    unsigned int spec_size;	/* for internal use         */
    FL_COLOR aux_col1, aux_col2;/* aux colors               */
    FL_COLOR dbl_background;    /* double buffer background */
	int how_return;
#endif
    int reserved[6];           /* for future use */

} FLO_ARRAY;

/*
 * The form callback data structure
 */
typedef struct _form_data {
	SV *	po;
	void *  u_vdata;
	SV *	fd_rawcallback;
	SV *	fd_fselcallback;
	SV * 	fd_callback;
	SV *	fd_atactivate;
	SV *	fd_atdeactivate;
	SV *	fd_atclose;
} form_data;

/*
 * The form callback data structure as an array
 */
typedef struct _fd_array {
	SV *	po;
	void *  u_vdata;
	SV *	fd_rawcallback;
	SV *	fd_fselcallback;
	SV * 	cb_ptr[4];
} fd_array;

/*
 * Pup callback logging blocks
 */
typedef struct _pupi_cb {
	struct _pupi_cb *next;
	int 	id;
	SV *	cb;
} pupi_cb;

typedef struct _pupm_cb {
	struct _pupm_cb *next;
	int 	id;
	SV *	cb;
	SV *	ecb;
	SV *	lcb;
	pupi_cb *items;
	
} pupm_cb;

/*
 * Block for recording xyplot overlay data. Used in co-ordinating
 * _add_..._overlay and _get_..._overlay functions
 */
typedef struct _xyplot_data {
	int	xy_pt_num;
	float	*xy_pt_data;
} xyplot_data;

/*
 * Block for collecting xyplot overlay data. Used in co-ordinating
 * _add_..._overlay and _get_..._overlay functions
 */
typedef struct _xyplot_hdr {
	int		xy_ol_num;
	xyplot_data	*xy_ol_data[1];
} xyplot_hdr;

/*
 * The object callback data structure
 */
typedef struct _object_data {
	SV *	po;
	void *  u_vdata;
	/*
	 * Basic object callback handlers
	 */
	SV * 	od_callback;
	SV *	od_brdbl_callback;
	SV * 	od_posthandler;
	SV * 	od_prehandler;
	SV *	od_input_filter;
	SV *	od_count_filter;
	SV *	od_slider_filter;
	SV * 	od_timer_filter;
	/*
	 * Specialized callback handlers
	 */
	SV *	od_freehandler;
	SV *	od_mcpinit;
	SV *	od_mcpact;
	SV *	od_mcpclean;
	SV *	od_makehandler;
	SV *	od_gainsel;
	SV *	od_losesel;
	SV **	od_cevents;
	int		od_max_overlays;
	SV **	od_xyplot_symbol;
} object_data;

/*
 * Remapped as an array
 */
typedef struct _od_array {
	SV *	po;
	void *  u_vdata;
	/*
	 * Basic object callback handlers as an array
	 */
	SV *	cb_ptr[15];
	SV **	od_cevents;
	int		od_max_overlays;
	SV **	od_xyplot_symbol;
} od_array;

#define OD_CALLBACK			0
#define OD_BRDBL_CALLBACK	1
#define OD_POSTHANDLER		2
#define OD_PREHANDLER		3
#define OD_INPUT_FILTER		4
#define OD_COUNT_FILTER		5
#define OD_SLIDER_FILTER	6
#define OD_TIMER_FILTER		7
#define OD_FREEHANDLER		8
#define OD_MCPINIT			9
#define OD_MCPACT			10
#define OD_MCPCLEAN			11
#define OD_MAKEHANDLER		12
#define OD_GAINSEL			13
#define OD_LOSESEL			14

/*
 * The data structure used to record timeout callback subroutines
 * (kept in a double link chain because xforms removes timeouts
 * implicitly when they have been called.
 */
typedef struct _to_data {
	int			in_use;
	int			time_out_id;
	SV *		parm;
	SV *		callback;
} to_data;

/*
 * The data structure used to record XEvent callback subroutines
 */
typedef struct _cb_data {
	struct _cb_data *	next_data;
	Window			window;
	SV *			callback;
} cb_data;

/*
 * The data structure used to record io event callback subroutines
 */
typedef struct _io_data {
	struct _io_data *	next_data;
	int			fd;
	unsigned		condition;
	SV *			parm;
    SV *			fh;
	SV *			callback;
} io_data;

/*
 * The data structure used to record signal callback subroutines
 */
typedef struct _sig_data {
	struct _sig_data *	next_data;
	int			sgnl;
	SV *			parm;
	SV *			callback;
} sig_data;

/*
 * The data structure used to record fselector callback subroutines
 * for application buttons.
 */
typedef struct _facb_data {
        struct _facb_data *      next_data;
        SV *                    callback;
        SV *                  parm;
        char                    string;
} facb_data;

/*
 * Macro for read/write access to fields in structures!
 */
#define ObjRWfld(f)	do {RETVAL = f; \
 						if (rw) \
							f = field; \
						} while(0)
/*
 * Some call back handlers referenced before defined
 */
static int process_object_posthandler(
	FLObject * 	object,
	int		event,
	FL_Coord	x,
	FL_Coord	y,
	int		int4,
	void *		xevent);
static int process_object_prehandler(
	FLObject * 	object,
	int		event,
	FL_Coord	x,
	FL_Coord	y,
	int		int4,
	void *		xevent);
static int process_input_filter(
	FLObject * 	object,
	const char *	parm1,
	const char *	parm2,
	int		parm3);
static const char * process_counter_filter(
	FLObject *      object,
	double          parm1,
	int             parm2);
static const char * process_slider_filter(
	FLObject *      object,
	double          parm1,
	int             parm2);
static char * process_timer_filter(
	FLObject * 	object,
	double		parm1);
static void process_form_callback(
	FLObject * 	object,
	void *		parm);
static void process_form_atactivate(
	FLForm * 	form,
	void *		parm);
static void process_form_atdeactivate(
	FLForm * 	form,
	void *		parm);
static int process_form_atclose(
	FLForm * 	form,
	void *		parm);

/*
 * Various functions used to help with managing this rather large XSUB!
 */
static void	get_buffer(int);
static void	savesv(SV **old_cb, SV *new_cb);
static int 	process_idle_callback(XEvent * event, void * parm);
static int 	process_event_callback(XEvent * event, void * parm);
static int 	process_atclose(FLForm * form, void * parm);
static form_data  	*get_form_data(FLForm *form);
static object_data 	*get_object_data(FLObject *object);
static IV 	chk_bless(SV * thing, int blesstype);
static SV * 	bless_form(FLForm *f);
static SV * 	bless_object(FLObject *o); 
static void 	return_save_sv(SV **stack, SV **old_cb, SV *new_cb); 
static void	sv_setpv_c(SV* sv, const char* ptr);
static void	call_perl_callback(SV *callback, char * cbname, int outexpct, 
			void *outvar, char *parmptrn, ...);
static void	usage(char *function);
static int	SvNULL(SV *sv);
#endif
