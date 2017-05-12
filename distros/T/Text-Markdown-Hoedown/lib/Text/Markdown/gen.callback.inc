
void
blockcode(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->blockcode = tmh_cb_blockcode;
    hv_stores(renderer->opaque, "blockcode", newSVsv(code));

void
blockquote(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->blockquote = tmh_cb_blockquote;
    hv_stores(renderer->opaque, "blockquote", newSVsv(code));

void
blockhtml(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->blockhtml = tmh_cb_blockhtml;
    hv_stores(renderer->opaque, "blockhtml", newSVsv(code));

void
header(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->header = tmh_cb_header;
    hv_stores(renderer->opaque, "header", newSVsv(code));

void
hrule(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->hrule = tmh_cb_hrule;
    hv_stores(renderer->opaque, "hrule", newSVsv(code));

void
list(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->list = tmh_cb_list;
    hv_stores(renderer->opaque, "list", newSVsv(code));

void
listitem(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->listitem = tmh_cb_listitem;
    hv_stores(renderer->opaque, "listitem", newSVsv(code));

void
paragraph(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->paragraph = tmh_cb_paragraph;
    hv_stores(renderer->opaque, "paragraph", newSVsv(code));

void
table(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->table = tmh_cb_table;
    hv_stores(renderer->opaque, "table", newSVsv(code));

void
table_row(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->table_row = tmh_cb_table_row;
    hv_stores(renderer->opaque, "table_row", newSVsv(code));

void
table_cell(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->table_cell = tmh_cb_table_cell;
    hv_stores(renderer->opaque, "table_cell", newSVsv(code));

void
footnotes(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->footnotes = tmh_cb_footnotes;
    hv_stores(renderer->opaque, "footnotes", newSVsv(code));

void
footnote_def(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->footnote_def = tmh_cb_footnote_def;
    hv_stores(renderer->opaque, "footnote_def", newSVsv(code));

void
autolink(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->autolink = tmh_cb_autolink;
    hv_stores(renderer->opaque, "autolink", newSVsv(code));

void
codespan(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->codespan = tmh_cb_codespan;
    hv_stores(renderer->opaque, "codespan", newSVsv(code));

void
double_emphasis(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->double_emphasis = tmh_cb_double_emphasis;
    hv_stores(renderer->opaque, "double_emphasis", newSVsv(code));

void
emphasis(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->emphasis = tmh_cb_emphasis;
    hv_stores(renderer->opaque, "emphasis", newSVsv(code));

void
underline(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->underline = tmh_cb_underline;
    hv_stores(renderer->opaque, "underline", newSVsv(code));

void
highlight(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->highlight = tmh_cb_highlight;
    hv_stores(renderer->opaque, "highlight", newSVsv(code));

void
quote(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->quote = tmh_cb_quote;
    hv_stores(renderer->opaque, "quote", newSVsv(code));

void
image(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->image = tmh_cb_image;
    hv_stores(renderer->opaque, "image", newSVsv(code));

void
linebreak(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->linebreak = tmh_cb_linebreak;
    hv_stores(renderer->opaque, "linebreak", newSVsv(code));

void
link(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->link = tmh_cb_link;
    hv_stores(renderer->opaque, "link", newSVsv(code));

void
raw_html_tag(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->raw_html_tag = tmh_cb_raw_html_tag;
    hv_stores(renderer->opaque, "raw_html_tag", newSVsv(code));

void
triple_emphasis(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->triple_emphasis = tmh_cb_triple_emphasis;
    hv_stores(renderer->opaque, "triple_emphasis", newSVsv(code));

void
strikethrough(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->strikethrough = tmh_cb_strikethrough;
    hv_stores(renderer->opaque, "strikethrough", newSVsv(code));

void
superscript(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->superscript = tmh_cb_superscript;
    hv_stores(renderer->opaque, "superscript", newSVsv(code));

void
footnote_ref(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->footnote_ref = tmh_cb_footnote_ref;
    hv_stores(renderer->opaque, "footnote_ref", newSVsv(code));

void
entity(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->entity = tmh_cb_entity;
    hv_stores(renderer->opaque, "entity", newSVsv(code));

void
normal_text(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->normal_text = tmh_cb_normal_text;
    hv_stores(renderer->opaque, "normal_text", newSVsv(code));

void
doc_header(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->doc_header = tmh_cb_doc_header;
    hv_stores(renderer->opaque, "doc_header", newSVsv(code));

void
doc_footer(SV* self, SV *code)
CODE:
    hoedown_renderer* renderer = XS_STATE(hoedown_renderer*, self);
    renderer->doc_footer = tmh_cb_doc_footer;
    hv_stores(renderer->opaque, "doc_footer", newSVsv(code));

