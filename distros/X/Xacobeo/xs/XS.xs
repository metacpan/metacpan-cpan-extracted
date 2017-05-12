#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <gtk2perl.h>

#include "code.h"
#include "libxml.h"


MODULE = Xacobeo::XS		PACKAGE = Xacobeo::XS		


void
xacobeo_populate_gtk_text_buffer(buffer, node, namespaces)
	GtkTextBuffer *buffer
	xmlNodePtr    node
	HV            *namespaces


void
xacobeo_populate_gtk_tree_store(store, node, namespaces)
	GtkTreeStore  *store
	xmlNodePtr    node
	HV            *namespaces


gchar*
xacobeo_get_node_path(node, namespaces)
	xmlNodePtr    node
	HV            *namespaces


gchar*
xacobeo_get_node_mark(node)
	xmlNodePtr    node
