
#include "x-api.h"

#include <X11/Intrinsic.h>
#include <X11/Core.h>
#include <X11/StringDefs.h>
#include <X11/Shell.h>
#include <X11/Vendor.h>

extern Widget UxTopLevel;
extern XtAppContext UxAppContext;

extern char *XtAppContext_Package;
extern char *WidgetClass_Package;
extern char *Widget_Package;
extern char *XtInArg_Package;
extern char *XtOutArg_Package;

extern char *Modifiers_Package;
extern char *XtAccelerators_Package;
extern char *XtTranslations_Package;
extern char *XtWidgetGeometryPtr_Package;

extern char *XtActionHookId_Package;
extern char *XtInputId_Package;
extern char *XtIntervalId_Package;
extern char *XtRequestId_Package;
extern char *XtWorkProcId_Package;

struct XtInArgStruct {
    SV *src;		    /* resource in string (i.e. source) format */
    char *res_type;	    /* name of resource type */
    int res_size;	    /* size in bytes of resource (if negative, just use SvPV result directly) */
    void *dst;		    /* pointer to buffer for internal resource form */
};

struct XtOutArgStruct {
    SV *res_name;	    /* name of resource */
    SV *res_class;	    /* name of resource class */
    SV *res_type;	    /* name of resource type */
    int res_size;	    /* size in bytes of resource */
    int res_signed;	    /* is the resource signed? */
    XtArgVal dst;	    /* buffer (or pointer to buffer) for internal resource form */
};

struct XtPerlClosureStruct {
    SV *proc;		    /* user's subroutine (code ref) */
    SV *client_data;	    /* client data given in callback registration */
    SV *call_type;	    /* reference to classname of callback call data argument */
};

typedef struct XtInArgStruct *XtInArg;
typedef struct XtOutArgStruct *XtOutArg;
typedef struct XtPerlClosureStruct *XtPerlClosure;

typedef XtOutArg *XtOutArgList;

typedef SV *(*XtOutArgConverter)(Widget, WidgetClass, XtOutArg);

Cardinal xt_build_input_arg_list(Widget w, WidgetClass wc, ArgList *arg_list_out, SV **sp, int items);
Cardinal xt_build_output_arg_list(ArgList *arg_list_out, XtOutArgList *arg_info_list_out,
				  SV **sp, int items);

void register_resource_converter_by_name(WidgetClass wc, char *res_name,
					 char *package_name, XtOutArgConverter f);
void register_resource_converter_by_class(char *res_class,
					  char *package_name, XtOutArgConverter f);
void register_resource_converter_by_type(char *res_type,
					 char *package_name, XtOutArgConverter f);

XS(boot_X11__Toolkit);
