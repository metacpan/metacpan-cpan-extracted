//
// Sample program that displays an XML file in a GtkTextView.
// 
// Copyright (C) 2008 Emmanuel Rodriguez
//
// This program is free software; you can redistribute it and/or modify it under
// the same terms as Perl itself, either Perl version 5.8.8 or, at your option,
// any later version of Perl 5 you may have available.
//
//

#include "code.h"
#include "logger.h"
#include <glib/gprintf.h>

#include <libxml/parser.h>
#include <libxml/parserInternals.h>

#define TAG(name, ...) gtk_text_buffer_create_tag(buffer, name, __VA_ARGS__, NULL)


static void               my_create_buffer_tags (GtkTextBuffer *buffer);
static void               my_create_widgets     (GtkTextView **textview, GtkTreeView **treeview);
static GtkTreeViewColumn* my_add_text_column    (GtkTreeView *treeview, DomModelColumnsEnum field, const gchar *title, gint width);
static GtkWidget*         my_create_textview    (void);
static GtkWidget*         my_create_treeview    (void);
static GtkWidget*         my_wrap_in_scrolls    (GtkWidget *widget);
static xmlDoc*            my_parse_document     (const gchar *filename);


int main (int argc, char **argv) {

	gboolean no_xml    = FALSE;
	gboolean no_source = FALSE;
	gboolean no_dom    = FALSE;
	gboolean quit      = FALSE;

	// Parse the arguments
	gtk_init(&argc, &argv);

	GOptionEntry entries[] = {
		{ "no-xml",    'X', 0, G_OPTION_ARG_NONE, &no_xml,    "Don't load the XML document", NULL },
		{ "no-source", 'S', 0, G_OPTION_ARG_NONE, &no_source, "Don't show the XML source", NULL },
		{ "no-dom",    'D', 0, G_OPTION_ARG_NONE, &no_dom,    "Don't show the DOM tree", NULL },
		{ "quit",      'q', 0, G_OPTION_ARG_NONE, &quit,      "Quit as soon as the proram is ready", NULL },
		{ NULL, 0, 0, G_OPTION_ARG_NONE, NULL, NULL, NULL  },
	};

	GError *error = NULL;
	GOptionContext *context = g_option_context_new("- memory profiling");
	g_option_context_add_main_entries(context, entries, NULL);
	g_option_context_add_group(context, gtk_get_option_group(TRUE));
	if (!g_option_context_parse(context, &argc, &argv, &error)) {
		ERROR("option parsing failed: %s", error->message);
		g_error_free(error);
		return 1;
	}

	if (argc < 1) {
		ERROR("Usage: %s file\n", argv[0]);
		return 1;
	}
	char *filename = argv[1];


	// Load the XML document
	DEBUG("Reading file %s", filename);
	xmlDoc *document = !no_xml ? my_parse_document(filename) : NULL;
	if (!no_xml && document == NULL) {
		ERROR("Failed to parse %s", filename);
		return 1;
	}
	INFO("Read file %s", filename);


	// Render the XML document
	GtkTextView *textview = NULL;
	GtkTreeView *treeview = NULL;
	
	my_create_widgets(&textview, &treeview);
	
	// Fill the TextView (it's faster to remove the buffer and to put it back)
	GtkTextBuffer *buffer = gtk_text_view_get_buffer(textview);
	gtk_text_view_set_buffer(textview, NULL);
	if (!no_source) xacobeo_populate_gtk_text_buffer(buffer, (xmlNode *) document, NULL);
	gtk_text_view_set_buffer(textview, buffer);

	// Scroll to the beginning of the text
	GtkTextIter iter;
	gtk_text_buffer_get_start_iter(buffer, &iter);
	gtk_text_view_scroll_to_iter(textview, &iter, 0.0, FALSE, 0.0, 0.0); 
	
	GtkTreeStore *store = GTK_TREE_STORE(gtk_tree_view_get_model(treeview));
	gtk_tree_view_set_model(treeview, NULL);
	gtk_tree_store_clear(store);
	if (!no_dom) xacobeo_populate_gtk_tree_store(store, (xmlNode *) document, NULL);
	gtk_tree_view_set_model(treeview, GTK_TREE_MODEL(store));

	INFO("Freeing XML document");
	if (document) xmlFreeDoc(document);
	

	// If we just want to time the execution time we don't need an event loop
	if (!quit) {
		// Main event loop
		INFO("Starting main loop");
		gtk_main();
	}

	INFO("Cleaning XML parser");
	xmlCleanupParser();

	INFO("End of program");
	return 0;
}



//
// Creates the main widgets and prepares them for displaying. This function
// returns the GtkTextView casted as a GtkWidget.
//
static void my_create_widgets (GtkTextView **ptr_textview, GtkTreeView **ptr_treeview) {
	
	// The main widgets
	GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
	GtkWidget *textview = my_create_textview();
	GtkWidget *treeview = my_create_treeview();

	
	// Pack the widgets together
	GtkWidget *pane = gtk_hpaned_new();
	gtk_paned_set_position(GTK_PANED(pane), 200);
	gtk_paned_add1(GTK_PANED(pane), my_wrap_in_scrolls(treeview));
	gtk_paned_add2(GTK_PANED(pane), my_wrap_in_scrolls(textview));

	gtk_container_add(GTK_CONTAINER(window), pane);
	gtk_widget_show_all(window);
	
	
	// Connect the signals
	g_signal_connect(G_OBJECT(window), "delete_event", G_CALLBACK(gtk_main_quit), NULL);


	// Set the return values
	*ptr_textview = GTK_TEXT_VIEW(textview);
	*ptr_treeview = GTK_TREE_VIEW(treeview);
}



//
// Creates the text view and sets its model (text buffer)
//
static GtkWidget* my_create_textview (void) {
	// Prepare the text view
	GtkTextTagTable *table = gtk_text_tag_table_new();
	GtkTextBuffer *buffer = gtk_text_buffer_new(table);
	GtkWidget *textview = gtk_text_view_new_with_buffer(buffer);

	my_create_buffer_tags(buffer);

	gtk_widget_set_size_request(textview, 600, 400);
	gtk_text_view_set_editable(GTK_TEXT_VIEW(textview), FALSE);
	gtk_text_view_set_cursor_visible(GTK_TEXT_VIEW(textview), FALSE);
	
	return textview;
}



//
// Creates the tree view and sets its model (tree store)
//
static GtkWidget* my_create_treeview (void) {
	// Prepre the tree view
	GtkWidget *treeview = gtk_tree_view_new();
	GtkTreeStore *store = gtk_tree_store_new(5,
		G_TYPE_STRING, 
		G_TYPE_STRING,
		G_TYPE_STRING,
		G_TYPE_STRING,
		G_TYPE_STRING
	);
	gtk_tree_view_set_model(GTK_TREE_VIEW(treeview), GTK_TREE_MODEL(store));
	gtk_tree_view_set_fixed_height_mode(GTK_TREE_VIEW(treeview), TRUE);
	
	
	
	// Element name
	GtkTreeViewColumn *column = my_add_text_column(
		GTK_TREE_VIEW(treeview),
		DOM_COL_ELEMENT_NAME,
		"Element",
		150
	);

	// Icon
	GtkCellRenderer *cell = gtk_cell_renderer_pixbuf_new();
	gtk_tree_view_column_pack_end(column, cell, FALSE);
	gtk_tree_view_column_set_attributes(column, cell, "stock-id", DOM_COL_ICON, NULL);
	
	// XML::ID
	my_add_text_column(GTK_TREE_VIEW(treeview), DOM_COL_ID_NAME, "ID name", 75);
	my_add_text_column(GTK_TREE_VIEW(treeview), DOM_COL_ID_VALUE, "ID value", 75);

	return treeview;
}


static GtkTreeViewColumn* my_add_text_column (GtkTreeView *treeview, DomModelColumnsEnum field, const gchar *title, gint width) {
	GtkCellRenderer *cell = gtk_cell_renderer_text_new();
	GtkTreeViewColumn *column = gtk_tree_view_column_new();
	gtk_tree_view_column_pack_end(column, cell, TRUE);
	
	gtk_tree_view_column_set_title(column, title);
	gtk_tree_view_column_set_resizable(column, TRUE);
	gtk_tree_view_column_set_sizing(column, GTK_TREE_VIEW_COLUMN_FIXED);
	gtk_tree_view_column_set_fixed_width(column, width);
	gtk_tree_view_column_set_attributes(column, cell, "text", field, NULL);

	gtk_tree_view_append_column(treeview, column);
	
	return column;
}


//
// Wraps the a widget with scroll bars.
//
static GtkWidget* my_wrap_in_scrolls (GtkWidget *widget) {
	GtkWidget *scrolls = gtk_scrolled_window_new(NULL, NULL);
	gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scrolls), GTK_POLICY_AUTOMATIC, GTK_POLICY_ALWAYS);
	gtk_scrolled_window_set_shadow_type(GTK_SCROLLED_WINDOW(scrolls), GTK_SHADOW_OUT);
	gtk_container_add(GTK_CONTAINER(scrolls), widget);
	return scrolls;
}



//
// Creates the markup rules to use for displaying XML.
//
static void my_create_buffer_tags (GtkTextBuffer *buffer) {

	TAG("result_count", 
		"family",      "Courier 10 Pitch",
		"background",  "#EDE9E3",
		"foreground",  "black",
		"style",       PANGO_STYLE_ITALIC,
		"weight",      PANGO_WEIGHT_LIGHT
	);
	
	TAG("boolean", 
			"family",      "Courier 10 Pitch",
			"foreground",  "black",
			"weight",      PANGO_WEIGHT_BOLD
	);
	
	TAG("number", 
			"family",      "Courier 10 Pitch",
			"foreground",  "black",
			"weight",      PANGO_WEIGHT_BOLD
	);

	TAG("attribute_name", 
		"foreground",  "red"
	);

	TAG("attribute_value", 
		"foreground",  "blue"
	);
	
	TAG("comment", 
		"foreground",  "#008000",
		"style",       PANGO_STYLE_ITALIC,
		"weight",      PANGO_WEIGHT_LIGHT
	);
	
	TAG("dtd", 
		"foreground",  "#558CBA",
		"style",       PANGO_STYLE_ITALIC
	);
	
	TAG("element", 
		"foreground",  "#800080",
		"weight",      PANGO_WEIGHT_BOLD
	);
	
	TAG("pi", 
		"foreground",  "#558CBA",
		"style",       PANGO_STYLE_ITALIC
	);
	
	TAG("pi_data", 
		"foreground",  "red",
		"style",       PANGO_STYLE_ITALIC
	);
	
	TAG("syntax", 
		"foreground",  "black",
		"weight",      PANGO_WEIGHT_BOLD
	);
	
	TAG("text", 
		"foreground",  "black"
	);
	
	TAG("literal", 
		"foreground",  "black"
	);
	
	TAG("cdata", 
		"foreground",  "red",
		"weight",      PANGO_WEIGHT_BOLD
	);
	
	TAG("cdata_content", 
		"foreground",  "purple",
		"weight",      PANGO_WEIGHT_BOLD,
		"style",       PANGO_STYLE_ITALIC,
		"weight",      PANGO_WEIGHT_LIGHT
	);
	
	TAG("namespace_name", 
		"foreground",  "red",
		"style",       PANGO_STYLE_ITALIC,
		"weight",      PANGO_WEIGHT_LIGHT
	);
	
	TAG("namespace_uri", 
		"foreground",  "blue",
		"style",       PANGO_STYLE_ITALIC,
		"weight",      PANGO_WEIGHT_LIGHT
	);
	
	TAG("entity_ref", 
		"foreground",  "red",
		"weight",      PANGO_WEIGHT_BOLD
	);
}


//
// Parses the XML document. Returns an XML document if the parsing was
// successful otherwise NULL.
//
// The document has to be	freed with xmlFreeDoc();
//
static xmlDoc* my_parse_document (const gchar *filename) {

	// Construct a parser contenxt
	xmlParserCtxt *parserCtxt = xmlCreateFileParserCtxt(filename);
	parserCtxt->loadsubset = XML_DETECT_IDS;
	
	// Parse the document
	xmlDoc *document = NULL;
	if (xmlParseDocument(parserCtxt) == 0) {
		document = parserCtxt->myDoc;
		parserCtxt->myDoc = NULL;
	}

	xmlFreeParserCtxt(parserCtxt);
	return document;
}
