#ifndef __XACOBEO_CODE_H__
#define __XACOBEO_CODE_H__


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gtk/gtk.h>
#include <libxml/tree.h>


// The columns in the DOM Tree View
enum DomModelColumns {
	DOM_COL_XML_POINTER,
	DOM_COL_ICON,
	DOM_COL_ELEMENT_NAME,
	DOM_COL_ID_NAME,
	DOM_COL_ID_VALUE,
};
typedef enum DomModelColumns DomModelColumnsEnum;


// Public prototypes
void xacobeo_populate_gtk_text_buffer (GtkTextBuffer *buffer, xmlNode *node, HV *namespaces);
void xacobeo_populate_gtk_tree_store  (GtkTreeStore *store,   xmlNode *node, HV *namespaces);
gchar* xacobeo_get_node_path          (xmlNode *node, HV *namespaces);
gchar* xacobeo_get_node_mark          (xmlNode *node);


#endif
