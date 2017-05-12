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
#include "libxml.h"

#include <string.h>


#define buffer_add(xargs, tag, text) my_buffer_add(xargs, tag, NULL, text)
#define buffer_add_node(xargs, tag, node, text) my_buffer_add(xargs, tag, node, text)

#define buffer_cat(xargs, tag, ...) \
do { \
	gchar *content = g_strconcat(__VA_ARGS__, NULL); \
	my_buffer_add(xargs, tag, NULL, content); \
	g_free(content); \
} while (FALSE)

#define ELEMENT_MATCH(a, b) (a)->type == XML_ELEMENT_NODE \
	&& xmlStrEqual((a)->name, (b)->name) \
	&& (a)->ns == (b)->ns

// The icon type to use for an element
#define ICON_ELEMENT "gtk-directory"


// The markup styles to be used
typedef struct _MarkupTags {
	GtkTextTag *result_count;
	GtkTextTag *boolean;
	GtkTextTag *number;
	GtkTextTag *attribute_name;
	GtkTextTag *attribute_value;
	GtkTextTag *comment;
	GtkTextTag *dtd;
	GtkTextTag *element;
	GtkTextTag *pi;
	GtkTextTag *pi_data;
	GtkTextTag *syntax;
	GtkTextTag *literal;
	GtkTextTag *cdata;
	GtkTextTag *cdata_content;
	GtkTextTag *namespace_name;
	GtkTextTag *namespace_uri;
	GtkTextTag *entity_ref;
	GtkTextTag *error;
} MarkupTags;


// The context used for displaying the XML. Since a lot of functions need these
// parameters, it's easier to group them in a custom struct and pass that struct
// around.
typedef struct _TextRenderCtx {

	// The GTK text buffer on which to perform the rendering
	GtkTextBuffer *buffer;

	// The markup tags defined in the text buffer
	MarkupTags    *markup;

	// Perl hash with the namespaces to use (key: uri, value: prefix)
	HV            *namespaces;

	// Contents of the XML document (it gets build at runtime)
	GString       *xml_data;

	// Current position on the XML document. It counts the characters (not the
	// bytes) accumulated. This counter keeps track of the characters already
	// present in the buffer. It's purpose is to provide the position where to
	// apply the text tags (syntax highlighting styles).
	guint          buffer_pos;

	// The tags to apply (collected at runtime as the XML document gets built).
	GArray        *tags;

	// Statistics used for debugging purposes
	gsize  calls;
} TextRenderCtx;


//
// The text styles to apply for the syntax highlighting of the XML.
//
typedef struct _ApplyTag {
	GtkTextTag *tag;
	gsize      start;
	gsize      end;
	gchar      *name;
} ApplyTag;


//
// The context used for populating the DOM tree.
//
typedef struct _TreeRenderCtx {

	// The GTK tree store to fill
	GtkTreeStore *store;

	// Perl hash with the namespaces to use (key: uri, value: prefix)
	HV *namespaces;

	// ProxyNode used by XML::LibXML
	ProxyNode *proxy;

	// Statistics used for debugging purposes
	gsize  calls;
} TreeRenderCtx;



//
// Function prototypes
//
static MarkupTags*  my_get_buffer_tags         (GtkTextBuffer *buffer);
static gchar*       my_to_string               (xmlNode *node);
static void         my_buffer_add              (TextRenderCtx *xargs, GtkTextTag *tag, xmlNode *node, const gchar *text);
static void         my_display_document_syntax (TextRenderCtx *xargs, xmlNode *node);
static gchar*       my_get_node_name_prefixed  (xmlNode *node, HV *namespaces);
static const gchar* my_get_uri_prefix          (const xmlChar *uri, HV *namespaces);
static void         my_render_buffer           (TextRenderCtx *xargs);
static void         my_add_text_and_entity     (TextRenderCtx *xargs, GString *buffer, GtkTextTag *markup, const gchar *entity);
static void         my_populate_tree_store     (TreeRenderCtx *xargs, xmlNode *node, GtkTreeIter *parent, gint pos);

static void         my_XML_DOCUMENT_NODE       (TextRenderCtx *xargs, xmlNode *node);
static void         my_XML_HTML_DOCUMENT_NODE  (TextRenderCtx *xargs, xmlNode *node);
static void         my_XML_ELEMENT_NODE        (TextRenderCtx *xargs, xmlNode *node);
static void         my_XML_ATTRIBUTE_NODE      (TextRenderCtx *xargs, xmlNode *node);
static void         my_XML_ATTRIBUTE_VALUE     (TextRenderCtx *xargs, xmlNode *node);
static void         my_XML_TEXT_NODE           (TextRenderCtx *xargs, xmlNode *node);
static void         my_XML_COMMENT_NODE        (TextRenderCtx *xargs, xmlNode *node);
static void         my_XML_CDATA_SECTION_NODE  (TextRenderCtx *xargs, xmlNode *node);
static void         my_XML_PI_NODE             (TextRenderCtx *xargs, xmlNode *node);
static void         my_XML_ENTITY_REF_NODE     (TextRenderCtx *xargs, xmlNode *node);
static void         my_XML_ENTITY_REF_VALUE    (TextRenderCtx *xargs, const gchar *name);
static void         my_XML_DTD_NODE            (TextRenderCtx *xargs, xmlNode *node);
static void         my_XML_NAMESPACE_DECL      (TextRenderCtx *xargs, xmlNs *ns);


//
// This function displays a simplified version of the DOM tree of an XML node
// into a GtkTreeStore. The XML nodes are displayed with their corresponding
// namespace prefix. The prefixes to use are taken from the given Perl hash.
//
// At the moment the DOM shows only the XML Elements. All other nodes are not
// rendered. If an element defines an attribute that's an ID (with xml:id or
// through the DTD) then the ID will be displayed.
//
void xacobeo_populate_gtk_tree_store (GtkTreeStore *store, xmlNode *node, HV *namespaces) {

	////
	// Parameters validation

	// Initialize the tree store
	if (store == NULL) {
		WARN("GtkTreeStore is NULL");
		return;
	}
	gtk_tree_store_clear(store);


	// Get the root element
	if (node == NULL) {
		WARN("XML node is NULL");
		return;
	}
	xmlNode *root = xmlDocGetRootElement(node->doc);
	if (root == NULL) {
		WARN("Document has no root element");
		return;
	}
	DEBUG("Adding root element %s", root->name);


	// The argument contenxt
	TreeRenderCtx xargs = {
		.store      = store,
		.namespaces = namespaces,
		.calls      = 0,
		.proxy      = PmmOWNERPO(PmmPROXYNODE(node)),
	};


	// Populate the DOM tree (timed)
	DEBUG("Populating DOM tree");
	GTimeVal start, end;
	g_get_current_time(&start);
	my_populate_tree_store(&xargs, root, NULL, 0);
	g_get_current_time(&end);


	// Calculate the number of micro seconds spent since the last time
	glong elapsed = (end.tv_sec - start.tv_sec) * 1000000; // Seconds
	elapsed += end.tv_usec - start.tv_usec; // Microseconds
	INFO("Calls = %d, Time = %ld, Frequency = %05f Time/Calls", xargs.calls, elapsed, (elapsed/(1.0 * xargs.calls)));
}


//
// This functions inserts recursively nodes into a TreStore. It takes as input
// XML Elements.
//
static void my_populate_tree_store (TreeRenderCtx *xargs, xmlNode *node, GtkTreeIter *parent, gint pos) {

	++xargs->calls;


	gchar *node_name = my_get_node_name_prefixed(node, xargs->namespaces);
	SV *sv = NULL;
	if (xargs->namespaces) {
		// This part is optional because the C main wrapper used for testing can't
		// deal with the creation of an SV.
		sv = PmmNodeToSv(node, xargs->proxy);
	}

	// Find out if the node has an attribute that's an ID
	gboolean done = FALSE;
	GtkTreeIter iter;
	for (xmlAttr *attr = node->properties; attr; attr = attr->next) {
		if (xmlIsID(node->doc, node, attr)) {

			done = TRUE;

			gchar *id_name = my_get_node_name_prefixed((xmlNode *) attr, xargs->namespaces);
			// If we pass 'attr' then the output will be "id='23'" instead of "23"
			gchar *id_value = my_to_string((xmlNode *) attr->children);


			// Add the current node
			gtk_tree_store_insert_with_values(
				xargs->store, &iter, parent, pos,

				DOM_COL_ICON,         ICON_ELEMENT,
				DOM_COL_XML_POINTER,  sv,
				DOM_COL_ELEMENT_NAME, node_name,

				// Add the columns ID_NAME and ID_VALUE
				DOM_COL_ID_NAME,      id_name,
				DOM_COL_ID_VALUE,     id_value,

				-1
			);

			g_free(id_name);
			g_free(id_value);
			break;
		}
	}

	// Add the current node if it wasn't already added
	if (! done) {
		gtk_tree_store_insert_with_values(
			xargs->store, &iter, parent, pos,

			DOM_COL_ICON,         ICON_ELEMENT,
			DOM_COL_XML_POINTER,  sv,
			DOM_COL_ELEMENT_NAME, node_name,

			-1
		);
	}
	g_free(node_name);


	// Do the children
	gint i = 0;
	for (xmlNode *child = node->children; child; child = child->next) {
		if(child->type == XML_ELEMENT_NODE) {
			my_populate_tree_store(xargs, child, &iter, i++);
		}
	}
}



//
// This function displays an XML node into a GtkTextBuffer. The XML nodes are
// displayed with their corresponding namespace prefix. The prefixes to use are
// taken from the given Perl hash.
//
// The XML is rendered with syntax highlighting. The GtkTextBuffer is expected
// to have the styles already predefined. The name of the styles to be used are:
//
// XPath results:
//   result_count - Margin counter used to identify each XPath result.
//   boolean      - Boolean result from an XPath expression.
//   number       - Numerical result from an XPath expression.
//   literal      - Literal result (string) from an XPath expression.
//
// XML Elements
//   element         - An XML element (both opening and closing tag).
//   attribute_name  - The name of an attribute.
//   attribute_value - The value of an attribute.
//   namespace_name  - The name (prefix) of a namespace declaration.
//   namespace_uri   - The URI of a namespace declaration.
//
// XML syntax
//   comment - An XML comment.
//   dtd           - A DTD definition.
//   pi            - The name of a processing instruction.
//   pi_data       - The data of a processing instruction.
//   syntax        - Syntax tokens : <, >, &, ;, etc.
//   cdata         - A CDATA (both opening and closing syntax).
//   cdata_content - The content of a CDATA.
//   entity_ref    - an entity reference.
//
void xacobeo_populate_gtk_text_buffer (GtkTextBuffer *buffer, xmlNode *node, HV *namespaces) {

	////
	// Parameters validation
	if (buffer == NULL) {
		WARN("GtkTextBuffer is NULL");
		return;
	}

	TextRenderCtx xargs = {
		.buffer = buffer,
		.markup = my_get_buffer_tags(buffer),
		.namespaces = namespaces,
		.xml_data = g_string_sized_new(5 * 1024),
		.buffer_pos = 0,
		// A 400Kb document can require to apply up to 150 000 styles!
		.tags = g_array_sized_new(TRUE, TRUE, sizeof(ApplyTag), 200 * 1000),
		.calls = 0,
	};

	// Compute the current position in the buffer
	GtkTextIter iter;
	gtk_text_buffer_get_end_iter(buffer, &iter);
	xargs.buffer_pos = gtk_text_iter_get_offset(&iter);


	DEBUG("Displaying document with syntax highlighting");
	GTimeVal start;
	g_get_current_time(&start);

	// Render the XML document
	DEBUG("Computing syntax highlighting");
	my_display_document_syntax(&xargs, node);
	g_free(xargs.markup);

	// Copy the text into the buffer
	gsize tags = xargs.tags->len;
	DEBUG("Applying syntax highlighting");
	my_render_buffer(&xargs);


	GTimeVal end;
	g_get_current_time(&end);

	// Calculate the number of micro seconds spent since the last time
	glong elapsed = (end.tv_sec - start.tv_sec) * 1000000; // Seconds
	elapsed += end.tv_usec - start.tv_usec; // Microseconds
	INFO("Calls = %d, Tags = %d, Time = %ld, Frequency = %05f Time/Calls", xargs.calls, tags, elapsed, (elapsed/(1.0 * xargs.calls)));
}



//
// Adds the contents of the XML document to the buffer and applies the syntax
// highlighting.
//
// This function frees the data members 'xml_data' and 'tags'.
//
static void my_render_buffer (TextRenderCtx *xargs) {

	// Insert the whole text into the buffer
	GtkTextIter iter_end;
	gtk_text_buffer_get_end_iter(xargs->buffer, &iter_end);
	gtk_text_buffer_insert(
		xargs->buffer, &iter_end,
		xargs->xml_data->str, xargs->xml_data->len
	);
	g_string_free(xargs->xml_data, TRUE);


	// Apply each tag individually
	// It's a bit faster to emit the signal "apply-tag" than to call
	// gtk_text_buffer_apply_tag().
	guint signal_apply_tag_id = g_signal_lookup("apply-tag", GTK_TYPE_TEXT_BUFFER);
	for (size_t i = 0; i < xargs->tags->len; ++i) {
		ApplyTag *to_apply = &g_array_index(xargs->tags, ApplyTag, i);
		if (! to_apply) {
			break;
		}

		GtkTextIter iter_start;
		gtk_text_buffer_get_iter_at_offset(xargs->buffer, &iter_start, to_apply->start);
		gtk_text_buffer_get_iter_at_offset(xargs->buffer, &iter_end, to_apply->end);

		if (to_apply->name) {
			gchar *name;

			name = g_strjoin("|", to_apply->name, "start", NULL);
			gtk_text_buffer_create_mark(xargs->buffer, name, &iter_start, TRUE);
			g_free(name);

			name = g_strjoin("|", to_apply->name, "end", NULL);
			gtk_text_buffer_create_mark(xargs->buffer, name, &iter_end, FALSE);
			g_free(name);

			g_free(to_apply->name);
		}

		// This is the bottleneck of the function. On the #gedit IRC channel it was
		// suggested that the highlight could be done in an idle callback.
		g_signal_emit(xargs->buffer, signal_apply_tag_id, 0, to_apply->tag, &iter_start, &iter_end);
	}

	g_array_free(xargs->tags, TRUE);
}



//
// Displays an XML document by walking recursively through the DOM. The XML is
// displayed in a GtkTextBuffer and rendered with a corresponding markup rule.
//
static void my_display_document_syntax (TextRenderCtx *xargs, xmlNode *node) {

	if (node == NULL) {
		buffer_add(xargs, xargs->markup->error, "\n");
	}

	switch (node->type) {

		case XML_DOCUMENT_NODE:
			my_XML_DOCUMENT_NODE(xargs, node);
		break;

		case XML_HTML_DOCUMENT_NODE:
			my_XML_HTML_DOCUMENT_NODE(xargs, node);
		break;

		case XML_ELEMENT_NODE:
			my_XML_ELEMENT_NODE(xargs, node);
		break;

		case XML_ATTRIBUTE_NODE:
			my_XML_ATTRIBUTE_NODE(xargs, node);
		break;

		case XML_TEXT_NODE:
			my_XML_TEXT_NODE(xargs, node);
		break;

		case XML_COMMENT_NODE:
			my_XML_COMMENT_NODE(xargs, node);
		break;

		case XML_CDATA_SECTION_NODE:
			my_XML_CDATA_SECTION_NODE(xargs, node);
		break;

		case XML_PI_NODE:
			my_XML_PI_NODE(xargs, node);
		break;

		case XML_ENTITY_REF_NODE:
			my_XML_ENTITY_REF_NODE(xargs, node);
		break;

		case XML_DTD_NODE:
			my_XML_DTD_NODE(xargs, node);
		break;

		default:
			WARN("Unknown XML type %d for %s", node->type, node->name);
		break;
	}
}



// Displays a 'Document' node.
static void my_XML_DOCUMENT_NODE (TextRenderCtx *xargs, xmlNode *node) {

	// Create the XML declaration <?xml version="" encoding=""?>
	xmlDoc *doc = (xmlDoc *) node;
	GString *gstring = g_string_sized_new(30);
	g_string_printf(gstring, "version=\"%s\" encoding=\"%s\"",
		doc->version,
		doc->encoding ? (gchar *) doc->encoding : "UTF-8"
	);
	gchar *piBuffer = g_string_free(gstring, FALSE);

	xmlNode *pi = xmlNewPI(BAD_CAST "xml", BAD_CAST piBuffer);
	g_free(piBuffer);
	my_display_document_syntax(xargs, pi);
	xmlFreeNode(pi);
	buffer_add(xargs, xargs->markup->syntax, "\n");


	for (xmlNode *child = node->children; child; child = child->next) {
		my_display_document_syntax(xargs, child);
		// Add some new lines between the elements of the prolog. Libxml removes
		// the white spaces in the prolog.
		if (child != node->last) {
			buffer_add(xargs, xargs->markup->syntax, "\n");
		}
	}
}



// Displays an HTML 'Document' node.
static void my_XML_HTML_DOCUMENT_NODE (TextRenderCtx *xargs, xmlNode *node) {
	for (xmlNode *child = node->children; child; child = child->next) {
		my_display_document_syntax(xargs, child);
		// Add some new lines between the elements of the prolog. Libxml removes
		// the white spaces in the prolog.
		if (child != node->last) {
			buffer_add(xargs, xargs->markup->syntax, "\n");
		}
	}
}



// Displays an Element ex: <tag>...</tag>
static void my_XML_ELEMENT_NODE (TextRenderCtx *xargs, xmlNode *node) {

	gchar *name = my_get_node_name_prefixed(node, xargs->namespaces);

	// Start of the element
	buffer_add(xargs, xargs->markup->syntax, "<");
	buffer_add_node(xargs, xargs->markup->element, node, name);


	// The element's namespace definitions
	for (xmlNs *ns = node->nsDef; ns; ns = ns->next) {
		my_XML_NAMESPACE_DECL(xargs, ns);
	}


	// The element's attributes
	for (xmlAttr *attr = node->properties; attr; attr = attr->next) {
		my_XML_ATTRIBUTE_NODE(xargs, (xmlNode *) attr);
	}


	// An element can be closed with <element></element> or <element/>
	if (node->children) {

		// Close the start of the element
		buffer_add(xargs, xargs->markup->syntax, ">");

		// Do the children
		for (xmlNode *child = node->children; child; child = child->next) {
			my_display_document_syntax(xargs, child);
		}

		// Close the element
		buffer_add(xargs, xargs->markup->syntax, "</");
		buffer_add(xargs, xargs->markup->element, name);
		buffer_add(xargs, xargs->markup->syntax, ">");
	}
	else {
		// Empty element, ex: <empty />
		// TODO only elements defined as empty in the DTD shoud be empty. The others
		//      should be written as: <no-content></no-content>
		buffer_add(xargs, xargs->markup->syntax, "/>");
	}

	g_free(name);
}



// Displays a Nanespace declaration ex: <... xmlns:x="http://www.w3.org/1999/xhtml" ...>
static void my_XML_NAMESPACE_DECL (TextRenderCtx *xargs, xmlNs *ns) {

	const gchar *prefix = my_get_uri_prefix(ns->href, xargs->namespaces);
	gchar *name = NULL;
	if (prefix) {
		name = g_strconcat("xmlns:", prefix, NULL);
	}
	else {
		name = g_strdup("xmlns");
	}
	buffer_add(xargs, xargs->markup->syntax, " ");
	buffer_add(xargs, xargs->markup->namespace_name, name);
	g_free(name);

	// Value
	buffer_add(xargs, xargs->markup->syntax, "=\"");
	buffer_add(xargs, xargs->markup->namespace_uri, (gchar *) ns->href);
	buffer_add(xargs, xargs->markup->syntax, "\"");
}



// Displays an Attribute ex: <... var="value" ...>
static void my_XML_ATTRIBUTE_NODE (TextRenderCtx *xargs, xmlNode *node) {

	// Name
	gchar *name = my_get_node_name_prefixed(node, xargs->namespaces);
	buffer_add(xargs, xargs->markup->syntax, " ");
	buffer_add(xargs, xargs->markup->attribute_name, name);
	g_free(name);

	// Value
	buffer_add(xargs, xargs->markup->syntax, "=\"");
	my_XML_ATTRIBUTE_VALUE(xargs, node);
	buffer_add(xargs, xargs->markup->syntax, "\"");
}



//
// This method is inspired by xmlGetPropNodeValueInternal(). This version adds
// the contents to the internal buffer and renders the entities of the
// attributes.
//
static void my_XML_ATTRIBUTE_VALUE (TextRenderCtx *xargs, xmlNode *node) {

	if (node->type == XML_ATTRIBUTE_NODE) {
		for (xmlNode *child = node->children; child; child = child->next) {
			my_display_document_syntax(xargs, child);
		}
	}
	else if (node->type == XML_ATTRIBUTE_DECL) {
		xmlAttribute *child = (xmlAttribute *) node;
		buffer_add(xargs, xargs->markup->attribute_value, (gchar *) child->defaultValue);
	}
}



// Displays a Text node, plain text in the document.
//
// This is tricky as plain text needs to have some characters (<, >, &, ' and ")
// escaped. Furthermore, not all characters need to be always escaped, for
// instance when the TEXT node is a direct child of an ELEMENT then < and & need
// to be escaped (> is optional as an XML parser should only look for the next
// opening tag). But if the TEXT node is within an ATTRIBUTE then the proper
// quotes also need to be escaped.
//
// Another important aspect is the visual representation. As TEXT nodes are used
// everywhere they don't have a dedicated style, instead their style is dictated
// by the parent node.
//
static void my_XML_TEXT_NODE (TextRenderCtx *xargs, xmlNode *node) {

	// The type of text node rendering to do (Attribute, Element, etc)
	gboolean do_quotes = FALSE;
	GtkTextTag *markup = NULL; // NULL -> no style

	if (node->parent) {
		switch (node->parent->type) {
			case XML_ELEMENT_NODE:
				// Use the default values - Nothing more to do
			break;

			case XML_ATTRIBUTE_NODE:
			case XML_ATTRIBUTE_DECL:
				markup = xargs->markup->attribute_value;
				do_quotes = TRUE;
			break;

			default:
				WARN("Unhandled TEXT node for type %d", node->parent->type);
			break;
		}
	}


	const gchar *p = (gchar *) node->content;
	size_t length = strlen(p);
	const gchar *end = p + length;

	// The text should be added to a temporary buffer first and appended to the
	// main buffer (xargs->buffer) before rendering each entity. Otherwise each
	// character in the TEXT node will be tagged one by one! Of course the output
	// will be the same but it's overkill.
	GString *buffer = g_string_sized_new(length);

	// Scan the string for the characters to escape
	while (p != end) {
		const gchar *next = g_utf8_next_char(p);

		switch (*p) {
			case '&':
				my_add_text_and_entity(xargs, buffer, markup, "amp");
			break;

			case '<':
				my_add_text_and_entity(xargs, buffer, markup, "lt");
			break;

			case '>':
				my_add_text_and_entity(xargs, buffer, markup, "gt");
			break;

			default: {

				gboolean append = TRUE;

				if (do_quotes) {
					append = FALSE;

					switch (*p) {
						case '\'':
							my_add_text_and_entity(xargs, buffer, markup, "apos");
						break;

						case '"':
							my_add_text_and_entity(xargs, buffer, markup, "quot");
						break;

						default:
							// Append the UTF-8 character as it is to the buffer
							append = TRUE;
						break;
					}
				}

				// Keep the UTF-8 character unchanged
				if (append) {
					g_string_append_len(buffer, p, next - p);
				}
			}
			break;
		}

		p = next;
	}

	// Write the last bytes in the buffer
	buffer_add(xargs, markup, buffer->str);
	g_string_free(buffer, TRUE);
}



//
// Helper function for my_XML_TEXT_NODE() it ensures that the temporary buffer
// is merged into the main buffer before an entity is written.
//
static void my_add_text_and_entity (TextRenderCtx *xargs, GString *buffer, GtkTextTag *markup, const gchar *entity) {
	buffer_add(xargs, markup, buffer->str);
	g_string_truncate(buffer, 0);
	my_XML_ENTITY_REF_VALUE(xargs, entity);
}



// Displays a Comment ex: <!-- comment -->
static void my_XML_COMMENT_NODE (TextRenderCtx *xargs, xmlNode *node) {
	buffer_cat(xargs, xargs->markup->comment, "<!--", (gchar *) node->content, "-->");
}



// Displays a CDATA section ex: <![CDATA[<greeting>Hello, world!</greeting>]]>
static void my_XML_CDATA_SECTION_NODE (TextRenderCtx *xargs, xmlNode *node) {
	buffer_add(xargs, xargs->markup->cdata, "<![CDATA[");
	buffer_add(xargs, xargs->markup->cdata_content, (gchar *) node->content);
	buffer_add(xargs, xargs->markup->cdata, "]]>");
}



// Displays a PI (processing instruction) ex: <?stuff ?>
static void my_XML_PI_NODE (TextRenderCtx *xargs, xmlNode *node) {
	buffer_add(xargs, xargs->markup->syntax, "<?");
	buffer_add(xargs, xargs->markup->pi, (gchar *) node->name);

	// Add the data if there's something
	if (node->content) {
		buffer_add(xargs, xargs->markup->syntax, " ");
		buffer_add(xargs, xargs->markup->pi_data,(gchar *) node->content);
	}

	buffer_add(xargs, xargs->markup->syntax, "?>");
}



// Displays an Entity ex: &entity;
static void my_XML_ENTITY_REF_NODE (TextRenderCtx *xargs, xmlNode *node) {
	my_XML_ENTITY_REF_VALUE(xargs, (gchar *) node->name);
}



// Performs the actual display of an Entity ex: &my-chunk;
static void my_XML_ENTITY_REF_VALUE (TextRenderCtx *xargs, const gchar *name) {
	buffer_add(xargs, xargs->markup->syntax, "&");
	buffer_add(xargs, xargs->markup->entity_ref, name);
	buffer_add(xargs, xargs->markup->syntax, ";");
}


// Displays a DTD ex: <!DOCTYPE NewsML PUBLIC ...>
static void my_XML_DTD_NODE (TextRenderCtx *xargs, xmlNode *node) {
	// TODO the DTD node has children, so it's possible to have more advanced
	//      syntax highlighting.
	gchar *content = my_to_string(node);
	buffer_add(xargs, xargs->markup->dtd, content);
	g_free(content);
}



//
// Returns the node name with the right prefix based on the namespaces declared
// in the document. If the node has no namespace then the node name is return
// without a prefix (although the string still needs to be freed).
//
// This function returns an object that has to be freed with g_free().
//
static gchar* my_get_node_name_prefixed (xmlNode *node, HV *namespaces) {

	gchar *name = (gchar *) node->name;

	if (node->ns) {
		// Get the prefix corresponding to the namespace
		const gchar *prefix = my_get_uri_prefix(node->ns->href, namespaces);
		if (prefix) {
			name = g_strconcat(prefix, ":", name, NULL);
		}
		else {
			name = g_strdup(name);
		}
	}
	else {
		// The node has no namespace so we use the name
		name = g_strdup(name);
	}

	return name;
}



//
// Returns the prefix to use for the given URI. The prefix is chosen based on
// the namespaces declared in the document. If the prefix can't be found then
// NULL is returned.
//
// The string returned by this function shouldn't be modified nor freed.
//
static const gchar* my_get_uri_prefix (const xmlChar *uri, HV *namespaces) {

	// Reset of the namespace to the default namespace
	if (xmlStrEqual(uri, BAD_CAST "")) {
		return NULL;
	}

	// Get the prefix corresponding to the namespace
	SV **svPtr = hv_fetch(namespaces, (gchar *) uri, xmlStrlen(uri), FALSE);
	if (!svPtr) {
		// Can't find the prefix of the URI
		WARN("Can't find namespace for URI %s", uri);
		return NULL;
	}

	if (SvTYPE(*svPtr) != SVt_PV) {
		// Prefix isn't a string, something else was stored in the hash
		WARN("No valid namespace associated with URI %s, got: '%s'", uri, SvPV_nolen(*svPtr));
		return NULL;
	}

	// Ok found the prefix!
	return SvPVX(*svPtr);
}



//
// Returns a string representation of the given node.
//
// This function returns a string that has to be freed with g_free().
//
static gchar* my_to_string (xmlNode *node) {

	// Get the text representation of the XML node
	xmlBuffer *buffer = xmlBufferCreate();

	int old_indent = xmlIndentTreeOutput;
	xmlIndentTreeOutput = 1;
	int level = 0;
	int format = 0;
	xmlNodeDump(buffer, node->doc, node, level, format);
	xmlIndentTreeOutput = old_indent;

	// Transform the string to a glib string
	const gchar *content = (const gchar *) xmlBufferContent(buffer);
	gchar *string = g_strdup(content);
	xmlBufferFree(buffer);

	return string;
}



//
// Adds a text chunk to the buffer. The text is added with a markup tag (style).
//
// Normally the function gtk_text_buffer_insert_with_tags() should be used for
// this purpose. The problem is that inserting data by chunks into the text
// buffer is really slow. Also applying the style elements is taking a lot of
// time.
//
// So far the best way for insterting the data into the buffer is to collect it
// all into a string and to add the single string with the contents of the
// document into the buffer. Once the buffer is filled the styles can be
// applied.
//
static void my_buffer_add (TextRenderCtx *xargs, GtkTextTag *tag, xmlNode *node, const gchar *text) {

	const gchar *content = text ? text : "";

	++xargs->calls;
	g_string_append(xargs->xml_data, content);

	// We don't want the length of the string but the number of characters.
	// UTF-8 may encode one character as multiple bytes.
	glong end = xargs->buffer_pos + g_utf8_strlen(content, -1);

	gchar *name = node ? xacobeo_get_node_mark(node) : NULL;

	// Apply the markup if there's a tag
	if (tag) {
		ApplyTag to_apply = {
			.tag   = tag,
			.start = xargs->buffer_pos,
			.end   = end,
			.name  = name,
		};
		g_array_append_val(xargs->tags, to_apply);
	}
	xargs->buffer_pos = end;
}



//
// Gets the markup rules to use for rendering the XML with syntax highlighting.
// The markup rules are expected to be already defined in the buffer as tags.
//
// This function returns an object that has to be freed with g_free().
//
static MarkupTags* my_get_buffer_tags (GtkTextBuffer *buffer) {
	MarkupTags *markup = g_new0(MarkupTags, 1);
	GtkTextTagTable *table = gtk_text_buffer_get_tag_table(buffer);

	markup->result_count = gtk_text_tag_table_lookup(table, "result_count");
	markup->boolean      = gtk_text_tag_table_lookup(table, "boolean");
	markup->number       = gtk_text_tag_table_lookup(table, "number");
	markup->literal      = gtk_text_tag_table_lookup(table, "literal");

	markup->attribute_name  = gtk_text_tag_table_lookup(table, "attribute_name");
	markup->attribute_value = gtk_text_tag_table_lookup(table, "attribute_value");

	markup->comment       = gtk_text_tag_table_lookup(table, "comment");
	markup->dtd           = gtk_text_tag_table_lookup(table, "dtd");
	markup->element       = gtk_text_tag_table_lookup(table, "element");
	markup->pi            = gtk_text_tag_table_lookup(table, "pi");
	markup->pi_data       = gtk_text_tag_table_lookup(table, "pi_data");
	markup->syntax        = gtk_text_tag_table_lookup(table, "syntax");
	markup->cdata         = gtk_text_tag_table_lookup(table, "cdata");
	markup->cdata_content = gtk_text_tag_table_lookup(table, "cdata_content");

	markup->entity_ref = gtk_text_tag_table_lookup(table, "entity_ref");

	markup->namespace_name = gtk_text_tag_table_lookup(table, "namespace_name");
	markup->namespace_uri  = gtk_text_tag_table_lookup(table, "namespace_uri");
	markup->error  = gtk_text_tag_table_lookup(table, "error");

	return markup;
}



//
// Returns the path of a node. The path is expected to be unique for each node.
//
// This function returns a string that has to be freed with g_free().
//
gchar* xacobeo_get_node_path (xmlNode *origin, HV *namespaces) {

	if (origin == NULL) {
		return NULL;
	}

	// Reverse the path to the node (from top to bottom)
	GSList *list = NULL;
	for (xmlNode *iter = origin; iter; iter = iter->parent) {
		list = g_slist_prepend(list, iter);
	}

	// Build the path to the node
	GString *gstring = g_string_sized_new(32);
	gboolean use_separator = FALSE;
	for (GSList *iter = list; iter; iter = iter->next) {
		xmlNode *node = (xmlNode *) iter->data;

		switch (node->type) {
			case XML_DOCUMENT_NODE:
			case XML_HTML_DOCUMENT_NODE:
				g_string_append_c(gstring, '/');
			break;

			case XML_ELEMENT_NODE:
					if (use_separator) {
						g_string_append_c(gstring, '/');
					}
					else {
						use_separator = TRUE;
					}
					gchar *name = my_get_node_name_prefixed(node, namespaces);
					g_string_append(gstring, name);
					g_free(name);


					// Check if the node has siblings with the same name and namespace. If
					// yes then we must add an offset to the xpath expression.

					// Look for previous sibling with the same name.
					int similar = 0;
					for (xmlNode *sibling = node->prev; sibling; sibling = sibling->prev) {
						if (ELEMENT_MATCH(sibling, node)) {
							++similar;
						}
					}

					if (similar == 0) {
						// No previous sibling, but maybe we are the first in the incoming
						// list! Let's scan on the other direction
						for (xmlNode *sibling = node->next; sibling; sibling = sibling->next) {
							if (ELEMENT_MATCH(sibling, node)) {
								similar = 1;
								break;
							}
						}
					}
					else {
						// XPath starts its indexex at 1 instead of 0
						++similar;
					}

					if (similar) {
						// The node name is not unique we must add an index
						g_string_append_printf(gstring, "[%d]", similar);
					}

			break;

			default:
				WARN("Unknown XML type %d for %s", node->type, node->name);
			break;
		}
	}

	g_slist_free(list);
	gchar *path = g_strdup(gstring->str);
	g_string_free(gstring, TRUE);

	return path;
}


//
// Returns a unique identifier for a give node.
//
// This function returns a string that has to be freed with g_free().
//
gchar* xacobeo_get_node_mark (xmlNode *node) {
	return g_strdup_printf("%p", (void *)node);
}
