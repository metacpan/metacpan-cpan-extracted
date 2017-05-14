/*   Xforms.xs - An extension to PERL to access XForms functions.
#    Copyright (C) 1996-1997  Martin Bartlett
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation;
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
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <forms.h>
#include "Xforms.h"
/*
 * My calloc/frees - due to a mother of a memory leak, I added this to
 * try and keep track of what was happening!
 */


void *X4Pcalloc(size_t nmemb, size_t size)
{
	void * ptr;

/*fprintf(stderr, "Allocating %i bytes (%i * %i) ... ", nmemb*size, nmemb, size);*/
	ptr = calloc(nmemb, size);
/*fprintf(stderr, "at %p\n", ptr);*/
    return ptr;
}

void X4Pfree(void *ptr)
{
/*fprintf (stderr, "Freeing %p\n", ptr);*/
	free(ptr);
}

/*
 * Array of object pointers that we know about
 */

static char *object_name[] = {
		"X11::Xforms",
		"X11::Xforms::FLForm",
		"X11::Xforms::FLObject",
		"X11::Xforms::FLOpt",
		"X11::Xforms::FDCmdlog",
		"X11::Xforms::FDFselector",
		"X11::Xforms::FLEditKeymap",
		"X11::XEvent",
		"X11::XFontStruct"
};

#define X11Xforms				0
#define X11XformsFLForm			1
#define X11XformsFLObject		2
#define X11XformsFLOpt			3
#define X11XformsFDCmdlog		4
#define X11XformsFDFselector	5
#define X11XformsFLEditKeymap	6
#define X11XEvent				7
#define X11XFontStruct			8

#if FL_INCLUDE_VERSION >= 87
#define leftScrollBar	scrollbarType
#define thinScrollBar	scrollbarType
#endif

/*
 *  Function arrays, making ALIAS a highly efficient way of calling
 *  functions with the same prototype from the same XSUB function, while
 *  cutting a vast chunk of the size of the library itself.
 *
 * Many liberties are taken here - functions with the same call parms but
 * different return types are sometimes cast to be the same; call back 
 * routines (at the bottom) are heavily re-cast since we don't care about 
 * the protocol here (only xforms does). 
 */

typedef struct {
	FL_OBJECT * (*func)(int,FL_Coord,FL_Coord,
		FL_Coord,FL_Coord,const char *);
	SV *init_cb;
} CrtAddFunc;

static CrtAddFunc	create_add_funcs[] = {

#ifdef XFOPENGL
		{fl_create_glcanvas, NULL},
		{fl_add_glcanvas, NULL},
#else
		{NULL, NULL},
		{NULL, NULL},
#endif
		{fl_create_button, NULL},
		{fl_add_button, NULL},
		{fl_create_lightbutton, NULL},
		{fl_add_lightbutton, NULL},
		{fl_create_roundbutton, NULL},
		{fl_add_roundbutton, NULL},
		{fl_create_checkbutton, NULL},
		{fl_add_checkbutton, NULL},
		{fl_create_bitmapbutton, NULL},
		{fl_add_bitmapbutton, NULL},
		{fl_create_pixmapbutton, NULL},
		{fl_add_pixmapbutton, NULL},
		{fl_create_bitmap, NULL},
		{fl_add_bitmap, NULL},
		{fl_create_pixmap, NULL},
		{fl_add_pixmap, NULL},
		{fl_create_box, NULL},
		{fl_add_box, NULL},
		{fl_create_text, NULL},
		{fl_add_text, NULL},
		{fl_create_menu, NULL},
		{fl_add_menu, NULL},
		{fl_create_chart, NULL},
		{fl_add_chart, NULL},
		{fl_create_choice, NULL},
		{fl_add_choice, NULL},
		{fl_create_counter, NULL},
		{fl_add_counter, NULL},
		{fl_create_slider, NULL},
		{fl_add_slider, NULL},
		{fl_create_valslider, NULL},
		{fl_add_valslider, NULL},
		{fl_create_input, NULL},
		{fl_add_input, NULL},
		{fl_create_browser, NULL},
		{fl_add_browser, NULL},
		{fl_create_dial, NULL},
		{fl_add_dial, NULL},
		{fl_create_timer, NULL},
		{fl_add_timer, NULL},
		{fl_create_clock, NULL},
		{fl_add_clock, NULL},
		{fl_create_positioner, NULL},
		{fl_add_positioner, NULL},
		{fl_create_xyplot, NULL},
		{fl_add_xyplot, NULL},
		{fl_create_canvas, NULL},
		{fl_add_canvas, NULL},
		{fl_create_frame, NULL},
		{fl_add_frame, NULL},
		{fl_create_round3dbutton, NULL},
		{fl_add_round3dbutton, NULL},
		{fl_create_labelframe, NULL},
		{fl_add_labelframe, NULL},
#if FL_INCLUDE_VERSION >= 87
/*
 ************** Menubar has been removed at 0.87.3
		{fl_create_menubar, NULL},
		{fl_add_menubar, NULL},
 */
		{NULL, NULL},
		{NULL, NULL},
/*
 *************************************************
 */
		{fl_create_tabfolder, NULL},
		{fl_add_tabfolder, NULL},
		{fl_create_scrollbutton, NULL},
		{fl_add_scrollbutton, NULL},
		{fl_create_scrollbar, NULL},
		{fl_add_scrollbar, NULL},
#endif
};

typedef struct {
	int fl_number;
	int ix_number;
} fl2ix;

static	fl2ix	fl_2_ix[] = {
	{FL_INVALID_CLASS,	-1},
    {FL_BUTTON, 		2},
	{FL_LIGHTBUTTON, 	4},
    {FL_ROUNDBUTTON, 	6},
	{FL_ROUND3DBUTTON, 	52},
    {FL_CHECKBUTTON, 	8},
    {FL_BITMAPBUTTON, 	10},
	{FL_PIXMAPBUTTON, 	12},
    {FL_BITMAP, 		14},
	{FL_PIXMAP, 		16},
    {FL_BOX, 			18},
	{FL_TEXT, 			20},
    {FL_MENU, 			22},
	{FL_CHART, 			24},
	{FL_CHOICE, 		26},
    {FL_COUNTER, 		28},
	{FL_SLIDER, 		30},
	{FL_VALSLIDER, 		32},
	{FL_INPUT, 			34},
    {FL_BROWSER, 		36},
    {FL_DIAL, 			38},
    {FL_TIMER, 			40},
    {FL_CLOCK, 			42},
    {FL_POSITIONER, 	44},
    {FL_FREE, 			-1},
    {FL_XYPLOT, 		46},
    {FL_FRAME, 			50},
    {FL_LABELFRAME, 	54},
    {FL_CANVAS, 		48},
    {FL_GLCANVAS, 		0},
#if FL_INCLUDE_VERSION >= 87
    {FL_TABFOLDER, 		58},
    {FL_SCROLLBAR, 		62},
    {FL_SCROLLBUTTON, 	60},
    {FL_MENUBAR, 		56},
#endif
	{FL_IMAGECANVAS,	-1},
#if FL_INCLUDE_VERSION < 87
	{FL_FOLDER,			-1},
#endif
    {FL_TEXTBOX,		-1}
};

#define FL_MAX_CLASS FL_TEXTBOX

#ifdef XFOPENGL
static	int	XFOpenGL = 1;
#else
static	int	XFOpenGL = 0;
#endif

typedef const char * (*CcharVoidFunc)(void);

static CcharVoidFunc     cchar_void_funcs[] = {
		fl_get_directory,
		fl_get_filename,
		fl_get_pattern,
#if FL_INCLUDE_VERSION >= 87
		fl_now,
		fl_whoami
#endif
};

typedef FL_OBJECT * (*FloVoidFunc)(void);

static FloVoidFunc	FLO_void_funcs[] = {
		fl_bgn_group,
		fl_end_group,
		fl_check_forms,
		fl_check_only_forms,
		fl_do_forms,
		fl_do_only_forms
};

typedef int (*IntFloFunc)(FL_OBJECT *);

static IntFloFunc	int_FLO_funcs[] = {
		fl_get_browser,
		fl_get_browser_maxline,
		fl_get_browser_screenlines,
		fl_get_browser_topline,
		fl_get_button,
		fl_get_button_numb,
		fl_get_canvas_depth,
		fl_get_choice,
		fl_get_choice_maxitems,
		fl_get_menu,
		fl_get_menu_maxitems,
		fl_get_input_topline,
		fl_get_input_screenlines,
		fl_get_input_numberoflines,
#if FL_INCLUDE_VERSION >= 87
		fl_get_folder_number,
		fl_get_active_folder_number,
		fl_get_menu_popup,
		fl_get_input_xoffset
#endif
};

typedef void (*VoidFLCFunc)(FL_COLOR);

static VoidFLCFunc	void_FLC_funcs[] = {
		fl_bk_color,
		fl_bk_textcolor,
		fl_color,
		fl_textcolor,
		fl_setpup_checkcolor
};

typedef void (*VoidFLFFunc)(FL_FORM *);

static VoidFLFFunc	void_FLF_funcs[] = {
		fl_activate_form,
		fl_addto_form,
		fl_deactivate_form,
		fl_free_form,
		fl_freeze_form,
		fl_hide_form,
		fl_redraw_form,
		fl_set_app_mainform,
		fl_unfreeze_form
};

typedef void (*VoidFLFiiFunc)(FL_FORM *,int,int);

static VoidFLFiiFunc	void_FLF_ii_funcs[] = {
		fl_set_form_hotspot,
		fl_set_form_maxsize,
		fl_set_form_minsize,
		fl_set_form_position,
		fl_set_form_size
};

typedef const char *(*CharFLOFunc)(FL_OBJECT *);

static CharFLOFunc	char_FLO_funcs[] = {
		fl_get_choice_text,
		fl_get_menu_text,
#if FL_INCLUDE_VERSION >= 87
		fl_get_folder_name,
		fl_get_active_folder_name
#endif
};

typedef const char *(*CharFLOIntFunc)(FL_OBJECT *, int);

static CharFLOIntFunc	char_FLO_int_funcs[] = {
		fl_get_browser_line,
		fl_get_choice_item_text,
		fl_get_menu_item_text
};

typedef void (*VoidFLFFLOFunc)(FL_FORM *,FL_OBJECT *);

static VoidFLFFLOFunc	void_FLF_FLO_funcs[] = {
		fl_add_object,
		fl_set_focus_object,
		fl_set_form_hotobject
};

typedef void (*VoidFLOiiiiFunc)(FL_OBJECT *, FL_Coord *, FL_Coord *, FL_Coord *,FL_Coord *);

static VoidFLOiiiiFunc	void_FLO_iiii_funcs[] = {
		fl_get_object_geometry,
		fl_get_browser_dimension,
		fl_get_object_bbox,
#if FL_INCLUDE_VERSION >= 87
		fl_get_folder_area
#endif
};

typedef void (*VoidXXXXFunc)(FL_Coord, FL_Coord, FL_Coord,FL_Coord);

static VoidXXXXFunc	void_XXXX_funcs[] = {
		fl_set_clipping,
		fl_wingeometry,
		fl_initial_wingeometry
};

typedef void (*VoidFLOFunc)(FL_OBJECT *);

static VoidFLOFunc	void_FLO_funcs[] = {
		fl_activate_object,
		fl_addto_group,
		fl_call_object_callback,
		fl_clear_browser,
		fl_deactivate_object,
		fl_delete_object,
		fl_deselect_browser,
		fl_draw_object_label,
		NULL, 			/* used to be fl_free_object */
		fl_free_pixmap_pixmap,
		fl_hide_object,
		fl_redraw_object,
		fl_show_object,
		fl_trigger_object,
		fl_hide_canvas,
		fl_clear_choice,
		fl_clear_menu,
		fl_clear_chart,
		fl_reset_focus_object,
		fl_suspend_timer,
		fl_resume_timer,
		fl_clear_xyplot,
		fl_draw_object_label_outside,
#if FL_INCLUDE_VERSION >= 87
/*
 ************** Menubar has been removed at 0.87.3
		fl_clear_menubar			menubar not in yet
 */
		NULL
/*
 **************
 */
#endif
};

typedef void (*VoidWinFLXFLXFunc)(Window, FL_Coord, FL_Coord);

static VoidWinFLXFLXFunc     void_win_FLX_FLX_funcs[] = {
		fl_winaspect,
		fl_winmaxsize,
		fl_winminsize,
		fl_winmove,
		fl_winresize,
		fl_winstepunit,
};

typedef void (*VoidFLOFLXFLXFunc)(FL_OBJECT *, FL_Coord, FL_Coord);

static VoidFLOFLXFLXFunc	void_FLO_FLX_FLX_funcs[] = {
		fl_fit_object_label,
		fl_set_object_position,
		fl_set_object_size
};

typedef void (*VoidFLXFLXFunc)(FL_Coord, FL_Coord);

static VoidFLXFLXFunc     void_FLX_FLX_funcs[] = {
		fl_initial_winsize,
		fl_winposition,
		fl_winsize,
		fl_set_mouse,
		fl_add_vertex
};

typedef void (*VoidWinFunc)(Window);

static VoidWinFunc     void_win_funcs[] = {
		fl_reset_winconstraints,
		fl_winclose,
		fl_winhide,
		fl_winset,
		fl_activate_event_callbacks,
#if FL_INCLUDE_VERSION >= 87
		fl_winfocus
#endif
};

typedef void (*FltFltFLOFunc)(FL_OBJECT *, float *, float *);

static FltFltFLOFunc	flt_flt_FLO_funcs[] = {
		fl_get_xyplot_xbounds,
		fl_get_xyplot_xmapping,
		fl_get_xyplot_ybounds,
		fl_get_xyplot_ymapping,
#if FL_INCLUDE_VERSION >= 87
		fl_get_counter_step,
		fl_get_scrollbar_increment,
		fl_get_scrollbar_bounds,
		fl_get_slider_increment
#endif
};

typedef void (*DblDblFLOFunc)(FL_OBJECT *, double *, double *);

static DblDblFLOFunc	dbl_dbl_FLO_funcs[] = {
		fl_get_dial_bounds,
		fl_get_positioner_xbounds,
		fl_get_positioner_ybounds,
		fl_get_slider_bounds,
		fl_get_counter_bounds
};

typedef double (*DblFLOFunc)(FL_OBJECT *);

static DblFLOFunc	dbl_FLO_funcs[] = {
		fl_get_timer,
		fl_get_counter_value,
		fl_get_dial_value,
		fl_get_positioner_xvalue,
		fl_get_positioner_yvalue,
		fl_get_slider_value,
#if FL_INCLUDE_VERSION >= 87
		fl_get_scrollbar_value
#endif
};

typedef void (*VoidFLODblFunc)(FL_OBJECT *, double);

static VoidFLODblFunc	void_FLO_dbl_funcs[] = {
		fl_set_timer,
		fl_set_counter_value,
		fl_set_dial_step,
		fl_set_dial_value,
		fl_set_positioner_xstep,
		fl_set_positioner_xvalue,
		fl_set_positioner_ystep,
		fl_set_positioner_yvalue,
		fl_set_slider_size,
		fl_set_slider_step,
		fl_set_slider_value,
#if FL_INCLUDE_VERSION >= 87
		fl_set_scrollbar_value,
		fl_set_scrollbar_size,
		fl_set_scrollbar_step,
#endif
};

typedef void (*VoidFLODblDblFunc)(FL_OBJECT *, double, double);

static VoidFLODblDblFunc	void_FLO_dbl_dbl_funcs[] = {
		fl_scale_object,
		fl_set_counter_bounds,
		fl_set_counter_step,
		fl_set_dial_angles,
		fl_set_dial_bounds,
		fl_set_positioner_xbounds,
		fl_set_positioner_ybounds,
		fl_set_slider_bounds,
		fl_set_chart_bounds,
		fl_set_xyplot_xbounds,
		fl_set_xyplot_ybounds,
		fl_set_slider_increment,
#if FL_INCLUDE_VERSION >= 87
		fl_set_scrollbar_increment,
		fl_set_scrollbar_bounds
#endif
};

typedef void (*VoidFLOIntCharFunc)(FL_OBJECT *, int, const char *);

static VoidFLOIntCharFunc	void_FLO_int_char_funcs[] = {
		fl_insert_browser_line,
		fl_replace_browser_line,
		fl_replace_choice,
		fl_replace_menu_item,
		fl_set_choice_item_shortcut,
		fl_set_menu_item_shortcut,
#if FL_INCLUDE_VERSION >= 87
		fl_set_xyplot_key
#endif
};

typedef void (*VoidFLOCharFunc)(FL_OBJECT *, const char *);

static VoidFLOCharFunc	void_FLO_char_funcs[] = {
		fl_add_browser_line,
		fl_addto_browser,
		fl_set_bitmap_file,
		fl_set_bitmapbutton_file,
		fl_set_input,
		fl_set_object_label,
		fl_set_pixmap_file,
		fl_set_choice_text,
		fl_set_menu,
		fl_delete_xyplot_text,
		fl_addto_browser_chars,
#if FL_INCLUDE_VERSION >= 87
/*
 ************** Menubar has been removed at 0.87.3
		fl_set_menubar,
 */
		NULL,
/*
 **************
 */
		fl_delete_folder_byname,
		fl_set_folder_byname,
#endif
};

typedef void (*VoidFLOCharCharFunc)(FL_OBJECT *, const char *, const char *);

static VoidFLOCharCharFunc	void_FLO_char_char_funcs[] = {
		fl_set_xyplot_alphaxtics,
		fl_set_xyplot_alphaytics,
		fl_set_xyplot_fixed_xaxis,
		fl_set_xyplot_fixed_yaxis,
		NULL
};

typedef void (*VoidFLOIntFunc)(FL_OBJECT *, int);

static VoidFLOIntFunc	void_FLO_int_funcs[] = {
		fl_delete_browser_line,
		fl_deselect_browser_line,
		fl_select_browser_line,
		fl_set_browser_fontsize,
		fl_set_browser_fontstyle,
		NULL,                   /* was fl_set_browser_leftslider  */
		fl_set_browser_specialkey,
		fl_set_browser_topline,
		fl_set_browser_vscrollbar,
		fl_set_button,
		fl_set_input_maxchars,
		fl_set_input_return,
		fl_set_input_scroll,
		fl_set_input_selected,
		fl_set_object_automatic,
		fl_set_object_boxtype,
		fl_set_object_bw,
		fl_set_object_dblbuffer,
		fl_set_object_lalign,
		fl_set_object_lsize,
		fl_set_object_lstyle,
		fl_set_object_return,
		NULL,                 /* was fl_set_canvas_decoration */
		fl_set_canvas_depth,
		fl_canvas_yield_to_shortcut,
		fl_delete_choice,
		fl_delete_menu_item,
		fl_set_choice,
		fl_set_choice_align,
		fl_set_choice_fontsize,
		fl_set_choice_fontstyle,
		fl_set_menu_popup,
		fl_show_menu_symbol,
		(VoidFLOIntFunc)fl_set_object_resize,
		(VoidFLOIntFunc)fl_set_object_shortcutkey,
		fl_set_counter_precision,
		fl_set_counter_return,
		fl_set_dial_cross,
		fl_set_dial_return,
		fl_set_positioner_return,
		fl_set_slider_precision,
		fl_set_slider_return,
		fl_delete_xyplot_overlay,
		fl_set_chart_autosize,
		fl_set_chart_maxnumb,
		fl_set_xyplot_fontsize,
		fl_set_xyplot_fontstyle,
		fl_set_xyplot_inspect,
		fl_set_xyplot_return,
		fl_set_xyplot_symbolsize,
		fl_set_chart_lstyle,
		fl_set_chart_lsize,
		fl_set_dial_direction,
		fl_set_input_hscrollbar,
		fl_set_input_vscrollbar,
		fl_set_input_xoffset,
		fl_set_input_topline,
		fl_set_timer_countup,
		fl_set_xyplot_xgrid,
		fl_set_xyplot_ygrid,
		fl_set_browser_hscrollbar,
		fl_set_pixmapbutton_focus_outline,
#if FL_INCLUDE_VERSION >= 87
		fl_delete_folder_bynumber,
		fl_set_folder_bynumber,
		fl_set_scrollbar_return,
		fl_set_clock_ampm,
		fl_show_browser_line
#endif
};

typedef void (*VoidFLOIntIntFunc)(FL_OBJECT *, int, int);

static VoidFLOIntIntFunc	void_FLO_int_int_funcs[] = {
		(VoidFLOIntIntFunc)fl_set_object_gravity,
		fl_set_browser_line_selectable,
		fl_set_input_color,
		fl_set_input_cursorpos,
		fl_set_input_selected_range,
		(VoidFLOIntIntFunc)fl_set_choice_item_mode,
		(VoidFLOIntIntFunc)fl_set_menu_item_mode,
		fl_set_xyplot_overlay_type,
		fl_set_xyplot_xtics,
		fl_set_xyplot_ytics,
		fl_set_input_format,
		fl_set_input_scrollbarsize,
		fl_set_xyplot_linewidth,
		fl_set_browser_scrollbarsize,
#if FL_INCLUDE_VERSION >= 87
		fl_set_xyplot_key_font
#endif
};

typedef int (*IntVoidFunc)(void);

static IntVoidFunc	int_void_funcs[] = {
		fl_get_border_width,
		fl_get_coordunit,
		fl_get_visual_depth,
		fl_get_linewidth,
		fl_get_linestyle,
		fl_get_drawmode,
		fl_end_all_command,
#if FL_INCLUDE_VERSION >= 87
		fl_current_pup
#endif
};

typedef int (*IntIntFunc)(int);

static IntIntFunc	int_int_funcs[] = {
		fl_use_fselector,
		fl_XEventsQueued,
		fl_dopup,
		fl_setpup_maxpup,
		fl_show_colormap,
		fl_setpup_fontsize,
		fl_setpup_fontstyle,
#if FL_INCLUDE_VERSION >= 87
		fl_getpup_items,
		fl_setpup_default_bw
#endif
};

typedef int (*IntIntIntFunc)(int,int);

static IntIntIntFunc	int_int_int_funcs[] = {
		(IntIntIntFunc)fl_getpup_mode,
		fl_mode_capable,
		fl_get_char_width
};

typedef void (*VoidIntFunc)(int);

static VoidIntFunc	void_int_funcs[] = {
		fl_set_app_nomainform,
		fl_set_border_width,
		fl_set_color_leak,
		fl_set_coordunit,
		fl_show_errors,
		fl_signal_caught,
		fl_app_signal_direct,
		fl_freepup,
		fl_hidepup,
		fl_initial_winstate,
		fl_showpup,
		fl_disable_fselector_cache,
		fl_set_fselector_border,
		fl_set_fselector_placement,
		fl_drawmode,
		fl_linestyle,
		fl_linewidth,
		fl_ringbell,
		fl_show_command_log,
		fl_set_fselector_fontsize,
		fl_set_fselector_fontstyle,
		fl_set_dirlist_sort,
#if FL_INCLUDE_VERSION >= 88
		fl_set_scrollbar_type
#endif
};

typedef void (*VoidIntIntFunc)(int, int);

static VoidIntIntFunc	void_int_int_funcs[] = {
		fl_set_font,
		fl_set_graphics_mode,
		fl_set_ul_property,
		fl_setpup_bw,
		fl_setpup_position,
		fl_setpup_selection,
		fl_setpup_shadow,
		fl_setpup_softedge,
		fl_set_goodies_font,
		fl_set_oneliner_font,
		fl_set_command_log_position
};

typedef void (*VoidIIIFunc)(int, int, int);

static VoidIIIFunc	void_iii_funcs[] = {
		fl_setpup_submenu,
		fl_setpup_pad,
		fl_set_pixmap_colorcloseness
};

typedef void (*VoidVoidFunc)(void);

static VoidVoidFunc	void_void_funcs[] = {
		fl_activate_all_forms,
		fl_deactivate_all_forms,
		fl_end_form,
		fl_finish,
		fl_freeze_all_forms,
		fl_unfreeze_all_forms,
		fl_unset_clipping,
		fl_noborder,
		fl_transient,
		fl_hide_oneliner,
		fl_invalidate_fselector_cache,
		fl_refresh_fselector,
		fl_endline,
		fl_reset_vertex,
		fl_endclosedline,
		fl_endpolygon,
		fl_hide_fselector,
		fl_hide_command_log,
		fl_clear_command_log,
#if FL_INCLUDE_VERSION >= 87
		fl_hide_message,
		fl_hide_question,
		fl_hide_alert,
		fl_hide_input,
		fl_hide_choice,
#endif
};

typedef void (*TXYWHCFunc)(int, FL_Coord, FL_Coord,
				FL_Coord, FL_Coord, FL_COLOR);
static TXYWHCFunc       txywhc_funcs[] = {
		fl_roundrectangle,
		fl_rectangle,
		fl_oval
};

typedef void (*XYWHCFunc)(FL_Coord, FL_Coord,
			  FL_Coord, FL_Coord, FL_COLOR);
static XYWHCFunc        xywhc_funcs[] = {
		fl_line,
		fl_ovalbound,
		fl_rectbound
};

typedef void (*TXYWHCIFunc)(int, FL_Coord, FL_Coord,
				FL_Coord, FL_Coord, FL_COLOR, int);
static TXYWHCIFunc      txywhci_funcs[] = {
		fl_drw_box,
		fl_drw_checkbox,
		fl_drw_frame
};

typedef void (*TXYWHCIISFunc)(int, FL_Coord, FL_Coord, FL_Coord, FL_Coord, 
				FL_COLOR, int, int, char *);
static TXYWHCIISFunc      txywhciis_funcs[] = {
		fl_drw_text,
		fl_drw_text_beside
};

typedef void (*cbFLOcbFunc)(FLObject *, void *);
static cbFLOcbFunc      cb_FLO_cb_funcs[] = {
		(cbFLOcbFunc)fl_set_object_posthandler, 
		(cbFLOcbFunc)fl_set_object_prehandler, 
		(cbFLOcbFunc)fl_set_input_filter, 
		(cbFLOcbFunc)fl_set_counter_filter,
		(cbFLOcbFunc)fl_set_slider_filter,
		(cbFLOcbFunc)fl_set_timer_filter
};
void *cb_FLO_cb_handlers[] = {
		(void *)process_object_posthandler,
		(void *)process_object_prehandler,
		(void *)process_input_filter,
		(void *)process_counter_filter,
		(void *)process_slider_filter,
		(void *)process_timer_filter
};

typedef void (*cbFLFcbParmFunc)(FLForm *, SV *, SV *);
static cbFLFcbParmFunc      cb_FLF_cb_parm_funcs[] = {
		(cbFLFcbParmFunc)fl_set_form_callback, 
		(cbFLFcbParmFunc)fl_set_form_atactivate, 
		(cbFLFcbParmFunc)fl_set_form_atdeactivate, 
		(cbFLFcbParmFunc)fl_set_form_atclose 
};

void *cb_FLF_cb_parm_handlers[] = {
		(void *)process_form_callback,
		(void *)process_form_atactivate,
		(void *)process_form_atdeactivate,
		(void *)process_form_atclose
};

/******************************************************************************
 ******************************************************************************
 ******************************************************************************

  	T H E    C A L L B A C K    M E C H A N I S M

 The structures, fields and functions defined below are the guts of the
 callback mechanism. Basically a perl subroutine can be registered as a 
 callback routine in exactly the same way as in a C program that uses the
 XForms library. In order to make this possible, various different schemes
 are utilized so that most of the callbacks that can be registered with
 the XForms library are available to perl programs. The basic idea is that
 the SV pointer of the perl subroutine is saved in an appropriate place
 and a generic C subroutine is registered with the XForms library. When this
 routine is called-back, it finds the SV pointer of the appropriate perl
 subroutine and invokes it.
 
 ******************************************************************************
 ******************************************************************************
 *****************************************************************************/

/*
 * Application atclose, idle, and event callback pointers
 * (All this just to get a generic piece of code that works
 * off alias numbers for slightly different routines!!!)
 */

static SV *appl_cb[] = {
	NULL,
	NULL,
	NULL
};

#define APPLCB_atclose 	0
#define APPLCB_idle 	1
#define APPLCB_event 	2

typedef int (*AtcloseStub)(FLForm *, void *);
typedef int (*EventStub)(XEvent *, void *);
typedef int (*ApplStub)(void *, void *);

static 	ApplStub	appl_stubs[] = {
		(ApplStub)process_atclose,
		(ApplStub)process_idle_callback,
		(ApplStub)process_event_callback
};

typedef int (*ApplCB) (void*, void *);
typedef void (*SetApplCB)(ApplCB, void *);

static 	SetApplCB	set_appl_cb_funcs[] = {
		(SetApplCB)fl_set_atclose,
		(SetApplCB)fl_set_idle_callback,
		(SetApplCB)fl_set_event_callback
};

/*
 * Anchor for io callback routines
 */
static io_data *	io_cb = NULL;

/*
 * Anchor for signal callback routines
 */
static sig_data *	sig_cb = NULL;

/*
 * Anchor for timeout callback routines
 */
static to_data *	to_cb   = NULL;
static int          n_to_cb = 0;
#define TO_CB_INCR  5

int get_free_to(void)
{
	int i;
	to_data *new_to_cb;

	for (i = 0; i < n_to_cb; ++i)
	{
		if (!to_cb[i].in_use)
			break;
	}

	if (i >= n_to_cb)
	{
		/*
	     * Either no cb data or all are in use
	     */
		i = n_to_cb;
		new_to_cb = (to_data*)X4Pcalloc(n_to_cb + TO_CB_INCR, sizeof(to_data));
		if (new_to_cb == NULL)
			croak("Timeout callback data allocation error");

		if (n_to_cb > 0)
		{
			memcpy(new_to_cb, to_cb, n_to_cb * sizeof(to_data));
			X4Pfree(to_cb);
		}
		to_cb = new_to_cb;
		n_to_cb += TO_CB_INCR;
	}
	return i;
}

void free_to(int time_out_id)
{
	int i;

	for (i = 0; i < n_to_cb; ++i)
	{
		if (to_cb[i].time_out_id == time_out_id)
		{
			to_cb[i].in_use = 1;
			break;
		}
	}
	return;
}
	
	
/*
 * One slot for each XEvent - when a callback is registered, we
 * chain a cb_data structure off the appropriate slot. XErrorEvent
 * is limited to one callback routine due to the unpredicatable
 * nature of its XID variable - but that may be taken care of by
 * XForms itself.
 */
static cb_data **      ecb_data = NULL;

/*
 * This function returns the above pointer, calloc-ing the necessary
 * storage if the pointer is null
 */
static cb_data **
get_cb_data()
{
	if (ecb_data == NULL)
		ecb_data = (cb_data **)X4Pcalloc(LASTEvent, sizeof(cb_data **));
	if (ecb_data == NULL)
		croak("Event callback data allocation error");
	return ecb_data;
}

#if FL_INCLUDE_VERSION >= 87

/*
 * fl_set_error_handler callback and fl_set_error_logfp
 */
static SV   *error_handler = NULL;
static FILE *error_log     = NULL;

/*
 * XYPlot symbol drawers are post 0.86
 */

SV **alloc_overlay_data(FLObject *object, int overlay)
{
	object_data *od = get_object_data(object);
	int i;
	SV ** ol_data;
	int max_ol, min_ol = 
		(overlay < od->od_max_overlays ? overlay : od->od_max_overlays);
		
	if (od->od_max_overlays == 0)
		max_ol = 
			(overlay > FL_MAX_XYPLOTOVERLAY ? overlay : FL_MAX_XYPLOTOVERLAY);
	else
		max_ol = 
			(od->od_max_overlays > overlay ? od->od_max_overlays : overlay);

	if (od->od_max_overlays != max_ol || od->od_xyplot_symbol == NULL)
	{
		fl_set_xyplot_maxoverlays(object, max_ol);

		ol_data = (SV **)X4Pcalloc(max_ol, sizeof(SV *));
		if (ol_data == NULL)
			croak("XYplot overlay data allocation error");
		if (od->od_xyplot_symbol != NULL)
		{
			for (i = 0; i < min_ol; ++i)
				ol_data[i] = od->od_xyplot_symbol[i];
			for (; i < od->od_max_overlays; ++i)
				fl_set_xyplot_symbol(object, i, NULL);
			X4Pfree(od->od_xyplot_symbol);
		}
		od->od_xyplot_symbol = ol_data;
		od->od_max_overlays = max_ol;
	}
	return 	od->od_xyplot_symbol;
}

/*
 * PUP callbacks are only supported post 0.86
 */

/*
 * Pup callback anchor
 */
static int		dummy_pup   = -1;
static int		pup_count   = 0;
static pupm_cb	*pup_anchor = NULL;

/*
 * Routines to manage pup callback chain
 */
static pupm_cb *
get_pup_menu(int id, pupm_cb **prev) 
{
    /*
     * Keep track of previous pupm_cb we looked at so we can
     * manage the chain correctly
     */
	pupm_cb 	*pupm = pup_anchor, *pupm_prev = (pupm_cb *)&pup_anchor;
	while(pupm && pupm->id != id)
	{
		pupm_prev = pupm;
		pupm = pupm->next;
	}
	if (prev != NULL)
		*prev = pupm_prev;
	return pupm;
}

/*
 * Change the the pup menu id from the first par to the second
 */
void
change_pupm_id(int old_id, int new_id)
{
	pupm_cb *pupm = get_pup_menu(old_id, NULL);
	if (pupm != NULL)
		pupm->id = new_id;
}

static pupm_cb *
get_current_pup(void)
{
	pupm_cb		*pupm;
	if ((pupm = get_pup_menu(fl_current_pup(), NULL)) == NULL)
		croak("Pup menu callback: no active callback ");
	return pupm;
}

static pupm_cb *
add_pup_menu(int id) 
{
	pupm_cb 	*pupm = get_pup_menu(id, NULL);
	if (pupm == NULL) 
	{
		pupm = X4Pcalloc(1, sizeof(pupm_cb));
		pupm->next = pup_anchor;
		pup_anchor = pupm;
		pupm->id = id;
	}
	return pupm;
}

void
del_pup_menu(int id) 
{
	pupm_cb 	*pupm, *pupm_prev;
	pupi_cb 	*pupi, *pupd;

	pupm = get_pup_menu(id, &pupm_prev);
	if (pupm != NULL) 
	{
		pupi = pupm->items;
		while (pupd = pupi) 
		{
			pupi = pupi->next;
			X4Pfree((void *)pupd);
		}
		pupm_prev->next = pupm->next;
		X4Pfree((void *)pupm);	
	}
}

static pupi_cb *
get_pup_item(int mid, int iid) 
{
	pupm_cb 	*pupm = pup_anchor;
	pupi_cb		*pupi = NULL;

	if ((pupm = get_pup_menu(mid, NULL)) != NULL)
	{
		pupi = pupm->items;
		while(pupi && pupi->id != iid)
			pupi = pupi->next;
	}
	return pupi;
}

static pupi_cb *
add_pup_item(int mid, int iid) 
{
	pupm_cb 	*pupm = get_pup_menu(mid, NULL);
	pupi_cb 	*pupi;
	if (pupm == NULL) 
	{
		pupm = add_pup_menu(mid);
		pupm->cb = NULL;
		pupm->ecb = NULL;
		pupm->lcb = NULL;
	}

	if ((pupi = get_pup_item(mid, iid)) == NULL) 
	{
		pupi = X4Pcalloc(1, sizeof(pupi_cb));
		pupi->next = pupm->items;
		pupm->items = pupi;
		pupi->id = iid;
	}
	return pupi;
}

static int
process_pupm_callback(int ite_rc)
{
	int		retint;

	/*
	 * Generic PUP menu callback
	 */
	call_perl_callback(get_current_pup()->cb, 
			"Pup menu",
			CB_RET_INT, (void *)&retint,
			"i",
			ite_rc);
	return retint;
}
	
static void
process_pupm_entercb(int item, void *parm)
{
	/*
	 * Generic PUP menu enter callback
	 */
	call_perl_callback(get_current_pup()->ecb, 
			"Pup enter menu",
			CB_FALSE, NULL,
			"iS",
			item, parm);
}
	
static void
process_pupm_leavecb(int item, void *parm)
{
	/*
	 * Generic PUP menu leave callback
	 */
	call_perl_callback(get_current_pup()->lcb, 
			"Pup leave menu",
			CB_FALSE, NULL,
			"iS",
			item, parm);
}
	
static int
process_pupi_callback(int item)
{
	pupi_cb 	*pupi;
	int			retint;
	/*
   	 * If current pupm is -1, we have a problem
	 */

	if ((pupi = get_pup_item(fl_current_pup(), item)) == NULL)
		croak("Pup item callback: no active callback ");

	call_perl_callback(pupi->cb, 
			"Pup item",
			CB_RET_INT, (void *)&retint,
			"i",
			item);
	return retint;
}

#endif
	
/*
 * fselector callback mechanisms
 */

static int		current_fsel = 1;

/*
 * This handles fselector application buttom callback routines
 */
static facb_data **      fcb_anchor = NULL;
static facb_data **      get_facb_data(int fsel){

	if (!fcb_anchor)
		fcb_anchor = (facb_data**)X4Pcalloc(FL_MAX_FSELECTOR+1,sizeof(facb_data));
	if (!fcb_anchor)
		croak("Allocation error - fselector callback array");
	return &fcb_anchor[fsel];
}

/*
 * These routines are registered with the XForms library as the real callbacks
 * when the perl program requires a callback. They find the pointer to the
 * perl subroutine and call it via a generic perl-subroutine-invoker that does
 * all the specific gunge of setting up the perl stack, calling the subroutine
 * and returning a value (only an int return value is allowed if any is
 * required).
 */

static int
process_fselector_callback(string,parm)
const char *    string;
void *          parm;
{
	/*
	 * fselector callback processor
	 */

	int		retint;

	call_perl_callback((get_form_data(fl_get_fselector_form()))->fd_fselcallback, 
			"Fselector",
			CB_RET_INT, (void *)&retint,
			"sS",
			string, parm);
	return retint;
}

static void
process_fselapp_callback(parm)
void *          parm;
{
	/*
	 * Generic fselector application button callback
	 * the parm is really a pointer to the facb_data structure!!
	 */

	call_perl_callback(((facb_data *)parm)->callback, "Fselector button",
			   CB_FALSE, NULL,
			   "S",
			   ((facb_data *)parm)->parm);
}

static int
process_idle_callback(event,parm)
XEvent *        event;
void *          parm;
{

	/*
	 * Generic idle callback
	 */
	int		retint;

	call_perl_callback(appl_cb[APPLCB_idle], "User idle",
				  CB_RET_INT, (void *)&retint,
				  "eS",
				  event,parm);
		return retint;
}

static void
process_signal_callback(sgnl,parm)
int		sgnl;
void 	*parm;
{

	/*
	 * Generic signal callback
	 */

	call_perl_callback(((sig_data *)parm)->callback, "Signal",
			   CB_FALSE, NULL, 
			   "iS", 
			   sgnl,((sig_data *)parm)->parm);
}

static int
process_form_raw_callback(form,xevent)
FLForm * 	form;
void *		xevent;
{
	/*
	 * Raw callback processor
	 */

	int		retint;

	call_perl_callback((get_form_data(form))->fd_rawcallback, 
		"Form raw",
		CB_RET_INT, (void *)&retint, 
		"Fe", 
		form, xevent);
		return retint;
}    

static int
process_atclose(form,parm)
FLForm * 	form;
void *		parm;
{
	/*
	 * Generic at-close callback 
	 */
	int		retint;

	call_perl_callback(appl_cb[APPLCB_atclose], 
		"Application atclose",
		CB_RET_INT, (void *)&retint, 
		"FS", 
		form, parm);
		return retint;
}    

static int
process_form_atclose(form,parm)
FLForm * 	form;
void *		parm;
{
	/*
	 * Generic form at-close callback
	 */

	int		retint;

	call_perl_callback((get_form_data(form))->fd_atclose, 
		"Form atclose",
		CB_RET_INT, (void *)&retint, 
		"FS", 
		form, parm);
		return retint;
}    

static void
process_object_callback(object, parm)
FLObject * 	object;
long		parm;
{
	/*
	 * Generic object callback
	 */

	call_perl_callback((get_object_data(object))->od_callback, 
		"Object",
		CB_FALSE, NULL, 
		"Ol", 
		object, parm);
}    

static int
process_input_filter(object, parm1, parm2, parm3)
FLObject * 	object;
const char *	parm1;
const char *	parm2;
int				parm3;
{

	/*
	 * Generic input filter process
	 */

	int		retint;

	call_perl_callback((get_object_data(object))->od_input_filter, 
		"Input filter",
		CB_RET_INT, (void *)&retint, 
		"Ossi", 
		object, parm1, parm2, parm3);
		return retint;
}    

static char *
process_timer_filter(object, parm1)
FLObject * 	object;
double		parm1;
{
	/*
	 * Generic timer filter process
	 */

	char *		retstr;

	call_perl_callback((get_object_data(object))->od_timer_filter, 
		"Timer filter",
		CB_RET_STR, (void *)&retstr, 
		"Od", 
		object, parm1);
		return retstr;
}    

#if FL_INCLUDE_VERSION >= 87

void
process_xyplot_symbol(object, ol, points, pts, wd, ht)
FLObject * 	object;
int		ol;
FL_POINT *	points;
int		pts;
int		wd;
int		ht;
{
	/*
	 * Generic xyplot point drawing process
	 */

	call_perl_callback(((get_object_data(object))->od_xyplot_symbol)[ol], 
		"XYplot symbol",
		CB_FALSE, NULL, 
		"OiiinP", 
		object, ol, wd, ht, pts, points);

}    

void
process_error_handler(const char *where, const char *format, ...)
{
	/*
	 * Generic error handler
	 */

	char fmtd_str[1024];
    va_list arg_ptr;

	va_start(arg_ptr, format);
    vsnprintf(fmtd_str, 1024, format, arg_ptr);
    va_endt(arg_ptr);

	call_perl_callback(error_handler, 
		"Error handler",
		CB_FALSE, NULL, 
		"ss", 
		where, fmtd_str);

}    
#endif

static void
process_brdbl_callback(object, parm)
FLObject * 	object;
long		parm;
{
	/*
	 * Generic browser double-click callback
	 */

	call_perl_callback((get_object_data(object))->od_brdbl_callback, 
		"Browser double-click",
		CB_FALSE, NULL, 
		"Ol", 
		object, parm);
}    

static void
process_form_callback(object,parm)
FLObject * 	object;
void *		parm;
{
	/*
	 * Generic form callback
	 */
	call_perl_callback((get_form_data(object->form))->fd_callback, 
		"Form",
		CB_FALSE, NULL, 
		"OS", 
		object, parm);
}    

static void
process_form_atactivate(form,parm)
FLForm * 	form;
void *		parm;
{
	/*
	 * Generic form at-activate callback
	 */

	call_perl_callback((get_form_data(form))->fd_atactivate, 
		"Form atactivate",
		CB_FALSE, NULL, 
		"FS", 
		form, parm);
}    

static void
process_form_atdeactivate(form,parm)
FLForm * 	form;
void *		parm;
{
	/*
	 * Generic form at-deactivate callback
	 */

	call_perl_callback((get_form_data(form))->fd_atdeactivate, 
		"Form atdeactivate",
		CB_FALSE, NULL, 
		"FS", 
		form, parm);
}    

static int
process_make_handle(object,event,x,y,int4,xevent)
FLObject * 	object;
int			event;
FL_Coord	x;
FL_Coord	y;
int			int4;
void *		xevent;
{
	/*
	 * Generic make object handle
	 */

	int		retint;

	call_perl_callback((get_object_data(object))->od_makehandler, 
		"Make object",
		CB_RET_INT, (void *)&retint, 
		"Oiiiie", 
		object,event,x,y,int4, xevent);
		return retint;
}    

static int
process_free_handle(object,event,x,y,int4,xevent)
FLObject *  object;
int			event;
FL_Coord	x;
FL_Coord	y;
int			int4;
void *		xevent;
{
	/*
	 * Generic free object handler
	 */

	int		retint;

	call_perl_callback((get_object_data(object))->od_freehandler, 
		"Create Free object",
		CB_RET_INT, (void *)&retint,
		"Oiiiie",
		object,event,x,y,int4, xevent);
		return retint;
}

static int
process_object_prehandler(object,event,x,y,int4,xevent)
FLObject * 	object;
int			event;
FL_Coord	x;
FL_Coord	y;
int			int4;
void *		xevent;
{
	/*
	 * Generic object pre-handle
	 */

	int		retint;

	call_perl_callback((get_object_data(object))->od_prehandler, 
		"Object pre-handler",
		CB_RET_INT, (void *)&retint, 
		"Oiiiie", 
		object,event,x,y,int4, xevent);
		return retint;
}    

static int
process_object_posthandler(object,event,x,y,int4,xevent)
FLObject * 	object;
int			event;
FL_Coord	x;
FL_Coord	y;
int			int4;
void *		xevent;
{
	/*
	 * Generic object post-handle
	 */

	int		retint;

	call_perl_callback((get_object_data(object))->od_posthandler, 
		"Object post-handler",
		CB_RET_INT, (void *)&retint, 
		"Oiiiie", 
		object,event,x,y,int4, xevent);
		return retint;
}    

static void
process_timeout_callback(time_out_id,parm)
int  		time_out_id;
void *		parm;
{
	/*
	 *  Timeout callback
	 */

	to_data	*this = &to_cb[(int)parm];
	call_perl_callback(this->callback, 
		"Timeout",
		CB_FALSE, NULL, 
		"iS", 
		time_out_id,this->parm);

	/*
	 * And remove the timeout (since xforms will
	 * remove its copy of the timeout, we must too)
	 */
	this->in_use = 0;
}    

static void
process_io_event_callback(fd,parm)
int  		fd;
void *		parm;
{
	/*
	 *  IO event callback
	 */

	call_perl_callback(((io_data *)parm)->callback, "IO event",
			  CB_FALSE, NULL, 
			   "SS", 
			   ((io_data *)parm)->fh,((io_data *)parm)->parm);
}    

static int
process_event_callback(event,parm)
XEvent *        event;
void *          parm;
{
	/*
	 * Generic XEvent callback
	 */
	int		retint;

	call_perl_callback(appl_cb[APPLCB_event], "User event",
				  CB_RET_INT, (void *)&retint,
				  "eS",
				  event,parm);
		return retint;
}

static const char *
process_counter_filter(object, parm1, parm2)
FLObject *      object;
double          parm1;
int             parm2;
{
	/*
	 * Generic counter filter process
	 */

	char *	retstr;

	call_perl_callback((get_object_data(object))->od_count_filter, 
		"Counter filter",
		CB_RET_STR, (void *)&retstr, 
		"Odi",
		object, parm1, parm2);
		return retstr;
}

static const char *
process_slider_filter(object, parm1, parm2)
FLObject *      object;
double          parm1;
int             parm2;
{
	/*
	 * Generic slider filter process
	 */

	char *	retstr;

	call_perl_callback((get_object_data(object))->od_slider_filter, 
		"Slider filter",
		CB_RET_STR, (void *)&retstr, 
		"Odi",
		object, parm1, parm2);
		return retstr;

}

static int
process_mcp_init(object)
FLObject *      object;
{
	/*
	 * Generic canvas init callback
	 */

	int		retint;

	call_perl_callback((get_object_data(object))->od_mcpinit, 
		"Initialize canvas",
		CB_RET_INT, (void *)&retint,
		"O",
		object);
		return retint;
}

static int
process_mcp_act(object)
FLObject *      object;
{
	/*
	 * Generic canvas activate
	 */

	int		retint;

	call_perl_callback((get_object_data(object))->od_mcpact, 
		"Activate canvas",
		CB_RET_INT, (void *)&retint,
		"O",
		object);
		return retint;
}

static int
process_mcp_clean(object)
FLObject *      object;
{
	/*
	 * Generic canvas cleanup callback
	 */

	int		retint;

	call_perl_callback((get_object_data(object))->od_mcpclean, 
		"Cleanup canvas",
		CB_RET_INT, (void *)&retint,
		"O",
		object);
		return retint;
}

static int
process_canvas_event(object,window,int1,int2,event,parm)
FLObject *  object;
Window		window;
int         int1;
int         int2;
XEvent *    event;
void *      parm;
{
	SV **   canv_event_cbs =
		(get_object_data(object))->od_cevents;
	SV *	object_callback_ptr;
	int		retint;

	if (canv_event_cbs == NULL)
		croak("Canvas event callback routine not set");
	call_perl_callback(canv_event_cbs[event->type], 
		"Canvas event",
		CB_RET_INT, (void *)&retint,
		"OiiieS",
		object,window,int1,int2,event,parm);
		return retint;
}

static int
process_single_event_callback(event,parm)
XEvent *        event;
void *          parm;
{

	/*
	 * Individual XEvent callback
	 */

	int             event_type, retint;
	cb_data *this,  **prev;
	Window          window;

	/*
	 * We only allow one handler for XErrorEvents for
	 * all windows. this is because the XErrorEvent
	 * may not contain a valid window variable
	 */
	window = (event_type = event->type) ?
		event->xany.window : 0;

	prev = &(get_cb_data()[event_type]);
	while ((this = *prev) && this->window != window)
		prev = &(this->next_data);

	call_perl_callback(this->callback, "Xevent",
				  CB_RET_INT, (void *)&retint,
				  "eS",
				  event,parm);
		return retint;
}

static int
process_lose_sel_cb(object, type)
FLObject *	object;
long		type;
{
	/*
	 * Generic lose clipboard selection callback
	 */

	int		retint;

	call_perl_callback((get_object_data(object))->od_losesel, 
		"Lose Selection",
		CB_RET_INT, (void *)&retint,
		"Ol",
		object,type);
		return retint;
}

static int
process_gain_sel_cb(object, type, data, size)
FLObject *	object;
long		type;
const void *data;
long		size;
{
	/*
	 * Generic gain clipboard selection data callback.
	 */
	int		retint;

	call_perl_callback((get_object_data(object))->od_gainsel, 
		"Gain Selection Data",
		CB_RET_INT, (void *)&retint,
		"Olsl",
		object,type,data,size);
		return retint;
}

/*
 * This function does the real perl-specific stuff involved in calling
 * a perl subroutine registered as a callback.
 */
static void
call_perl_callback(SV *callback, char * cbname, int outexpct, void *outvar, char *parmptrn, ...)
{

	/*
	 * Sets up the perl stack, calls the SUB, returns output if required
	 * This replaces the need for multiple real callback routines.
	 * It accepts a variable length parm list, the first three of
	 * which are required and are:
	 *
	 *      SV *            pointer to perl subroutine to call
	 *      char *	    	character string identifying the callback
	 *      int             integer indicating whether a return value
	 *                      is expected, and what type it is:
	 *							CB_FALSE -	No return value
	 *							CB_RET_INT -    An integer
	 *							CB_RET_STR -	A character string
	 *		void *			Pointer to output variable
	 *      char *          a format string, one character for
	 *                      each parm to the perl sub, the chars
	 *                      being:
	 *								d - a double float value
     *                              n - a number indicating that the
     *                                  next parm is an array pointer
     *                              P - an FL_POINT
	 *                              p - a pointer
	 *                              i - an integer
	 *                              j - a short integer
	 *                              l - a long integer
	 *                              I - an IV
	 *								S - an SV
	 *                              s - a string
	 *                              e - an XEvent perl object
	 *                              F - an FL_FORM perl object
	 *                              O - an FL_OBJECT perl object
	 *
	 * the rest of the parms are the arguments to the perl subroutine.
	 */

	dSP ;

	va_list ap;
    FL_POINT *point;
	int     count, ival, array_count;
	long    lval;
	IV      Ival;
	double  dval;
	void    *pval;
	char    *sval, **psval;
	SV      *tempsv, *Sval;
	form_data *fd;
	object_data *od;
	FLForm  *form;
	FLObject *object;
	ENTER;
	SAVETMPS;
	PUSHMARK(sp) ;

	if (SvNULL(callback))
		croak("%s callback routine not set", cbname);

	va_start(ap, parmptrn);
	while(*parmptrn) {
		switch(*parmptrn) {

			case 'n':
					array_count = va_arg(ap, int);
                    break;
            case 'P':
                    point = va_arg(ap, FL_POINT *);
                    while (array_count > 0)
                    {
						XPUSHs(sv_2mortal(newSViv((IV)point->x)));
						XPUSHs(sv_2mortal(newSViv((IV)point->y)));
						array_count--;
						point++;
                    }
                    break;
                         
			case 'p':
					pval = va_arg(ap, void *);
					XPUSHs(sv_2mortal(newSViv((IV)pval)));
					break;
			case 'I':
					Ival = va_arg(ap, IV);
					XPUSHs(sv_2mortal(newSViv((IV)Ival)));
					break;

			case 'S':
					Sval = va_arg(ap, SV *);
					XPUSHs(Sval);
					break;

			case 'A':
					Sval = va_arg(ap, SV *);
					XPUSHs(sv_2mortal(newRV_inc(Sval)));
					break;

			case 'd':
					dval = va_arg(ap, double);
					XPUSHs(sv_2mortal(newSVnv(dval)));
					break;

			case 'i':
					ival = va_arg(ap, int);
					XPUSHs(sv_2mortal(newSViv((IV)ival)));
					break;

			case 'j':
					ival = va_arg(ap, short);
					XPUSHs(sv_2mortal(newSViv((IV)ival)));
					break;

			case 'l':
					lval = va_arg(ap, long);
					XPUSHs(sv_2mortal(newSViv((IV)lval)));
					break;

			case 's':
					sval = va_arg(ap, char *);
					if (sval == NULL)
						XPUSHs(&sv_undef);
					else
						XPUSHs(sv_2mortal(newSVpv(sval,0)));
					break;

			case 'e':
					pval = va_arg(ap, void *);
					tempsv = sv_newmortal();
					sv_setref_iv(tempsv,object_name[X11XEvent],(IV)pval);
					XPUSHs(tempsv);
					break;

			case 'F':
					form = (FLForm *)(va_arg(ap, void *));
					tempsv = bless_form(form);
					XPUSHs(tempsv);
					break;

			case 'O':
					object = (FLObject *)(va_arg(ap, void *));
					tempsv = bless_object(object);
					XPUSHs(tempsv);
					break;

			default:
					croak("Erroneous call to 'call_perl_callback'");
					break;

		}
        if (*parmptrn != 'n')
            array_count = -1;
        ++parmptrn;
	}
	va_end(ap);
	PUTBACK ;

	count = perl_call_sv(callback, G_SCALAR);

	SPAGAIN;
	if (count > 1)
			croak("Perl callback routine returned incorrectly");
	else if (count == 1) 
	{
		if (outexpct == CB_RET_INT)
			*((int *)outvar) = POPi;
		else if (outexpct == CB_RET_STR) 
		{
			sval = POPp;
			get_buffer(strlen(sval));
			strcpy(temp_str_buf, sval);
			*((char **)outvar) = temp_str_buf;
		}
	}
	PUTBACK;
	FREETMPS;
	LEAVE;

	if (outexpct && !count)
		croak("Perl callback routine returned incorrectly");

	return;
}

/*
 * Attempting to overcome the problem of casting
 * consts in sv_setpv
 */
static void     sv_setpv_c(SV* sv, const char* ptr)
{
	sv_setpv(sv,(char *)ptr);
}

/*
 * Check if an SV conatins a null value: Its either undefined, the
 * empty string or the integer 0 
 */
static int
SvNULL(SV *sv)
{
	if (sv == NULL || (!SvOK(sv)) || (SvIOKp(sv) && SvIV(sv) == 0)
	|| (SvPOKp(sv) && SvCUR(sv) == 0))
		return 1;
	return 0;
}

/*
 * Callback pointer maintenance functions
 */
static void
savesv(SV **old_cb, SV *new_cb)
{
	if (*old_cb == NULL)
		*old_cb = newSVsv(new_cb);
	else 
		SvSetSV(*old_cb,new_cb);
}

static void
return_save_sv(SV **stack, SV **old_cb, SV *new_cb) {

		*stack = sv_newmortal();
		if (*old_cb)
				sv_setsv(*stack, *old_cb);
		savesv(old_cb, new_cb);
}

/*
 * Simple reference checker - if the SV * is a reference then either
 * return the special form or object blessed reference or create a
 * new reference, otherwise return the SV * itself. Since objects and
 * forms are the things most often banded around like this, this saves
 * a bit of storage in Perl by NOT creating endless references.
 */
static SV *
get_a_ref(SV *parm)
{
	if (parm != NULL && SvROK(parm))
	{
		if (sv_isa(parm,object_name[X11XformsFLForm]))
			return get_form_data((FLForm*)SvIV((SV*)SvRV(parm)))->po; 
		else if (sv_isa(parm,object_name[X11XformsFLObject]))
			return get_object_data((FLObject*)SvIV((SV*)SvRV(parm)))->po; 
		else 
			return newRV(SvRV(parm));
	}
	else
	{
		return parm;
	}
}
	
/*
 * Special bless macro for forms (ensures comparison of blessed
 * form pointers gives expected results)
 */
static SV *
bless_form(FLForm *f) {

	form_data *     sfd;

		if ((sfd = get_form_data(f))->po == NULL) {
				sfd->po = newSViv(0);
				sv_setref_iv(sfd->po,object_name[X11XformsFLForm],(IV)f);
				SvREFCNT_inc(sfd->po);
		}
	return sfd->po;
}

/*
 * Special bless function for objects (ensures comparison of blessed
 * object pointers gives expected results)
 */
static SV *
bless_object(FLObject *o) {

		object_data *   sod;

		if ((sod = get_object_data(o))->po == NULL) {
				sod->po = newSViv(0);
				sv_setref_iv(sod->po,object_name[X11XformsFLObject],(IV)o);
				SvREFCNT_inc(sod->po);
		}
	return sod->po;
}

/*
 * Space saving blessed 'thing' checker
 */

static IV 
chk_bless(SV * thing, int blesstype) {
	
	if(sv_isa(thing, object_name[blesstype])) 
		return SvIV((SV*)SvRV(thing));
	else
		croak("Argument is not of type %s", object_name[blesstype]);
}

/*
 * This function returns a pointer to the Object-specific callback
 * data structure that is used to hold the Perl subroutine pointers
 * that are registered as callbacks. If the structure doesn't
 * exist for an Object, it callocs it. It is anchored off the
 * OBJECT structure's u_vdata field.
 */

static object_data *
get_object_data(FLObject *object)
{
		if (object->u_vdata == NULL)
				object->u_vdata = X4Pcalloc(1, sizeof(object_data));
		if (object->u_vdata == NULL)
				croak("Object user data allocation error");
		return (object_data *)(object->u_vdata);
}

/*
 * This function returns a pointer to the Form-specific callback
 * data structure that is used to hold the Perl subroutine pointers
 * that are registered as callbacks. If the structure doesn't
 * exist for a Form, it callocs it. It is anchored off the
 * FORM structure's u_vdata field.
 */

static form_data *
get_form_data(FLForm *form)
{
		if (form->u_vdata == NULL)
				form->u_vdata = X4Pcalloc(1, sizeof(form_data));
		if (form->u_vdata == NULL)
				croak("Form user data allocation error");
		return (form_data *)(form->u_vdata);
}

/*
 * Manage the temporary string buffer
 */
static
void	get_buffer(int bufsize){

	if (temp_str_buf_size <= bufsize) {

		if (temp_str_buf != NULL)
			X4Pfree(temp_str_buf);
		if ((temp_str_buf = X4Pcalloc(1, bufsize + 1)) == NULL)
			croak("Unable to get temporary string buffer");
		temp_str_buf_size = bufsize + 1;

	}
}

/*
 * Gracefully dying in the event of a non-supported function being attempted
 */
static 
void	not_implemented(char * funcname) {

	croak("Function %s is not implemented in your version of Xforms",
		funcname);
}
 
/*
 * return true if update, false if not, die of other
 */
static
int	update_field(int items) {

	if (items < 1 || items > 2)
		usage("Structure field access");
	return --items;
}
 
/*
 * Used by the modified boot function. Returns the xsub name constructed by
 * concatenating the package name from the integer with the function name
 * given by the string
 */
static
char *	make_xsub_name(int package, char *xsub)
{

	if (temp_str_buf_size == 0)
		get_buffer(RESBUF);

	temp_str_buf[0] = '\0';
	strcat(temp_str_buf, object_name[package]);
	strcat(temp_str_buf, "::");
	strcat(temp_str_buf, xsub);

	return temp_str_buf;
}

/*
 * Replace the croak macro so that it points the caller to the
 * documentation for usage errors. This is because the default message
 * is misleading when multiple protocols are supported by a single XSUB
 * function
 */
#undef 	croak
#define FL_USAGE	"Usage: %s("
#define FL_DOC_USAGE	"Usage: %s. See Xforms4Perl documentation."

static
void	croak(char * format, ...) {

	char 	message[RESBUF];
	va_list	ap;

	va_start(ap, format);

	/*
 	 * If the first part of the format string reads 
	 * "Usage: %s(" then replace the message. Otherwise
	 * pass it on.
	 */

	if (strncmp(FL_USAGE, format, 10) == 0) {
		vsprintf(message, FL_DOC_USAGE, ap);
	} else {
		vsprintf(message, format, ap);
	}
	va_end(ap);
	Perl_croak(message);
}

/*
 * Croak for usage - function name passed
 */
static
void	usage(char *function)
{
	croak(FL_USAGE, function);
}
/*
 * Space-saving alloc for fl_set_xyplot_data and fl_set_xyplot_overlay
 */
static void
build_xyplot_data(SV **stack, int numpts, float **xfloat, float **yfloat) {

	int	i;

	*xfloat = (float *)X4Pcalloc(2*numpts, sizeof(float));
	if (*xfloat == NULL)
		croak("Failed to get xyplot point storage");
	*yfloat = *xfloat + numpts;

	for (i=0; i<numpts; ++i) {
/****************
 * HEAVILY RELIANT ON PERL IMPLEMENTATION OF STACK!!!
 */
		(*xfloat)[i] = SvNV(stack[(i*2)]);
/****************
 * HEAVILY RELIANT ON PERL IMPLEMENTATION OF STACK!!!
 */
		(*yfloat)[i] = SvNV(stack[(i*2)+1]);

	}
}

/*
 * Space-saving alloc for fl_set_pixmap_data and fl_create_from_pixmap
 */

static char **
build_pixmap_data(SV **stack, int items) {

	STRLEN	strsize, stgsize;
	int	i;
	char	**buffer, **next_ptr, *next_str;
		
	/*
	 * First get the lengths of the strings (adding a null for 
	 * safety!
	 */
	for (i=0; i<items; ++i) {
/****************
 * HEAVILY RELIANT ON PERL IMPLEMENTATION OF STACK!!!
 */
		SvPV(stack[i],strsize);
		stgsize += strsize+1;
	}

	/*
	 * Add in pointer storage and one for a null pointer
	 */
	stgsize += ((items+1) * sizeof(char *));

	/*
	 * get the storage
	 */
	buffer = (char **)X4Pcalloc(1, stgsize);
	if (buffer == NULL)
		croak("fl_set_pixmap_data: failed to get argument storage");
	next_ptr = buffer;
	next_str = (char *)(next_ptr + items + 1);

	/*
  	 * build the storage area
	 */
	for (i=0; i<items; ++i) {
		*next_ptr = next_str;
/****************
 * HEAVILY RELIANT ON PERL IMPLEMENTATION OF STACK!!!
 */
		memcpy(next_str,SvPV(stack[i],strsize),strsize);
		next_str[strsize] = '\0';
		next_str += strsize+1;
		next_ptr++;
	}

	return buffer;
}

/***************************************************************************	
 ***************************************************************************	
 ***************************************************************************	
 ***************************************************************************	
 ***************************************************************************	
 ***************************************************************************	
 ***************************************************************************	
 *
 * The rest is XSUB code to implement the interface between PERL and XForms
 *
 ***************************************************************************	
 ***************************************************************************	
 ***************************************************************************	
 ***************************************************************************	
 ***************************************************************************	
 ***************************************************************************	
 */

MODULE = X11::Xforms		PACKAGE = X11::Xforms

PROTOTYPES: DISABLE

I32 
fl_screen()
	PROTOTYPE:
	ALIAS:
		fl_scrh = 1
		fl_scrw = 2
		fl_vmode = 3
		fl_display = 4
		fl_mouse_button = 5
		fl_get_border_width = 2000
		fl_get_coordunit = 2001
		fl_get_visual_depth = 2002
		fl_get_linewidth = 2003
		fl_get_linestyle = 2004
		fl_get_drawmode = 2005
		fl_end_all_command = 2006
		fl_current_pup = 2007
	CODE:
		switch(ix) {
#if FL_INCLUDE_VERSION < 87
		case 2007:
			not_implemented(GvNAME(CvGV(cv)));
			break;
#endif
		case 0:
			RETVAL = fl_screen;
			break;
		case 1:
			RETVAL = fl_scrh;
			break;
		case 2:
			RETVAL = fl_scrw;
			break;
		case 3:
			RETVAL = fl_vmode;
			break;
		case 4:
			RETVAL = (I32)fl_display;
			break;
		case 5:
			RETVAL = fl_mouse_button();
			break;			
		default:
			RETVAL = (int_void_funcs[ix-2000])();
			break;
		}
	OUTPUT:
	RETVAL

void
fl_library_version()
	PPCODE:
	{
		int 	result, v, r;

		result = fl_library_version(&v, &r);

		EXTEND(sp, 3);
		PUSHs(sv_2mortal(newSViv(result)));
		PUSHs(sv_2mortal(newSViv(v)));
		PUSHs(sv_2mortal(newSViv(r)));
	}
		
Display *
fl_initialize_real(...)
	CODE: 
	{
		/*
		 * fl_initialize can process the command line
		 * options and alter them. Therefore we need to
		 * rebuild the argc and argv variables in c form.
		 * This is done by taking the $0 scalar and
		 * adding the contents of @ARGV such that we
		 * have the char** format expected by fl_initialize.
	 	 * 
		 * It also accepts XrmOptionDesc structures. This 
		 * functionality is provided via a variable length 
		 * parm list through which the user provides the 
		 * elements of each XrmOptionDesc structure as a
		 * simple list.
		 */

		int	num_opts, num_args, size_args, i, j;
		I32	num_argv;
		AV	*perl_argv = perl_get_av("ARGV", FALSE);
		SV	*temp_sv, *perl_argv_0 = perl_get_sv("0", FALSE);
		char    *argv_mem, **fl_argv, **temp_argv, *appclass;
		FL_CMD_OPT *cmd_opts = NULL;

		/*
		 * First establish if we have options to deal with. This
		 * is indicated by a call with more than one argument, in
		 * which case the remainder must be a multiple of 4.

		 */
		if (items < 1 || (items-1) % 4 != 0)
			usage("fl_initialze");
		appclass = (char *)SvPV(ST(0),na);
		num_opts = (items - 1) / 4;

		/*
		 * Now get the storage for the options and populate it
		 */

		if (num_opts) {

			cmd_opts = (FL_CMD_OPT *)X4Pcalloc(num_opts, 
							sizeof(FL_CMD_OPT));

			for(i=0; i<num_opts; ++i) {
				cmd_opts[i].option  = 
					(char *)SvPV(ST(i*4+1),na);
				cmd_opts[i].specifier  = 
					(char *)SvPV(ST(i*4+2),na);
				cmd_opts[i].argKind = SvIV(ST(i*4+3));
				if (cmd_opts[i].argKind == XrmoptionNoArg)
					cmd_opts[i].value  = 
					(char *)SvPV(ST(i*4+4),na);
			}
		}

		/*
		 * Now deal with the input ARGV array
		 *
		 * Get the number of ARGV array members
		 * and the length of the $0 scalar
		 */

		num_argv = av_len(perl_argv);
		size_args = strlen(SvPV(perl_argv_0,na)) + 1;

		/*
		 * Add the total size of ARGV array members
		 */

		for (num_args = 0; num_args <= num_argv; ++num_args ) {
			size_args += strlen(SvPV(*av_fetch(perl_argv, num_args, 0),na)) + 1; 
		}
		/*
		 * Add the 'argv[0]' slot
		 */
		num_args++;

		/*
		 * Get some storage of that size + space for the last null ptr
		 */

		fl_argv = temp_argv = 
			X4Pcalloc(1, size_args+((num_args+1)*sizeof(temp_argv)));

		/*
		 * Make the top bit the char * and the rest 
		 * contains the argv strings themselves
		 */

		argv_mem = (char *)(fl_argv + (num_args+1));
		
		fl_argv[0] = argv_mem;
		j = strlen(strcpy(argv_mem,SvPV(perl_argv_0,na))) + 1;
						argv_mem += j;

		for (i = 0; i <= num_argv; ++i ) {
			fl_argv[i+1] = argv_mem;
			j = strlen(strcpy(argv_mem,
				  SvPV(*av_fetch(perl_argv, i, 0),na))) + 1; 
						argv_mem += j;
		}

		/*
		 * NOW call fl_initialize, saving current argc
		 */

		num_argv = num_args;
		RETVAL = fl_initialize(&num_args, fl_argv, 
					appclass, 
					cmd_opts, num_opts);

		if (num_args < num_argv) {
			/*
			 * An ARGV variable was changed so clear the
			 * ARGV array and rebuild it
			 */

			av_clear(perl_argv);

			for (i = 1; i < num_args; ++i) {
				av_push(perl_argv, newSVpv(fl_argv[i], 0));
			}
		}
		
		X4Pfree(fl_argv);
	}
	OUTPUT:
	RETVAL

SV *
fl_set_atclose(callback,parm)
	SV *		callback
	SV * 		parm
	ALIAS:
		fl_set_idle_callback = 1
		fl_set_event_callback = 2
		fl_set_fselector_callback = 100
	CODE:
	{
		form_data	*fmdat;

		parm = get_a_ref(parm);
		switch (ix) {
		case 100:
			/*
			 * fselector callback is handled via its
			 * form callback structure
			 */
			fmdat = get_form_data(fl_get_fselector_form());

			savesv(&(fmdat->fd_fselcallback), callback);
			fl_set_fselector_callback((SvNULL(callback) ? NULL :
				process_fselector_callback),
				(void *)parm);
			break;
		default:
			return_save_sv(&(ST(0)),
				&(appl_cb[ix]),
				callback);
			(set_appl_cb_funcs)[ix]((SvNULL(callback) ? NULL :
				appl_stubs[ix]),
				(void *)parm);
			break;
		}
	}

void
fl_add_event_callback(window,event,callback,parm)
	Window          window
	int             event
	SV *            callback
	SV *            parm
	CODE:
	{
		cb_data *this,  **prev;

		parm = get_a_ref(parm);
		prev = &(get_cb_data()[event]);
		/*
		 * We only allow one handler for XErrorEvents for
		 * all windows. this is because the XErrorEvent
		 * may not contain a valid window variable
		 */
		if (!event)
			window = 0;

		/*
		 * Now see if this event/window pair has a callback
		 * already set.
		 */
		while ((this = *prev) && this->window != window)
			prev = &(this->next_data);

		ST(0) = sv_newmortal();
		if (this) {
			/*
			 * A callback was found, return the
			 * SV * of it and then use the existing
			 * cb_data area for the new callback
			 */
			sv_setsv(ST(0),this->callback);
		} else {
			/*
			 * No callback was found, get a new cb_data
			 * area and chain the end of the list for
			 * the current event
			 */
			this = *prev =
				(cb_data *)X4Pcalloc(1, sizeof(cb_data));
			this->window = window;
		}
		/*
		 * Now save the callback pointer and call the
		 * XForm library function
		 */
		savesv(&this->callback, callback);

		fl_add_event_callback(window, event,
					  (SvNULL(callback) ? NULL :
					  process_single_event_callback),
					  (void *)parm);
	}

SV *
fl_add_canvas_handler(object,event,callback,parm)
	FLObject *	object
	int		event
	SV *		callback
	SV *		parm
	CODE:
	{
		object_data *obdat =
			get_object_data(object);
		SV **   canv_event_cbs = obdat->od_cevents;

		parm = get_a_ref(parm);
		if (!canv_event_cbs) {
			canv_event_cbs =
				(SV **)X4Pcalloc(LASTEvent, sizeof(SV *));
			obdat->od_cevents = canv_event_cbs;
		}
		return_save_sv(&(ST(0)),
				   &(canv_event_cbs[event]),
				   callback);
		fl_add_canvas_handler(object, event,
					  (SvNULL(callback) ? NULL :
					  process_canvas_event),
					  (void *)parm);
	}

SV *
fl_register_raw_callback(form,mask,callback)
	FLForm *	form
	long		mask
	SV *		callback
	CODE:
	{
		return_save_sv(&(ST(0)), 
			&(get_form_data(form)->fd_rawcallback), 
			callback);
		fl_register_raw_callback(form, mask,
			(SvNULL(callback) ? NULL : process_form_raw_callback));
	}

SV *
fl_set_form_callback(form,callback,parm)
	FLForm *	form
	SV *		callback
	SV * 		parm
	ALIAS:
		fl_set_form_atactivate = 1
		fl_set_form_atdeactivate = 2
		fl_set_form_atclose = 3
	CODE:
	{

		return_save_sv(&(ST(0)), 
			&(((fd_array *)get_form_data(form))->cb_ptr[ix]), 
			callback);
		(cb_FLF_cb_parm_funcs[ix])(form, 
			(SvNULL(callback) ? NULL : cb_FLF_cb_parm_handlers[ix]),
			(void *)parm);
	} 

SV *
fl_set_object_callback(object,callback,parm=0)
	FLObject *	object
	SV *		callback
	long		parm
	ALIAS:
		fl_set_browser_dblclick_callback = 1
		fl_set_object_posthandler = 2
		fl_set_object_prehandler = 3
		fl_set_input_filter = 4
		fl_set_counter_filter = 5
		fl_set_slider_filter = 6
		fl_set_timer_filter = 7
		fl_request_clipboard = 100
	CODE:
	{
		int i;

		if (ix < 100)
			return_save_sv(&(ST(0)), 
			   &(((od_array *)get_object_data(object))->cb_ptr[ix]), 
			   callback);

		switch (ix) {
#if FL_INCLUDE_VERSION < 87
		case 100:
			not_implemented(GvNAME(CvGV(cv)));
			break;
#endif
		case 0:
			fl_set_object_callback(object, 
			(SvNULL(callback) ? NULL : process_object_callback), 
			parm);
			break;
		case 1:
			fl_set_browser_dblclick_callback(object, 
			(SvNULL(callback) ? NULL : process_brdbl_callback), 
			parm);
			break;
#if FL_INCLUDE_VERSION >= 87
		case 100:
			savesv(&((get_object_data(object))->od_gainsel), callback);
			i = fl_request_clipboard(object, FL_STRING,
			(SvNULL(callback) ? NULL : process_gain_sel_cb));
			ST(0) = sv_newmortal();
			sv_setiv(ST(0), (IV)i);
			break;
#endif
		default:
			(cb_FLO_cb_funcs[ix-2])(object, 
			(SvNULL(callback) ? NULL : cb_FLO_cb_handlers[ix-2]));
			break;
		}
	} 

FLForm *
fl_bgn_form(box_type=0,width=0,height=0)
	int		box_type
	int		width
	int		height
	ALIAS:
		fl_current_form = 1
		fl_get_app_mainform = 2
		fl_get_fselector_form = 3
	CODE:
	{
		switch (ix) {
		case 0:
			RETVAL = fl_bgn_form(box_type,width,height);
			break;
		case 1:
			RETVAL = fl_current_form;
			break;
		case 2:
			RETVAL = fl_get_app_mainform();
			break;
		case 3:
			RETVAL = fl_get_fselector_form();
			break;
		}
		ST(0) = bless_form(RETVAL);
	}

FLObject *
fl_create_glcanvas(type,x,y,width,height,label,handle=0,int2=0)
	int		type
	FL_Coord	x
	FL_Coord	y
	FL_Coord	width
	FL_Coord	height
	char *		label
	SV *		handle
	int		int2
	ALIAS:
		fl_add_glcanvas = 1
		fl_create_button = 2 
		fl_add_button = 3
		fl_create_lightbutton = 4
		fl_add_lightbutton = 5
		fl_create_roundbutton = 6
		fl_add_roundbutton = 7
		fl_create_checkbutton = 8
		fl_add_checkbutton = 9
		fl_create_bitmapbutton = 10
		fl_add_bitmapbutton = 11
		fl_create_pixmapbutton = 12
		fl_add_pixmapbutton = 13
		fl_create_bitmap = 14
		fl_add_bitmap = 15
		fl_create_pixmap = 16
		fl_add_pixmap = 17
		fl_create_box = 18
		fl_add_box = 19
		fl_create_text = 20
		fl_add_text = 21
		fl_create_menu = 22
		fl_add_menu = 23
		fl_create_chart = 24
		fl_add_chart = 25
		fl_create_choice = 26
		fl_add_choice = 27
		fl_create_counter = 28
		fl_add_counter = 29
		fl_create_slider = 30
		fl_add_slider = 31
		fl_create_valslider = 32
		fl_add_valslider = 33
		fl_create_input = 34
		fl_add_input = 35
		fl_create_browser = 36
		fl_add_browser = 37
		fl_create_dial = 38
		fl_add_dial = 39
		fl_create_timer = 40
		fl_add_timer = 41
		fl_create_clock = 42
		fl_add_clock = 43
		fl_create_positioner = 44
		fl_add_positioner = 45
		fl_create_xyplot = 46
		fl_add_xyplot = 47
		fl_create_canvas = 48
		fl_add_canvas = 49
		fl_create_frame = 50
		fl_add_frame = 51
		fl_create_round3dbutton = 52
		fl_add_round3dbutton = 53
		fl_create_labelframe = 54
		fl_add_labelframe = 55
		fl_create_menubar = 56
		fl_add_menubar = 57
		fl_create_tabfolder = 58
		fl_add_tabfolder = 59
		fl_create_scrollbutton = 60
		fl_add_scrollbutton = 61
		fl_create_scrollbar = 62
		fl_add_scrollbar = 63
		fl_make_object = 100
		fl_create_generic_button = 101
		fl_create_generic_canvas = 102
		fl_create_free = 104
		fl_add_free = 105
	CODE:
	{
		object_data 	*obdat;
		int		hndl_ix = -1;

		switch (ix) {
#ifndef XFOPENGL
		case 0:
		case 1:
			croak("Xforms4Perl OpenGL functions are not installed.");
			break;
#endif
		case 56:
		case 57:
#if FL_INCLUDE_VERSION < 87
		case 58:
		case 59:
		case 60:
		case 61:
		case 62:
		case 63:
#endif
			not_implemented(GvNAME(CvGV(cv)));
			break;
		case 100:
			RETVAL = fl_make_object(type,int2,x,y,width,
						height,label,
						(SvNULL(handle) ? NULL : 
						process_make_handle));
			hndl_ix = OD_MAKEHANDLER;
			break;
		case 101:
			RETVAL = fl_create_generic_button(type,int2,x,y,width,
						height,label);
			break;
		case 102:
			RETVAL = fl_create_generic_canvas(type,int2,x,y,width,
						height,label);
			break;
		case 104 :
			RETVAL = fl_create_free(type,x,y,
					   width,height,label,
					   (SvNULL(handle) ? NULL :
					   process_free_handle));
			hndl_ix = OD_FREEHANDLER;
			break;
		case 105 :
			RETVAL = fl_add_free(type,x,y,
					   width,height,label,
					   (SvNULL(handle) ? NULL :
					   process_free_handle));
			hndl_ix = OD_FREEHANDLER;
			break;
		default:
			RETVAL = (create_add_funcs[ix].func)(type,x,y,width,height,label);
			break;
		}
		if (RETVAL == NULL)
			croak("%s of object type %i failed", 
				((ix % 2) ? "Add" : "Create"),
				ix);
		RETVAL->u_vdata = NULL;
		obdat = get_object_data(RETVAL);
		if (hndl_ix >= 0)
			savesv(&((od_array *)obdat)->cb_ptr[hndl_ix], handle);
		ST(0) = bless_object(RETVAL);
		if (ix < 100 && create_add_funcs[ix].init_cb != NULL)
			call_perl_callback(create_add_funcs[ix].init_cb, 
				"Class Initialization",
				CB_FALSE, NULL, 
				"O", RETVAL);
	}

SV *
fl_set_class_callback(class_num,callback)
	int			class_num
	SV *		callback
	CODE:
	{
		int ix_num;

		if (class_num > FL_MAX_CLASS)
			croak("Invalid xforms class");

		if (class_num != fl_2_ix[class_num].fl_number
		|| (ix_num = fl_2_ix[class_num].ix_number) < 0)
		{
			ST(0) = &sv_undef;
		}
		else
		{
			return_save_sv(&(ST(0)), 
			   &(create_add_funcs[ix_num].init_cb), 
			   callback);
			create_add_funcs[ix_num+1].init_cb = 
				create_add_funcs[ix_num].init_cb;
		}
	}

FLObject *
fl_bgn_group()
	ALIAS:
		fl_end_group = 1
		fl_check_forms = 2
		fl_check_only_forms = 3
		fl_do_forms = 4
		fl_do_only_forms = 5
	CODE:
	{
		RETVAL = (FLO_void_funcs[ix])();
		if (ix < 2)
		{
			RETVAL->u_vdata = NULL;
			ST(0) = bless_object(RETVAL);
		}
		else if (RETVAL == NULL)
			ST(0) = &sv_undef;
		else
			ST(0) = bless_object(RETVAL);			
	}

void
fl_default_window()
	ALIAS:
		fl_root = 1
		fl_vroot = 2
		fl_get_mouse = 3
		fl_ul_magic_char = 4
		fl_unset_text_clipping = 5
		fl_XNextEvent = 6
		fl_XPeekEvent = 7
		fl_last_event = 8
		fl_gettime = 9
		fl_activate_all_forms = 100
		fl_deactivate_all_forms = 101
		fl_end_form = 102
		fl_finish = 103
		fl_freeze_all_forms = 104
		fl_unfreeze_all_forms = 105
		fl_unset_clipping = 106
		fl_noborder = 107
		fl_transient = 108
		fl_hide_oneliner = 109
		fl_invalidate_fselector_cache = 110
		fl_refresh_fselector = 111
		fl_endline = 112
		fl_reset_vertex = 113
		fl_endclosedline = 114
		fl_endpolygon = 115
		fl_hide_fselector = 116
		fl_hide_command_log = 117
		fl_clear_command_log = 118
		fl_hide_message = 119
		fl_hide_question = 120
		fl_hide_alert = 121
		fl_hide_input = 122
		fl_hide_choice = 123
	PPCODE:
	{
		Window		win;
		FL_Coord	x, y;
		unsigned int	i1;
		long		l1, l2;
		XEvent *        event;
		SV *            tempsv;

		switch (ix) {
#if FL_INCLUDE_VERSION < 87
		case 119:
		case 120:
		case 121:
		case 122:
		case 123:
			not_implemented(GvNAME(CvGV(cv)));
			break;
#endif
		case 0:
			win = fl_default_window();
			XPUSHs(sv_2mortal(newSViv(win)));
			break;
		case 1:
			XPUSHs(sv_2mortal(newSViv(fl_root)));
			break;
		case 2:
			XPUSHs(sv_2mortal(newSViv(fl_vroot)));
			break;
		case 3:
			win = fl_get_mouse(&x, &y, &i1);
			EXTEND(sp, 4);
			PUSHs(sv_2mortal(newSViv(win)));
			PUSHs(sv_2mortal(newSViv(x)));
			PUSHs(sv_2mortal(newSViv(y)));
			PUSHs(sv_2mortal(newSViv(i1)));
			break;
		case 4:
			XPUSHs(sv_2mortal(newSVpv(fl_ul_magic_char,0)));
			break;
		case 5:
			fl_unset_text_clipping();
			break;
		case 6:
		case 7:
		case 8:
			{
			if (ix == 8) 
				event = (XEvent *)fl_last_event();
			else {
				event = (XEvent *)X4Pcalloc(1, sizeof(XEvent));
				i1 = (ix == 6 ? fl_XNextEvent(event) :
						fl_XPeekEvent(event));
				XPUSHs(sv_2mortal(newSViv(i1)));
			}
			tempsv = sv_newmortal();
			sv_setref_iv(tempsv, object_name[X11XEvent], (IV)event);
			XPUSHs(tempsv);
			break;
			}
		case 9:
			fl_gettime(&l1, &l2);
			EXTEND(sp, 2);
			PUSHs(sv_2mortal(newSViv(l1)));
			PUSHs(sv_2mortal(newSViv(l2)));
			break;
		default:
			void_void_funcs[ix-100]();
			break;
		}
	}

XFontStruct *
fl_get_fontstruct(val1,val2)
	int		val1
	int		val2

void
fl_get_choice_text(object,i=0)
	FLObject *      object
	int             i
	ALIAS:
		fl_get_menu_text = 1
		fl_get_folder_name = 2
		fl_get_active_folder_name = 3
		fl_get_browser_line = 100
		fl_get_choice_item_text = 101
		fl_get_menu_item_text = 102
		fl_isselected_browser_line = 200
		fl_get_menu_item_mode = 201
	PPCODE:
	{
		const char	*char_out;
		int	int_out;

		switch (ix) {
#if FL_INCLUDE_VERSION < 87
		case 2:
		case 3:
			not_implemented(GvNAME(CvGV(cv)));
			break;
#endif
		case 200:
			int_out = fl_isselected_browser_line(object,i);
			break;
		case 201:
			int_out = fl_get_menu_item_mode(object,i);
			break;
		default:
			if (ix >= 100)
				char_out = (char_FLO_int_funcs[ix-100])(object,i);
			else
				char_out = (char_FLO_funcs[ix])(object);
			break;
		}
		if (ix >= 200)
			XPUSHs(sv_2mortal(newSViv(int_out)));
		else {
			if (char_out == NULL)
				XPUSHs(&sv_undef);
			else
				XPUSHs(sv_2mortal(newSVpv((char *)char_out,0)));
		}
	}

void
fl_setpup_mode(int1=0,int2=0,int3=0)
	I32             int1
	I32             int2
	I32	        int3
	ALIAS:
		fl_msleep = 1
		fl_dopup = 2
		fl_check_command = 3
		fl_getpup_mode = 100
		fl_mode_capable = 101
		fl_get_char_width = 102
		fl_use_fselector = 200
		fl_XEventsQueued = 201
		fl_setpup_maxpup = 203
		fl_show_colormap = 204
		fl_setpup_fontsize = 205
		fl_setpup_fontstyle = 206
		fl_getpup_items = 207
		fl_setpup_default_bw = 208
		fl_end_command = 300
		fl_getpup_text = 400
		fl_vclass_name = 401
		fl_get_directory = 500
		fl_get_filename = 501
		fl_get_pattern = 502
		fl_now = 503
		fl_whoami = 504
	PPCODE:
	{
		I32		out_int;
		const char *	out_char;
		int		our_pup;

		switch (ix) {
#if FL_INCLUDE_VERSION < 87
		case 3:
		case 207:
		case 208:
		case 503:
		case 504:
			not_implemented(GvNAME(CvGV(cv)));
			break;
#endif
		case 0:
			out_int = fl_setpup_mode(int1,int2,int3);
			break;
		case 1:
			out_int = fl_msleep(int1);
			break;
		case 2:
			out_int = fl_dopup(int1);
			break;
#if FL_INCLUDE_VERSION >= 87
		case 3:
			out_int = fl_check_command(int1);
			break;
#endif
		case 300:
			out_int = fl_end_command(int1);
			break;
		case 400:
			out_char = fl_getpup_text(int1,int2);
			break;
		case 401:
			out_char = fl_vclass_name(int1);
			break;
		default:
			if (ix >= 500) 
				out_char = cchar_void_funcs[ix-500]();
			else if (ix >= 200) {
				if (ix == 200)
					current_fsel = int1;
				out_int = (int_int_funcs[ix-200])(int1);
			} else
				out_int = (int_int_int_funcs[ix-100])(int1,int2);
			break;
		}
		if (ix >= 400) {
			if (out_char == NULL)
				XPUSHs(&sv_undef);
			else
				XPUSHs(sv_2mortal(newSVpv((char *)out_char,0)));
		} else
			XPUSHs(sv_2mortal(newSViv(out_int)));
	}

FDFselector *
fl_get_fselector_fdstruct()

void
fl_set_input_editkeymap(keymap)
	FLEditKeymap *	keymap

void 
fl_drw_slider(i1,x,y,w,h,c1,c2,i2,d1,d2,s1,i3,i4,i5)
	int		i1 
	FL_Coord 	x
	FL_Coord 	y
	FL_Coord 	w
	FL_Coord	h
	FL_COLOR 	c1
	FL_COLOR 	c2
	int 		i2
	double 		d1
	double 		d2
	char *		s1
	int 		i3
	int 		i4
	int		i5

long 
fl_show_question(string1,int1)
	const char *	string1
	int		int1
	ALIAS:
		fl_exe_command = 1
	CODE:
		RETVAL = (ix == 0 ? fl_show_question(string1,int1) :
					fl_exe_command(string1,int1));
	OUTPUT:
	RETVAL

int 
fl_add_timeout(time,callback,parm)
	long		time 
	SV *		callback 
	SV *		parm
	CODE:
	{
		int     to_cb_idx = get_free_to();
		to_data	*new_to = &to_cb[to_cb_idx];

		parm = get_a_ref(parm);
		/* 
		 * Add new timeout callback
		 */
		new_to->in_use = 1;
		new_to->callback = callback;
		new_to->parm = parm; 
		new_to->time_out_id = fl_add_timeout(time,
				   process_timeout_callback,
				   (void *)to_cb_idx);

		RETVAL = new_to->time_out_id;
	}
	OUTPUT:
	RETVAL

void
fl_remove_timeout(time_out_id)
	int             time_out_id
	CODE:
	{
		free_to(time_out_id);
		fl_remove_timeout(time_out_id);
	}

FDCmdlog *
fl_get_command_log_fdstruct()

void
fl_show_messages(string1,string2="",string3="",string4="")
	const char *	string1
	const char *	string2
	const char *	string3
	const char *	string4
	ALIAS:
		fl_addto_command_log = 1
		fl_show_input = 2
		fl_show_fselector = 3
		fl_show_simple_input = 4
		fl_get_resource = 5
		fl_vclass_val = 100
		fl_set_directory = 101
	PPCODE:
	{
		char	resval[RESBUF];
		const char *char_out;
		int	int_out;

		switch (ix) {
		case 0:
			fl_show_messages(string1);
			break;
		case 1:
			fl_addto_command_log(string1);
			break;
		case 4:
			char_out = fl_show_simple_input(string1,string2);
			break;
		case 2:
			char_out = fl_show_input(string1,string2);
			break;
		case 3:
			char_out = fl_show_fselector(string1,string2,
					string3,string4);
			break;
		case 5:
			fl_get_resource(string1,
					string2,
					FL_STRING,
					string3,
					resval,
					RESBUF);
			char_out = resval;
			break;
		case 100:
			int_out = fl_vclass_val(string1);
			break;
		case 101:
			int_out = fl_set_directory(string1);
			break;
		}
		if (ix >= 100)
			XPUSHs(sv_2mortal(newSViv(int_out)));
		else if (ix > 1) {
			if (char_out == NULL)
				XPUSHs(&sv_undef);
			else
				XPUSHs(sv_2mortal(newSVpv((char *)char_out,0)));
		}
	}
		
void
fl_set_bitmap_data(object,w,h,bits)
	FLObject *	object
	int		w
	int		h
	unsigned char *	bits
	ALIAS:
		fl_set_bitmapbutton_data = 1
	CODE:
	{
		if (ix == 0)
			fl_set_bitmap_data(object,w,h,bits);
		else
			fl_set_bitmapbutton_data(object,w,h,bits);
	}	

Pixmap
fl_create_from_bitmapdata(win,bits,w,h)
	Window		win
	char *		bits
	int		w
	int		h

int 
fl_create_bitmap_cursor(str1,str2,int1,int2,int3,int4)
	const char *	str1 
	const char *	str2
	int		int1
	int		int2
	int		int3
	int		int4

void 
fl_get_string_widthTAB(val1,val2,string="",length=0)
	int             val1
	int             val2
	const char *    string
	int             length
	ALIAS:
		fl_get_string_width = 1
		fl_get_string_dimension = 4
		fl_get_string_height = 5
		fl_get_char_height = 6
		fl_setpup_shortcut = 50

	PPCODE:
	{
		int     result, ascend, descend;

		switch (ix) {
		case 0:
			result = fl_get_string_widthTAB(val1,
							val2,
							string,
							length);
			break;
		case 1:
			result = fl_get_string_width(	val1,
							val2,
							string,
							length);
			break;
		case 4:
			result = 1;
 			fl_get_string_dimension(val1,
						val2,
						string,
						length,
						&ascend,
						&descend);
			break;
		case 5:
			result = fl_get_string_height(	val1,
							val2,
							string,
							length,
							&ascend,
							&descend);
			break;
		case 6:
			result = fl_get_char_height(val1,val2,
						&ascend,&descend);
			break;
		case 50:
			fl_setpup_shortcut(val1,val2,string);
			break;
		}
		
		if (ix < 50) {
			XPUSHs(sv_2mortal(newSViv(result)));
			if (ix > 3) {
				XPUSHs(sv_2mortal(newSViv(ascend)));
				XPUSHs(sv_2mortal(newSViv(descend)));
			}
		}
	}

unsigned long 
fl_mapcolorname(c,s)
	FL_COLOR	c
	const char *	s

long
fl_prepare_form_window(form,placement,border,formname)
	FLForm *	form
	int		placement
	int		border
	char *		formname
	ALIAS:
		fl_show_form = 1
	CODE:
	{
		RETVAL = (ix ? fl_show_form(form,placement,border,formname)
				 : fl_prepare_form_window(form,placement,
							border,formname));
	}
	OUTPUT:
	RETVAL

unsigned long 
fl_mapcolor(c,r=0,g=0,b=0)
	FL_COLOR	c
	int		r
	int		g
	int		b
	ALIAS:
		fl_get_pixel = 1
		fl_set_icm_color = 2
		fl_set_oneliner_color = 3
	CODE:
	{
		switch (ix) {
		case 0:
			RETVAL = fl_mapcolor(c,r,g,b);
			break;
		case 1:
			RETVAL = fl_get_pixel(c);
			break;
		case 2:
			RETVAL = 1;
			fl_set_icm_color(c,r,g,b);
			break;
		case 3:
			RETVAL = 1;
			fl_set_oneliner_color(c,r);
			break;
		}
	}
	OUTPUT:
	RETVAL

void
fl_winreshape(win,x,y,xl=0,yl=0)
	Window          win
	FL_Coord        x
	FL_Coord        y
	FL_Coord        xl
	FL_Coord        yl
	ALIAS:
		fl_winaspect = 100
		fl_winmaxsize = 101
		fl_winminsize = 102
		fl_winmove = 103
		fl_winresize = 104
		fl_winstepunit = 105
	CODE:
	{
		switch (ix) {
		case 0:
			fl_winreshape(win,x,y,xl,yl);
			break;
		default:
			(void_win_FLX_FLX_funcs[ix-100])(win, x, y);
			break;
		}
	}

void 
fl_get_icm_color(c)
	FL_COLOR        c
	ALIAS:
		fl_getmcolor = 1
		fl_bk_color = 100
		fl_bk_textcolor = 101
		fl_color = 102
		fl_textcolor = 103
		fl_setpup_checkcolor = 104
	PPCODE:
	{
		int 	r, g, b;
		unsigned long	result;

		switch (ix) {
			case 0:
				fl_get_icm_color(c,&r,&g,&b); 
				EXTEND(sp, 3);
				break;
			case 1:
				result = fl_getmcolor(c,&r,&g,&b);
				EXTEND(sp, 4);
				PUSHs(sv_2mortal(newSViv(result)));
				break;
			default:
				(void_FLC_funcs[ix-100])(c);
				break;
		}
		if (ix < 100) {
			PUSHs(sv_2mortal(newSViv(r)));
			PUSHs(sv_2mortal(newSViv(g)));
			PUSHs(sv_2mortal(newSViv(b)));
		}
	}

void 
fl_setpup_color(c1,c2)
	FL_COLOR	c1
	FL_COLOR	c2

void 
fl_free_colors(...)
	CODE:
	{
		FL_COLOR 	*colors;
		int	i = 1, color, numpts = 0;

		if (items < 1)
				usage("fl_free_colors");
		
		colors = (FL_COLOR *)X4Pcalloc(items, sizeof(FL_COLOR));
		for (i=0; i<items; i++)
			colors[i] = SvIV(ST(i));

		fl_free_colors(colors, items);
		X4Pfree((void *)colors);
	}

void 
fl_initial_winsize(x,y,xl=0,yl=0)
	FL_Coord	x
	FL_Coord	y
	FL_Coord	xl
	FL_Coord	yl
	ALIAS:
		fl_winposition = 1
		fl_winsize = 2
		fl_set_mouse = 3
		fl_add_vertex = 4
		fl_set_clipping = 100
		fl_wingeometry = 101
		fl_initial_wingeometry = 102
	CODE:
	{
		switch (ix) {
		case 0:
			(void_FLX_FLX_funcs[ix])(xl, yl);
			break;
		deafult: 
			(void_XXXX_funcs[ix-100])(x,y,xl,yl);
			break;
		}
	}

void
fl_activate_form(form)
	FLForm *	form
	ALIAS:
		fl_addto_form = 1
		fl_deactivate_form = 2
		fl_free_form = 3
		fl_freeze_form = 4
		fl_hide_form = 5
		fl_redraw_form = 6
		fl_set_app_mainform = 7
		fl_unfreeze_form = 8
		fl_lower_form = 9
		fl_raise_form = 10
		fl_get_form_mouse = 11
		fl_show_form_window = 12
		fl_get_form_event_cmask = 13
		fl_form_is_visible = 14
		fl_adjust_form_size = 15
	PPCODE:
	{
		Window		win;
		FL_Coord	x, y;
		unsigned int	i1;
		long		l1;
		unsigned long	u1;
		double		d1;
		form_data *	fm_data;

		switch (ix) {
		case 3:
			/*
			 * we must tidy up since xforms will delete the
			 * form - slight memory leak potential otherwise
			 */
			fm_data = get_form_data(form);
			fl_free_form(form);
					SvREFCNT_dec(fm_data->po);
			X4Pfree(fm_data);
			break;
		case 9:
			fl_lower_form(form);
			break;
		case 10:
			fl_raise_form(form);
			break;
		case 11:
			win = fl_get_form_mouse(form, &x, &y, &i1);
			EXTEND(sp, 4);
			PUSHs(sv_2mortal(newSViv(win)));
			PUSHs(sv_2mortal(newSViv(x)));
			PUSHs(sv_2mortal(newSViv(y)));
			PUSHs(sv_2mortal(newSViv(i1)));
			break;
		case 12:
			l1 =  fl_show_form_window(form);
			XPUSHs(sv_2mortal(newSViv(l1)));  
			break;
		case 13:
			u1 =  fl_get_form_event_cmask(form);
			XPUSHs(sv_2mortal(newSViv(u1)));  
			break;
		case 14:
			i1 = fl_form_is_visible(form);
			PUSHs(sv_2mortal(newSViv(i1)));  
			break;
		case 15:
			d1 = fl_adjust_form_size(form);
			PUSHs(sv_2mortal(newSVnv(d1)));  
			break;
		default:
			(void_FLF_funcs[ix])(form);
			break;
		}
	}

void
fl_set_form_geometry(form,x,y,width=0,height=0)
	FLForm *	form
	FL_Coord	x
	FL_Coord	y
	FL_Coord	width
	FL_Coord	height
	ALIAS:
		fl_set_form_hotspot = 1
		fl_set_form_maxsize = 2
		fl_set_form_minsize = 3
		fl_set_form_position = 4
		fl_set_form_size = 5
	CODE:
	{
		if (ix == 0) {
			fl_set_form_geometry(form,x,y,width,height);
		} else {
			(void_FLF_ii_funcs[ix-1])(form,x,y);
		}
	}

void
fl_add_object(form,object)
	FLForm *	form
	FLObject *	object
	ALIAS:
		fl_set_focus_object = 1
		fl_set_form_hotobject = 2
	CODE:
	{
		(void_FLF_FLO_funcs[ix])(form,object);
	}

#if FL_INCLUDE_VERSION >= 87

void 
fl_replace_folder_bynumber(object,number,form)
	FLObject *		object
	int				number
	FLForm *		form 

void
fl_get_input_selected_range(object)
	FLObject *	object
	CODE:
	{
		int				start, finish;
		const char *	selstr;

		selstr = fl_get_input_selected_range(object, &start, &finish);

		if (selstr == NULL)
		{	
			XPUSHs(&sv_undef);
		}
		else
		{
			EXTEND(sp, 3);
			PUSHs(sv_2mortal(newSVpv((char *)selstr,0)));
			PUSHs(sv_2mortal(newSViv(start)));
			PUSHs(sv_2mortal(newSViv(finish)));
		}
	}

FLObject *
fl_get_focus_object(form)
	FLForm *	form
 
SV *
fl_set_xyplot_symbol(object,overlay,callback)
	FLObject *	object
	int			overlay
	SV *		callback
	CODE:
	{
		return_save_sv(&(ST(0)),&((alloc_overlay_data(object, overlay))[overlay]),
			   callback);
		fl_set_xyplot_symbol(object,overlay,process_xyplot_symbol);
	}

long
fl_set_clock_adjustment(object,l)
	FLObject *      object
	long			l

FLObject *
fl_get_object_component(object,i1,i2,i3)
	FLObject *      object
	int				i1
	int				i2
	int				i3
	CODE:
	{
		RETVAL = fl_get_object_component(object,i1,i2,i3);
		if (RETVAL == NULL)
			ST(0) = &sv_undef;
		else
			ST(0) = bless_object(RETVAL);
	}		

void 
fl_point(x,y,c)
	FL_Coord		x
	FL_Coord		y 
	FL_COLOR		c

int
fl_stuff_clipboard(object,string,callback)
	FLObject *      object
	char *			string
	SV *			callback
	CODE:
	{
		int size = strlen(string);
		savesv(&((get_object_data(object))->od_losesel), callback);
		RETVAL = fl_stuff_clipboard(object, FL_STRING, 
			string, (long)strlen(string),
			(SvNULL(callback) ? NULL : process_lose_sel_cb));
	}
	OUTPUT:
	RETVAL

void
fl_get_xyplot_data(object,id=0)
	FLObject *      object
	int				id
	ALIAS:
		fl_get_xyplot_overlay_data = 1
	PPCODE:
	{
		float *xf, *yf;
		int	pts, rpts, i;
		/*
		 * Get the number of points that are in the requested plot
		 */
		pts = fl_get_xyplot_numdata(object,id);

		/*
		 * If this is greater than 0, allocate an array of floats
		 * twice its size, get the data into the array and then
		 * send it back as x,y pairs in the result list
		 */
		if (pts > 0)
		{
			xf = (float *)X4Pcalloc(pts*2, sizeof(float));
			yf = xf + pts;
			if (ix == 0)
				fl_get_xyplot_data(object, xf, yf, &rpts);
			else 
				fl_get_xyplot_overlay_data(object, id,
					xf, yf, &rpts);
			/*
			 * Return the list of points
			 */
			EXTEND(sp, (pts*2));
			for(i=0; i<pts; ++i)
			{
				PUSHs(sv_2mortal(newSVnv(xf[i])));
				PUSHs(sv_2mortal(newSVnv(yf[i])));
			}
			X4Pfree((void *)xf);
		}
		else
		{
			XPUSHs(&sv_undef);
		}
	}
			
void
fl_setpup_menucb(menu,callback,parm=0)
	int		menu
	SV *	callback
	SV *	parm
	ALIAS:
		fl_setpup_entercb = 1
		fl_setpup_leavecb = 2
	CODE:
	{
		pupm_cb 	*pupm = add_pup_menu(menu);
		parm = get_a_ref(parm);
		switch(ix) {
		case 0:
			return_save_sv(&(ST(0)), &(pupm->cb), callback);
			fl_setpup_menucb(menu, (SvNULL(callback) ? 
					NULL : process_pupm_callback));
			break;
		case 1:
			return_save_sv(&(ST(0)), &(pupm->ecb), callback);
			fl_setpup_entercb(menu, (SvNULL(callback) ? 
					NULL : process_pupm_entercb), (void *)parm);
			break;
		case 2:
			return_save_sv(&(ST(0)), &(pupm->lcb), callback);
			fl_setpup_leavecb(menu, (SvNULL(callback) ? 
					NULL : process_pupm_leavecb), (void *)parm);
			break;
		}
	}

SV *
fl_setpup_itemcb(menu,item,callback)
	int		menu
	int		item
	SV *	callback
	CODE:
	{
		pupi_cb 	*pupi = add_pup_item(menu,item);
		return_save_sv(&RETVAL, &(pupi->cb), callback);
		fl_setpup_itemcb(menu, item,
			(SvNULL(callback) ? NULL : process_pupi_callback));
	}
	OUTPUT:
	RETVAL

int
fl_set_menu_entries(...)
	ALIAS:
		fl_set_menubar_entries = 1
		fl_setpup_entries = 2
		fl_set_choice_entries = 3
	CODE:
	{
		FLObject		*object;
		int	 			i, parm, parm2, pup_id, dummy_id, num_entries;
		char			*name;
		FL_PUP_ENTRY    *entries;
		pupi_cb 		*pupi;

		/*
		 * Extract the basics and set the parm index
		 */
		switch (ix) {
		case 0:
		case 3:
			if (items < 2)
				usage(GvNAME(CvGV(cv)));
			object = (FLObject *)chk_bless(ST(0),X11XformsFLObject);
			parm = 1;
			break;
		case 1:
			not_implemented(GvNAME(CvGV(cv)));
/*			if (items < 3)
				usage(GvNAME(CvGV(cv)));
			object = (FLObject *)chk_bless(ST(0), X11XformsFLObject);
			name = (char *)SvPV(ST(1),na);
			parm = 2;
*/			break;
		case 2:
			if (items < 2)
				usage(GvNAME(CvGV(cv)));
			parm = 1;
			pup_id = (int)SvIV(ST(0));
			break;
		}

		/*
		 * Now check the rest of the parms to ensure that we have
		 * roughly the right format: an 'entry' is either four parms
		 * long or the undefined value. We count to ensure the
		 * we have the right number and to allocate the entry array
		 */
		parm2 = parm;
		num_entries = 1;
		while(parm < items)
		{
			++num_entries;
			if (SvNULL(ST(parm)))
				++parm;
			else
				parm += 4;
		}
		if (parm > items)
			usage(GvNAME(CvGV(cv)));

		/*
		 * OK, we have a basically correct parm list and we know its
		 * size. Allocate the entries array and then populate each
		 * entry.
		 * dummy_id is used as a place holder when we don't yet know the
		 * pup_id for the menu being added. We decrement it just to make
		 * sure it works properly.
		 */
		dummy_id = dummy_pup--;
		entries = (FL_PUP_ENTRY *)X4Pcalloc(num_entries, sizeof(FL_PUP_ENTRY));
		for(i = 0, parm = parm2; parm < items; ++i)
		{
			if (SvNULL(ST(parm))) 
			{
				entries[i].text = NULL;
				parm++;
			}
			else
			{
				entries[i].text = (char *)SvPV(ST(parm),na);
				pupi = add_pup_item(dummy_id,i+1);
				savesv(&(pupi->cb), ST(parm+1));
				entries[i].callback = 
					(SvNULL(ST(parm+1)) ? NULL : process_pupi_callback);
				entries[i].shortcut = (char *)SvPV(ST(parm+2),na);
				entries[i].mode = (int)SvIV(ST(parm+3));
				parm += 4;
			}
		}

		/*
		 * Set the last entry
		 */
		entries[i].text = NULL;

		/*
		 * Call the relevant routine(s)
		 */
		switch (ix) {
		case 0:
			RETVAL = fl_set_menu_entries(object, entries);
			pup_id = fl_get_menu_popup(object);
			break;
/*		case 1:
			fl_set_menubar_entries(object, name, entries);
			pup_id = fl_get_menu_popup(object);
			RETVAL = 0;
			break;
*/		case 2:
			RETVAL = fl_setpup_entries(pup_id, entries);
			break;
		case 3:
			RETVAL = fl_set_choice_entries(object, entries);
			break;
		}

		/*
		 * Now replace the dummy pup id that we used with the real
		 * pup-id - this is done because in the case of menus we don't
		 * know the real id until now.
		 *
		 * If, however, the pup id is negative, we simply delete the
		 * the dummy entry that we set up for it.
		 */
		if (pup_id >= 0)
		{
			del_pup_menu(pup_id);
			change_pupm_id(dummy_id, pup_id);
		}
		else
			del_pup_menu(dummy_id);
				
		/*
		 * And free the area
		 */
		X4Pfree((void *)entries);
	}
	OUTPUT:
	RETVAL

void
fl_delete_folder(object,form)
	FLObject *	object
	FLForm *	form
	ALIAS:
		fl_set_folder = 1
	CODE:
	{
		if (ix == 0) {
			fl_delete_folder(object,form);
		} else {
			fl_set_folder(object,form);
		}
	}

FLForm *
fl_get_folder(object)
	FLObject *	object
	ALIAS:
		fl_get_active_folder = 1
	CODE:
	{
		if (ix == 0)
			ST(0) = bless_form(fl_get_folder(object));
		else
			ST(0) = bless_form(fl_get_active_folder(object));
	}

FLObject *
fl_addto_tabfolder(object,name,form)
	FLObject *	object
	const char *    name
	FLForm *	form

void
fl_set_xyplot_keys(object,x,y,align,...)
	FLObject *      object
	float		x
	float		y
	int		align
	ALIAS:
		fl_set_xyplot_key_position = 1
	CODE:
	{
	if (ix == 1) {
		fl_set_xyplot_key_position(object,x,y,align);
	} else {
		int	i, array_size, num_keys;
		char 	**keys, *key_str;

		if (items < 5)
				usage("fl_set_xyplot_keys");

		num_keys = items-4;
		/*
		 * Add the total size of the key strings
		 */
		for (i = 4, array_size = 0; i < items; ++i ) {
			array_size += strlen((const char *)SvPV(ST(i),na))+1; 
		}

		/*
		 * Get some storage of that size + space for the last null ptr
		 */

		keys = (char **)X4Pcalloc(1, array_size+((num_keys+1)*sizeof(keys)));

		/*
		 * Make the top bit the char *i array and the rest 
		 * contains the key strings themselves
		 */

		key_str = (char *)(keys + (num_keys+1));
		
		for (i=0; i < num_keys; ++i) {
			keys[i] = key_str;
			key_str += strlen(strcpy(key_str,
				  SvPV(ST(i),na))) + 1; 
		}

		/*
		 * Call fl_set_xyplot_keys, then free the storage
		 */
		fl_set_xyplot_keys(object,keys,x,y,align);
		X4Pfree((void *)keys);
	}

	}

int 
fl_create_animated_cursor(...)
	CODE:
	{
		int 	*cursors, num_cursors, interval;
		int	i;

		num_cursors = items - 1;
		if (num_cursors < 1)
				usage("fl_create_animated_cursor");

		interval = SvIV(ST(items-1));
		
		cursors = (int *)X4Pcalloc(num_cursors+1, sizeof(int));
		for (i=0; i<num_cursors; i++)
			cursors[i] = SvIV(ST(i));
		cursors[i] = -1;

		RETVAL = fl_create_animated_cursor(cursors, interval);
		X4Pfree((void *)cursors);
	}
	OUTPUT:
	RETVAL

#endif

void 
fl_set_form_icon(form,p1,p2)
	FLForm *	form
	Pixmap		p1
	Pixmap		p2

void
fl_set_form_title(form,title)
	FLForm *	form
	const char *	title

void
fl_scale_form(form,xfact,yfact)
	FLForm *	form
	double		xfact
	double		yfact

void
fl_set_form_dblbuffer(form,i)
	FLForm *	form
	IV		i
	ALIAS:
		fl_set_form_property = 1
		fl_set_form_event_cmask = 2
	CODE:
	{
		switch (ix) {
		case 0:
				fl_set_form_dblbuffer(form,i);
			break;
		case 1:
			fl_set_form_property(form,i);
			break;
		case 2:
			fl_set_form_event_cmask(form,i);
			break;
		}
	}

void
fl_remove_canvas_handler(object,event_type)
	FLObject *	object
	int			event_type
	CODE:
	{
		object_data *ob_data = get_object_data(object);

		if (ob_data &&
		ob_data->od_cevents &&
		ob_data->od_cevents[event_type]) 
		{
			fl_remove_canvas_handler(object, event_type, process_canvas_event);
			ob_data->od_cevents[event_type] = NULL;
		}	
	}

void
fl_get_object_position(object,place=0,str="")
	FLObject *	object
	int			place
	char *		str
	ALIAS:
		fl_get_pixmap_pixmap = 1
		fl_get_clock = 2
		fl_get_input_cursorpos = 3
		fl_get_input = 5
		fl_get_canvas_id = 7
		fl_get_canvas_colormap = 8
		fl_set_xyplot_maxoverlays = 9
		fl_free_object = 10
		fl_get_xyplot_numdata = 11
		fl_get_browser = 100
		fl_get_browser_maxline = 101
		fl_get_browser_screenlines = 102
		fl_get_browser_topline = 103
		fl_get_button = 104
		fl_get_button_numb = 105
		fl_get_canvas_depth = 106
		fl_get_choice = 107
		fl_get_choice_maxitems = 108
		fl_get_menu = 109
		fl_get_menu_maxitems = 110
		fl_get_input_topline = 111
		fl_get_input_screenlines = 112
		fl_get_input_numberoflines = 113
		fl_get_folder_number = 114
		fl_get_active_folder_number = 115
		fl_get_menu_popup = 116
		fl_get_input_xoffset = 117
		fl_delete_browser_line = 200
		fl_deselect_browser_line = 201
		fl_select_browser_line = 202
		fl_set_browser_fontsize = 203
		fl_set_browser_fontstyle = 204
		fl_set_browser_specialkey = 206
		fl_set_browser_topline = 207
		fl_set_browser_vscrollbar = 208
		fl_set_button = 209
		fl_set_input_maxchars = 210
		fl_set_input_return = 211
		fl_set_input_scroll = 212
		fl_set_input_selected = 213
		fl_set_object_automatic = 214
		fl_set_object_boxtype = 215
		fl_set_object_bw = 216
		fl_set_object_dblbuffer = 217
		fl_set_object_lalign = 218
		fl_set_object_lsize = 219
		fl_set_object_lstyle = 220
		fl_set_object_return = 221
		fl_set_canvas_depth = 223
		fl_canvas_yield_to_shortcut = 224
		fl_delete_choice = 225
		fl_delete_menu_item = 226
		fl_set_choice = 227
		fl_set_choice_align = 228
		fl_set_choice_fontsize = 229
		fl_set_choice_fontstyle = 230
		fl_set_menu_popup = 231
		fl_show_menu_symbol = 232
		fl_set_object_resize = 233
		fl_set_object_shortcutkey = 234
		fl_set_counter_precision = 235
		fl_set_counter_return = 236
		fl_set_dial_cross = 237
		fl_set_dial_return = 238
		fl_set_positioner_return = 239
		fl_set_slider_precision = 240
		fl_set_slider_return = 241
		fl_delete_xyplot_overlay = 242
		fl_set_chart_autosize = 243
		fl_set_chart_maxnumb = 244
		fl_set_xyplot_fontsize = 245
		fl_set_xyplot_fontstyle = 246
		fl_set_xyplot_inspect = 247
		fl_set_xyplot_return = 248
		fl_set_xyplot_symbolsize = 249
		fl_set_chart_lstyle = 250
		fl_set_chart_lsize = 251
		fl_set_dial_direction = 252
		fl_set_input_hscrollbar = 253
		fl_set_input_vscrollbar = 254
		fl_set_input_xoffset = 255
		fl_set_input_topline = 256
		fl_set_timer_countup = 257
		fl_set_xyplot_xgrid = 258
		fl_set_xyplot_ygrid = 259
		fl_set_browser_hscrollbar = 260
		fl_set_pixmapbutton_focus_outline = 261
		fl_delete_folder_bynumber = 262
		fl_set_folder_bynumber = 263
		fl_set_scrollbar_return = 264
		fl_set_clock_ampm = 265
		fl_show_browser_line = 266
		fl_insert_browser_line = 300
		fl_replace_browser_line = 301
		fl_replace_choice = 302
		fl_replace_menu_item = 303
		fl_set_choice_item_shortcut = 304
		fl_set_menu_item_shortcut = 305
		fl_set_xyplot_key = 306
		fl_activate_object = 500
		fl_addto_group = 501
		fl_call_object_callback = 502
		fl_clear_browser = 503
		fl_deactivate_object = 504
		fl_delete_object = 505
		fl_deselect_browser = 506
		fl_draw_object_label = 507
		fl_free_pixmap_pixmap = 509
		fl_hide_object = 510
		fl_redraw_object = 511
		fl_show_object = 512
		fl_trigger_object = 513
		fl_hide_canvas = 514
		fl_clear_choice = 515
		fl_clear_menu = 516
		fl_clear_chart = 517
		fl_reset_focus_object = 518
		fl_suspend_timer = 519
		fl_resume_timer = 520
		fl_clear_xyplot = 521
		fl_draw_object_label_outside = 522
		fl_clear_menubar = 523
		fl_get_object_geometry = 600
		fl_get_browser_dimension = 601
		fl_get_object_bbox = 602
		fl_get_folder_area = 603
	PPCODE:
	{
		FL_Coord 	x, y, xl, yl;
		Pixmap		p1, p2, p3;
		Window		win;
		Colormap	cmap;
		int 		hrs, min, sec, i;
		const 		char *conch;
		object_data *   ob_data;

	switch (ix) {
		case 523:
#if FL_INCLUDE_VERSION < 87
		case 11:
		case 114:
		case 115:
		case 116:
		case 117:
		case 262:
		case 263:
		case 264:
		case 265:
		case 266:
		case 306:
		case 603:
#endif
			not_implemented(GvNAME(CvGV(cv)));
			break;
		case 0: 
			fl_get_object_position(object, &x, &y);
			EXTEND(sp, 2);
			PUSHs(sv_2mortal(newSViv(x)));
			PUSHs(sv_2mortal(newSViv(y)));
		case 1:
			p1 = fl_get_pixmap_pixmap(object, &p2, &p3);
			EXTEND(sp, 3);
			PUSHs(sv_2mortal(newSViv(p1)));
			PUSHs(sv_2mortal(newSViv(p2)));
			PUSHs(sv_2mortal(newSViv(p3)));
			break;
		case 2:
		case 3:
			if (ix == 2) 
				fl_get_clock(object, &hrs, &min, &sec);
			else
				hrs = fl_get_input_cursorpos(object, &min, &sec);
			EXTEND(sp, 3);
			PUSHs(sv_2mortal(newSViv(hrs)));
			PUSHs(sv_2mortal(newSViv(min)));
			PUSHs(sv_2mortal(newSViv(sec)));
			break;
		case 5:
			conch = fl_get_input(object);
			if (conch == NULL)
				XPUSHs(&sv_undef);
			else
				XPUSHs(sv_2mortal(newSVpv((char *)conch,0)));
			break;
		case 7:
			win = fl_get_canvas_id(object);
			XPUSHs(sv_2mortal(newSViv(win)));
			break;
		case 8:
			cmap = fl_get_canvas_colormap(object);
			XPUSHs(sv_2mortal(newSViv(cmap)));
			break;
		case 9:
			ob_data = get_object_data(object);
			if (ob_data->od_xyplot_symbol == NULL)
			{
				i = fl_set_xyplot_maxoverlays(object,place);
				(get_object_data(object))->od_max_overlays = place;
			}
			else
			{
				i = ob_data->od_max_overlays;
				alloc_overlay_data(object, place);
			}
			XPUSHs(sv_2mortal(newSViv(i)));
			break;
		case 10:
			/*
			 * We must tidy up since xforms will delete the
			 * object - nasty memory leak potential otherwise
			 */
			ob_data = get_object_data(object);
			fl_free_object(object);
			SvREFCNT_dec(ob_data->po);
			X4Pfree(ob_data);
			break;
#if FL_INCLUDE_VERSION >= 87
		case 11:
			i = fl_get_xyplot_numdata(object,place);
			XPUSHs(sv_2mortal(newSViv(i)));
			break;
#endif
		case 600:
		case 601:
		case 602:
#if FL_INCLUDE_VERSION >= 87
		case 603:
#endif
			(void_FLO_iiii_funcs[ix-600])(object, &x, &y, 
							&xl, &yl);
			EXTEND(sp, 4);
			PUSHs(sv_2mortal(newSViv(x)));
			PUSHs(sv_2mortal(newSViv(y)));
			PUSHs(sv_2mortal(newSViv(xl)));
			PUSHs(sv_2mortal(newSViv(yl)));
			break;
		default:
			if (ix >= 500)
				(void_FLO_funcs[ix-500])(object);
			else if (ix >= 300) 
				(void_FLO_int_char_funcs[ix-300])(object,
							place,str);
			else if (ix >= 200) 
				(void_FLO_int_funcs[ix-200])(object,place);
			else if (ix >= 100) {
				i = (int_FLO_funcs[ix-100])(object);
				XPUSHs(sv_2mortal(newSViv(i)));
			}
			break;
		}	
	}

void
fl_create_from_pixmapdata(win,tran,...)
	Window		win
	FL_COLOR	tran
	PPCODE:
	{
		Pixmap	result, shpmsk;
		int	hotx, hoty;
		unsigned int	w, h;
		char **	buffer;

		if (items < 3)
			usage("fl_create_from_pixmapdata");

		/*
		 * Build the pixmap data storage
		 */
		buffer = build_pixmap_data(&(ST(2)), items-2);

		result = fl_create_from_pixmapdata(win, buffer, &w, &h, 
			&shpmsk, &hotx, &hoty, tran);
		EXTEND(sp, 6);
		PUSHs(sv_2mortal(newSViv(result)));
		PUSHs(sv_2mortal(newSViv(w)));
		PUSHs(sv_2mortal(newSViv(h)));
		PUSHs(sv_2mortal(newSViv(shpmsk)));
		PUSHs(sv_2mortal(newSViv(hotx)));
		PUSHs(sv_2mortal(newSViv(hoty)));

		/*
		 * Free buffer
		 */
		X4Pfree((void *)buffer);
	}

void
fl_read_pixmapfile(win,fname,tran=0)
	Window		win
	const char *	fname
	FL_COLOR	tran
	ALIAS:
		fl_read_bitmapfile = 1
	PPCODE:
	{
		Pixmap	result, shpmsk;
		int	hotx, hoty;
		unsigned int	w, h;

		if (ix == 0) {
			result = fl_read_pixmapfile(win, fname, &w, &h, 
				&shpmsk, &hotx, &hoty, tran);
			EXTEND(sp, 6);
		} else {
			result = fl_read_bitmapfile(win, fname, &w, &h, 
				&hotx, &hoty);
			EXTEND(sp, 5);
		}

		PUSHs(sv_2mortal(newSViv(result)));
		PUSHs(sv_2mortal(newSViv(w)));
		PUSHs(sv_2mortal(newSViv(h)));
		if (ix == 0)
			PUSHs(sv_2mortal(newSViv(shpmsk)));
		PUSHs(sv_2mortal(newSViv(hotx)));
		PUSHs(sv_2mortal(newSViv(hoty)));
	}

void
fl_set_pixmap_data(object,...)
	FLObject *	object
	CODE:
	{
		char	**buffer;
		
		if (items < 2)
			usage("fl_set_pixmap_data");

		/*
		 * Build the pixmap data storage
		 */
		buffer = build_pixmap_data(&(ST(1)), items-1);

		/*
		 * Call the function
		 */
		fl_set_pixmap_data(object, buffer);

		/*
		 * free the buffer
		 */
		X4Pfree((void *)buffer);
	}

		
		
void
fl_set_object_color(object,color1,color2=0)
	FLObject *	object
	FL_COLOR	color1
	FL_COLOR	color2
	ALIAS:
		fl_set_object_lcol = 1
		fl_set_chart_lcolor = 2
	CODE:
	{
		switch (ix) {
		case 0:
			fl_set_object_color(object,color1,color2);
			break;
		case 1:
			fl_set_object_lcol(object,color1);
			break; 
		case 2:
			fl_set_chart_lcolor(object,color1);
			break;
		}
	}

void
fl_get_xyplot(object)
	FLObject *      object
	ALIAS:
		fl_get_browser_xoffset = 1
		fl_get_dial_bounds = 100
		fl_get_positioner_xbounds = 101
		fl_get_positioner_ybounds = 102
		fl_get_slider_bounds = 103
		fl_get_counter_bounds = 104
		fl_get_xyplot_xbounds = 200
		fl_get_xyplot_xmapping = 201
		fl_get_xyplot_ybounds = 202
		fl_get_xyplot_ymapping = 203
		fl_get_counter_step = 204
		fl_get_scrollbar_increment = 205
		fl_get_scrollbar_bounds = 206
		fl_get_slider_increment = 207
		fl_get_timer = 300
		fl_get_counter_value = 301
		fl_get_dial_value = 302
		fl_get_positioner_xvalue = 303
		fl_get_positioner_yvalue = 304
		fl_get_slider_value = 305
		fl_get_scrollbar_value = 306
		fl_get_input_format = 400
	PPCODE:
	{
		double	value1, value2;
		float	float1, float2;
		FL_Coord	x;
		int	int1, int2;

		switch (ix) {
#if FL_INCLUDE_VERSION < 87
		case 1:
		case 204:
		case 205:
		case 206:
		case 207:
		case 306:
			not_implemented(GvNAME(CvGV(cv)));
			break;
#endif
#if FL_INCLUDE_VERSION >= 87
		case 1:
			x = fl_get_browser_xoffset(object);
			XPUSHs(sv_2mortal(newSViv(x)));
			break;
#endif
		case 0:
			fl_get_xyplot(object, &float1, &float2, &int1);
			EXTEND(sp, 3);
			PUSHs(sv_2mortal(newSVnv(float1)));
			PUSHs(sv_2mortal(newSVnv(float2)));
			PUSHs(sv_2mortal(newSViv(int1)));
			break;
		case 400:
			fl_get_input_format(object,&int1,&int2);
			EXTEND(sp, 2);
			PUSHs(sv_2mortal(newSViv(int1)));
			PUSHs(sv_2mortal(newSViv(int2)));
			break;
		default:
			if (ix >= 300){
				value1 = (dbl_FLO_funcs[ix-300])(object);
				XPUSHs(sv_2mortal(newSVnv(value1)));
			} else {
				EXTEND(sp, 2);
				if (ix >= 200) {
					(flt_flt_FLO_funcs[ix-200])(object, 
						&float1, &float2);
					value1 = float1;
					value2 = float2;
				} else 
					(dbl_dbl_FLO_funcs[ix-100])(object, 
						&value1, &value2);
				PUSHs(sv_2mortal(newSVnv(value1)));
				PUSHs(sv_2mortal(newSVnv(value2)));
			}
			break;
		}
	}

void
fl_set_object_geometry(object,x,y=0,xl=0,yl=0)
	FLObject *	object
	FL_Coord	x
	FL_Coord	y
	FL_Coord	xl
	FL_Coord	yl
	ALIAS:
		fl_set_browser_xoffset = 1
		fl_fit_object_label = 2
		fl_set_object_position = 3
		fl_set_object_size = 4
	CODE:
	{
		switch (ix) {
		case 0:
			fl_set_object_geometry(object,x,y,xl,yl);
			break;
		case 1:
			fl_set_browser_xoffset(object,x);
			break;
		default:
			(void_FLO_FLX_FLX_funcs[ix-2])(object,x,y);
			break;
		}
	}


void 
fl_set_pixmap_pixmap(obj,p1,p2)
	FLObject *	obj 
	Pixmap		p1
	Pixmap		p2

void
fl_set_object_shortcut(object,str,show=0)
	FLObject *	object
	char *		str
	int		show
	ALIAS:
		fl_load_browser = 1
		fl_addto_choice = 2
		fl_addto_menu = 3
		fl_add_browser_line = 100
		fl_addto_browser = 101
		fl_set_bitmap_file = 102
		fl_set_bitmapbutton_file = 103
		fl_set_input = 104
		fl_set_object_label = 105
		fl_set_pixmap_file = 106
		fl_set_choice_text = 107
		fl_set_menu = 108
		fl_delete_xyplot_text = 109
		fl_addto_browser_chars = 110
		fl_set_menubar = 111
		fl_delete_folder_byname = 112
		fl_set_folder_byname = 113
	PPCODE:
	{
		int	result;
		
		switch (ix) {
		case 111:
#if FL_INCLUDE_VERSION < 87
		case 112:
		case 113:
#endif
			not_implemented(GvNAME(CvGV(cv)));
			break;
		case 0:
			fl_set_object_shortcut(object,str,show);
			break;
		case 1:
			result = fl_load_browser(object,str);
			XPUSHs(sv_2mortal(newSViv(result)));
			break;
		case 2:
#if FL_INCLUDE_VERSION >= 87
			result = 
#endif
				fl_addto_choice(object,str);
#if FL_INCLUDE_VERSION >= 87
			XPUSHs(sv_2mortal(newSViv(result)));
#endif
			break;
		case 3:
#if FL_INCLUDE_VERSION >= 87
			result = 
#endif
				fl_addto_menu(object,str);
#if FL_INCLUDE_VERSION >= 87
			XPUSHs(sv_2mortal(newSViv(result)));
#endif
			break;
		default:
			(void_FLO_char_funcs[ix-100])(object,str);
			break;
		}
	}

void
fl_set_timer(object,x,y=1)
	FLObject *	object
	double		x
	double		y
	ALIAS:
		fl_set_counter_value = 1
		fl_set_dial_step = 2 
		fl_set_dial_value = 3
		fl_set_positioner_xstep = 4
		fl_set_positioner_xvalue = 5
		fl_set_positioner_ystep = 6
		fl_set_positioner_yvalue = 7
		fl_set_slider_size = 8
		fl_set_slider_step = 9
		fl_set_slider_value = 10
		fl_set_scrollbar_value = 11
		fl_set_scrollbar_size = 12
		fl_set_scrollbar_step = 13
		fl_scale_object = 100
		fl_set_counter_bounds = 101
		fl_set_counter_step = 102
		fl_set_dial_angles = 103
		fl_set_dial_bounds = 104
		fl_set_positioner_xbounds = 105
		fl_set_positioner_ybounds = 106
		fl_set_slider_bounds = 107
		fl_set_chart_bounds = 108
		fl_set_xyplot_xbounds = 109
		fl_set_xyplot_ybounds = 110
		fl_set_slider_increment = 111
		fl_set_scrollbar_increment = 112
		fl_set_scrollbar_bounds = 113
		fl_xyplot_s2w = 200
		fl_xyplot_w2s = 201
	PPCODE:
	{
		float 	fx, fy;
	
		switch (ix) {
#if FL_INCLUDE_VERSION < 87
		case 11:
		case 12:
		case 13:
		case 112:
		case 113:
			not_implemented(GvNAME(CvGV(cv)));
			break;
#endif
		case 200:
		case 201:
			if (ix == 200)
				fl_xyplot_s2w(object, x, y, &fx, &fy);
			else
				fl_xyplot_w2s(object, x, y, &fx, &fy);
			EXTEND(sp, 2);
			PUSHs(sv_2mortal(newSVnv(fx)));
			PUSHs(sv_2mortal(newSVnv(fy)));
			break;
		default:
			if (ix >= 100)
				(void_FLO_dbl_dbl_funcs[ix-100])(object,x,y);
			else
				(void_FLO_dbl_funcs[ix])(object,x);
			break;
		}
	}


void 
fl_set_pixmap_align(obj,int1,int2,int3=0)
	FLObject *	obj 
	int 		int1
	int 		int2
	int			int3
	ALIAS:
		fl_set_object_gravity = 100
		fl_set_browser_line_selectable = 101
		fl_set_input_color = 102
		fl_set_input_cursorpos = 103
		fl_set_input_selected_range = 104
		fl_set_choice_item_mode = 105
		fl_set_menu_item_mode = 106
		fl_set_xyplot_overlay_type = 107
		fl_set_xyplot_xtics = 108
		fl_set_xyplot_ytics = 109
		fl_set_input_format = 110
		fl_set_input_scrollbarsize = 111
		fl_set_xyplot_linewidth = 112
		fl_set_browser_scrollbarsize = 113
		fl_set_xyplot_key_font = 114
	CODE:
	{
		switch (ix) {
#if FL_INCLUDE_VERSION < 87
		case 114:
			not_implemented(GvNAME(CvGV(cv)));
			break;
#endif
		case 0:
			fl_set_pixmap_align(obj,int1,int2,int3);
			break;
		default:
				(void_FLO_int_int_funcs[ix-100])(obj,int1,int2);
			break;
		}
	}

void
fl_get_app_resources(...)
	PPCODE:
	{
		int		numres, i;
		char *		str_buffer;
		FL_resource *	res_buffer;

		if (items < 3 || items%3 != 0)
			usage("fl_get_app_resources");
		numres = items / 3;

		/*
		 * Get the input and output buffers
		 */

		str_buffer = (char *)X4Pcalloc(numres, RESBUF);
		res_buffer = (FL_resource *)X4Pcalloc(numres, sizeof(FL_resource));

		/*
		 * Now build the input list
		 */

		for (i=0; i<numres; ++i) {

			res_buffer[i].type   = FL_STRING;
			res_buffer[i].var    = &str_buffer[i*RESBUF];
			res_buffer[i].nbytes = RESBUF;

			res_buffer[i].res_name  = 
				(const char *)SvPV(ST(i*3),na);
			res_buffer[i].res_class = 
				(const char *)SvPV(ST(i*3+1),na);
			res_buffer[i].defval    = 
				(const char *)SvPV(ST(i*3+2),na);

		}

		fl_get_app_resources(res_buffer, numres);

		for (i=0; i<numres; ++i) {
			if (res_buffer[i].var == NULL)
				XPUSHs(&sv_undef);
			else
				XPUSHs(sv_2mortal(newSVpv(res_buffer[i].var,0)));
			}

		X4Pfree(res_buffer);
		X4Pfree(str_buffer);
	}

#if FL_INCLUDE_VERSION >= 87

void
fl_share_canvas_colormap(object,colormap)
	FLObject *	object
	Colormap	colormap

#endif

void
fl_set_canvas_colormap(object,colormap)
	FLObject *	object
	Colormap	colormap

void
fl_set_canvas_visual(object,visual)
	FLObject *	object
	Visual *	visual

void
fl_set_canvas_attributes(object,int1,winattr)
	FLObject *		object
	unsigned		int1
	XSetWindowAttributes *	winattr

void
fl_modify_canvas_prop(object,init_cb,act_cb,clean_cb)
	FLObject *	object
	SV *		init_cb
	SV *		act_cb
	SV *		clean_cb
	CODE:
	{
		object_data *obdat = get_object_data(object);

		savesv(&obdat->od_mcpinit, init_cb);
		savesv(&obdat->od_mcpact, act_cb);
		savesv(&obdat->od_mcpclean, clean_cb);
		fl_modify_canvas_prop(object,
					  (SvNULL(init_cb) ? NULL :
					  process_mcp_init),
					  (SvNULL(act_cb) ? NULL :
					  process_mcp_act),
					  (SvNULL(clean_cb) ? NULL :
					  process_mcp_clean));
	}

void
fl_get_winsize(win)
	Window          win
	ALIAS:
		fl_get_winorigin = 1
		fl_get_wingeometry = 2
		fl_get_win_mouse = 3
		fl_reset_winconstraints = 100
		fl_winclose = 101
		fl_winhide = 102
		fl_winset = 103
		fl_activate_event_callbacks = 104
		fl_winfocus = 105
	PPCODE:
	{
		Window          outwin;
		FL_Coord        x, y, xl, yl;
		unsigned int    i1;

		switch (ix) {
#if FL_INCLUDE_VERSION < 87
		case 105:
			not_implemented(GvNAME(CvGV(cv)));
			break;
#endif
		case 0: {
			fl_get_winsize(win, &x, &y);
			EXTEND(sp, 2);
			break;
			}
		case 1:
			{
			fl_get_winorigin(win, &x, &y);
			EXTEND(sp, 2);
			break;
			}
		case 2:
			{
			fl_get_wingeometry(win, &x, &y, &xl, &yl);
			EXTEND(sp, 4);
			break;
			}
		case 3:
			{
			outwin = fl_get_win_mouse(win, &x, &y, &i1);
			EXTEND(sp, 4);
			PUSHs(sv_2mortal(newSViv(outwin)));
			break;
			}
		default:
			(void_win_funcs[ix-100])(win);
			break;
		}
		if (ix < 4) {
			PUSHs(sv_2mortal(newSViv(x)));
			PUSHs(sv_2mortal(newSViv(y)));
			if (ix == 2) {
				PUSHs(sv_2mortal(newSViv(xl)));
				PUSHs(sv_2mortal(newSViv(yl)));
			}
			if (ix == 3) {
				PUSHs(sv_2mortal(newSViv(i1)));
			}
		}
	}

void 
fl_free_pixmap(pix)
	Pixmap		pix 

void 
fl_set_cursor(window,int1)
	Window		window
	int		int1

void
fl_remove_event_callback(window,event)
	Window          window
	int             event
	CODE:
	{
		cb_data *this,  **prev;

		prev = &(get_cb_data()[event]);
		/*
		 * We only allow one handler for XErrorEvents for
		 * all windows. this is because the XErrorEvent
		 * may not contain a valid window variable
		 */
		if (!event)
			window = 0;

		while ((this = *prev) != NULL && this->window != window)
			prev = &(this->next_data);

		if (this) {
			*prev = this->next_data;
			X4Pfree(this);
		}

		fl_remove_event_callback(window, event);
	}

void
fl_XPutBackEvent(event)
	XEvent *        event

XEvent *
fl_print_xevent_name(string,event)
	const char *    string
	XEvent *  event

void 
fl_set_clippings(x,y,xl,yl,int1)
	int		x
	int		y
	int		xl
	int		yl
	int		int1
	ALIAS:
		fl_set_fselector_filetype_marker = 1
	CODE:
	{
		FL_RECT		xrect;
		switch (ix) {
		case 0:
			xrect.x = x;
			xrect.y = y;
			xrect.width = xl;
			xrect.height = yl;

			fl_set_clippings(&xrect, int1);
			break;
		case 1:
			fl_set_fselector_filetype_marker(x,y,xl,yl,int1);
			break;
		}

	}

void
fl_set_resource(str,val="")
	const char *	str
	const char *	val
	ALIAS:
		fl_set_tabstop = 1
		fl_set_pattern = 2
	CODE:
	{
		switch (ix) {
		case 0:
			fl_set_resource(str,val);
			break;
		case 1:
			fl_set_tabstop(str);
			break;
		case 2:
			fl_set_pattern(str);
			break;
		}
	}

void 
fl_set_gamma(d1,d2,d3)
	double		d1
	double		d2
	double		d3

void
fl_add_float_vertex(f1,f2)
	float           f1
	float           f2

void
fl_set_visualID(i)
	long		i
	ALIAS:
		fl_get_cursor_byname = 1
		fl_remove_signal_callback = 2
		fl_set_idle_delta = 3
		fl_set_app_nomainform = 100
		fl_set_border_width = 101
		fl_set_color_leak = 102
		fl_set_coordunit = 103
		fl_show_errors = 104
		fl_signal_caught = 105
		fl_app_signal_direct = 106
		fl_freepup = 107
		fl_hidepup = 108
		fl_initial_winstate = 109
		fl_showpup = 110
		fl_disable_fselector_cache = 111
		fl_set_fselector_border = 112
		fl_set_fselector_placement = 113
		fl_drawmode = 114
		fl_linestyle = 115
		fl_linewidth = 116
		fl_ringbell = 117
		fl_show_command_log = 118
		fl_set_fselector_fontsize = 119
		fl_set_fselector_fontstyle = 120
		fl_set_dirlist_sort = 121
		fl_set_scrollbar_type = 122
	PPCODE:
	{
		Cursor		crsr;
		sig_data	*this,	**prev = &sig_cb;

	switch (ix) {
#if FL_INCLUDE_VERSION < 122
	case 105:
		not_implemented(GvNAME(CvGV(cv)));
		break;
#endif
	case 0:
		fl_set_visualID(i);
		break;
	case 1:
		crsr = fl_get_cursor_byname((int)i);
		XPUSHs(sv_2mortal(newSViv(crsr)));
		break;
	case 2:
		/*
		 * See if this signal has a callback
		 * already set.
		 */
		while ((this = *prev) && (this->sgnl != i))
			prev = &(this->next_data);

		if (this) {
			/* 
			 * A callback was found, unchain the data block,
			 * call the fl_ routine and free the data block
			 */
			(*prev)->next_data = this->next_data;
			fl_remove_signal_callback(this->sgnl);
			X4Pfree(this);
		}
		break;
	case 3:
		fl_set_idle_delta(i);
		break;
	default:
		(void_int_funcs[ix-100])((int)i);
		break;
	}
	}

void 
fl_set_cursor_color(int1,col1,col2)
	int		int1
	FL_COLOR	col1
	FL_COLOR	col2

void 
fl_add_signal_callback(sgnl,callback,parm)
	int		sgnl 
	SV *		callback 
	SV *		parm
	CODE:
	{
		sig_data	*this,	**prev = &sig_cb;
		parm = get_a_ref(parm);

		/*
		 * Now see if this signal has a callback
		 * already set.
		 */
		while ((this = *prev) && (this->sgnl != sgnl))
			prev = &(this->next_data);

		if (!this) {
			/* 
			 * No callback was found, get a new io_data
			 * area and chain the end of the list for
			 * the current event
			 */
			this = *prev =
				(sig_data *)X4Pcalloc(1, sizeof(sig_data));
		} else {
			fl_remove_signal_callback(this->sgnl);
		}
		/*
		 * Now save the callback pointer and call the
		 * XForm library function, using the sig_data pointer
		 * as the parm
		 */
		this->callback = callback;
		this->sgnl = sgnl; 
		this->parm = parm; 

		fl_add_signal_callback(sgnl,
				   process_signal_callback,
				   this);
	}

void
fl_setpup_title(num,string)
	int		num
	const char *	string
	ALIAS:
		fl_set_font_name = 1
		fl_addtopup = 2
	PPCODE:
	{
		int	result;

		switch (ix) {
		case 0:
			fl_setpup_title(num,string);
			break;
		case 1:	
			result = fl_set_font_name(num,string);
			XPUSHs(sv_2mortal(newSViv(result)));
			break;
		case 2:
			result = fl_addtopup(num,string);
			XPUSHs(sv_2mortal(newSViv(result)));
			break;
		}
	}

void 
fl_get_align_xy(int1,int2,int3,int4,int5,int6,int7,int8,int9)
	int             int1
	int             int2
	int             int3
	int             int4
	int             int5
	int             int6
	int             int7
	int             int8
	int             int9
	PPCODE:
	{
		int     int10, int11;

		fl_get_align_xy(int1, int2, int3, int4, int5,
				int6, int7, int8, int9, 
				&int10, &int11);

		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSViv(int10)));
		PUSHs(sv_2mortal(newSViv(int11)));
	}


void 
fl_remove_io_callback_real(fd,condition)
	int		fd 
	unsigned	condition 
	CODE:
	{
		io_data	*this,	**prev = &io_cb;

		/*
		 * Now see if this fd/condition pair has a callback set
		 */
		while ((this = *prev) && 
		(this->fd != fd || this->condition != condition ))
			prev = &(this->next_data);

		if (this) {
			/* 
			 * A callback was found, remove from the chain,
			 * and free the data area 
			 */
			*prev = this->next_data;
			X4Pfree(this);
		}
		/*
		 * Now call the XForm library function
		 */
		fl_remove_io_callback(fd, condition, 
					  process_io_event_callback);
	}

void 
fl_add_io_callback_real(fd,condition,callback,parm,fh)
	int		fd 
	unsigned	condition 
	SV *		callback 
	SV *		parm
	SV *		fh
	CODE:
	{
		io_data	*this,	**prev = &io_cb;
		parm = get_a_ref(parm);

		/*
		 * Now see if this fd/condition pair has a callback
		 * already set.
		 */
		while ((this = *prev) && 
		(this->fd != fd || this->condition != condition ))
			prev = &(this->next_data);

		if (!this) {
			/* 
			 * No callback was found, get a new io_data
			 * area and chain the end of the list for
			 * the current event
			 */
			this = *prev =
				(io_data *)X4Pcalloc(1, sizeof(io_data));
		}
		/*
		 * Now save the callback pointer and call the
		 * XForm library function, using the io_data pointer
		 * as the parm
		 */
		savesv(&this->callback,callback);
		this->fd = fd; 
		this->condition = condition; 
		this->parm = parm;
        this->fh = fh; 

		fl_add_io_callback(fd, condition, 
				   process_io_event_callback,
				   this);
	}

void 
fl_free_pixels(...)
	CODE:
	{
		unsigned long 	*pixels;
		int	i = 1;

		if (items < 1)
				usage("fl_free_pixels");
		
		pixels = (unsigned long *)X4Pcalloc(items, sizeof(unsigned long));
		for (i=0; i<items; i++)
			pixels[i] = SvIV(ST(i));

		fl_free_pixels(pixels, items);
		X4Pfree((void *)pixels);
	}

FLOpt *
fl_get_defaults()
	CODE:
	{
		RETVAL = X4Pcalloc(sizeof(FL_IOPT), 1);
		fl_get_defaults(RETVAL);	
	}
	OUTPUT:
	RETVAL

void
fl_set_defaults(mask,opts)
	long		mask
	FLOpt *		opts

FLForm *
fl_win_to_form(win)
	Window		win
	CODE:
	{
		ST(0) = bless_form(fl_win_to_form(win));
	}

Cursor
fl_setpup_default_cursor(int1,int2=0)
	int		int1
	int		int2
	ALIAS:
		fl_setpup_cursor = 1
	CODE:
	{
		switch (ix) {
		case 0:
			RETVAL = fl_setpup_default_cursor(int1);
			break;
		case 1:
			RETVAL = fl_setpup_cursor(int1,int2);
			break;
		}
	}
	OUTPUT:
	RETVAL

Window
fl_get_real_object_window(object)
	FLObject *	object

int
fl_winreparent(win1,win2)
	Window		win1
	Window		win2

Window
fl_winshow(win)
	Window		win

Window
fl_wincreate(string)
	const char *	string
	ALIAS:
		fl_winopen = 1
	CODE:
		ix ? fl_winopen(string) : fl_wincreate(string);

Window
fl_winget()

int
fl_defpup(iv_parm,string="")
	IV		iv_parm
	const char *	string
	ALIAS:
		fl_newpup = 1
		fl_winisvalid = 2
		fl_keysym_pressed = 3
	CODE:
	{
		switch(ix) {
		case 0:
			RETVAL = fl_defpup(iv_parm,string);
			break;
		case 1:
		   	RETVAL = fl_newpup(iv_parm);
			break;
		case 2:
			RETVAL = fl_winisvalid(iv_parm);
			break;
		case 3:
			RETVAL = fl_keysym_pressed(iv_parm);
			break;
		}
	}
	OUTPUT:
	RETVAL

void
fl_set_gc_clipping(gc1,x=0,y=0,xl=0,yl=0)
	GC		gc1
	FL_Coord	x
	FL_Coord	y
	FL_Coord	xl
	FL_Coord	yl
	ALIAS:
		fl_unset_gc_clipping = 1
	CODE:
	{
		switch (ix) {
		case 0:
			fl_set_gc_clipping(gc1,x,y,xl,yl);
			break;
		case 1:
			fl_unset_gc_clipping(gc1);
			break;
		}
	}

void
fl_winicon(win,p1,p2)
	Window		win
	Pixmap		p1
	Pixmap		p2

void
fl_wintitle(win,string)
	Window		win
	const char *	string

long
fl_winbackground(win,ul)
	Window		win
	unsigned long	ul
	ALIAS:
		fl_addto_selected_xevent = 1
		fl_remove_selected_xevent = 2
	CODE:
	{
		switch (ix) {
		case 0:
			RETVAL = 1;
			fl_winbackground(win,ul);
			break;
		case 1:
			RETVAL = fl_add_selected_xevent(win,ul);
			break;
		case 2:
			RETVAL = fl_remove_selected_xevent(win,ul);
			break;
		}
	}
	OUTPUT:
	RETVAL

void
fl_set_text_clipping(int1,int2,int3=0,int4=0)
	int		int1
	int		int2
	int		int3
	int		int4
	ALIAS:
		fl_setpup_submenu = 100
		fl_setpup_pad = 101
		fl_set_pixmap_colorcloseness = 102
		fl_set_font = 200
		fl_set_graphics_mode = 201
		fl_set_ul_property = 202
		fl_setpup_bw = 203
		fl_setpup_position = 204
		fl_setpup_selection = 205
		fl_setpup_shadow = 206
		fl_setpup_softedge = 207
		fl_set_goodies_font = 208
		fl_set_oneliner_font = 209
		fl_set_command_log_position = 210
	CODE:
	{
		switch (ix) {
		case 0:
			fl_set_text_clipping(int1,int2,int3,int4);
			break;
		default:
			if (ix >= 200)
				(void_int_int_funcs[ix-200])(int1, int2);
			else
				(void_iii_funcs[ix-100])(int1,int2,int3);
			break;
		}
	}

GC
fl_create_GC()
	ALIAS:
		fl_textgc = 1
		fl_get_gc = 2
	CODE:
	{
		switch (ix) {
		case 0:
			RETVAL = XCreateGC(fl_get_display(),
				   fl_default_window(),0,0);
			break;
		case 1:
			RETVAL = fl_textgc;
			break;
		case 2:
#if FL_INCLUDE_VERSION >= 87
			RETVAL = fl_get_gc();
#else
			RETVAL = fl_state[fl_vmode].gc[0];
#endif
			break;
		}
	}
	OUTPUT:
	RETVAL


void
fl_fill_rectangle(win,gc,x,y,xl,yl)
	Window		win
	GC		gc
	int		x
	int		y
	int		xl
	int		yl
	CODE:
	{
		XFillRectangle(fl_get_display(), win, gc, x, y, xl, yl);
	}

void
fl_set_background(gc,color)
	GC		gc
	FL_COLOR	color
	ALIAS:
		fl_set_foreground = 1
	CODE:
		ix ? fl_set_foreground(gc,color) 
		   : fl_set_background(gc,color);

int
fl_show_choice(line1,line2,line3,value,line4,line5,line6,value2=0)
	char *          line1
	char *          line2
	char *          line3
	int             value
	char *          line4
	char *          line5
	char *          line6
	int             value2
	CODE:
		RETVAL = fl_show_choice(line1,line2,line3,
				value,line4,line5,line6,value2);
	OUTPUT:
	RETVAL

int
fl_show_choices(line1,value,line4,line5,line6,dflt)
	char *          line1
	int             value
	char *          line4
	char *          line5
	char *          line6
	int		dflt

void
fl_remove_fselector_appbutton(string)
	const char *    string
	CODE:
	{
		facb_data        *this,   **prev = get_facb_data(current_fsel);

		while ((this = *prev) && !strcmp(&this->string,string))
			prev = &(this->next_data);

		if (this) {
			*prev = this->next_data;
			X4Pfree(this);
		}

		fl_remove_fselector_appbutton(string);
	}

void
fl_show_oneliner(string,x,y)
	const char *    string
	FL_Coord        x
	FL_Coord        y

void
fl_show_alert(line1,line2,line3,value=0)
	char *          line1
	char *          line2
	char *          line3
	int             value
	ALIAS:
		fl_set_choice_shortcut = 1
		fl_show_message = 2
	CODE:
	{
		switch(ix) {

			case 0:
				fl_show_alert(line1,line2,line3,value);
				break;
			case 1:
				fl_set_choice_shortcut(line1,line2,line3);
				break;
			case 2:
				fl_show_message(line1,line2,line3);
				break;
		}
	}

void
fl_add_fselector_appbutton(string,callback,parm)
	const char *    string
	SV *            callback
	SV *		parm
	CODE:
	{
		/*
		 * These buttons are a pain! They get keyed by the
		 * string on them! Anyway, to cater for this, facb_data
		 * structures get chained off an array of pointers held
		 * above. And, to get over the 'unknownness' of the
		 * button that actually calls the callback, the facb_data
		 * structure is passed as the parm, the application's parm
		 * being hidden in the structure!
		 */

		facb_data        *this,   **prev = get_facb_data(current_fsel);
		parm = get_a_ref(parm);

		/*
		 * Now see if this button is already there. If so,
		 * delete it first!.
		 */
		while ((this = *prev) && strcmp(&(this->string),string))
			prev = &(this->next_data);

		if (this) {
			/*
			 * A button was found, delete it and use its
			 * area
			 */
			fl_remove_fselector_appbutton(string);
		} else {
			/*
			 * No callback was found, get a new facb_data
			 * area and chain the end of the list for
			 * the current form
			 */
			this = *prev =
				(facb_data *)X4Pcalloc(1, sizeof(facb_data)+
						   strlen(string));
			this->next_data = NULL;
			strcpy(&(this->string), string);
		}
		/*
		 * Now save the callback pointerand the user parm and call the
		 * XForm library function
		 */
		savesv(&this->callback, callback);
		this->parm = parm;

		fl_add_fselector_appbutton(string,
					   (SvNULL(callback) ? NULL :
					   process_fselapp_callback),
					   this);
	}

void
fl_line(x,y,w,h,c)
	FL_Coord        x
	FL_Coord        y
	FL_Coord        w
	FL_Coord        h
	FL_COLOR        c
	ALIAS:
		fl_ovalbound = 1
		fl_rectbound = 2
	CODE:
	{
		(xywhc_funcs[ix])(x,y,w,h,c);
	}

void
fl_draw_text(int1,x,y,w,h,c,int2=0,int3=0,string="")
	int             int1
	FL_Coord        x
	FL_Coord        y
	FL_Coord        w
	FL_Coord        h
	FL_COLOR        c
	int             int2
	int             int3
	char *          string
	ALIAS:
		fl_drw_text = 1
		fl_drw_text_beside = 2
		fl_roundrectangle = 100
		fl_rectangle = 101
		fl_oval = 102
		fl_drw_box = 200
		fl_drw_checkbox = 201
		fl_drw_frame = 202
	CODE:
	{
		if (ix == 0)
			fl_draw_text(int1,x,y,w,h,c,int2,int3,string);
		if (ix >= 200)
			(txywhci_funcs[ix-200])(int1,x,y,w,h,c,int2);
		else if(ix >= 100)
			(txywhc_funcs[ix-100])(int1,x,y,w,h,c);
		else
			(txywhciis_funcs[ix-1])(int1,x,y,w,h,c,int2,int3,
					string);
	}


void
fl_pieslice(i1,x,y,xl,yl,i6,i7,c)
	int             i1
	FL_Coord        x
	FL_Coord        y
	FL_Coord        xl
	FL_Coord        yl
	int             i6
	int             i7
	FL_COLOR        c
	ALIAS:
		fl_ovalarc = 1
	CODE:
	{
		switch (ix) {
		case 0:
			fl_pieslice(i1,x,y,xl,yl,i6,i7,c);
			break;
		case 1:
			fl_ovalarc(i1,x,y,xl,yl,i6,i7,c);
			break;
		}
	}

void
fl_drw_text_cursor(int1,x,y,xl,yl,int2,int3,int4,string,int5,int6)
	int             int1
	FL_Coord        x
	FL_Coord        y
	FL_Coord        xl
	FL_Coord        yl
	int             int2
	int             int3
	int             int4
	char *          string
	int             int5
	int             int6

void
fl_polygon(...)
	ALIAS:
		fl_polyl = 1
		fl_polyf = 2
		fl_polybound = 3
		fl_lines = 100
		fl_points = 101
	CODE:
	{
		XPoint  *polypts, *savepts;
		int     type, i, color, numpts;
#if FL_INCLUDE_VERSION < 87
		if (ix == 101)
			not_implemented(GvNAME(CvGV(cv)));
#endif
		if (ix == 0) {
			if (items < 4 || items % 2 != 0)
				usage("fl_polygon");
			i = 1;
			numpts = (items - 2) / 2;
			type = SvIV(ST(0));
		} else {
			if (items < 3 || (items-1) % 2 != 0)
				usage(GvNAME(CvGV(cv)));
			i = 0;
			numpts = (items - 1) / 2;
			type = ix - 1;
		}

		/* Build XPoint data */
		polypts = (XPoint *)X4Pcalloc(numpts, sizeof(XPoint));
		if (polypts == NULL)
			croak("Failed to get XPoint storage");
		savepts = polypts;
		while(i<items-1) {
			polypts->x = SvIV(ST(i));
			i++;
			polypts->y = SvIV(ST(i));
			i++;
			polypts++;
		}

		color = SvIV(ST(items-1));

		if (ix == 3)
			fl_polybound(savepts, numpts, color);
		else if (ix == 100)
			fl_lines(savepts,numpts,color);
#if FL_INCLUDE_VERSION >= 87
		else if (ix == 101)
			fl_points(savepts,numpts,color);
#endif
		else
			fl_polygon(type,savepts,numpts,color);

		X4Pfree((void *)savepts);
	}

void
fl_dashedlinestyle(c,i)
	char *          c
	int             i

void
fl_interpolate(...)
	PPCODE:
	{
		float           *inx, *iny, *outx, *outy, temp;
		int             i, rc, ndeg, numpts;
		double          grid;

		if (items < 4 || items % 2 != 0)
			usage("fl_interpolate");

		/* The number of points sent */
		numpts = (items - 2) / 2;

		/* now get ndeg and grid */
		grid = SvNV(ST(items-2));
		ndeg = SvIV(ST(items-1));

		/* build the point data */
		build_xyplot_data(&(ST(0)), numpts, &inx, &iny);

		/* Calculate the number of points coming back (as per xforms doc) */
		temp = ((inx[numpts - 1] - inx[0]) / grid) + 1.01;
		if ((int)temp < 0)
			croak("fl_interpolate: data not in ascending order.");	

		if ((int)temp > 0)
		{
			/* Allocate output area */
			outx = (float *)X4Pcalloc(sizeof(float), ((int)temp)*2);
			outy = outx + (int)temp;

			/* Call the function! */
			rc = fl_interpolate(inx,iny,numpts,outx,outy,grid,ndeg);

			if (rc > (int)temp)
				croak("fl_interpolate: too many points returned.");

			/* Now return the list */
			if (rc > 0)
			{
				EXTEND(sp, (rc*2)+1);
				PUSHs(sv_2mortal(newSViv(rc)));
				for (i = 0; i < rc; ++i)
				{
					PUSHs(sv_2mortal(newSVnv(outx[i])));
					PUSHs(sv_2mortal(newSVnv(outy[i])));
				}
			} 
			else 
			{
				XPUSHs(&sv_undef);
			}
			X4Pfree((void*)outx);
		}
		else
		{
			XPUSHs(&sv_undef);
		}
		X4Pfree((void*)inx);
	}

void
fl_set_xyplot_data(object,...)
	FLObject *      object
	CODE:
	{
		float           *xfloat, *yfloat;
		int             i, numpts, xST, yST;
		char            *str1, *str2, *str3;
		if (items < 6 || items % 2 != 0)
			usage("fl_set_xyplot_data");
		/* The number of points sent */
		numpts = (items - 4) / 2;

		/*
		 * get the string data
		 */
		str1 = SvPV(ST(items-3),na);
		str2 = SvPV(ST(items-2),na);
		str3 = SvPV(ST(items-1),na);

		/* build the point data */
		build_xyplot_data(&(ST(1)), numpts, &xfloat, &yfloat);

		/* call the function */
		fl_set_xyplot_data(object,xfloat,yfloat,numpts,
					(const char *)str1,
					(const char *)str2,
					(const char *)str3);

		/* Free the data area */
		X4Pfree((void *)xfloat);
	}

void
fl_add_xyplot_overlay(object,overlay_id,...)
	FLObject *      object
	int             overlay_id
	CODE:
	{
		float   *xfloat, *yfloat;
		int     i, numpts, color;

		if (items < 5 || (items-1) % 2 != 0)
			usage("fl_add_xyplot_overlay");
		numpts = (items - 3) / 2;
		color = SvIV(ST(items-1));

		/* build the point data AND SAVE IT FOR POSSIBLE _get_ */
		build_xyplot_data(&(ST(2)), numpts, &xfloat, &yfloat);

		/* call the function */
		fl_add_xyplot_overlay(object,overlay_id,xfloat,yfloat,numpts,color);

		/* Free the data area */
		X4Pfree((void *)xfloat);
	}

void
fl_set_xyplot_xscale(object,i,d,string="",int2=0)
	FLObject *      object
	int             i
	double          d
	const char *    string
	int             int2
	ALIAS:
		fl_set_xyplot_yscale = 1
		fl_insert_chart_value = 2
		fl_replace_chart_value = 3
	CODE:
	{
		switch (ix) {
		case 0:
			fl_set_xyplot_xscale(object,i,d);
			break;
		case 1:
			fl_set_xyplot_yscale(object,i,d);
			break;
		case 2:
			fl_insert_chart_value(object,i,d,string,int2);
			break;
		case 3:
			fl_replace_chart_value(object,i,d,string,int2);
			break;
		}
	}

int
fl_set_xyplot_file(object,filename,title,xlabel="",ylabel="")
	FLObject *      object
	const char *    filename
	const char *    title
	const char *    xlabel
	const char *    ylabel
	ALIAS:
		fl_set_xyplot_alphaxtics = 100
		fl_set_xyplot_alphaytics = 101
		fl_set_xyplot_fixed_xaxis = 102
		fl_set_xyplot_fixed_yaxis = 103
	CODE:
	{
		switch (ix) {
		case 0:
			RETVAL = 
#if FL_INCLUDE_VERSION < 87
				0;
#endif
				fl_set_xyplot_file(object,filename,title,xlabel,ylabel);
			break;
		default:
			RETVAL = 0;
			(void_FLO_char_char_funcs[ix-100])(object,filename,title);
			break;
		}
	}
	OUTPUT:
	RETVAL


void
fl_add_chart_value(object,double1,string,int1)
	FLObject *      object
	double          double1
	const char *    string
	int             int1

void
fl_add_xyplot_text(object,value1,value2,string,value3,color)
	FLObject *      object
	double          value1
	double          value2
	const char *    string
	int             value3
	int             color

void
fl_replace_xyplot_point(object,value1,value2,value3)
	FLObject *      object
	int             value1
	double          value2
	double          value3

void
fl_set_xyplot_interpolate(object,value1,value2,value3)
	FLObject *      object
	int             value1
	int             value2
	double          value3

void
fl_set_error_logfp_real(fd)
	int		fd
	CODE:
	{
#if FL_INCLUDE_VERSION >= 87
		error_log = fdopen(fd, "w");
        if (error_log == NULL)
			croak("Failed to create FILE pointer for log file");

        fl_set_error_logfp(error_log);
#else
		croak("fl_set_error_logfp is not implemeted");
#endif
	}

#if FL_INCLUDE_VERSION >= 87

void
fl_set_error_handler(callback)
	SV *		callback
	CODE:
	{
        savesv(&error_handler, callback);
        fl_set_error_handler(process_error_handler);
	}

int 
fl_add_xyplot_overlay_file(object,int1,string1,col1)
	FLObject *		object
	int				int1
	const char *	string1
	FL_COLOR		col1

#else

void 
fl_add_xyplot_overlay_file(object,int1,string1,col1)
	FLObject *		object
	int				int1
	const char *	string1
	FL_COLOR		col1

#endif

#ifdef XFOPENGL

void 
fl_set_glcanvas_defaults(...)
	CODE:
	{
		int 		*defaults;
		int		i;

		if (items < 1)
				usage("fl_set_glcanvas_defaults");
		
		/*
 		 * Allocate storage and fill it.
		 */
		defaults = (int *)X4Pcalloc(items+1, sizeof(int));
		for (i = 0; i < items; i++) {
			defaults[i] = SvIV(ST(i));
		}
		defaults[items] = 0;
		fl_set_glcanvas_defaults(defaults);

		/* Ok, we're done, lose the area */
		X4Pfree((void*)defaults);
	}

void 
fl_get_glcanvas_defaults()
	PPCODE:
	{
		int 		defaults[32];	  /* FIXME: bogus constant */
		int		i;

		fl_get_glcanvas_defaults(defaults);

		/* push all defaults on the stack */
		for(i = 0; defaults[i] != 0; i++) {
		}

		EXTEND(sp, i);

		for(i = 0; defaults[i] != 0; i++) {
			PUSHs(sv_2mortal(newSViv(defaults[i])));
		}
	}


void 
fl_set_glcanvas_attributes(object,...)
	FLObject *	object
	CODE:
	{
		int 		*defaults;
		int		i;

		if (items < 2)
				usage("fl_set_glcanvas_attributes");
		/*
 		 * Allocate storage and fill it.
		 */
		defaults = (int *)X4Pcalloc(items, sizeof(int));
		for (i = 1; i < items; i++) {
			defaults[i-1] = SvIV(ST(i));
		}
		defaults[items-1] = 0;
		fl_set_glcanvas_attributes(object, defaults);

		/* Ok, we're done, lose the area */
		X4Pfree((void*)defaults);
	}

void 
fl_get_glcanvas_attributes(object)
	FLObject *	object
	PPCODE:
	{
		int 	defaults[32];	  /* FIXME: bogus constant */
		int	i;

		fl_get_glcanvas_attributes(object, defaults);

		for(i = 0; defaults[i] != 0; i++) {
		}

		EXTEND(sp, i);

		/* push all defaults on the stack */
		for(i = 0; defaults[i] != 0; i++) {
			PUSHs(sv_2mortal(newSViv(defaults[i])));
		}
	}


void
fl_set_glcanvas_direct(object, flag)
	FLObject *	object
	int		flag

void
fl_activate_glcanvas(object)
	FLObject *	object

XVisualInfo *
fl_get_glcanvas_xvisualinfo(object)
	FLObject *	object

GLXContext
fl_get_glcanvas_context(object)
	FLObject *	object

void 
fl_glwincreate(int1,int2)
	int		int1
	int		int2
	ALIAS:
		fl_glwinopen = 1
	PPCODE:
	{
		Window 		win;
		GLXContext	glxc;
		int		int3;
		win = (ix ? fl_glwinopen(&int3, &glxc, int1, int2)
			  : fl_glwincreate(&int3, &glxc, int1, int2));
		EXTEND(sp, 3);
		PUSHs(sv_2mortal(newSViv(win)));
		PUSHs(sv_2mortal(newSViv(int3)));
		PUSHs(sv_2mortal(newSViv((IV)glxc)));
	}

#else

#if XSUBPP_VERSION < 1935

void
fl_get_glcanvas_defaults(...)
	CODE:
	{
		croak("Xforms4Perl OpenGL functions are not installed.");
	}

void
fl_set_glcanvas_attributes(...)
	CODE:
	{
		croak("Xforms4Perl OpenGL functions are not installed.");
	}

void
fl_get_glcanvas_attributes(...)
	CODE:
	{
		croak("Xforms4Perl OpenGL functions are not installed.");
	}

void
fl_set_glcanvas_direct(...)
	CODE:
	{
		croak("Xforms4Perl OpenGL functions are not installed.");
	}

void
fl_get_glcanvas_xvisualinfo(...)
	CODE:
	{
		croak("Xforms4Perl OpenGL functions are not installed.");
	}

void
fl_get_glcanvas_context(...)
	CODE:
	{
		croak("Xforms4Perl OpenGL functions are not installed.");
	}

void
fl_glwincreate(...)
	CODE:
	{
		croak("Xforms4Perl OpenGL functions are not installed.");
	}

void
fl_glwinopen(...)
	CODE:
	{
		croak("Xforms4Perl OpenGL functions are not installed.");
	}

void
fl_activate_glcanvas(...)
	CODE:
	{
		croak("Xforms4Perl OpenGL functions are not installed.");
	}

void
fl_set_glcanvas_defaults(...)
	CODE:
	{
		croak("Xforms4Perl OpenGL functions are not installed.");
	}

#else

void
fl_set_glcanvas_defaults(...)
	ALIAS:
		fl_get_glcanvas_defaults = 3
		fl_set_glcanvas_attributes = 4
		fl_get_glcanvas_attributes = 5
		fl_set_glcanvas_direct = 6
		fl_get_glcanvas_xvisualinfo = 7
		fl_get_glcanvas_context = 8
		fl_glwincreate = 9
		fl_glwinopen = 10
		fl_activate_glcanvas = 11
	CODE:
	{
		croak("Xforms4Perl OpenGL functions are not installed.");
	}

#endif

#endif

MODULE = X11::Xforms	PACKAGE = X11::Xforms::FLForm 	PREFIX = fl_form_

PROTOTYPES: DISABLE

long
fl_form_u_ldata(...)
	CODE:
	{
		int		ud;
		FLForm * 	form; 

		ud = update_field(items);
		form = (FLForm *)chk_bless(ST(0), X11XformsFLForm);
		RETVAL = form->u_ldata;
		if (ud)
			form->u_ldata = SvIV(ST(1));
	}
	OUTPUT:
	RETVAL

void *
fl_form_u_vdata(...)
	CODE:
	{
		int			rw;
		FLForm * 	form; 

		rw = update_field(items);
		form = (FLForm *)chk_bless(ST(0), X11XformsFLForm);
		ST(0) = (SV *)get_form_data(form)->u_vdata;
		if (rw)
			get_form_data(form)->u_vdata = (void *)(ST(1));
	}

void *
fl_form_fdui(...)
	CODE:
	{
		int			rw;
		FLForm * 	form; 

		rw = update_field(items);
		form = (FLForm *)chk_bless(ST(0), X11XformsFLForm);
		ST(0) = (SV *)form->fdui;
		if (rw)
			form->fdui = (void *)(ST(1));
	}

FL_Coord
fl_form_x(...)
	ALIAS:
		y = 1
		w = 2
		h = 3
		hotx = 4
		hoty = 5
	CODE:
	{
		long	rw;
		FL_Coord field;
		FLForm * 	form; 

		rw = update_field(items);
		form = (FLForm *)chk_bless(ST(0), X11XformsFLForm);

		RETVAL = ((FLF_ARRAY *)form)->flf_flc[ix];
		if (rw)
			((FLF_ARRAY *)form)->flf_flc[ix] = 
				(FL_Coord)SvIV(ST(1));
	}
	OUTPUT:
	RETVAL

Window
fl_form_window(form)
	FLForm *	form
	CODE:
	{
		RETVAL = form->window;
	}
	OUTPUT:
	RETVAL

unsigned long
fl_form_vmode(...)
	ALIAS:
		deactivated = 1
		use_pixmap = 2
		frozen = 3
		visible = 4
		wm_border = 5
		prop = 6
		has_auto = 7
		top = 8
		compress_mask = 100
		evmask = 101
		icon_pixmap = 102
		icon_mask = 103
	CODE:
	{
		long	rw, field;
		FLForm * 	form; 

		rw = update_field(items);
		form = (FLForm *)chk_bless(ST(0), X11XformsFLForm);
		
		if (rw)
			field = SvIV(ST(1));

		switch (ix) {
		case 100:
			ObjRWfld(form->compress_mask);
			break;
		case 101:
			ObjRWfld(form->evmask);
			break;
		case 102:
			ObjRWfld(form->icon_pixmap);
			break;
		case 103:
			ObjRWfld(form->icon_mask);
			break;
		default:
			ObjRWfld(((FLF_ARRAY *)form)->flf_int[ix]);
		}
	}
	OUTPUT:
	RETVAL


char * 
fl_form_label(...)
	ALIAS:
		u_cdata = 1
	CODE:
	{
		int	rw;
		FLForm * 	form; 

		rw = update_field(items);
		form = (FLForm *)chk_bless(ST(0), X11XformsFLForm);
		
		if (ix == 0)
		{
			RETVAL = form->label;
			if (rw)
				form->label = SvPV(ST(1),na);
		}
		else
#if FL_INCLUDE_VERSION < 87
			croak("Field \"%s\" not in FL_FORM structure in your version of xforms", GvNAME(CvGV(cv)));
#else
		{
			RETVAL = form->u_cdata;
			if (rw)
				form->u_cdata = SvPV(ST(1),na);
		}
#endif
	}
	OUTPUT:
	RETVAL

FLObject *
fl_form_first(form)
	FLForm *	form
	ALIAS:
		last = 1
		focusobj = 2
	CODE:
	{
		RETVAL = (((FLF_ARRAY *)form)->flf_flo[ix]);
		if (RETVAL == NULL)
			ST(0) = &sv_undef;
		else
			ST(0) = bless_object(RETVAL);			
	}

MODULE = X11::Xforms	PACKAGE = X11::Xforms::FLObject 	PREFIX = fl_object_

PROTOTYPES: DISABLE

FLForm *
fl_object_form(object)
	FLObject *	object
	CODE:
	{
		RETVAL = object->form;
		if (RETVAL == NULL)
			ST(0) = &sv_undef;
		else
			ST(0) = bless_form(RETVAL);			
	}

long
fl_object_u_ldata(object,...)
	FLObject *	object
	CODE:
	{
		int	rw;
		FLObject * 	object; 

		rw = update_field(items);
		object = (FLObject *)chk_bless(ST(0), X11XformsFLObject);
		
		RETVAL = object->u_ldata;
		if (rw)
			object->u_ldata = SvIV(ST(1));
	}
	OUTPUT:
	RETVAL

void *
fl_object_u_vdata(...)
	CODE:
	{
		int	rw;
		FLObject * 	object; 

		rw = update_field(items);
		object = (FLObject *)chk_bless(ST(0), X11XformsFLObject);
		
		ST(0) = (SV *)get_object_data(object)->u_vdata;
		if (rw)
			get_object_data(object)->u_vdata = (void *)(ST(1));
	}

FL_Coord
fl_object_x(...)
	ALIAS:
		y = 1
		w = 2
		h = 3
		bw = 4
	CODE:
	{
				FL_Coord field;
				int     rw;
		FLObject * 	object; 

		rw = update_field(items);
		object = (FLObject *)chk_bless(ST(0), X11XformsFLObject);
		
		RETVAL = ((FLO_ARRAY *)object)->flo_flc[ix];
		if (rw)
			((FLO_ARRAY *)object)->flo_flc[ix] =
							(FL_Coord)SvIV(ST(1));
	}
	OUTPUT:
	RETVAL

FL_COLOR
fl_object_col1(...)
	ALIAS:
		col2 = 1
		lcol = 2
		aux_col1 = 3
		aux_col2 = 4
		dbl_background = 5
	CODE:
	{
				FL_COLOR field;
				int     rw;
		FLObject * 	object; 

		rw = update_field(items);
		object = (FLObject *)chk_bless(ST(0), X11XformsFLObject);
		
		if (rw)
			field = (FL_COLOR)SvIV(ST(1));

		switch (ix) {
#if FL_INCLUDE_VERSION < 87
		case 3:
		case 4:
		case 5:
			croak("Field \"%s\" not in FL_OBJECT structure in your version of xforms", GvNAME(CvGV(cv)));
			break;
#endif
		case 0:
			ObjRWfld(object->col1);
			break;
		case 1:
			ObjRWfld(object->col2);
			break;
		case 2:
			ObjRWfld(object->lcol);
			break;
#if FL_INCLUDE_VERSION >= 87
		case 3:
			ObjRWfld(object->aux_col1);
			break;
		case 4:
			ObjRWfld(object->aux_col2);
			break;
		case 5:
			ObjRWfld(object->dbl_background);
			break;
#endif
		}
	}
	OUTPUT:
	RETVAL

char *
fl_object_label(...)
	ALIAS:
		u_cdata	= 1
	CODE:
	{
				int     rw;
		FLObject * 	object; 

		rw = update_field(items);
		object = (FLObject *)chk_bless(ST(0), X11XformsFLObject);
		
		if (ix == 0)
		{
			RETVAL = object->label;
			if (rw)
				object->label = SvPV(ST(1),na);
		}
		else
#if FL_INCLUDE_VERSION < 87
			croak("Field \"%s\" not in FL_OBJECT structure in your version of xforms", GvNAME(CvGV(cv)));
#else
		{
			RETVAL = object->u_cdata;
			if (rw)
				object->u_cdata = SvPV(ST(1),na);
		}
#endif
	}
	OUTPUT:
	RETVAL

Window
fl_object_window(object)
	FLObject *	object
	CODE:
	{
		RETVAL = object->form->window;
	}
	OUTPUT:
	RETVAL

FLObject *
fl_prev(object)
	FLObject *	object
	ALIAS:
        next = 1
		parent = 2
		child = 3
		nc = 4
	CODE:
	{
		RETVAL = (((FLO_ARRAY *)object)->flo_obj[ix]);
		if (RETVAL == NULL)
			ST(0) = &sv_undef;
		else
			ST(0) = bless_object(RETVAL);			
	}

long
fl_use_pixmap(...)
	ALIAS:
        double_buffer = 1
		object_pushed = 2
		focus = 3
		belowmouse = 4
		active = 5
		input = 6
		wantkey = 7
		radio = 8
		automatic = 9
		redraw = 10
		visible = 11
		clip = 12
		resize = 100
		nwgravity = 101
		segravity = 102
		objclass = 200
		type = 201
		boxtype = 202
		align = 300
		lsize = 301
		lstyle = 302
		click_timeout = 400
		argument = 401
		how_return = 404
	CODE:
	{
		long	field;
				int     rw;
		FLObject * 	object; 

		rw = update_field(items);
		object = (FLObject *)chk_bless(ST(0), X11XformsFLObject);
		if (rw)
			field = SvIV(ST(1));

		switch (ix) {
#if FL_INCLUDE_VERSION < 87
		case 404:
			croak("Field \"%s\" not in FL_OBJECT structure in your version of xforms", GvNAME(CvGV(cv)));
			break;
#endif
		case 400:
			ObjRWfld(object->click_timeout);
			break;
		case 401:
			ObjRWfld(object->argument);
			break;
#if FL_INCLUDE_VERSION >= 87
		case 404:
			ObjRWfld(object->how_return);
			break;
#endif
		case 300:	
		case 301:	
		case 302:	
			ObjRWfld(((FLO_ARRAY *)object)->flo_int1[ix-300]);
			break;
		case 200:
		case 201:
		case 202:
			ObjRWfld(((FLO_ARRAY *)object)->flo_int2[ix-200]);
			break;
		case 100:
		case 101:
		case 102:
			ObjRWfld(((FLO_ARRAY *)object)->flo_ui[ix-100]);
			break;
		default:
			ObjRWfld(((FLO_ARRAY *)object)->flo_int[ix]);
			break;
		}
	}
	OUTPUT:
	RETVAL

MODULE = X11::Xforms	PACKAGE = X11::Xforms::FDFselector 	PREFIX = fd_fsel_

void
fd_fsel_fselect(fsel)
	FDFselector *	fsel
	ALIAS:
		browser = 1
		input = 2
		prompt = 3
		resbutt = 4
		patbutt = 5
		dirbutt = 6
		cancel = 7
		ready = 8
		dirlabel = 9
		patlabel = 10
	CODE:
	{
		void *	form_obj;
		form_obj = ((FD_FSEL_ARRAY *)fsel)->fsel_ob[ix];
		if (ix == 0) 
			ST(0) = bless_form((FLForm *)form_obj);
		else
			ST(0) = bless_object((FLObject *)form_obj);
	}

void
fd_fsel_appbutts(fsel)
	FDFselector *	fsel
	PPCODE:
	{
		int	i;
		SV	*sv;
		EXTEND(sp, 3);
		for (i=0; i<3; ++i) {
			if (fsel->appbutt[i] == NULL)
				XPUSHs(&sv_undef);
			else {
				sv = bless_object(fsel->appbutt[i]);
				XPUSHs(sv);
			}
		}
	}

MODULE = X11::Xforms	PACKAGE = X11::Xforms::FDCmdlog 	PREFIX = fd_cmdlog_

void
fd_cmdlog_form(cmdlog)
	FDCmdlog *	cmdlog
	ALIAS:
		browser = 1
		close_browser = 2
		clear_browser = 3
	CODE:
	{
		void *	form_obj = ((FD_CMD_ARRAY *)cmdlog)->cmd_ob[ix];
		if (ix == 0) 
			ST(0) = bless_form((FLForm *)form_obj);
		else
			ST(0) = bless_object((FLObject *)form_obj);
	}

MODULE = X11::Xforms	PACKAGE = X11::Xforms::FLOpt 	PREFIX = fl_opt_

FLOpt *
fl_opt_new(...)
	CODE:
	{
		RETVAL = (FL_IOPT *)X4Pcalloc(1, sizeof(FL_IOPT));
	}
	OUTPUT:
	RETVAL

void
fl_opt_DESTROY(opt)
	FLOpt *		opt
	CODE:
	{
		X4Pfree(opt);
	}
		
void 
fl_opt_gamma(...)
	PPCODE:
	{
		float	rgamma, ggamma, bgamma;
		FLOpt *		opt;
		if (items != 4 && items != 1)
			usage("Structure field access");
		opt = (FLOpt *)chk_bless(ST(0), X11XformsFLOpt);
		if (items == 4) {
			opt->rgamma = SvNV(ST(1));
			opt->ggamma = SvNV(ST(2));
			opt->bgamma = SvNV(ST(3));
		}
		
		EXTEND(sp, 3);
		PUSHs(sv_2mortal(newSVnv(opt->rgamma)));
		PUSHs(sv_2mortal(newSVnv(opt->ggamma)));
		PUSHs(sv_2mortal(newSVnv(opt->bgamma)));
	}

long
fl_opt_debug(...)
	ALIAS:
		sync = 1
		depth = 2
		vclass = 3
		doubleBuffer = 4
		ulPropWidth = 5
		ulThickness = 6
		buttonFontSize = 7
		sliderFontSize = 8
		inputFontSize = 9
		browserFontSize = 10
		menuFontSize = 11
		choiceFontSize = 12
		labelFontSize = 13
		pupFontSize = 14
		pupFontStyle = 15
		privateColormap = 16
		sharedColormap = 17
		standardColormap = 18
		leftScrollBar = 19
		thinScrollBar = 19 
		scrollbarType = 19 
		backingStore = 20
		coordUnit = 21
		borderWidth = 22
		safe = 23
		xFirst = 24
	CODE:
	{
		int     rw;
		FLOpt * opt; 

		rw = update_field(items);
		opt = (FLOpt *)chk_bless(ST(0), X11XformsFLOpt);
		
		RETVAL = ((FL_IOPT_ARRAY *)opt)->opt_int[ix];
		if (rw)
			((FL_IOPT_ARRAY *)opt)->opt_int[ix] =
				SvIV(ST(1));
	}
	OUTPUT:
	RETVAL

char *
fl_opt_rgbfile(...)
	ALIAS:
		vname = 1
	CODE:
	{
				int     rw;
		FLOpt * opt; 

		rw = update_field(items);
		opt = (FLOpt *)chk_bless(ST(0), X11XformsFLOpt);
		
		if (ix == 0) {
			RETVAL = opt->rgbfile;
			if (rw)
				opt->rgbfile = SvPV(ST(1),na);
		} else {
			RETVAL = opt->vname;
			if (rw)
				memcpy(opt->vname,SvPV(ST(1),na),24);
		}
	}
	OUTPUT:
	RETVAL

MODULE = X11::Xforms	PACKAGE = X11::Xforms::FLEditKeymap 	PREFIX = fl_key_

FLEditKeymap *
fl_key_new(...)
	CODE:
	{
		RETVAL = (FL_EditKeymap *)X4Pcalloc(1, sizeof(FL_EditKeymap));
	}
	OUTPUT:
	RETVAL

long
fl_key_del_prev_char(...)
	ALIAS:
		del_next_char   	= 1
		del_prev_word   	= 2
		del_next_word   	= 3 
		moveto_prev_line   	= 4
		moveto_next_line   	= 5
		moveto_prev_char   	= 6
		moveto_next_char   	= 7
		moveto_prev_word   	= 8
		moveto_next_word   	= 9
		moveto_prev_page   	= 11
		moveto_next_page   	= 12
		moveto_bol   	= 13
		moveto_eol   	= 14
		moveto_bof   	= 15
		moveto_eof   	= 16
		transpose   	= 17
		paste   	= 18
		backspace   	= 19
		del_to_bol   	= 20
		del_to_eol   	= 21
		clear_field   	= 22
		del_to_eos   	= 23
	CODE:
	{
				int     rw;
		FLEditKeymap *	keymap;

		rw = update_field(items);
		keymap = (FLEditKeymap *)chk_bless(ST(0),X11XformsFLEditKeymap);
		
		RETVAL = ((FL_KEYMAP_ARRAY *)keymap)->keymap_long[ix];
		if (rw) 
			((FL_KEYMAP_ARRAY *)keymap)->keymap_long[ix] =
				SvIV(ST(1));
	}
	OUTPUT:
	RETVAL
