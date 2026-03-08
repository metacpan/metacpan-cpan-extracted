/* C++ headers before Perl to avoid macro conflicts (do_open/do_close vs <locale>) */
#include <pugixml.hpp>
#include <sstream>
#include <string>
#include <cerrno>
#include <cstring>

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

using namespace pugi;

/* Forward declaration for compiled XPath wrapper */
struct PugiXPath {
    xpath_query* query;
};

/* Wrapper structures */

struct PugiDoc {
    xml_document* doc;
};

struct PugiNode {
    xml_node node;
    SV* doc_sv;  /* Reference to document to keep it alive */
};

struct PugiAttr {
    xml_attribute attr;
    SV* doc_sv;  /* Reference to document to keep it alive */
};

typedef PugiDoc*   XML__PugiXML;
typedef PugiNode*  XML__PugiXML__Node;
typedef PugiAttr*  XML__PugiXML__Attr;
typedef PugiXPath* XML__PugiXML__XPath;

/* Helper functions */

static SV* wrap_node(pTHX_ xml_node node, SV* doc_sv) {
    if (!node) {
        return &PL_sv_undef;
    }

    PugiNode* wrapper = new (std::nothrow) PugiNode;
    if (!wrapper) {
        croak("Out of memory allocating node wrapper");
    }
    wrapper->node = node;
    wrapper->doc_sv = SvREFCNT_inc(doc_sv);

    SV* sv = newSV(0);
    sv_setref_pv(sv, "XML::PugiXML::Node", (void*)wrapper);
    return sv;
}

static SV* wrap_attr(pTHX_ xml_attribute attr, SV* doc_sv) {
    if (!attr) {
        return &PL_sv_undef;
    }

    PugiAttr* wrapper = new (std::nothrow) PugiAttr;
    if (!wrapper) {
        croak("Out of memory allocating attr wrapper");
    }
    wrapper->attr = attr;
    wrapper->doc_sv = SvREFCNT_inc(doc_sv);

    SV* sv = newSV(0);
    sv_setref_pv(sv, "XML::PugiXML::Attr", (void*)wrapper);
    return sv;
}

/* Helpers to return UTF-8 strings */
static SV* newSVpv_utf8(pTHX_ const char* str) {
    SV* sv = newSVpv(str, 0);
    SvUTF8_on(sv);
    return sv;
}

static SV* new_utf8_svpvn(pTHX_ const char* str, STRLEN len) {
    SV* sv = newSVpvn(str, len);
    SvUTF8_on(sv);
    return sv;
}

static void set_parse_result(pTHX_ xml_parse_result& result) {
    if (!result) {
        sv_setpvf(get_sv("@", GV_ADD), "XML parse error: %s at offset %" IVdf,
                  result.description(), (IV)result.offset);
    } else {
        sv_setpvs(get_sv("@", GV_ADD), "");
    }
}

MODULE = XML::PugiXML  PACKAGE = XML::PugiXML

PROTOTYPES: DISABLE

XML::PugiXML
new(const char* CLASS)
CODE:
{
    PERL_UNUSED_VAR(CLASS);
    PugiDoc* doc = new (std::nothrow) PugiDoc;
    if (!doc) {
        croak("Out of memory allocating document");
    }
    doc->doc = new (std::nothrow) xml_document();
    if (!doc->doc) {
        delete doc;
        croak("Out of memory allocating xml_document");
    }
    RETVAL = doc;
}
OUTPUT:
    RETVAL

void
DESTROY(XML::PugiXML self)
CODE:
{
    delete self->doc;
    delete self;
}

bool
load_file(XML::PugiXML self, const char* path, unsigned int parse_options = parse_default)
CODE:
{
    xml_parse_result result = self->doc->load_file(path, parse_options);
    set_parse_result(aTHX_ result);
    RETVAL = (bool)result;
}
OUTPUT:
    RETVAL

bool
load_string(XML::PugiXML self, const char* xml, unsigned int parse_options = parse_default)
CODE:
{
    xml_parse_result result = self->doc->load_string(xml, parse_options);
    set_parse_result(aTHX_ result);
    RETVAL = (bool)result;
}
OUTPUT:
    RETVAL

void
reset(XML::PugiXML self)
CODE:
{
    self->doc->reset();
}

bool
save_file(XML::PugiXML self, const char* path, const char* indent = "\t", unsigned int flags = format_default)
CODE:
{
    RETVAL = self->doc->save_file(path, indent, flags);
    if (!RETVAL) {
        sv_setpvf(get_sv("@", GV_ADD), "Failed to save XML file: %s", strerror(errno));
    } else {
        sv_setpvs(get_sv("@", GV_ADD), "");
    }
}
OUTPUT:
    RETVAL

SV*
to_string(XML::PugiXML self, const char* indent = "\t", unsigned int flags = format_default)
CODE:
{
    std::ostringstream oss;
    self->doc->save(oss, indent, flags);
    std::string str = oss.str();
    RETVAL = new_utf8_svpvn(aTHX_ str.c_str(), str.length());
}
OUTPUT:
    RETVAL

SV*
root(XML::PugiXML self)
CODE:
{
    xml_node root = self->doc->document_element();
    RETVAL = wrap_node(aTHX_ root, ST(0));
}
OUTPUT:
    RETVAL

SV*
child(XML::PugiXML self, const char* name)
CODE:
{
    xml_node child = self->doc->child(name);
    RETVAL = wrap_node(aTHX_ child, ST(0));
}
OUTPUT:
    RETVAL

SV*
select_node(XML::PugiXML self, const char* xpath)
CODE:
{
    try {
        xpath_node result = self->doc->select_node(xpath);
        RETVAL = wrap_node(aTHX_ result.node(), ST(0));
    } catch (const xpath_exception& e) {
        croak("XPath error: %s", e.what());
    }
}
OUTPUT:
    RETVAL

void
select_nodes(XML::PugiXML self, const char* xpath)
PPCODE:
{
    try {
        xpath_node_set nodes = self->doc->select_nodes(xpath);
        for (xpath_node_set::const_iterator it = nodes.begin(); it != nodes.end(); ++it) {
            SV* node_sv = wrap_node(aTHX_ it->node(), ST(0));
            XPUSHs(sv_2mortal(node_sv));
        }
    } catch (const xpath_exception& e) {
        croak("XPath error: %s", e.what());
    }
}

SV*
compile_xpath(XML::PugiXML self, const char* xpath)
CODE:
{
    PERL_UNUSED_VAR(self);
    try {
        xpath_query* query = new (std::nothrow) xpath_query(xpath);
        if (!query) {
            croak("Out of memory allocating xpath_query");
        }
        PugiXPath* wrapper = new (std::nothrow) PugiXPath;
        if (!wrapper) {
            delete query;
            croak("Out of memory allocating XPath wrapper");
        }
        wrapper->query = query;

        SV* sv = newSV(0);
        sv_setref_pv(sv, "XML::PugiXML::XPath", (void*)wrapper);
        RETVAL = sv;
    } catch (const xpath_exception& e) {
        croak("XPath compilation error: %s", e.what());
    }
}
OUTPUT:
    RETVAL

unsigned int
FORMAT_DEFAULT()
CODE:
    RETVAL = format_default;
OUTPUT:
    RETVAL

unsigned int
FORMAT_INDENT()
CODE:
    RETVAL = format_indent;
OUTPUT:
    RETVAL

unsigned int
FORMAT_NO_DECLARATION()
CODE:
    RETVAL = format_no_declaration;
OUTPUT:
    RETVAL

unsigned int
FORMAT_RAW()
CODE:
    RETVAL = format_raw;
OUTPUT:
    RETVAL

unsigned int
FORMAT_WRITE_BOM()
CODE:
    RETVAL = format_write_bom;
OUTPUT:
    RETVAL

unsigned int
PARSE_DEFAULT()
CODE:
    RETVAL = parse_default;
OUTPUT:
    RETVAL

unsigned int
PARSE_MINIMAL()
CODE:
    RETVAL = parse_minimal;
OUTPUT:
    RETVAL

unsigned int
PARSE_PI()
CODE:
    RETVAL = parse_pi;
OUTPUT:
    RETVAL

unsigned int
PARSE_COMMENTS()
CODE:
    RETVAL = parse_comments;
OUTPUT:
    RETVAL

unsigned int
PARSE_CDATA()
CODE:
    RETVAL = parse_cdata;
OUTPUT:
    RETVAL

unsigned int
PARSE_WS_PCDATA()
CODE:
    RETVAL = parse_ws_pcdata;
OUTPUT:
    RETVAL

unsigned int
PARSE_ESCAPES()
CODE:
    RETVAL = parse_escapes;
OUTPUT:
    RETVAL

unsigned int
PARSE_EOL()
CODE:
    RETVAL = parse_eol;
OUTPUT:
    RETVAL

unsigned int
PARSE_DECLARATION()
CODE:
    RETVAL = parse_declaration;
OUTPUT:
    RETVAL

unsigned int
PARSE_DOCTYPE()
CODE:
    RETVAL = parse_doctype;
OUTPUT:
    RETVAL

unsigned int
PARSE_FULL()
CODE:
    RETVAL = parse_full;
OUTPUT:
    RETVAL


MODULE = XML::PugiXML  PACKAGE = XML::PugiXML::Node

void
DESTROY(XML::PugiXML::Node self)
CODE:
{
    SvREFCNT_dec(self->doc_sv);
    delete self;
}

SV*
name(XML::PugiXML::Node self)
CODE:
{
    RETVAL = newSVpv_utf8(aTHX_ self->node.name());
}
OUTPUT:
    RETVAL

SV*
value(XML::PugiXML::Node self)
CODE:
{
    RETVAL = newSVpv_utf8(aTHX_ self->node.value());
}
OUTPUT:
    RETVAL

SV*
text(XML::PugiXML::Node self)
CODE:
{
    RETVAL = newSVpv_utf8(aTHX_ self->node.text().get());
}
OUTPUT:
    RETVAL

SV*
parent(XML::PugiXML::Node self)
CODE:
{
    RETVAL = wrap_node(aTHX_ self->node.parent(), self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
child(XML::PugiXML::Node self, const char* name)
CODE:
{
    RETVAL = wrap_node(aTHX_ self->node.child(name), self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
first_child(XML::PugiXML::Node self)
CODE:
{
    RETVAL = wrap_node(aTHX_ self->node.first_child(), self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
next_sibling(XML::PugiXML::Node self, const char* name = NULL)
CODE:
{
    if (name) {
        RETVAL = wrap_node(aTHX_ self->node.next_sibling(name), self->doc_sv);
    } else {
        RETVAL = wrap_node(aTHX_ self->node.next_sibling(), self->doc_sv);
    }
}
OUTPUT:
    RETVAL

SV*
previous_sibling(XML::PugiXML::Node self, const char* name = NULL)
CODE:
{
    if (name) {
        RETVAL = wrap_node(aTHX_ self->node.previous_sibling(name), self->doc_sv);
    } else {
        RETVAL = wrap_node(aTHX_ self->node.previous_sibling(), self->doc_sv);
    }
}
OUTPUT:
    RETVAL

SV*
last_child(XML::PugiXML::Node self)
CODE:
{
    RETVAL = wrap_node(aTHX_ self->node.last_child(), self->doc_sv);
}
OUTPUT:
    RETVAL

void
children(XML::PugiXML::Node self, const char* name = NULL)
PPCODE:
{
    if (name) {
        for (xml_node child = self->node.child(name); child; child = child.next_sibling(name)) {
            SV* node_sv = wrap_node(aTHX_ child, self->doc_sv);
            XPUSHs(sv_2mortal(node_sv));
        }
    } else {
        for (xml_node child = self->node.first_child(); child; child = child.next_sibling()) {
            SV* node_sv = wrap_node(aTHX_ child, self->doc_sv);
            XPUSHs(sv_2mortal(node_sv));
        }
    }
}

void
attrs(XML::PugiXML::Node self)
PPCODE:
{
    for (xml_attribute attr = self->node.first_attribute(); attr; attr = attr.next_attribute()) {
        SV* attr_sv = wrap_attr(aTHX_ attr, self->doc_sv);
        XPUSHs(sv_2mortal(attr_sv));
    }
}

SV*
attr(XML::PugiXML::Node self, const char* name)
CODE:
{
    RETVAL = wrap_attr(aTHX_ self->node.attribute(name), self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
append_child(XML::PugiXML::Node self, const char* name)
CODE:
{
    xml_node child = self->node.append_child(name);
    RETVAL = wrap_node(aTHX_ child, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
prepend_child(XML::PugiXML::Node self, const char* name)
CODE:
{
    xml_node child = self->node.prepend_child(name);
    RETVAL = wrap_node(aTHX_ child, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
insert_child_before(XML::PugiXML::Node self, const char* name, XML::PugiXML::Node ref_node)
CODE:
{
    xml_node child = self->node.insert_child_before(name, ref_node->node);
    RETVAL = wrap_node(aTHX_ child, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
insert_child_after(XML::PugiXML::Node self, const char* name, XML::PugiXML::Node ref_node)
CODE:
{
    xml_node child = self->node.insert_child_after(name, ref_node->node);
    RETVAL = wrap_node(aTHX_ child, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
append_cdata(XML::PugiXML::Node self, const char* content)
CODE:
{
    xml_node cdata = self->node.append_child(node_cdata);
    if (cdata) {
        cdata.set_value(content);
    }
    RETVAL = wrap_node(aTHX_ cdata, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
append_comment(XML::PugiXML::Node self, const char* content)
CODE:
{
    xml_node comment = self->node.append_child(node_comment);
    if (comment) {
        comment.set_value(content);
    }
    RETVAL = wrap_node(aTHX_ comment, self->doc_sv);
}
OUTPUT:
    RETVAL

int
type(XML::PugiXML::Node self)
CODE:
{
    RETVAL = (int)self->node.type();
}
OUTPUT:
    RETVAL

SV*
path(XML::PugiXML::Node self, char delimiter = '/')
CODE:
{
    std::string p = self->node.path(delimiter);
    RETVAL = new_utf8_svpvn(aTHX_ p.c_str(), p.length());
}
OUTPUT:
    RETVAL

SV*
find_child_by_attribute(XML::PugiXML::Node self, const char* name, const char* attr_name, const char* attr_value)
CODE:
{
    xml_node child = self->node.find_child_by_attribute(name, attr_name, attr_value);
    RETVAL = wrap_node(aTHX_ child, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
root(XML::PugiXML::Node self)
CODE:
{
    RETVAL = wrap_node(aTHX_ self->node.root(), self->doc_sv);
}
OUTPUT:
    RETVAL

bool
set_name(XML::PugiXML::Node self, const char* name)
CODE:
{
    RETVAL = self->node.set_name(name);
}
OUTPUT:
    RETVAL

bool
set_value(XML::PugiXML::Node self, const char* value)
CODE:
{
    RETVAL = self->node.set_value(value);
}
OUTPUT:
    RETVAL

bool
set_text(XML::PugiXML::Node self, const char* text)
CODE:
{
    RETVAL = self->node.text().set(text);
}
OUTPUT:
    RETVAL

SV*
select_node(XML::PugiXML::Node self, const char* xpath)
CODE:
{
    try {
        xpath_node result = self->node.select_node(xpath);
        RETVAL = wrap_node(aTHX_ result.node(), self->doc_sv);
    } catch (const xpath_exception& e) {
        croak("XPath error: %s", e.what());
    }
}
OUTPUT:
    RETVAL

void
select_nodes(XML::PugiXML::Node self, const char* xpath)
PPCODE:
{
    try {
        xpath_node_set nodes = self->node.select_nodes(xpath);
        for (xpath_node_set::const_iterator it = nodes.begin(); it != nodes.end(); ++it) {
            SV* node_sv = wrap_node(aTHX_ it->node(), self->doc_sv);
            XPUSHs(sv_2mortal(node_sv));
        }
    } catch (const xpath_exception& e) {
        croak("XPath error: %s", e.what());
    }
}

bool
valid(XML::PugiXML::Node self)
CODE:
{
    RETVAL = (bool)self->node;
}
OUTPUT:
    RETVAL

SV*
append_attr(XML::PugiXML::Node self, const char* name)
CODE:
{
    xml_attribute attr = self->node.append_attribute(name);
    RETVAL = wrap_attr(aTHX_ attr, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
prepend_attr(XML::PugiXML::Node self, const char* name)
CODE:
{
    xml_attribute attr = self->node.prepend_attribute(name);
    RETVAL = wrap_attr(aTHX_ attr, self->doc_sv);
}
OUTPUT:
    RETVAL

bool
remove_child(XML::PugiXML::Node self, XML::PugiXML::Node child)
CODE:
{
    RETVAL = self->node.remove_child(child->node);
}
OUTPUT:
    RETVAL

bool
remove_attr(XML::PugiXML::Node self, const char* name)
CODE:
{
    xml_attribute attr = self->node.attribute(name);
    RETVAL = self->node.remove_attribute(attr);
}
OUTPUT:
    RETVAL

SV*
append_copy(XML::PugiXML::Node self, XML::PugiXML::Node source)
CODE:
{
    xml_node copy = self->node.append_copy(source->node);
    RETVAL = wrap_node(aTHX_ copy, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
prepend_copy(XML::PugiXML::Node self, XML::PugiXML::Node source)
CODE:
{
    xml_node copy = self->node.prepend_copy(source->node);
    RETVAL = wrap_node(aTHX_ copy, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
insert_copy_before(XML::PugiXML::Node self, XML::PugiXML::Node source, XML::PugiXML::Node ref_node)
CODE:
{
    xml_node copy = self->node.insert_copy_before(source->node, ref_node->node);
    RETVAL = wrap_node(aTHX_ copy, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
insert_copy_after(XML::PugiXML::Node self, XML::PugiXML::Node source, XML::PugiXML::Node ref_node)
CODE:
{
    xml_node copy = self->node.insert_copy_after(source->node, ref_node->node);
    RETVAL = wrap_node(aTHX_ copy, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
set_attr(XML::PugiXML::Node self, const char* name, const char* value)
CODE:
{
    xml_attribute attr = self->node.attribute(name);
    if (!attr) {
        attr = self->node.append_attribute(name);
    }
    if (attr) {
        attr.set_value(value);
    }
    RETVAL = wrap_attr(aTHX_ attr, self->doc_sv);
}
OUTPUT:
    RETVAL

SV*
append_pi(XML::PugiXML::Node self, const char* target, const char* data = NULL)
CODE:
{
    xml_node pi = self->node.append_child(node_pi);
    if (pi) {
        pi.set_name(target);
        if (data) {
            pi.set_value(data);
        }
    }
    RETVAL = wrap_node(aTHX_ pi, self->doc_sv);
}
OUTPUT:
    RETVAL

size_t
hash(XML::PugiXML::Node self)
CODE:
{
    RETVAL = self->node.hash_value();
}
OUTPUT:
    RETVAL

IV
offset_debug(XML::PugiXML::Node self)
CODE:
{
    RETVAL = (IV)self->node.offset_debug();
}
OUTPUT:
    RETVAL


MODULE = XML::PugiXML  PACKAGE = XML::PugiXML::Attr

void
DESTROY(XML::PugiXML::Attr self)
CODE:
{
    SvREFCNT_dec(self->doc_sv);
    delete self;
}

SV*
name(XML::PugiXML::Attr self)
CODE:
{
    RETVAL = newSVpv_utf8(aTHX_ self->attr.name());
}
OUTPUT:
    RETVAL

SV*
value(XML::PugiXML::Attr self)
CODE:
{
    RETVAL = newSVpv_utf8(aTHX_ self->attr.value());
}
OUTPUT:
    RETVAL

int
as_int(XML::PugiXML::Attr self)
CODE:
{
    RETVAL = self->attr.as_int();
}
OUTPUT:
    RETVAL

double
as_double(XML::PugiXML::Attr self)
CODE:
{
    RETVAL = self->attr.as_double();
}
OUTPUT:
    RETVAL

bool
as_bool(XML::PugiXML::Attr self)
CODE:
{
    RETVAL = self->attr.as_bool();
}
OUTPUT:
    RETVAL

unsigned int
as_uint(XML::PugiXML::Attr self)
CODE:
{
    RETVAL = self->attr.as_uint();
}
OUTPUT:
    RETVAL

IV
as_llong(XML::PugiXML::Attr self)
CODE:
{
    RETVAL = (IV)self->attr.as_llong();
}
OUTPUT:
    RETVAL

UV
as_ullong(XML::PugiXML::Attr self)
CODE:
{
    RETVAL = (UV)self->attr.as_ullong();
}
OUTPUT:
    RETVAL

bool
set_value(XML::PugiXML::Attr self, const char* value)
CODE:
{
    RETVAL = self->attr.set_value(value);
}
OUTPUT:
    RETVAL

bool
valid(XML::PugiXML::Attr self)
CODE:
{
    RETVAL = (bool)self->attr;
}
OUTPUT:
    RETVAL


MODULE = XML::PugiXML  PACKAGE = XML::PugiXML::XPath

void
DESTROY(XML::PugiXML::XPath self)
CODE:
{
    delete self->query;
    delete self;
}

SV*
evaluate_node(XML::PugiXML::XPath self, XML::PugiXML::Node node)
CODE:
{
    try {
        xpath_node result = self->query->evaluate_node(node->node);
        RETVAL = wrap_node(aTHX_ result.node(), node->doc_sv);
    } catch (const xpath_exception& e) {
        croak("XPath error: %s", e.what());
    }
}
OUTPUT:
    RETVAL

void
evaluate_nodes(XML::PugiXML::XPath self, XML::PugiXML::Node node)
PPCODE:
{
    try {
        xpath_node_set nodes = self->query->evaluate_node_set(node->node);
        for (xpath_node_set::const_iterator it = nodes.begin(); it != nodes.end(); ++it) {
            SV* node_sv = wrap_node(aTHX_ it->node(), node->doc_sv);
            XPUSHs(sv_2mortal(node_sv));
        }
    } catch (const xpath_exception& e) {
        croak("XPath error: %s", e.what());
    }
}

SV*
evaluate_string(XML::PugiXML::XPath self, XML::PugiXML::Node node)
CODE:
{
    try {
        std::string result = self->query->evaluate_string(node->node);
        RETVAL = new_utf8_svpvn(aTHX_ result.c_str(), result.length());
    } catch (const xpath_exception& e) {
        croak("XPath error: %s", e.what());
    }
}
OUTPUT:
    RETVAL

double
evaluate_number(XML::PugiXML::XPath self, XML::PugiXML::Node node)
CODE:
{
    try {
        RETVAL = self->query->evaluate_number(node->node);
    } catch (const xpath_exception& e) {
        croak("XPath error: %s", e.what());
    }
}
OUTPUT:
    RETVAL

bool
evaluate_boolean(XML::PugiXML::XPath self, XML::PugiXML::Node node)
CODE:
{
    try {
        RETVAL = self->query->evaluate_boolean(node->node);
    } catch (const xpath_exception& e) {
        croak("XPath error: %s", e.what());
    }
}
OUTPUT:
    RETVAL
