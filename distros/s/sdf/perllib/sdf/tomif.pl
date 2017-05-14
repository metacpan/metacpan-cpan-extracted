# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     MIF Format Driver
#
# >>Copyright::
# Copyright (c) 1992-1996, Ian Clatworthy (ianc@mincom.com).
# You may distribute under the terms specified in the LICENSE file.
#
# >>History::
# -----------------------------------------------------------------------
# Date      Who     Change
# 01-Mar-98 ianc    Inner and Outer alignment of tables now supported
#                   David Schooley's patch to MifPathName also applied.
# 29-Feb-96 ianc    SDF 2.000
# -----------------------------------------------------------------------
#
# >>Purpose::
# This library provides an [[SDF_DRIVER]] which generates
# [[FrameMaker]]'s [[MIF]] (Maker Interchange Format) files.
#
# >>Description::
# Variables supported include:
# 
# * {{MIF_EXT}} - the extension to use for Frame files in jumps
# * {{MIF_BOOK_MODE}} - build a book, rather than a normal document
# * {{MIF_ALL_STYLES}} - output all paragraph styles, rather than
#   just the used ones.
#
# >>Limitations::
# Changing a font family or style does not update the FPostScriptName
# attribute. In practice, this may not be a problem as it may be
# fixed by [[FrameMaker]] during the loading of a [[MIF]] file.
#
# Is _MifProcessControls() the best way to handle document control settings?
# (There may be problems with only processing DOC_* variables at the end.)
#
# We do not support a Running header/footer type of {{paratag}} as
# inserting the name of a Frame paragraph tag would probably be
# meaningless.
#
# Only the predefined colours are currently supported. Ultimately,
# the RGB value of an arbitary color could be converted to CMYK and
# added to the color catalog.
#
# >>Resources::
#
# >>Implementation::
#

##### Constants #####

# FrameMaker 5.0 adds blank pages for tables with titles, so
# this configuration flag controls whether
# we produce real or simple/simulated table titles.
# Unless a book is being generated, generating a list of tables
# only works when table titles are separate paragraphs.
$_MIF_SIMPLE_TBL_TITLES = 1;

# Define the set of paragraph attributes.
@MIF_PARA_ATTRS = (
    'AcrobatLevel',
    'Alignment',
    'AutoNum',
    'BlockSize',
    'BotSepAtIndent',
    'BotSepOffset',
    'BotSeparator',
    'CellAlignment',
    'CellBMarginFixed',
    'CellLMarginFixed',
    'CellMargins',
    'CellRMarginFixed',
    'CellTMarginFixed',
    'FIndent',
    'FIndentOffset',
    'FIndentRelative',
    'FontAngle',
    'FontCase',
    'FontChangeBar',
    'FontColor',
    'FontDW',
    'FontDX',
    'FontDY',
    'FontFamily',
    'FontLocked',
    'FontOutline',
    'FontOverline',
    'FontPairKern',
    'FontPosition',
    'FontSeparation',
    'FontShadow',
    'FontSize',
    'FontStrike',
    'FontUnderlining',
    'FontVar',
    'FontWeight',
    'HyphenMaxLines',
    'HyphenMinPrefix',
    'HyphenMinSuffix',
    'HyphenMinWord',
    'Hyphenate',
    'LIndent',
    'Language',
    'Leading',
    'LetterSpace',
    'LineSpacing',
    'Locked',
    'MaxWordSpace',
    'MinWordSpace',
    'NextTag',
    'NumFormat',
    'NumberFont',
    'NumAtEnd',
    'OptWordSpace',
    'Placement',
    'PlacementStyle',
    'RIndent',
    'RunInDefaultPunct',
    'SpAfter',
    'SpBefore',
    'TabStop',
    'TopSepAtIndent',
    'TopSepOffset',
    'TopSeparator',
    'UseNextTag',
    'WithNext',
    'WithPrev',
);

# Define the set of font attributes.
@MIF_FONT_ATTRS = (
    'Family',
    'Var',
    'Weight',
    'Angle',
    'PostScriptName',
    'Size',
    'Underlining',
    'Overline',
    'Strike',
    'ChangeBar',
    'Outline',
    'Shadow',
    'PairKern',
    'Case',
    'Position',
    'DX',
    'DY',
    'DW',
    'Locked',
    'Separation',
    'Color');

# This is the gap in points between the actual border and the
# decoration for an area on a master page
$_MIF_BORDER_GAP = 6;

# This is the text flow id of the main text
$_MIF_TEXTFLOW_MAIN = 9999;

# This is where we start numbering our text flows from to ensure there
# are no conflicts with those already in templates
$_MIF_TEXTFLOW_START = 10000;

# This is where we start numbering our objects from to ensure there
# are no conflicts with those already in templates
$_MIF_OBJ_REF_START = 11000;

# This is where we start numbering TOC cross-references
$_MIF_TOC_XREF_START = 2000;

# The character mapping table (SDF -> MIF)
%_MIF_CHAR = (
    'bullet',       'Bullet',
    'c',            '\xa9 ',
    'cent',         'Cent',
    'dagger',       'Dagger',
    'doubledagger', 'DoubleDagger',
    'emdash',       'EmDash',
    'endash',       'EnDash',
    'emspace',      'EmSpace',
    'enspace',      'EnSpace',
    'lbrace',       '{',
    'lbracket',     '[',
    'nbdash',       'HardHyphen',
    'nbspace',      'HardSpace',
    'nl',           'HardReturn',
    'pound',        'Pound',
    'r',            '\xa8 ',
    'rbrace',       '}',
    'rbracket',     ']',
    'tab',          'Tab',
    'tm',           '\xaa ',
    'yen',          'Yen',

    # From pod2fm ...

    'amp'       =>      '&',    #   ampersand
    'lt'        =>      '<',    #   left chevron, less-than
    'gt'        =>      '\\>',    #   right chevron, greater-than
    'quot'      =>      '"',    #   double quote

    "Aacute"    =>      "\\xe7 ",    #   capital A, acute accent
    "aacute"    =>      "\\x87 ",    #   small a, acute accent
    "Acirc"     =>      "\\xe5 ",    #   capital A, circumflex accent
    "acirc"     =>      "\\x89 ",    #   small a, circumflex accent
    "AElig"     =>      '\\xae ',    #   capital AE diphthong (ligature)
    "aelig"     =>      '\\xbe ',    #   small ae diphthong (ligature)
    "Agrave"    =>      "\\xcb ",    #   capital A, grave accent
    "agrave"    =>      "\\x88 ",    #   small a, grave accent
    "Aring"     =>      '\\x81 ',    #   capital A, ring
    "aring"     =>      '\\x8c ',    #   small a, ring
    "Atilde"    =>      '\\xcc ',    #   capital A, tilde
    "atilde"    =>      '\\x8b ',    #   small a, tilde
    "Auml"      =>      '\\x80 ',    #   capital A, dieresis or umlaut mark
    "auml"      =>      '\\x8a ',    #   small a, dieresis or umlaut mark
    "Ccedil"    =>      '\\x82 ',    #   capital C, cedilla
    "ccedil"    =>      '\\x8d ',    #   small c, cedilla
    "Eacute"    =>      "\\x83 ",    #   capital E, acute accent
    "eacute"    =>      "\\x8e ",    #   small e, acute accent
    "Ecirc"     =>      "\\xe6 ",    #   capital E, circumflex accent
    "ecirc"     =>      "\\x90 ",    #   small e, circumflex accent
    "Egrave"    =>      "\\xe9 ",    #   capital E, grave accent
    "egrave"    =>      "\\x8f ",    #   small e, grave accent
    "Euml"      =>      "\\xe8 ",    #   capital E, dieresis or umlaut mark
    "euml"      =>      "\\x91 ",    #   small e, dieresis or umlaut mark
    "Iacute"    =>      "\\xea ",    #   capital I, acute accent
    "iacute"    =>      "\\x92 ",    #   small i, acute accent
    "Icirc"     =>      "\\xeb ",    #   capital I, circumflex accent
    "icirc"     =>      "\\x90 ",    #   small i, circumflex accent
    "Igrave"    =>      "\\xe9 ",    #   capital I, grave accent
    "igrave"    =>      "\\x93 ",    #   small i, grave accent
    "Iuml"      =>      "\\xec ",    #   capital I, dieresis or umlaut mark
    "iuml"      =>      "\\x95 ",    #   small i, dieresis or umlaut mark
    "Ntilde"    =>      '\\x84 ',    #   capital N, tilde
    "ntilde"    =>      '\\x96 ',    #   small n, tilde
    "Oacute"    =>      "\\xee ",    #   capital O, acute accent
    "oacute"    =>      "\\x97 ",    #   small o, acute accent
    "Ocirc"     =>      "\\xef ",    #   capital O, circumflex accent
    "ocirc"     =>      "\\x99 ",    #   small o, circumflex accent
    "Ograve"    =>      "\\xf1 ",    #   capital O, grave accent
    "ograve"    =>      "\\x98 ",    #   small o, grave accent
    "Oslash"    =>      "\\xaf ",    #   capital O, slash
    "oslash"    =>      "\\xbf ",    #   small o, slash
    "Otilde"    =>      "\\xcd ",    #   capital O, tilde
    "otilde"    =>      "\\x9b ",    #   small o, tilde
    "Ouml"      =>      "\\x85 ",    #   capital O, dieresis or umlaut mark
    "ouml"      =>      "\\x9a ",    #   small o, dieresis or umlaut mark
    "Uacute"    =>      "\\xf2 ",    #   capital U, acute accent
    "uacute"    =>      "\\x9c ",    #   small u, acute accent
    "Ucirc"     =>      "\\xf3 ",    #   capital U, circumflex accent
    "ucirc"     =>      "\\x9e ",    #   small u, circumflex accent
    "Ugrave"    =>      "\\xf4 ",    #   capital U, grave accent
    "ugrave"    =>      "\\x9d ",    #   small u, grave accent
    "Uuml"      =>      "\\x86 ",    #   capital U, dieresis or umlaut mark
    "uuml"      =>      "\\x9f ",    #   small u, dieresis or umlaut mark
    "yuml"      =>      "\\xd8 ",    #   small y, dieresis or umlaut mark
);

# Lookup table of colour values
%_MIF_COLOR = (
    'Black',    'Black',
    'White',    'White',
    'Red',      'Red',
    'Green',    'Green',
    'Blue',     'Blue',
    'Yellow',   'Yellow',
    'Magenta',  'Magenta',
    'Cyan',     'Cyan',
);

# Lookup table of fill values
%_MIF_FILL_CODE = (
    100,    0,
    90,     1,
    70,     2,
    50,     3,
    30,     4,
    10,     5,
    3,      6,
    0,      15,
);

# Lookup table of known index types
%_MIF_INDEX_CODE = (
    "standard",     2,
    "comment",      3,
    "subject",      4,
    "author",       5,
);

# This is the numeric code matching the HardReturn character
$_MIF_HARDRETURN_CODE = 10;

#
# >>_Description::
# {{Y:%_MIF_REF}} maps logical names to MIF reference names.
#
%_MIF_REF = (
    'table',        'ATbl',
    'figure',       'AFrame',
);

# Lookup table of title tags for objects
%_MIF_TITLE_TAG = (
    'table',        'TT',
    'figure',       'FT',
);

# Lookup table of no-title tags for objects
%_MIF_NOTITLE_TAG = (
    'table',        'TA',
    'figure',       'FA',
);

# The text at the end of each paragraph and its length
$_MIF_PARA_END = " >\n> # end of Para";
$_MIF_PARA_END_LEN = length($_MIF_PARA_END);

#
# >>_Description::
# {{Y:%_MIF_DFLT_BOOK_ATTRS}} contains the default set of
# book attributes.
#
%_MIF_DFLT_BOOK_ATTRS = (
    "StartPageSide", "ReadFromFile",
    "PageNumbering", "Continue",
    "PgfNumbering", "Continue",
    "PageNumPrefix", "",
    "PageNumSuffix", "",
    "DefaultPrint", "Yes",
    "DefaultApply", "Yes",
);

# Mapping table for logical variable names to Frame equivalents
%_MIF_VAR_MAP = (
    'Running_H_F_1',    'Running H/F 1',
    'Running_H_F_2',    'Running H/F 2',
    'Running_H_F_3',    'Running H/F 3',
    'Running_H_F_4',    'Running H/F 4',
);

# Set of legal tab types
%_MIF_TAB_TYPE = (
    'Left',         1,
    'Center',       1,
    'Right',        1,
    'Decimal',      1,
);

# Directive mapping table
%_MIF_HANDLER = (
    'tuning',         '_MifHandlerTuning',
    'endtuning',      '_MifHandlerEndTuning',
    'table',            '_MifHandlerTable',
    'row',              '_MifHandlerRow',
    'cell',             '_MifHandlerCell',
    'endtable',         '_MifHandlerEndTable',
    'import',           '_MifHandlerImport',
    'inline',           '_MifHandlerInline',
    'output',           '_MifHandlerOutput',
    'object',           '_MifHandlerObject',
);

# Phrase directive mapping table
%_MIF_PHRASE_HANDLER = (
    'char',             '_MifPhraseHandlerChar',
    'import',           '_MifPhraseHandlerImport',
    'inline',           '_MifPhraseHandlerInline',
    'variable',         '_MifPhraseHandlerVariable',
    'xref',             '_MifPhraseHandlerXRef',
    'pagenum',          '_MifPhraseHandlerPageNum',
    'pagecount',        '_MifPhraseHandlerPageCount',
    'paratext',         '_MifPhraseHandlerParaText',
    'paranum',          '_MifPhraseHandlerParaNum',
    'paranumonly',      '_MifPhraseHandlerParaNumOnly',
    'parashort',        '_MifPhraseHandlerParaShort',
    'paralast',         '_MifPhraseHandlerParaLast',
);

# Table states
$_MIF_INTABLE = 1;
$_MIF_INROW   = 2;
$_MIF_INCELL  = 3;

# Table row suffixes
%_MIF_ROW_SUFFIX = (
    'Heading',  'H',
    'Body',     'Body',
    'Group',    'Body',
    'Footing',  'F',
);

# Parts in a book before numbering starts resetting
%_MIF_FRONT_PART = (
    'front',        1,
    'pretoc',       1,
    'toc',          1,
    'lof',          1,
    'lot',          1,
    'prechapter',   1,
);

##### Variables #####

# Counter to ensure stream processing functions are re-entrant
$_mif_cnt = 0;

# The current template stuff
@_mif_template = ();
%_mif_tpl_vars = ();
%_mif_tpl_xrefs = ();
%_mif_tpl_paras = ();
%_mif_tpl_fonts = ();
%_mif_tpl_tbls = ();
%_mif_tpl_ctrls = ();

# The current variables, cross-references, paragraph/font/table catalogs,
# control settings, reference frames and generated lists
%_mif_vars = ();
%_mif_xrefs = ();
%_mif_paras = ();
%_mif_fonts = ();
%_mif_tbls = ();
%_mif_ctrls = ();
%_mif_frames = ();
%_mif_lists = ();
%_mif_indexes = ();

# Counter of Running H/F variables used
$_mif_runninghf_cnt = 0;

# Style usage counters. We don't bother keeping usage counts for
# font styles because they are small to build and are referenced
# in lots of places (e.g. autonumber fonts).
%_mif_parastyle_used = ();
%_mif_tblstyle_used = ();

# The cover page name and rectangles
$_mif_cover = '';
%_mif_cover_rect = ();

# Buffers for collection of special objects
@_mif_toc_list = ();
@_mif_lof_list = ();
@_mif_lof_list = ();
@_mif_figure = ();
@_mif_table = ();
@_mif_textflows = ();
@_mif_pages = ();
$_mif_bodypage = '';

# Stacks for tables
@_mif_tbl_start = ();
@_mif_tbl_state = ();
@_mif_tbl_wide = ();
@_mif_tbl_id = ();
@_mif_tbl_title = ();
@_mif_tbl_style = ();
@_mif_tbl_landscape = ();

# Type of current row
@_mif_row_type = ();

# Alignment of current table cell
$_mif_cell_align = '';
$_mif_cell_valign = '';

# Margin around current cell (and defaults for current table)
$_mif_cell_lmargin = 0;
$_mif_cell_tmargin = 0;
$_mif_cell_rmargin = 0;
$_mif_cell_bmargin = 0;
$_mif_tbl_lmargin = 0;
$_mif_tbl_tmargin = 0;
$_mif_tbl_rmargin = 0;
$_mif_tbl_bmargin = 0;

#
# >>_Description::
# {{Y:_mif_buffered_fname}} and {{Y:_mif_buffered_file}} contain the
# filename and contents of the last album file fetched.
#
$_mif_buffered_fname = '';
@_mif_buffered_file = ();

# Used to ensure text flows are unique
$_mif_textflow_cnt = $_MIF_TEXTFLOW_START;

# Used to ensure cross-reference targets are unique
$_mif_xref_cnt = $_MIF_TOC_XREF_START;

# Arrays of paragraph attribute information
@_mif_paraattr_name = ();
@_mif_paraattr_full = ();
@_mif_paraattr_type = ();

# Root objects for faster catalog building
$_mif_pararoot_name = '';
%_mif_pararoot_attr = ();
$_mif_fontroot_name = '';
%_mif_fontroot_attr = ();
$_mif_tblroot_name = '';
%_mif_tblroot_attr = ();
$_mif_frameroot_name = '';
%_mif_frameroot_attr = ();
$_mif_listroot_name = '';
%_mif_listroot_attr = ();
$_mif_indexroot_name = '';
%_mif_indexroot_attr = ();

# Stacks of component file offsets and filenames
@_mif_component_offset = ();
@_mif_component_file = ();
@_mif_component_type = ();

# Table of component names and types
@_mif_component_tbl = ();

# Counter for building derived component names
$_mif_component_cntr = 0;

# Cursor in component type array
$_mif_component_cursor= 0;

##### Routines #####

#
# >>Description::
# {{Y:MifFormat}} is an SDF driver which outputs MIF.
#
sub MifFormat {
    local(*data) = @_;
    local(@result);
    local($msg_cursor, %msg_counts);

    # Init global variables/buffers
    $_mif_textflow_cnt = $_MIF_TEXTFLOW_START;
    $_mif_xref_cnt = $_MIF_TOC_XREF_START;
    %_mif_vars = ();
    %_mif_xrefs = ();
    %_mif_paras = ();
    %_mif_fonts = ();
    %_mif_tbls = ();
    %_mif_ctrls = ();
    %_mif_frames = ();
    %_mif_lists = ();
    %_mif_indexes = ();
    $_mif_runninghf_cnt = 0;
    %_mif_parastyle_used = ();
    %_mif_tblstyle_used = ();
    $_mif_cover = '';
    %_mif_cover_rect = ();
    @_mif_toc_list = ();
    @_mif_lof_list = ();
    @_mif_lot_list = ();
    @_mif_figure = ();
    @_mif_table = ();
    @_mif_textflows = ();
    @_mif_pages = ();
    $_mif_bodypage = '';
    @_mif_tbl_start = ();
    @_mif_tbl_wide = ();
    @_mif_tbl_state = ();
    @_mif_tbl_id = ();
    @_mif_tbl_title = ();
    @_mif_tbl_style = ();
    @_mif_tbl_landscape = ();
    @_mif_row_type = ();
    @_mif_component_offset = ();
    @_mif_component_file = ();
    @_mif_component_type = ();
    @_mif_component_tbl = ();
    $_mif_component_cntr = 0;
    $_mif_component_cursor = 0;

    # Initialise things for building a book, if necessary
    if ($SDF_USER'var{'MIF_BOOK_MODE'}) {
        @_mif_component_tbl = ('Part|Type');
    }

    # Get the current message cursor - we skip the finalisation stuff
    # if errors are found
    $msg_cursor = &AppMsgNextIndex();

    # Process the paragraphs
    @result = ();
    &_MifAddSection(*result, *data);

    # Save away any unclosed components
    while (@_mif_component_file) {
        &_MifHandlerOutput(*result, '-');
    }

    # Finalise the output, provided that no errors/aborts/fatals were found
    %msg_counts = &AppMsgCounts($msg_cursor);
    if ($msg_counts{'error'} || $msg_counts{'abort'} || $msg_counts{'fatal'} ) {
        # do nothing
    }
    elsif ($SDF_USER'var{'MIF_BOOK_MODE'}) {
        @_mif_component_tbl = &TableParse(@_mif_component_tbl);
        @result = &_MifBookBuild(*_mif_component_tbl, $SDF_USER'var{'DOC_BASE'});
    }
    else {
        @result = &_MifFinalise(*result);
    }

    # Return result
    return @result;
}

#
# >>_Description::
# {{Y:_MifAddSection}} formats a block of SDF (@data) into MIF and
# adds it to a buffer (@outbuf).
#
sub _MifAddSection {
    local(*outbuf, *data) = @_;
#   local();
    local($prev_tag, %prev_attrs);
    local($para_tag, $para_text, %para_attrs);
    local($directive);

    # Process the paragraphs
    $prev_tag = '';
    %prev_attrs = ();
#print "data: ", join("<\n", @data), "<\n" if $mif_debug;
    while (($para_text, $para_tag, %para_attrs) = &SdfNextPara(*data)) {

        # handle directives
        if ($para_tag =~ /^__(\w+)$/) {
            $directive = $_MIF_HANDLER{$1};
            if (defined &$directive) {
                &$directive(*outbuf, $para_text, %para_attrs);
            }
            else {
                &AppMsg("warning", "ignoring internal directive '$1' in MIF driver");
            }
            next;
        }

        # Add the paragraph
        &_MifParaAdd(*outbuf, $para_tag, $para_text, *para_attrs, $prev_tag,
          *prev_attrs);
    }

    # Do this stuff before starting next loop iteration
    continue {
        $prev_tag = $para_tag;
        %prev_attrs = %para_attrs;
    }
}
       
#
# >>_Description::
# {{Y:_MifEscape}} escapes special characters in a MIF string.
# If {{escape_space}} is true, space characters are also escaped.
#
sub _MifEscape {
    local(*text, $escape_space) = @_;
#   local();
    local($orig_linematch_flag);

    $orig_linematch_flag = $*;
    $* = 1;
    $text =~ s/([\\>])/\\$1/g;
    $text =~ s/\t/\\t/g;
    $text =~ s/'/\\q/g;
    $text =~ s/`/\\Q/g;
    $text =~ s/ /\\ /g if $escape_space;
    $* = $orig_linematch_flag;
}

#
# >>_Description::
# {{Y:_MifFmtMarker}} formats a mif marker.
#
sub _MifFmtMarker {
    local($prefix, $code, $text) = @_;
    local($marker);
    local($rest);

    # For long markers, make each entry a marker until the rest
    # is short enough to fit into one marker
    $marker = '';
    while (length($text) > 255) {
        if ($text =~ /[^\\];/) {
            $rest = $`;
            $text = $';
            &_MifEscape(*rest);
            $marker .=  "$prefix<Marker\n" .
                        "$prefix <MType $code>\n" .
                        "$prefix <MText `$rest'>\n" .
                        "$prefix> # end of Marker\n";
        }
        else {
            # If we reach here, we are unable to split the marker text.
            # Therefore, the best we can do is take the first 255 chars
            # and let the user know. :-(
            $rest = substr($text, 255);
            $text = substr($text, 0, 255);
            &AppMsg("warning", "ignoring marker text - '$rest'");
        }
    }

    # Handle the simple case
    &_MifEscape(*text);
    $marker .=  "$prefix<Marker\n" .
                "$prefix <MType $code>\n" .
                "$prefix <MText `$text'>\n" .
                "$prefix> # end of Marker\n";
    return $marker;
}
       
#
# >>_Description::
# {{Y:_MifParaAdd}} adds a paragraph.
#
sub _MifParaAdd {
    local(*result, $para_tag, $para_text, *para_attrs, $prev_tag, *prev_attrs) = @_;
#   local();
    local($is_example, $para_fmt);
    local($para_override);
    local($para);
    local($hdg_level);
    local($id, $hlpinfo);
    local($index, $index_code);

    # Get the example flag
    $is_example = $SDF_USER'parastyles_category{$para_tag} eq 'example';

    # After headings, use a FIRST tag instead of a normal tag
    if ($prev_tag =~ /^[HAP]\d$/ && $para_tag eq 'N' &&
      $SDF_USER'parastyles_to{'FIRST'} ne '') {
        $para_tag = 'FIRST';
    }

    # Get the Frame format name
    $para_fmt = $SDF_USER'parastyles_to{$para_tag};
    $para_fmt = $para_tag if $para_fmt eq '';
    $para_fmt .= 'NoTOC' if $para_attrs{'notoc'};
    $_mif_parastyle_used{$para_fmt}++;

    # Inherit the alignment and margins from the table cell, if applicable
    if (@_mif_tbl_state) {
        if ($_mif_cell_align ne $para_attrs{'align'}) {
            $para_attrs{'align'} = $_mif_cell_align;
        }
        if ($_mif_cell_valign ne '') {
            $para_attrs{'mif.CellAlignment'} = $_mif_cell_valign;
        }
        # Get the cell margins, if necessary
        if ($_mif_cell_lmargin  ne '' || $_mif_cell_tmargin ne '' ||
            $_mif_cell_rmargin  ne '' || $_mif_cell_bmargin ne '') {
            $_mif_cell_lmargin = $_mif_tbl_lmargin if $_mif_cell_lmargin eq '';
            $_mif_cell_tmargin = $_mif_tbl_tmargin if $_mif_cell_tmargin eq '';
            $_mif_cell_rmargin = $_mif_tbl_rmargin if $_mif_cell_rmargin eq '';
            $_mif_cell_bmargin = $_mif_tbl_bmargin if $_mif_cell_bmargin eq '';
            $para_attrs{'mif.CellMargins'} =
              "${_mif_cell_lmargin}pt ${_mif_cell_tmargin}pt " .
              "${_mif_cell_rmargin}pt ${_mif_cell_bmargin}pt";
            $para_attrs{'mif.CellLMarginFixed'} = 1;
            $para_attrs{'mif.CellTMarginFixed'} = 1;
            $para_attrs{'mif.CellRMarginFixed'} = 1;
            $para_attrs{'mif.CellBMarginFixed'} = 1;
        }
    }

    # Get the format overrides
    &SdfAttrMap(*para_attrs, 'mif', *SDF_USER'paraattrs_to,
      *SDF_USER'paraattrs_map, *SDF_USER'paraattrs_attrs,
      $SDF_USER'parastyles_attrs{$para_tag});
    $para_override = &_MifParaSdfAttr(*para_attrs, "  ");

    # Build the paragraph header
    $para  = "<Para\n" .
         " <PgfTag `$para_fmt'>\n";
    if ($para_override ne '') {
        $para .= " <Pgf\n$para_override >\n";
    }
    $para .= " <ParaLine\n";

    # Build a hypertext marker, if necessary
    if ($para_attrs{"id"}) {
        $id = &_MifEscapeNewlink($para_attrs{"id"});
        # We need this one for hypertext
        $para .= "  <Marker\n" .
             "   <MType 8>\n" .
             "   <MText `newlink $id'>\n" .
             "  > # end of Marker\n";
        # And we need this one for cross-references
        $para .= "  <Marker\n" .
             "   <MType 9>\n" .
             "   <MText `$id'>\n" .
             "  > # end of Marker\n";
        # And this one is for short text within a header/footer
        if ($para_attrs{"short"}) {
            $id = &_MifEscapeNewlink($para_attrs{"short"});
            $para .= "  <Marker\n" .
                 "   <MType 0>\n" .
                 "   <MText `$id'>\n" .
                 "  > # end of Marker\n";
        }
        $id = '';
    }
    for $hlpinfo ('context', 'header', 'topic', 'window', 'endwindow') {
        $id = $para_attrs{"hlp.$hlpinfo"};
        $id = &_MifEscapeNewlink($id);
        if ($id ne '') {
            $para .= "  <Marker\n" .
                 "   <MType 8>\n" .
                 "   <MText `sdf $hlpinfo=$id'>\n" .
                 "  > # end of Marker\n";
        }
    }

    # If this paragraph is in a generated list, add a cross reference,
    # unless we're in book mode
    unless ($SDF_USER'var{'MIF_BOOK_MODE'}) {
        if ($para_tag =~ /^[HAP](\d)$/) {
            $hdg_level = $1;
            if ($hdg_level <= $SDF_USER'var{'DOC_TOC'} &&
              !$para_attrs{'notoc'}) {
                &_MifAddListXref(*para, $para_fmt, *_mif_toc_list, 'TOC');
            }
        }
        elsif ($para_tag eq 'FT') {
            &_MifAddListXref(*para, $para_fmt, *_mif_lof_list, 'LOF');
        }
        elsif ($para_tag eq 'TT') {
            &_MifAddListXref(*para, $para_fmt, *_mif_lot_list, 'LOT');
        }
    }

    # Process index-related attributes
    $index = $para_attrs{"index"};
    if ($index) {
        $index_code = $para_attrs{"index_type"};
        if ($index_code eq '') {
            $index_code = 2;
        }
        elsif ($_MIF_INDEX_CODE{$index_code}) {
            $index_code = $_MIF_INDEX_CODE{$index_code};
        }
        elsif ($index_code !~ /^\d+/) {
            &AppMsg("warning", "unknown index type '$index_code' - assuming standard");
            $index_code = 2;
        }
        $para .= &_MifFmtMarker("  ", $index_code, $index);
    }

    # Indent examples, if necessary
    if ($is_example && $para_attrs{'in'}) {
        $para_text = " " x ($para_attrs{'in'} * 4) . $para_text;
        delete $para_attrs{'in'};
    }

    # Add the paragraph body
    if ($para_attrs{'verbatim'}) {
        delete $para_attrs{'verbatim'};
        &_MifEscape(*para_text, $is_example);
        $para .= "  <String `$para_text'>\n";
    }
    else {
        $para .= &_MifParaText($para_text, $is_example);
    }

    # Build result
    if ($is_example && $para_tag eq $prev_tag &&
      join('', %para_attrs) eq join('', %prev_attrs)) {
        &_MifParaAppend(*result, $para);
    }
    else {
        push(@result, $para . $_MIF_PARA_END);
    }
}

#
# >>_Description::
# {{Y:_MifAddListXref}} adds a paragraph to a generated list.
#
sub _MifAddListXref {
    local(*para, $para_fmt, *list, $list_type) = @_;
#   local();

    # Add the xref destination marker
    $para .=
         "  <Marker\n" .
         "   <MType 9>\n" .
         "   <MText `$_mif_xref_cnt'>\n" .
         "  > # end of Marker\n";

    # And a special marker for HLP format
    $para .= "  <Marker\n" .
         "   <MType 11>\n" .
         "   <MText `$_mif_xref_cnt'>\n" .
         "  > # end of Marker\n";

    # Add the xref to the global list
    $_mif_parastyle_used{"$para_fmt$list_type"}++;
    push(@list,
        "<Para\n" .
        " <PgfTag `$para_fmt$list_type'>\n" .
        " <ParaLine\n" .
        "  <XRef\n" .
        "   <XRefName `$list_type'>\n" .
        "   <XRefSrcText `$_mif_xref_cnt'>\n" .
        "  > # end of XRef\n" .
        " >\n" .
        "> # end of Para");

    # Update the global xref counter (which makes xref unique)
    $_mif_xref_cnt++;
}
       
#
# >>_Description::
# {{Y:_MifInitTemplate}} initialises the global template variables.
#
sub _MifInitTemplate {
#   local() = @_;
#   local();

    @_mif_template = ();
    %_mif_tpl_paras = ();
    %_mif_tpl_fonts = ();
    %_mif_tpl_vars = ();
    %_mif_tpl_xrefs = ();
    %_mif_tpl_tbls = ();
    %_mif_tpl_ctrls = ();
}
       
#
# >>_Description::
# {{Y:_MifFetchTemplate}} loads a MIF template.
# The following global variables are updated:
#
# * @_mif_template - each element contains one and only one main MIF object
# * %_mif_tpl_vars - the set of variables
# * %_mif_tpl_xrefs - the set of cross references
# * %_mif_tpl_paras - the paragraph catalog
# * %_mif_tpl_fonts - the font catalog
# * %_mif_tpl_tbls - the table catalog (soon)
# * %_mif_tpl_ctrls - the document control settings
#
sub _MifFetchTemplate {
    local($template_file) = @_;
    local($ok);
    local($strm, @rec);

    # Open the input stream
    $strm = sprintf("mif_s%d", $_mif_cnt++);
    open($strm, $template_file) || return 0;

    # Read the data. Objects taking a whole line get a record to
    # themselves. A slight variation of this is needed to cover the
    #  opening <MIFFile n> line as it often has a trailing comment.
    #. Otherwise, we use a > at the start of a line to detect
    # the end of objects.
    line:
    while (<$strm>) {
        next line if /^#/;
        chop;
        if (/^\<.*\>$/ || /^\<.*\>\s*\#/) {
            push(@_mif_template, $_);
        }
        else {
            push(@rec, $_); 
            if (/^\>/) {
                $text = join("\n", @rec);
                push(@_mif_template, $text);
                if ($rec[0] =~ /^\<VariableFormats/) {
                    %_mif_tpl_vars = &_MifVarsFromText(*rec);
                }
                elsif ($rec[0] =~ /^\<XRefFormats/) {
                    %_mif_tpl_xrefs = &_MifXRefsFromText(*rec);
                }
                elsif ($rec[0] =~ /^\<PgfCatalog/) {
$igc_start = time;
                    %_mif_tpl_paras = &_MifParasFromText(*rec);
#printf STDERR "para->text: %d seconds\n", time - $igc_start;
                }
                elsif ($rec[0] =~ /^\<FontCatalog/) {
                    %_mif_tpl_fonts = &_MifFontsFromText(*rec);
                }
                elsif ($rec[0] =~ /^\<TblCatalog/) {
                    %_mif_tpl_tbls = &_MifTblsFromText(*rec);
                }
                elsif ($rec[0] =~ /^\<Document/) {
                    %_mif_tpl_ctrls = &_MifCtrlsFromText(*rec);
                }
                @rec = ();
            }
        }
    }
    close($strm);
    
    # Return result
    return 1;
}       

#
# >>_Description::
# {{Y:_MifFetchAlbum}} handles fetching of album files.
#
sub _MifFetchAlbum {
    local($fname) = @_;
    local($ok, @file);
    local($strm);

    # Check if the file is buffered
    if ($fname eq $_mif_buffered_fname) {
        return (1, @_mif_buffered_file);
    }

    # Fetch the file
    $strm = sprintf("mif_s%d", $_mif_cnt++);
    $ok = open($strm, $fname);
    if ($ok) {
        @file = <$strm>;
        chop(@file);
        close($strm);
    }

    # Buffer the file
    $_mif_buffered_fname = $fname;
    @_mif_buffered_file = @file;

    # Return result
    return ($ok, @file);
}

#
# >>_Description::
# {{Y:_MifVarsFromText}} converts text records (@recs)
# that represent variable declarations in a MIF file to
# a set of name value pairs.
#
sub _MifVarsFromText {
    local(*recs) = @_;
    local(%vars);
    local($line);
    local($name, $value);

    for $line (@recs) {
        if ($line =~ /VariableName\s+`(.+)'\>/) {
            $name = $1;
        }
        elsif ($line =~ /VariableDef\s+`(.+)'\>/) {
            $value = $1;
            $value =~ s/\\q/'/g;
            $value =~ s/\\Q/`/g;
            $value =~ s/\\t/\t/g;
            $value =~ s/\\([\\\>])/$1/g;
            $vars{$name} = $value;
        }
    }

    # Return result
    return %vars;
}

#
# >>_Description::
# {{Y:_MifVarsToText}} converts {{%vars}} to the text string
# that represents those declarations in a MIF file.
#
sub _MifVarsToText {
    local(*vars) = @_;
    local($text);
    local($var, $value);

    # Build the result
    $text = "<VariableFormats\n";
    for $var (sort keys %vars) {
        # Escape special characters in the value
        $value = $vars{$var};
        &_MifEscape(*value);

        # Add this variable
        $text .= " <VariableFormat\n" .
             "  <VariableName `$var'>\n" .
             "  <VariableDef `$value'>\n" .
             " > # end of VariableFormat\n";
    }
    $text .= "> # end of VariableFormats";

    # Return result
    return $text;
}

#
# >>_Description::
# {{Y:_MifXRefsFromText}} converts text records (@recs)
# that represent cross-reference declarations in a MIF file to
# a set of name value pairs.
#
sub _MifXRefsFromText {
    local(*recs) = @_;
    local(%xrefs);
    local($line);
    local($name, $value);

    for $line (@recs) {
        if ($line =~ /XRefName\s+`(.+)'\>/) {
            $name = $1;
        }
        elsif ($line =~ /XRefDef\s+`(.+)'\>/) {
            $value = $1;
            $xrefs{$name} = $value;
        }
    }

    # Return result
    return %xrefs;
}

#
# >>_Description::
# {{Y:_MifXRefsToText}} converts {{%xrefs}} to the text string
# that represents those declarations in a MIF file.
#
sub _MifXRefsToText {
    local(*xrefs) = @_;
    local($text);
    local($xref, $value);

    # Build the result
    $text = "<XRefFormats\n";
    for $xref (sort keys %xrefs) {
        $value = $xrefs{$xref};

        # Add this definition
        $text .= " <XRefFormat\n" .
             "  <XRefName `$xref'>\n" .
             "  <XRefDef `$value'>\n" .
             " > # end of XRefFormat\n";
    }
    $text .= "> # end of XRefFormats";

    # Return result
    return $text;
}

#
# >>_Description::
# {{Y:_MifParasFromText}} converts text records (@recs) that represent
# paragraph definitions in a MIF file to a set of name value pairs.
# Use {{Y:_MifAttrSplit}} and {{Y:_MifAttrSplit}} to convert
# the value to and from an associative array.
#
sub _MifParasFromText {
    local(*recs) = @_;
    local(%result);
    local($line);
    local($name, %values);
    local($in_font, $in_tabstop, %tab, $tab);
    local($atname, $atvalue);

    $in_font = 0;
    $in_tabstop = 0;
    for $line (@recs) {
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        if ($line =~ /^\<PgfTag\s+`(.+)'\>$/) {
            $name = $1;
            %values = ();
        }
        elsif ($line =~ /^\<(\w+)\s+(.+)\>$/) {
            $atname = $1;
            $atvalue = &_MifAttrToText($2);
            if ($in_tabstop) {
                $tab{$atname} = $atvalue;
            }
            elsif($in_font) {
                $values{'Font' . substr($atname, 1)} = $atvalue;
            }
            else {
                $atname =~ s/^Pgf//;
                $values{$atname} = $atvalue;
            }
        }
        elsif ($line =~ /^\> # end of Pgf$/) {
            # Finalise the set of attributes
            delete $values{'FontTag'};
            delete $values{'FontPostScriptName'};
            delete $values{'NumTabs'};
            $values{'TabStop'} = '' unless defined($values{'TabStop'});

            # Store the attributes for this paragraph format
            $result{$name} = &_MifAttrJoin(*values);
        }
        elsif ($line =~ /^<PgfFont$/) {
            $in_font = 1;
        }
        elsif ($line =~ /^\> # end of PgfFont$/) {
            $in_font = 0;
        }
        elsif ($line =~ /^<TabStop$/) {
            $in_tabstop = 1;
            %tab = ();
        }
        elsif ($line =~ /^\> # end of TabStop$/) {
            $in_tabstop = 0;
            $tab{'TSType'}      = '' if $tab{'TSType'} eq 'Left';
            $tab{'TSLeaderStr'} = '' if $tab{'TSLeaderStr'} eq ' ';
            $tab = join('/', @tab{'TSX', 'TSType', 'TSLeaderStr'});
            $tab =~ s/\/+$//;
            if (defined($values{'TabStop'})) {
                $values{'TabStop'} .= "," . $tab;
                next;
            }
            $values{'TabStop'} = $tab;
        }
    }

    # Return result
    return %result;
}

#
# >>_Description::
# {{Y:_MifParasToText}} converts {{%paras}} to the text string
# that represents those declarations in a MIF file.
#
sub _MifParasToText {
    local(*paras) = @_;
    local($text);
    local(@styles);
    local($name, %attr);

    # Build the attribute information arrays
    &_MifBuildAttrInfo();

    # Decide on the styles to output
    @styles = $SDF_USER'var{'MIF_ALL_STYLES'} ? sort keys %paras :
                sort keys %_mif_parastyle_used;

    # Build the result
    $text = "<PgfCatalog\n";
    for $name (@styles) {
        %attr = &_MifAttrSplit($paras{$name});

        # If this paragraph is not defined, don't output an entry for it
        next unless %attr;

        # Add this paragraph
        # (join is used in preference to . for performance)
        $text .= join('',
             " <Pgf \n",
             "  <PgfTag `$name'>\n",
             &_MifParaMifAttr(*attr, '  '),
             " > # end of Pgf\n");
    }
    $text .= "> # end of PgfCatalog";

    # Return result
    return $text;
}

#
# >>_Description::
# {{Y:_MifFontsFromText}} converts text records (@recs) that represent
# font definitions in a MIF file to a set of name value pairs.
# Use {{Y:_MifAttrJoin}} and {{Y:_MifAttrSplit}} to convert
# the value to and from an associative array.
#
sub _MifFontsFromText {
    local(*recs) = @_;
    local(%result);
    local($line);
    local($name, %values);

    for $line (@recs) {
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        if ($line =~ /^<FTag\s+`(.+)'\>$/) {
            $name = $1;
            %values = ();
        }
        elsif ($line =~ /^<F(\w+)\s+(.+)\>$/) {
            $values{$1} = &_MifAttrToText($2);
        }
        elsif ($line =~ /^\> # end of Font$/) {
            delete $values{'PostScriptName'};
            $result{$name} = &_MifAttrJoin(*values);
        }
    }

    # Return result
    return %result;
}

#
# >>_Description::
# {{Y:_MifFontsToText}} converts {{%fonts}} to the text string
# that represents those declarations in a MIF file.
#
sub _MifFontsToText {
    local(*fonts) = @_;
    local($text);
    local($name, %attr);

    # Build the result
    $text = "<FontCatalog\n";
    for $name (sort keys %fonts) {
        %attr = &_MifAttrSplit($fonts{$name});

        # Add this font
        $text .= &_MifFontFormat($name, ' ', %attr);
    }
    $text .= "> # end of FontCatalog";

    # Return result
    return $text;
}

#
# >>_Description::
# {{Y:_MifTblsFromText}} converts text records (@recs) that represent
# table format definitions in a MIF file to a set of name value pairs.
# Use {{Y:_MifAttrJoin}} and {{Y:_MifAttrSplit}} to convert
# the value to and from an associative array.
#
sub _MifTblsFromText {
    local(*recs) = @_;
    local(%result);
    local($line);
    local($name, %values);

    for $line (@recs) {
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        if ($line =~ /^<TblTag\s+`(.+)'\>$/) {
            $name = $1;
            %values = ();
            $nested = 0;
        }
        elsif ($line =~ /^<Tbl(\w+)\s+(.+)\>$/) {
            $values{$1} = &_MifAttrToText($2) unless $nested;
        }
        elsif ($line =~ /^<Tbl(Column|TitlePgf1)$/) {
            $nested = 1;
        }
        elsif ($line =~ /^\> # end of Tbl(Column|TitlePgf1)$/) {
            $nested = 0;
        }
        elsif ($line =~ /^\> # end of TblFormat$/) {
            $result{$name} = &_MifAttrJoin(*values);
        }
    }

    # Return result
    return %result;
}

#
# >>_Description::
# {{Y:_MifTblsToText}} converts {{%tbls}} to the text string
# that represents those declarations in a MIF file.
#
sub _MifTblsToText {
    local(*tbls) = @_;
    local($text);
    local(@styles);
    local($name, %attr);

    # Decide on the styles to output
    @styles = $SDF_USER'var{'MIF_ALL_STYLES'} ? sort keys %tbls :
                sort keys %_mif_tblstyle_used;

    # Build the result
    $text = "<TblCatalog\n";
    for $name (@styles) {
        %attr = &_MifAttrSplit($tbls{$name});

        # Add this table format
        $text .= &_MifTblFormat($name, ' ', *attr);
    }
    $text .= "> # end of TblCatalog";

    # Return result
    return $text;
}

#
# >>_Description::
# {{Y:_MifTblFormat}} formats a table format name and
# set of attributes (%attr) into MIF.
# {{prefix}} is a string of spaces to put at the front of each line.
#
sub _MifTblFormat {
    local($name, $prefix, *attr) = @_;
#   local($result);
    local(@text);
    local($id, $type, $value);

    # Build the header
    @text = ("$prefix<TblFormat ", " <TblTag `$name'>");

    # Add the attributes
    for $id (sort keys %attr) {
        $type = $SDF_USER'tableparams_type{"mif.$id"};
        $value = &_MifAttrFromText($attr{$id}, $type);
        push(@text, " <Tbl$id $value>");
    }

    # Add a dummy table column
    push(@text,
        " <TblColumn",
        "  <TblColumnNum 0>",
        "  <TblColumnWidth 72pt>",
        "  <TblColumnH",
        "   <PgfTag `Cell'>",
        "  > # end of TblColumnH",
        "  <TblColumnBody",
        "   <PgfTag `Cell'>",
        "  > # end of TblColumnBody",
        "  <TblColumnF",
        "   <PgfTag `Cell'>",
        "  > # end of TblColumnF",
        " > # end of TblColumn");

    # Add the footer
    push(@text, "> # end of TblFormat\n");

    # Return result
    return join("\n$prefix", @text);
}

#
# >>_Description::
# {{Y:_MifCtrlsFromText}} converts text records (@recs) that represent
# document contorl settings in a MIF file to a set of name value pairs.
#
sub _MifCtrlsFromText {
    local(*recs) = @_;
    local(%result);
    local($line);

    for $line (@recs) {
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        if ($line =~ /^<(\w+)\s+(.+)\>$/) {
            $result{$1} = &_MifAttrToText($2);
        }
    }

    # Return result
    return %result;
}

#
# >>_Description::
# {{Y:_MifCtrlsToText}} converts {{%ctrls}} to the text string
# that represents those settings in a MIF file.
#
sub _MifCtrlsToText {
    local(*ctrls) = @_;
    local($text);
    local($name, $var_name, $type, $value);

    # Build the result
    $text = "<Document\n";
    for $name (sort keys %ctrls) {

        # Get the matching variable name and type
        $var_name = "MIF_" . &MiscMixedToUpper(substr($name, 1));
        $type = $SDF_USER'variables_type{$var_name};

        # format the value
        $value = &_MifAttrFromText($ctrls{$name}, $type);

        # build the result
        $text .= " <$name $value>\n";
    }
    $text .= "> # end of Document";

    # Return result
    return $text;
}

#
# >>_Description::
# {{Y:_MifAttrSplit}} split a string of attributes into an associative array.
# The string format is a null-separated list of "name=value" strings.
#
sub _MifAttrSplit {
    local($str) = @_;
    local(%attr);
    local($nv);

    for $nv (split(/\000/, $str)) {
        $nv =~ /\=/;
        $attr{$`} = $';
    }

    # Return result
    %attr;
}

#
# >>_Description::
# {{Y:_MifAttrJoin}} joins an associative array into a string of attributes.
# (A "reference" to the array is passed for performance.)
# The string format is a null-separated list of "name=value" strings.
#
sub _MifAttrJoin {
    local(*attr) = @_;
    local($str);
    local($name, $value);

    # Build the string
    $str .= "$name=$value\000" while ($name, $value) = each %attr;

    # Return result
    $str;
}

#
# >>_Description::
# {{Y:_MifAttrToText}} formats a MIF attribute into text.
# As this routine can have a major impact on performance,
# the implementation favors performance over readability.
#
sub _MifAttrToText {
    local($mif) = @_;
#   local($text);

    # Trim leading/trailing whitespace
    $mif =~ s/^\s+//;
    $mif =~ s/\s+$//;

    # Convert boolean values to numeric
    $mif = 0 if $mif eq 'No';

    # Trim surrounding quotes, if any
    $mif =~ s/^\`(.*)\'$/$1/;

    # Return result
    $mif;
}

#
# >>_Description::
# {{Y:_MifAttrFromText}} formats an attribute into MIF.
# {{type}} can be one of the following:
#
# * {{boolean}} - output is Yes or No
# * {{string}} - output is `data'
# * {{tabstop}} - output is a tabstop record
# * {{keyword}} - output has a trailing space (matches MIF conventions)
#
# Other types return the value as it is. If the type is unknown:
#
# * 0 is converted to No
# * other values are returned as is.
#
# This algorithm minimises the problems associated with unknown attributes.
#
# As this routine can have a major impact on performance,
# the implementation favors performance over readability.
#
sub _MifAttrFromText {
    local($value, $type) = @_;
#   local($text);

    # Handle special cases
    return $value ? 'Yes ' : 'No '  if $type =~ /^b/;   # boolean
    return "`$value'"               if $type =~ /^s/;   # string
    return "$value "                if $type =~ /^k/;   # keyword
    return &_MifTabFromText($value) if $type =~ /^t/;   # tabstop
    return $value                   if $type =~ /^\w/;  # other

    # Otherwise, return the value as is, or No
    return $value eq '0' ? 'No ' : $value;
}

#
# >>_Description::
# {{Y:_MifTabFromText}} formats a tabstop attribute into MIF.
#
sub _MifTabFromText {
    local($value) = @_;
    local($text);
    local(@tabs, $tab, $tsx, $tstype, $tsleader);

    @tabs = split(/\s*,\s*/, $value);
    $text = '';
    for $tab (@tabs) {
        $text .= ">\n  <TabStop " if $text;
        ($tsx, $tstype, $tsleader) = split(/\//, $tab, 3);
        if ($tstype) {
            unless ($_MIF_TAB_TYPE{$tstype}) {
                &AppMsg("warning", "tab type '$tstype' not in (Left,Center,Right,Decimal)");
            }
        }
        else {
            $tstype = 'Left';
        }
        $tsleader = ' ' if $tsleader eq '';
        $text .= "<TSX $tsx>";
        $text .= "<TSType $tstype>";
        $text .= "<TSLeaderStr `$tsleader'>";
        if ($tstype eq 'Decimal') {
            $text .= "<TSDecimalChar `.'>";
        }
    }

    # Return result
    return $text;
}

#
# >>_Description::
# {{Y:_MifParaSdfAttr}} formats a set of SDF paragraph attributes into MIF.
# {{prefix}} is a string of spaces to put at the front of each line.
#
sub _MifParaSdfAttr {
    local(*attrs, $prefix) = @_;
    local($mif);
    local($attr, $value, $type, $fm_prefix, $font);

    for $attr (sort keys %attrs) {

        # get the attribute value & type
        $value = $attrs{$attr};
        $type = $SDF_USER'paraattrs_type{$attr};

        # Get the Frame prefix
        $fm_prefix = $SDF_USER'phraseattrs_name{$attr} ? 'F' : 'Pgf';

        # Check it's a Frame attribute 
        next unless $attr =~ s/^mif\.//;

        # Map to the MIF name
        $attr = "$fm_prefix$attr" unless
          ($attr =~ /^HyphenM/ || $attr eq 'TabStop');

        # format the value
        $value = &_MifAttrFromText($value, $type);

        # build the result, separating the font attributes for now
        if ($fm_prefix eq 'F') {
             $font .= "$prefix <$attr $value>\n";
        }
        else {
            $mif .= "$prefix<$attr $value>\n";
        }
    }

    # Combine normal and font attributes
    $mif .= "$prefix<PgfFont\n$prefix <FTag `'>\n$font$prefix>\n" if $font;

    # Return result
    $mif;
}

#
# >>_Description::
# {{Y:_MifBuildAttrInfo}} builds the table of paragraph attribute
# information. Each record contains the the attribute name & type,
# separated by a NULL character.
#
sub _MifBuildAttrInfo {
#   local() = @_;
#   local();
    local($name, $short_name, $new_name);

    # If the work has already been done, don't bother doing it again
    return if @_mif_paraattr_name;

    # Add the attribute information
    for $name (sort keys %SDF_USER'paraattrs_type) {
        next unless $name =~ /^mif\./;

        # Skip attributes we don't weant to output
        next if $name eq 'mif.NumTabs';
        next if $name eq 'mif.component';

        # Convert the name
        $short_name = $name;
        $short_name =~ s/^mif\.//;
        if ($short_name =~ /^Font/) {
            $new_name = "F" . $';
        }
        elsif ($short_name =~ /^HyphenM|^TabS/) {
            $new_name = $short_name;
        }
        else {
            $new_name = "Pgf" . $short_name;
        }

        # Store the information
        push(@_mif_paraattr_name, $short_name);
        push(@_mif_paraattr_full, $new_name);
        push(@_mif_paraattr_type, $SDF_USER'paraattrs_type{$name});
    }
}

#
# >>_Description::
# {{Y:_MifParaMifAttr}} formats a set of MIF paragraph attributes into MIF.
# {{prefix}} is a string of spaces to put at the front of each line.
#
sub _MifParaMifAttr {
    local(*attrs, $prefix) = @_;
    local($mif);
    local($i, $attr, $value, $fullname, $type, $font);

    # This routine has a big impact on performance, so we
    # get the list of names from a prebuilt array, rather than by
    # sorting the keys of %attrs. Likewise, the fullname and type
    # come from prebuilt arrays, rather than from assocative arrays
    # indexed on attribute name, to improve performance.
    for ($i = 0; $i <= $#_mif_paraattr_name; $i++) {

        # get the attribute information
        $attr     = $_mif_paraattr_name[$i];
        $fullname = $_mif_paraattr_full[$i];
        $type     = $_mif_paraattr_type[$i];

        # format the value
        $value = &_MifAttrFromText($attrs{$attr}, $type);

        # build the result, separating the font attributes for now
        # and ignoring empty tab stops
        ## Note that we explicitly test for the most common case first
        ## in order to improve performance.
        #if ($fullname =~ /^P/) {
        #    $mif .= "$prefix<$fullname $value>\n";
        #}
        #elsif ($fullname =~ /^F/) {
        if ($fullname =~ /^F/) {
             $font .= "$prefix <$fullname $value>\n";
        }
        elsif ($fullname =~ /^T/ && $value eq '') {
            next;
        }
        else {
            $mif .= "$prefix<$fullname $value>\n";
        }
    }

    # Combine normal and font attributes
    $mif .= "$prefix<PgfFont\n$prefix <FTag `'>\n$font$prefix>\n" if $font;

    # Return result
    $mif;
}

#
# >>_Description::
# {{Y:_MifFontFormat}} formats a MIF font specification from a
# tag and set of MIF attributes.
#
sub _MifFontFormat {
    local($tag, $prefix, %attr) = @_;
    local($mif);
    local($attr);
    local($short_name);
    local($type, $value);

    # Init things
    $mif = "$prefix<Font\n" .
           "$prefix <FTag `$tag'>\n";

    # Process the attributes
    for $attr (sort keys %attr) {

        # Get the short name
        $short_name = $attr;
        $short_name =~ s/^mif\.//;

        # get the attribute type and value
        $type = $SDF_USER'phraseattrs_type{"mif.$short_name"};
        $value = $attr{$attr};

        # For MIF font definitions, an empty value implies "as-is"
        # and as-is attributes are not including in the definition
        next if $value eq '';

        # format the value
        $value = &_MifAttrFromText($value, $type);

        # build the result
        $mif .= "$prefix <F$attr $value>\n";
    }
    $mif .= "$prefix>\n";

    # Return result
    return $mif;
}

#
# >>_Description::
# {{Y:_MifCharFont}} formats a MIF font specification from a
# tag and set of SDF attributes.
#
sub _MifCharFont {
    local($tag, $prefix, %attr) = @_;
    local($mif);
    local($attr);
    local($type, $value);

    # Init things
    $mif = "$prefix<Font\n" .
           "$prefix <FTag `$tag'>\n";

    # Process the attributes
    for $attr (sort keys %attr) {

        # get the attribute type and value
        $type = $SDF_USER'phraseattrs_type{$attr};
        $value = $attr{$attr};

        # Check it's a Frame attribute and map it to a MIF name
        next unless $attr =~ s/^mif\./F/;

        # format the value
        $value = &_MifAttrFromText($value, $type);

        # build the result
        $mif .= "$prefix <$attr $value>\n";
    }
    $mif .= "$prefix>\n";

    # Return result
    return $mif;
}

#
# >>_Description::
# {{Y:_MifParaText}} converts SDF text into MIF "paragraph lines".
# 
sub _MifParaText {
    local($para_text, $is_example) = @_;
    local($para);
    local($state);
    local($sect_type, $char_tag, $text, %sect_attrs);
    local(@char_fonts);
    local($char_font, $id, $index, $index_code);
    local($directive);

    # Handle blank lines
    $para_text = " " if $para_text eq '';

    # Process the text
    $para = '';
    while (($sect_type, $text, $char_tag, %sect_attrs) =
      &SdfNextSection(*para_text, *state)) {

        # Escape any special characters
        if ($sect_type eq 'phrase') {
            ($text) = &SDF_USER'ExpandLink($text) if $char_tag eq 'L';
            &_MifEscape(*text, $is_example);
        }
        elsif ($sect_type eq 'string') {
            &_MifEscape(*text, $is_example);
        }

        # Build the paragraph
        if ($sect_type eq 'string') {
            # Convert hyphens to hard-hyphens, if in a phrase
            $text =~ s/\-/\\x15 /g if @char_fonts;

            $para .= "  <String `$text'>\n";
        }

        elsif ($sect_type eq 'phrase') {

            # Process formatting attributes
            &SdfAttrMap(*sect_attrs, 'mif', *SDF_USER'phraseattrs_to,
              *SDF_USER'phraseattrs_map, *SDF_USER'phraseattrs_attrs,
              $SDF_USER'phrasestyles_attrs{$char_tag});
            $char_font = &_MifCharFont($SDF_USER'phrasestyles_to{$char_tag}, "  ",
              %sect_attrs);
            push(@char_fonts, $char_font);
            $para .= $char_font;

            # Process hypertext-related attributes
            $id = &_MifEscapeNewlink($sect_attrs{"id"});
            if ($id) {
                # We need this one for hypertext
                $para .= "  <Marker\n" .
                    "   <MType 8>\n" .
                    "   <MText `newlink $id'>\n" .
                    "  > # end of Marker\n";
                # And we need this one for cross-references
                $para .= "  <Marker\n" .
                    "   <MType 9>\n" .
                    "   <MText `$id'>\n" .
                    "  > # end of Marker\n";
            }
            &_MifAddLink(*para, $sect_attrs{'jump'});
            $id = &_MifEscapeNewlink($sect_attrs{"hlp.popup"});
            if ($id ne '') {
                $para .= "  <Marker\n" .
                     "   <MType 8>\n" .
                     "   <MText `sdf popup=$id'>\n" .
                     "  > # end of Marker\n";
            }

            # Process index-related attributes
            $index = $sect_attrs{"index"};
            if ($index) {
                $index_code = $sect_attrs{"index_type"};
                if ($index_code eq '') {
                    $index_code = 2;
                }
                elsif ($_MIF_INDEX_CODE{$index_code}) {
                    $index_code = $_MIF_INDEX_CODE{$index_code};
                }
                elsif ($index_code !~ /^\d+/) {
                    &AppMsg("warning", "unknown index type '$index_code' - assuming standard");
                    $index_code = 2;
                }
                $para .= &_MifFmtMarker("  ", $index_code, $index);
            }

            # Convert hyphens to hard-hyphens
            $text =~ s/\-/\\x15 /g;

            # Convert spaces to non-breaking spaces, if necessary
            $text =~ s/ /\\x11 /g if $char_tag eq 'S';

            # Add the text for this phrase
            $para .= "  <String `$text'>\n";
        }

        elsif ($sect_type eq 'phrase_end') {
            pop(@char_fonts);
            $char_font = $char_fonts[$#char_fonts];
            $para .= $char_font ne '' ? $char_font :
			  "  <Font\n   <FTag `'>\n  > # end of Font\n";
        }

        elsif ($sect_type eq 'special') {
            $directive = $_MIF_PHRASE_HANDLER{$char_tag};
            if (defined &$directive) {
                &$directive(*para, $text, %sect_attrs);
            }
            else {
                &AppMsg("warning", "ignoring special phrase '$1' in MIF driver");
            }
        }
    }

    # Return result
    return $para;
}

#
# >>_Description::
# {{Y:_MifAddLink}} adds link information for a paragraph.
#
sub _MifAddLink {
    local(*para, $link) = @_;
#   local();

    if ($link) {
        $link = &_MifLink($link, $SDF_USER'var{'MIF_EXT'});
        $para .= "  <Marker\n" .
            "   <MType 8>\n" .
            "   <MText `$link'>\n" .
            "  > # end of Marker\n";
    }
}

#
# >>_Description::
# {{Y:_MifFinalise}} generates a MIF file.
# If a template has been loaded, the result is a merge of the buffered
# MIF objects with the current template. Otherwise, the output is the
# buffered MIF objects prepended onto the text records. (In the latter
# case, the generated MIF must be imported into a template to produce
# the final document.) If the output is a component in a book,
# {{component_type}} should be set accordingly (e.g. FRONT, TOC,
# CHAPTER, etc.)
#
sub _MifFinalise {
    local(*text, $component_type) = @_;
    local(@out_result);
    local($pwidth, $pheight);
    local($component_prefix);
    local(%offset, $old_match_rule);
    local(%merged_ctrls, %merged_vars, %merged_xrefs);
    local(%merged_paras, %merged_fonts, %merged_tbls);
    local($mainflow);

    # Process document control settings
    &_MifProcessControls(*SDF_USER'var, $component_type);

    # Get the page width and height
    $pwidth = $SDF_USER'var{'DOC_PAGE_WIDTH'};
    $pheight = $SDF_USER'var{'DOC_PAGE_HEIGHT'};

    # Generate the master pages
    $component_prefix = $component_type eq '' ? '' : $component_type . "_";
    &_MifAddMasterPage('First', $component_prefix . "FIRST", $pwidth, $pheight,
      $_MIF_TEXTFLOW_MAIN);
    &_MifAddMasterPage('Right', $component_prefix . "RIGHT", $pwidth, $pheight);
    if ($SDF_USER'var{'DOC_TWO_SIDES'}) {
        &_MifAddMasterPage('Left', $component_prefix . "LEFT", $pwidth, $pheight);
    }

    # Generate the reference pages
    &_MifAddRefPages($component_type);

    # Add the generated lists (Table of Contents, etc.) unless this is
    # a part of a book
    &_MifAddLists(*text) if $component_type eq '';

    #
    # Build the import table. Note that each record in the
    # import table contains a single MIF main statement.
    # As we go, we also build an offset table which is
    # required by MifMerge so it can merge the import
    # table with the nominated template.
    #       
    @out_result = ("<MIFFile 5.00>");
    if (%_mif_ctrls) {
        %merged_ctrls = %_mif_tpl_ctrls;
        @merged_ctrls{keys %_mif_ctrls} = values %_mif_ctrls;
        push(@out_result, &_MifCtrlsToText(*merged_ctrls));
        $offset{'Document'} = $#out_result;
    }
    if (%_mif_vars) {
        %merged_vars = %_mif_tpl_vars;
        @merged_vars{keys %_mif_vars} = values %_mif_vars;
        push(@out_result, &_MifVarsToText(*merged_vars));
        $offset{'VariableFormats'} = $#out_result;
    }
    if (%_mif_xrefs) {
        %merged_xrefs = %_mif_tpl_xrefs;
        @merged_xrefs{keys %_mif_xrefs} = values %_mif_xrefs;
        push(@out_result, &_MifXRefsToText(*merged_xrefs));
        $offset{'XRefFormats'} = $#out_result;
    }
    if (%_mif_paras) {
$igc_start = time;
        %merged_paras = %_mif_tpl_paras;
        @merged_paras{keys %_mif_paras} = values %_mif_paras;
        push(@out_result, &_MifParasToText(*merged_paras));
#printf STDERR "text->para: %d seconds\n", time - $igc_start;
        $offset{'PgfCatalog'} = $#out_result;
    }
    if (%_mif_fonts) {
$igc_start = time;
        %merged_fonts = %_mif_tpl_fonts;
        @merged_fonts{keys %_mif_fonts} = values %_mif_fonts;
        push(@out_result, &_MifFontsToText(*merged_fonts));
#printf STDERR "text->font: %d seconds\n", time - $igc_start;
        $offset{'FontCatalog'} = $#out_result;
    }
    if (%_mif_tbls) {
$igc_start = time;
        %merged_tbls = %_mif_tpl_tbls;
        @merged_tbls{keys %_mif_tbls} = values %_mif_tbls;
        push(@out_result, &_MifTblsToText(*merged_tbls));
#printf STDERR "text->tbl: %d seconds\n", time - $igc_start;
        $offset{'TblCatalog'} = $#out_result;
    }
    if (@_mif_figure) {
        push(@out_result, join("\n",
          '<AFrames',
          @_mif_figure,
          '> # end of AFrames'
        ));
        $offset{'AFrames'} = $#out_result;
    }
    if (@_mif_table) {
        push(@out_result, join("\n",
          '<Tbls ',
          @_mif_table,
          '> # end of Tbls'
        ));
        $offset{'Tbls'} = $#out_result;
    }
    if (@_mif_pages) {
        push(@out_result, join("\n", @_mif_pages, $_mif_bodypage));
        $offset{'Page'} = $#out_result;
    }

    # Build the main text flow:
    # * add the header
    # * patch in the TextRect ID for the main flow
    # * ensure that nested lines are indented
    # * add the footer.
    $mainflow = join("\n",
        "<TextFlow",
        "<TFTag `A'>",
        "<TFAutoConnect Yes>",
        "<TFSideheads Yes>",
        "<TFSideheadPlacement Left>",
        "<TFSideheadGap $SDF_USER'var{OPT_SIDEHEAD_GAP}>",
        "<TFSideheadWidth $SDF_USER'var{OPT_SIDEHEAD_WIDTH}>",
        "<Notes ",
        "> # end of Notes",
        @text);
    $old_match_rule = $*;
    $* = 1;
    $mainflow =~ s/\<ParaLine/$&\n  <TextRectID $_MIF_TEXTFLOW_MAIN>/;
    $mainflow =~ s/\n/\n /g;
    $mainflow .= "\n> # end of TextFlow";
    $* = $old_match_rule;

    # Add the text flows to the  import table
    push(@out_result, join("\n", @_mif_textflows, $mainflow));
    $offset{'TextFlow'} = $#out_result;

    # If we're building a book, reset the buffers ready for the next part
    if ($component_type ne '') {
        @_mif_figure = ();
        @_mif_table = ();
        @_mif_pages = ();
        @_mif_textflows = ();
    }

    # Merge with the current template, if necessary
    if (scalar(@_mif_template) > 0) {
        @out_result = &_MifMerge(*_mif_template, *out_result, %offset);
    }

    # Return result
    push(@out_result, "# End of MIFFile");
    return @out_result;
}

#
# >>_Description::
# {{Y:_MifProcessControls}} checks the document control variables
# and sets the MIF control settings appropriately.
#
sub _MifProcessControls {
    local(*vars, $component_type) = @_;
#   local();
    local($page_size, $page_width, $page_height);
    local($sdf_tag, $mif_tag, $prefix);

    # Set the page size
    $page_size = $sdf_pagesize{$vars{'OPT_PAGE_SIZE'}};
    if ($page_size ne '') {
        ($page_width, $page_height) = split(/\000/, $page_size, 2);
    }
    else {
        # Custom size
        ($page_width, $page_height) = split(/x/, $vars{'OPT_PAGE_SIZE'}, 2);
    }
    $page_width  .= "pt" if $page_width =~ /^[\d\.]+$/;
    $page_width  .= "pt" if $page_width =~ /^[\d\.]+$/;
    $_mif_ctrls{'DPageSize'} = "$page_width $page_height";

    # Set the number of sides
    $_mif_ctrls{'DTwoSides'} = $vars{'DOC_TWO_SIDES'} || $vars{'MIF_TWO_SIDES'};

    # If numbering per section is enabled, adjust the 'Current Page #'
    # variable definition, if necessary
    if ($vars{'MIF_BOOK_MODE'} && $vars{'OPT_NUMBER_PER_COMPONENT'}) {
        $_mif_ctrls{'DPageNumStyle'} = 'Arabic';
        if ($component_type eq 'CHAPTER') {
            $sdf_tag = $vars{'OPT_COMPONENT_COVER'} ? 'H1NUM' : 'H1';
            $mif_tag = $SDF_USER'parastyles_to{$sdf_tag};
            $prefix = "<\$paranumonly[$mif_tag]>";
        }
        elsif ($component_type eq 'APPENDIX') {
            $sdf_tag = $vars{'OPT_COMPONENT_COVER'} ? 'A1NUM' : 'A1';
            $mif_tag = $SDF_USER'parastyles_to{$sdf_tag};
            $prefix = "<\$paranumonly[$mif_tag]>";
        }
        elsif ($component_type eq 'IX') {
            $prefix = "Index";
        }
        elsif (! $_MIF_FRONT_PART{"\L$component_type"}) {
            $prefix = "\u\L$component_type";
        }
        else {
            # Use roman numerals for page numbers of front matter
            $_mif_ctrls{'DPageNumStyle'} = 'LCRoman';
        }
        if ($prefix) {
            $_mif_vars{'Current Page #'} = "$prefix-<\$curpagenum>";
        }
        else {
            $_mif_vars{'Current Page #'} = "<\$curpagenum>";
        }
    }
}

#
# >>_Description::
# {{Y:_MifAddMasterPage}} adds a master page to the internal buffers.
# {{name}} is either Left, Right or a 'user' name.
# (In the latter case, the MIF type is implicitly 'OtherMasterPage'.)
# {{sdf_type}} is the SDF page type (e.g. FIRST, FRONT_RIGHT).
# {{page_width}} and {{page_height}} are the page width and height
# in points.
# The text flows for the header and footer, if any, are added to
# internal buffers used to generate the final document.
# If you want a matching body page for this master page, then set
# {{bodypage_id}} to the id of the TextRect within that body page.
#
sub _MifAddMasterPage {
    local($name, $sdf_type, $page_width, $page_height, $bodypage_id) = @_;
#   local();
    local(@page);
    local($mif_type);
    local($left, $width);
    local($h_top, $h_height);
    local($m_top, $m_height);
    local($f_top, $f_height);
    local($prefix);
    local($sh_width, $sh_gap);
    local($col_count, $col_gap);
    local(@body);
    local(@text, $id);
    local($background);

    # Build the header
    if ($name eq 'Left' || $name eq 'Right') {
        $mif_type = $name . "MasterPage";
    }
    else {
        $mif_type = "OtherMasterPage";
    }
    @page = (
        "<Page",
        " <PageType $mif_type>",
        " <PageTag `$name'>",
        " <PageAngle 0.0>");

    # Calculate the left & width (used by all rectangles on the page)
    $left   = ($name eq 'Left') ? &SdfVarPoints("OPT_MARGIN_OUTER") :
              &SdfVarPoints("OPT_MARGIN_INNER");
    $width  = $page_width - &SdfVarPoints("OPT_MARGIN_OUTER") -
              &SdfVarPoints("OPT_MARGIN_INNER");

    # Calculate the tops and heights
    $h_top    = &SdfVarPoints("OPT_MARGIN_TOP");
    $h_height = &SdfPageInfo($sdf_type, "HEADER_HEIGHT", "pt");
    $f_height = &SdfPageInfo($sdf_type, "FOOTER_HEIGHT", "pt");
    $f_top    = $page_height - $f_height - &SdfVarPoints("OPT_MARGIN_BOTTOM");
    $m_top    = $h_top + $h_height +
                &SdfPageInfo($sdf_type, "HEADER_GAP", "pt");
    $m_height = $f_top - $m_top -
                &SdfPageInfo($sdf_type, "FOOTER_GAP", "pt");

    # Get the sidehead and column details
    $prefix    = $sdf_type =~ /^IX/ ? 'OPT_IX' : 'OPT';
    $sh_width  = &SdfVarPoints("${prefix}_SIDEHEAD_WIDTH");
    $sh_gap    = &SdfVarPoints("${prefix}_SIDEHEAD_GAP");
    $col_count = $SDF_USER'var{"${prefix}_COLUMNS"};
    $col_gap   = &SdfVarPoints("${prefix}_COLUMN_GAP");

    # Add the main section
    @text = ();
    $id = &_MifAddTextFlow(*text, 'A');
    &_MifAddTextArea(*page, $id, $left, $m_top, $width, $m_height,
      $sh_width, $sh_gap, &SdfPageInfo($sdf_type, "MAIN_BORDER"),
      $col_count, $col_gap);
    if ($bodypage_id ne '') {
        @body = (
            "<Page",
            " <PageType BodyPage>",
            " <PageBackground `$name'>");
        &_MifAddTextArea(*body, $bodypage_id, $left, $m_top, $width, $m_height,
          $sh_width, $sh_gap, '', $col_count, $col_gap);
        push(@body, "> # end of Page");
        $_mif_bodypage = join("\n", @body);
    }

    # Add the header, if any
    if ($h_height) {
        @text = split("\n", &SdfPageInfo($sdf_type, "HEADER", "macro"));
        @text = ('HEADER:') unless @text;
        $id = &_MifAddTextFlow(*text, '');
        &_MifAddTextArea(*page, $id, $left, $h_top, $width, $h_height,
          $sh_width, $sh_gap, &SdfPageInfo($sdf_type, "HEADER_BORDER"));
    }

    # Add the footer, if any
    if ($f_height) {
        @text = split("\n", &SdfPageInfo($sdf_type, "FOOTER", "macro"));
        @text = ('FOOTER:') unless @text;
#$mif_debug = 1;
        $id = &_MifAddTextFlow(*text, '');
$mif_debug = 0;
        &_MifAddTextArea(*page, $id, $left, $f_top, $width, $f_height,
          $sh_width, $sh_gap, &SdfPageInfo($sdf_type, "FOOTER_BORDER"));
    }

    # Add background objects, if any
    $background = &SdfPageInfo($sdf_type, "BACKGROUND");
    if ($background ne '') {
        &_MifAddPageBackground(*page, $background, $background);
    }

    # Add the object footer
    push(@page, "> # end of Page");

    # Add the page to the internal buffers
    push(@_mif_pages, join("\n", @page));
}

#
# >>_Description::
# {{Y:_MifAddTextFlow}} adds a text flow to the internal buffers.
# {{@text}} is the sdf for the text in the text flow,
# unless {{mif}} is true, in which case {{@text}} is assumed to be MIF.
# {{tag}} is the tag of the text flow, if any.
# The {{id}} of the text flow added is returned.
#
sub _MifAddTextFlow {
    local(*text, $tag, $mif) = @_;
    local($id);
    local(@hdr, @flow);
    local($textflow, $old_match_rule);

    # Get the next text flow id
    $id = $_mif_textflow_cnt++;

    # Build the text flow header
    @hdr = ("<TextFlow");
    if ($tag ne '') {
        push(@hdr,
            " <TFTag `$tag'>",
            " <TFAutoConnect Yes>");
    }

    # Convert the SDF to a MIF, if necessary
    if ($mif) {
        @flow = @text;
    }
    else {
        @flow = ();
        &_MifAddSection(*flow, *text);
    }

    # Convert to a text flow
    if (@flow) {
        $textflow = join("\n", @flow);
        $old_match_rule = $*;
        $* = 1;
        $textflow =~ s/\<ParaLine/$&\n  <TextRectID $id>/;
        $textflow =~ s/\n/\n /g;
        $textflow .= "\n> # end of TextFlow";
        $* = $old_match_rule;
    }

    # If nothing was generated, build the text flow with a dummy paragraph
    else {
        $textflow = join("\n",
            " <Para",
            "  <ParaLine",
            "   <TextRectID $id>",
            "  > # end of ParaLine",
            " > # end of Para",
            "> # end of TextFlow");
    }

    # Add the text flow to the internal buffers
    push(@_mif_textflows, join("\n", @hdr, $textflow));

    # Return result
    return $id;
}

#
# >>_Description::
# {{Y:_MifAddTextArea}} adds a text area to a master or reference page.
# {{@page}} is the MIF page data (so far).
# {{id}} is the id of the text flow for this area.
# {{left}}, {{top}}, {{width}} and {{height}} give the
# rectangle's position. {{shwidth}} and {{shgap}} give
# the sidehead width and gap respectively.
# {{border}} is a comma-separated list of
# attributes which collectively describe the border.
# The format of each attribute is name[=value].
# The supported attributes are:
#
# * {{top}} - a line above the area
# * {{bottom}} - a line below the area
# * {{box}} - a box around the area
# * {{radius}} - for a box, the radius of the corner.
#
# For {{top}}, {{bottom}} and {{box}}, the value of the
# attribute is the line width in points.
#
sub _MifAddTextArea {
    local(*page, $id, $left, $top, $width, $height, $shwidth, $shgap, $border, $colcnt, $colgap) = @_;
#   local();
    local(%border, $nv, $name, $value);
    local($left2, $top2, $width2, $height2);
    local($right, $bottom);

    # Convert the border attribute to a set of name-value pairs
    %border = ();
    for $nv (split(/\s*,\s*/, $border)) {
        if ($nv =~ /\=/) {
            $name = $`;
            $value = $';
        }
        else {
            $name = $nv;
            $value = 1;
        }
        $border{$name} = $value;
    }

    # Add the border, if any
    for $name (sort keys %border) {
        $value = $border{$name};
        if ($name eq 'top') {
            # put the line just above the actual border
            $top2 = $top - $_MIF_BORDER_GAP;
            $right = $left + $width;
            push(@page, &_MifLine($left, $top2, $right, $top2,
                " ", 0, $value));
        }
        elsif ($name eq 'bottom') {
            # put the line just below the actual border
            $right = $left + $width;
            $bottom = $top + $height + $_MIF_BORDER_GAP;
            push(@page, &_MifLine($left, $bottom, $right, $bottom,
                " ", 0, $value));
        }
        elsif ($name eq 'box') {
            # put the rectangle just around the actual border
            $left2 = $left - $_MIF_BORDER_GAP;
            $top2 = $top - $_MIF_BORDER_GAP;
            $width2 = $width + $_MIF_BORDER_GAP * 2;
            $height2 = $height + $_MIF_BORDER_GAP * 2;
            push(@page, &_MifRectangle($left2, $top2, $width2, $height2,
                $border{'radius'}, " ", 0, $value));
        }
    }

    # Add the text rectangle. Note that we explicitly do this AFTER
    # the border stuff so that MIF attribute inheritance will work
    # correctly for background objects (if any).
    $colcnt = 1 if $colcnt < 1;
    $colgap = 0 if $colgap eq '';
    push(@page,
        " <TextRect",
        "  <ID $id>",
        "  <Pen 15>",
        "  <Fill 15>",
        "  <ShapeRect  ${left}pt ${top}pt ${width}pt ${height}pt>",
        "  <BRect  ${left}pt ${top}pt ${width}pt ${height}pt>",
        "  <TRSideheadWidth  ${shwidth}pt>",
        "  <TRSideheadGap  ${shgap}pt>",
        "  <TRNumColumns  ${colcnt}>",
        "  <TRColumnGap  ${colgap}pt>",
        " > # end of TextRect");
}

#
# >>_Description::
# {{Y:_MifLine}} creates a MIF line object.
#
sub _MifLine {
    local($x1, $y1, $x2, $y2, $prefix, $pen, $pen_width, $color) = @_;
#   local($result);
    local(@line);

    # Apply defaults
    $pen       = 0          if $pen       eq '';
    $pen_width = 1          if $pen_width eq '';
    $color     = 'Black'    if $color     eq '';

    # Build the header
    @line = ("$prefix<PolyLine");

    # Add the attributes
    push(@line,
        " <Pen $pen>",
        " <PenWidth  $pen_width pt>",
        " <ObColor `$color'>",
        " <HeadCap Square>",
        " <TailCap Square>");

    # Add the points
    push(@line,
        " <NumPoints 2>",
        " <Point  ${x1}pt ${y1}pt>",
        " <Point  ${x2}pt ${y2}pt>",
        "> # end of PolyLine");

    # Return result
    return join("\n$prefix", @line);
}

#
# >>_Description::
# {{Y:_MifRectangle}} creates a MIF rectangle object.
# {{radius}} is the radius of the corner (0=square corner).
#
sub _MifRectangle {
    local($left, $top, $width, $height, $radius, $prefix, $pen, $pen_width) = @_;
#   local($result);
    local(@rect);

    # Build the header
    @rect = ("$prefix<RoundRect");

    # Add the attributes
    push(@rect,
        " <Pen $pen>",
        " <PenWidth  $pen_width pt>");

    # Add the shape
    push(@rect,
        " <ShapeRect ${left}pt ${top}pt ${width}pt ${height}pt>",
        " <Radius ${radius}pt>",
        "> # end of RoundRect");

    # Return result
    return join("\n$prefix", @rect);
}

#
# >>_Description::
# {{Y:_MifAddPageBackground}} adds background objects to a page.
# {{master}} is the name of the master page to get the
# objects from. The master page is assumed to be in a file called
# {{background}}.{{mif}}.
# If {{required}} is true, then a warning is output if the
# master page is not found.
#
sub _MifAddPageBackground {
    local(*page, $background, $master, $required) = @_;
#   local();
    local($bg_ext, $bg_short, $bg_file);
    local($_, $in_object, $in_file);

    # Find the file
    #$bg_ext = 'bg' . substr($sdf_fmext, -1);
    $bg_ext = 'mif';
    $bg_short = &NameJoin('', $background, $bg_ext);
    $bg_file = &SDF_USER'FindFile($bg_short);
    if ($bg_file eq '') {
        &AppMsg("warning", "unable to find background file '$bg_short'");
        return;
    }

    # Open the file
    unless (open(BGFILE, $bg_file)) {
        &AppMsg("warning", "unable to open background file '$bg_file'");
        return;
    }

    # Copy the objects
    $in_object = 0;
    $in_file = 0;
    while (<BGFILE>) {
        chop;
        if ($in_object) {
            push(@page, $_);
            $in_object = 0 if /^ \>/;
        }
        elsif ($in_file) {
            last if /^\>/;
            next if /\>$/;
            next if /^ \<TextRect/;
            if (/^ \<(\w+)/) {
                push(@page, $_);
                $in_object = 1;
            }
        }
        elsif (/^ \<PageTag\s+`$master'\>/) {
            $in_file = 1;
        }
    }
    close(BGFILE);

    # Output a warning, if necessary
    if ($required && !$in_file) {
        &AppMsg("warning", "master page '$master' not found in '$bg_file'");
    }
}

#
# >>_Description::
# {{Y:_MifAddRefPages}} adds the reference pages to the internal buffers.
# {{part_type}} is the book part type. If {{part_type}} is a derived
# list (e.g. TOC), the relevant special text flow is added.
#
sub _MifAddRefPages {
    local($part_type) = @_;
#   local();
    local(@page);
    local($name);
    local(%attr);
    local($page_x, $page_y, $width, $height);
    local($objects);
    local($pen, $pen_width);
    local($y, $length);

    # Build the reference page header
    @page = (
        "<Page",
        " <PageType ReferencePage>",
        " <PageTag `Reference'>",
        " <PageAngle 0.0>");

    # Add the frames
    $page_x = 72;
    $page_y = 72;
    for $name (sort keys %_mif_frames) {
        %attr = &_MifAttrSplit($_mif_frames{$name});
        $width  = $attr{'Width'};
        $width  = $SDF_USER'var{'DOC_FULL_WIDTH'} if $width eq '';
        $height = $attr{'Height'};
        $page_y += $height + 36;

        # Build the object in the frame, if necessary
        if ($attr{'LineLength'}) {
            $pen       = $attr{'Pen'};
            $pen_width = $attr{'PenWidth'};
            $x         = $attr{'LineX'};
            $x         = 0 if $x eq '';
            $y         = $attr{'LineY'};
            $y         = 0 if $y eq '';
            $length    = $attr{'LineLength'};
            $objects   = &_MifLine($x, $y, $length+$x, $y, "  ", $pen,
                         $pen_width, $attr{'Color'});
        }
        else {
            $objects = $attr{'Objects'};
        }

        # Add the frame
        push(@page,
            " <Frame ",
            "  <Pen 15>",
            "  <Fill 15>",
            "  <PenWidth  1.0 pt>",
            "  <ObColor `Black'>",
            "  <ShapeRect  ${page_x}pt ${page_y}pt ${width}pt ${height}pt>",
            "  <FrameType NotAnchored>",
            "  <Tag `$name'>",
            $objects,
            " > # end of Frame");
    }

    # Add the object footer
    push(@page, "> # end of Page");

    # Add the page to the internal buffers
    push(@_mif_pages, join("\n", @page));

    # Add the special text flow, if necessary
    &_MifAddSpecialTextFlow($part_type);
}
sub _MifAddSpecialTextFlow {
    local($name) = @_;
#   local();
    local(%attr, $layout);
    local(@mif_text, $j, $hdgtag, $tag, $tagtype, $tagbase);
    local($id);
    local(@page);
    local($left, $top, $width, $height, $sh_width, $sh_gap);

    # Get the attributes, if any
    if ($_mif_lists{$part_type}) {
        %attr = &_MifAttrSplit($_mif_lists{$name});
    }
    elsif ($_mif_indexes{$part_type}) {
        %attr = &_MifAttrSplit($_mif_indexes{$name});
    }
    else {
        return;
    }

    # Build the MIF for the text flow.
    # Note: Frame core dumps(!!) if a layout includes a paranumonly
    # or paranum when the matching paragraph has no autonumber, so
    # we make sure this cannot happen!!!
    @mif_text = ();
    if ($name eq 'TOC') {
        for ($j = 1; $j <= $SDF_USER'var{'DOC_TOC'}; $j++) {
            for $tagtype ('H', 'A', 'P') {
                $hdgtag = $SDF_USER'parastyles_to{"$tagtype$j"};
                $tag = $hdgtag . $name;
                $_mif_parastyle_used{$tag}++;
                $layout = &_MifFixLayout($attr{'Layout'}, $hdgtag);
                push(@mif_text,
                     "<Para ",
                     " <PgfTag `$tag'>",
                     " <ParaLine ",
                     "  <String `$layout'>",
                     " >",
                     "> # end of Para");
            }
        }

        # Ensure the index makes it into the contents
        $hdgtag = $SDF_USER'parastyles_to{"IXT"};
        $tag = $hdgtag . $name;
        $_mif_parastyle_used{$tag}++;
        $layout = &_MifFixLayout($attr{'Layout'}, $hdgtag);
        push(@mif_text,
             "<Para ",
             " <PgfTag `$tag'>",
             " <ParaLine ",
             "  <String `$layout'>",
             " >",
             "> # end of Para");
    }
    elsif ($name eq 'LOF') {
        $hdgtag = $SDF_USER'parastyles_to{"FT"};
        $tag = $hdgtag . $name;
        $_mif_parastyle_used{$tag}++;
        $layout = &_MifFixLayout($attr{'Layout'}, $hdgtag);
        push(@mif_text,
             "<Para ",
             " <PgfTag `$tag'>",
             " <ParaLine ",
             "  <String `$layout'>",
             " >",
             "> # end of Para");
    }
    elsif ($name eq 'LOT') {
        $hdgtag = $SDF_USER'parastyles_to{"TT"};
        $tag = $hdgtag . $name;
        $_mif_parastyle_used{$tag}++;
        $layout = &_MifFixLayout($attr{'Layout'}, $hdgtag);
        push(@mif_text,
             "<Para ",
             " <PgfTag `$tag'>",
             " <ParaLine ",
             "  <String `$layout'>",
             " >",
             "> # end of Para");
    }
    elsif ($name eq 'IX') {
        for $tagbase ('GroupTitles', 'Index', 'Level1', 'Level2') {
            $tag = $tagbase . $name;
            $_mif_parastyle_used{$tag}++ if $_mif_paras{$tag};
        }
    }

    # Add the text flow to the internal buffers
    $id = &_MifAddTextFlow(*mif_text, $name, 1);

    # Build the reference page header
    @page = (
        "<Page",
        " <PageType ReferencePage>",
        " <PageTag `$name'>",
        " <PageAngle 0.0>");

    # Calculate the page dimensions
    $left     = &SdfVarPoints("OPT_MARGIN_INNER");
    $width    = &SdfVarPoints("DOC_FULL_WIDTH");
    $top      = &SdfVarPoints("OPT_MARGIN_TOP");
    $height   = &SdfVarPoints("DOC_TEXT_HEIGHT");
    $sh_width = &SdfVarPoints("OPT_SIDEHEAD_WIDTH");
    $sh_gap   = &SdfVarPoints("OPT_SIDEHEAD_GAP");

    # Add the text area
    &_MifAddTextArea(*page, $id, $left, $top, $width, $height, $sh_width,
      $sh_gap);

    # Add the object footer
    push(@page, "> # end of Page");

    # Add the page to the internal buffers
    push(@_mif_pages, join("\n", @page));
}

#
# >>_Description::
# {{Y:_MifFixLayout}} removes paranum/paranumonly building blocks
# from a layout for a paragraph which does not have an autonumber.
#
sub _MifFixLayout {
    local($layout, $paratag) = @_;
    local($result);
    local(%attr);

    # Build the result
    $result = $layout;
    %attr = &_MifAttrSplit($_mif_paras{$paratag});
    if ($attr{'NumFormat'} eq '') {
        $result =~ s/\<\$paranumonly\\\>//g;
        $result =~ s/\<\$paranum\\\>//g;
    }
#print STDERR "$paratag:$result.\n";

    # Return result
    return $result;
}

#
# >>_Description::
# {{Y:_MifAddLists}} adds the generated lists (i.e. table of contents, etc.).
#
sub _MifAddLists {
    local(*text) = @_;
#   local();
    local($target, $soft);
    local($name);
    local(%attr);
    local($layout);
    local($i);
    local($old_match_rule, $toc_offset);

    # Set some flags based on the output ultimately generated
    $target = $SDF_USER'var{'OPT_TARGET'};
    $soft = $target eq 'help' || $target eq 'html';

    # Process the list definitions (add xrefs, etc.)
    for $name (sort keys %_mif_lists) {
        %attr = &_MifAttrSplit($_mif_lists{$name});
        $layout = $attr{'Layout'};
        $layout = '<$paratext\>' if $soft;
        $_mif_xrefs{$name} = $layout;
    }

    # Add titles
    if (@_mif_toc_list) {
        unshift(@_mif_toc_list, &_MifListTitle('TOC', 'Table of Contents'));
    }
    if (@_mif_lof_list) {
        unshift(@_mif_lof_list, &_MifListTitle('LOF', 'List of Figures'));
    }
    if (@_mif_lot_list) {
        unshift(@_mif_lot_list, &_MifListTitle('LOT', 'List of Tables'));
    }

    # Insert the generated lists before the first level 1 heading
    push(@_mif_toc_list, @_mif_lof_list, @_mif_lot_list);
    if (@_mif_toc_list) {
        $old_match_rule = $*;
        $* = 1;
        $toc_offset = 0;
        para:
        for ($i = 0; $i <= $#text; $i++) {
            if ($text[$i] =~ /\<MText \`$_MIF_TOC_XREF_START\'\>/) {
                $toc_offset = $i;
                last para;
            }
        }
        $* = $old_match_rule;
        splice(@text, $toc_offset, 0, @_mif_toc_list);
    }
}

#
# >>_Description::
# {{Y:_MifListTitle}} builds a title for a generated list.
# The mif for the title is returned. {{default_title}} is used if
# a title hasn't been specified via the appropriate SDF variable.
#
sub _MifListTitle {
    local($type, $default_title) = @_;
    local($mif);
    local($title, $tag);
    local(@sdf_data, @mif_data);

    # If we're building component covers, make sure that the relevant SDF
    # macro gets called
    $mif = '';
    if ($SDF_USER'var{'OPT_COMPONENT_COVER'} &&
        ($type eq 'TOC' || $type eq 'IX')) {
        @sdf_data = ('!DOC_COMPONENT_COVER_BEGIN');
        &_MifAddSection(*mif_data, *sdf_data);
        $mif = join("\n", @mif_data) . "\n";
    }

    $tag = $SDF_USER'parastyles_to{$type . 'T'};
    $_mif_parastyle_used{$tag}++;
    $title = $SDF_USER'var{"DOC_${type}_TITLE"};
    $title = $default_title if $title eq '';
    &_MifEscape(*title);
    $mif .=
        "<Para\n" .
        " <PgfTag `$tag'>\n" .
        " <ParaLine\n" .
        "  <String `$title'>\n" .
        " >\n" .
        "> # end of Para";

    # Return result
    return $mif;
}

#
# >>_Description::
# {{Y:_MifMerge}} merges an import table into a MIF template.
# The import table must be generated so that each
# main MIF object contains one record only. {{offset}} contains
# the indices of each main MIF object which exists in {{@import}}.
# Reference pages and their textflows are retained from {{@template}}.
# The other pages (i.e. the master and body pages) must be supplied
# by {{@import}}.
#
sub _MifMerge {
    local(*template, *import, %offset) = @_;
    local(@new);
    local($record, $obj);
    local($old_match_rule);
    local($merged_pages, $merged_textflows, %ref_textflow);
    local($side_width);
    local($page_type, $page_name, $page_size, $cover_rect);
    
    # To permit multi-line matching, save the old state here and
    # restore it later      
    $old_match_rule = $*;
    $* = 1;

    #
    # Do the merge. We ignore BookComponent objects
    # in @import as this simplifies the code somewhat.
    # As a Tbls section may or may not exist in the template,
    # we ignore existing Tbls and place new tables, if any,
    # immediately after figures (AFrames).
    #
    # We use while/shift, rather than for, to save memory.
    #
    $merged_pages = 0;
    $merged_textflows = 0;
    %ref_textflow = ();
    while($record = shift(@template)) {
    
        # Find the object 'name'
        unless ($record =~ /^\<(\w+)/) {
            &AppExit("fatal", "MIF template error - expecting object");
        }       
        $obj = $1;

        # Patch the comment to claim responsibility
        if ($obj eq 'MIFFile') {
            $record =~ s/\>.*$/>/;
            $record .= " # Generated by $app_product_name $app_product_version";
        }
        
        # Patch in records from import  
        if ($obj eq 'TextFlow') {

            # If this is the first text flow, merge the import text flows
            unless ($merged_textflows) {
                $merged_textflows = 1;
                push(@new, $import[$offset{'TextFlow'}]);
            }

            # If this is a text flow for a reference page, keep it
            if ($record =~ /\<TextRectID\s+(\d+)/) {
                push(@new, $record) if $ref_textflow{$1};
            }       
            else {
                &AppExit("warning", "MIF template error - no TextRectID for TextFlow");
            }
        }
        elsif ($obj eq 'Page') {
            $record =~ /\<PageType\s+(\w+)/;
            $page_type = $1;

            # If this is the first page, merge the import pages
            unless ($merged_pages) {
                $merged_pages = 1;
                push(@new, $import[$offset{'Page'}]);
            }

            # If this is a reference page, use it and
            # remember the textflow id, if any
            if ($page_type eq 'ReferencePage') {
                push(@new, $record);
                if ($record =~ /\<TextRect\s+\<ID\s+(\d+)\>/) {
                    $ref_textflow{$1} = 1;
                }
                #else {
                #    &AppMsg("warning", "MIF template error - no TextRect ID for reference page");
                #}
            }
        }
        elsif ($obj eq 'AFrames') {
            if ($offset{$obj}) {
                push(@new, $import[$offset{$obj}]);
            }
            if ($offset{"Tbls"}) {
                push(@new, $import[$offset{"Tbls"}]);
            }
        }
        elsif ($obj ne 'BookComponent' && $obj ne 'Tbls' && $offset{$obj}) {
            push(@new, $import[$offset{$obj}]);
        }
        else {
            push(@new, $record);
        }
    }
    
    # Return result
    $* = $old_match_rule;
    return @new;    
}

#
# >>_Description::
# {{Y:_MifHandlerTuning}} handles the 'tuning' directive.
#
sub _MifHandlerTuning {
    local(*outbuffer, $tuning, %attr) = @_;
#   local();
    local($template_file);

    # Regardless of what happens, make sure we init things
    &_MifInitTemplate();

    # A tuning of '.' means to skip merging (used in testing)
    if ($tuning eq '.') {
        return;
    }

    # Find the template file. A template file is searched for by
    # looking for {{tuning}}.{{fmver}} along the SDF include
    # path, where {{sdfver}} is fm4 or fm5 (typically).
    $template_file = &SDF_USER'FindFile(&NameJoin('', $tuning, $sdf_fmext));
    if ($template_file eq '') {
        #&AppMsg("warning", "unable to find template '$tuning'");
        return;
    }

    # Load the template file
    unless (&_MifFetchTemplate($template_file)) {
        &AppMsg("warning", "unable to load template file '$template_file'");
    }
}

#
# >>_Description::
# {{Y:_MifHandlerEndTuning}} handles the 'endtuning' directive.
#
sub _MifHandlerEndTuning {
    local(*outbuffer, $text, %attr) = @_;
#   local();

    # do nothing
}

#
# >>_Description::
# {{Y:_MifHandlerTable}} handles the 'table' directive.
#
sub _MifHandlerTable {
    local(*outbuffer, $columns, %attr) = @_;
#   local();
    local($tbl_id);
    local($style, $style_tag);
    local($tbl_title);
    local($tbl_width, $unit_width, $width, @widths);
    local($rest);
    local($target);
    local(@equal_cols, $col);
    local($lower, $sep, $upper);
    local($indent);
    local($align, $placement);
    local($margins);

    # Update the state
    push(@_mif_tbl_state, $_MIF_INTABLE);
    push(@_mif_tbl_start, $#outbuffer + 1);
    push(@_mif_tbl_wide, $attr{'wide'});
    push(@_mif_tbl_style, $attr{'style'});
    push(@_mif_tbl_landscape, $attr{'landscape'});
    push(@_mif_row_type, '');

    # Get the table id. Note that we keep a queue of these (rather
    # than a stack) to ensure that nested table are output in the
    # right order.
    $tbl_id = $#_mif_table + scalar(@_mif_tbl_id) + $_MIF_OBJ_REF_START;
    unshift(@_mif_tbl_id, $tbl_id);

    # Get the style
    $style = $attr{'style'};
    $style_tag = $SDF_USER'tablestyles_to{$style};
    if ($style_tag eq '') {
        &AppMsg("warning", "unknown table style '$style'");
        $style_tag = $style;
    }

    # Get the title, if any. FrameMaker 5.0 adds blank pages for
    # tables with titles, so a configuration flag controls whether
    # we produce real or simulated table titles.
    $tbl_title = $attr{'title'};
    push(@_mif_tbl_title, $tbl_title);
    $tbl_title = '' if $_MIF_SIMPLE_TBL_TITLES;

    # Get the indent
    if (!$attr{'wide'} && $attr{'listitem'} ne '') {
        $indent = &SdfVarPoints('OPT_LIST_INDENT') * $attr{'listitem'};
    }
    else {
        $indent = 0;
    }

    # Get the positioning details
    $align = $attr{'align'};
    $align = 'Inside' if $align eq 'Inner';
    $align = 'Outside' if $align eq 'Outer';
    $placement = $attr{'placement'};
    $placement =~ s/top/Top/ if $placement ne '';

    # For landscape tables, the default alignment is centered, i.e.
    # the table is centered BEFORE rotation
    if ($attr{'landscape'} && $align eq '') {
        $align = 'Center';
    }

    # Get the table width and 1% (i.e. unit) width
    if ($attr{'wide'}) {
        $tbl_width = $SDF_USER'var{'DOC_FULL_WIDTH'} - $indent;
    }
    else {
        $tbl_width = $SDF_USER'var{'DOC_TEXT_WIDTH'} - $indent;
    }
    $unit_width = $tbl_width / 100;

    # For margins not supplied, we use some defaults. Ideally,
    # the default values should come from the table format used.
    ($_mif_tbl_lmargin, $_mif_tbl_tmargin, $_mif_tbl_rmargin,
      $_mif_tbl_bmargin) = (6, 4, 6, 2);

    # Get the cell margins, if necessary
    if ($attr{'lmargin'} ne '' || $attr{'tmargin'} ne '' ||
        $attr{'rmargin'} ne '' || $attr{'bmargin'} ne '') {
        $_mif_tbl_lmargin = $attr{'lmargin'} if defined $attr{'lmargin'};
        $_mif_tbl_tmargin = $attr{'tmargin'} if defined $attr{'tmargin'};
        $_mif_tbl_rmargin = $attr{'rmargin'} if defined $attr{'rmargin'};
        $_mif_tbl_bmargin = $attr{'bmargin'} if defined $attr{'bmargin'};
        $margins =
          "${_mif_tbl_lmargin}pt ${_mif_tbl_tmargin}pt " .
          "${_mif_tbl_rmargin}pt ${_mif_tbl_bmargin}pt";
    }

    # Update the output buffer
    $_mif_tblstyle_used{$style_tag}++;
    push(@outbuffer, 
        " <Tbl",
        "  <TblID $tbl_id>",
        "  <TblTag `$style_tag'>");

    # If we're ultimately going to rtf or hlp, output a simple set of
    # column widths
    $target = $SDF_USER'var{'OPT_TARGET'};
    if ($target eq 'hlp' || $target eq 'rtf') {
        push(@outbuffer, "  <TblNumColumns $columns>");
        @widths = split(/,/, $attr{'format'});
        $rest = 100;
        for ($col = 0; $col < $columns; $col++) {
            $width = $widths[$col];
            if ($width =~ /([-=])/) {
                # Assume 30% for now :-(
                $width = (30 * $unit_width) . 'pt';
                $rest -= 30;
            }
            elsif ($width =~ /\*$/) {
                # Assume the rest for now. This will work provided
                # that it is last column and that preceding dimensions are 
                # guessed (e.g. -) or percentages. :-(
                $rest = 10 if $rest <= 0;
                $width = ($rest * $unit_width) . 'pt';
                $rest = 0;
            }
            else {
                # Convert the measurement to points if it's a percentage
                if ($width =~ /\%$/) {
                    $rest -= $`;
                    $width = ($` * $unit_width) . 'pt';
                }
            }
            push(@outbuffer, "  <TblColumnWidth $width>");
        }
    }

    else {
        # Override the table format
        push(@outbuffer, "  <TblFormat");
        push(@outbuffer, "   <TblTitlePlacement InHeader>") if $tbl_title;
        push(@outbuffer, "   <TblLIndent ${indent}pt>") if $indent ne '';
        push(@outbuffer, "   <TblAlignment $align >") if $align;
        push(@outbuffer, "   <TblPlacement $placement >") if $placement;
        push(@outbuffer, "   <TblCellMargins $margins >") if $margins;
        push(@outbuffer, "   <TblWidth ${tbl_width}pt>");

        # Output the column widths
        @widths = split(/,/, $attr{'format'});
        @equal_cols = ();
        for ($col = 0; $col < $columns; $col++) {
            $width = $widths[$col];
            push(@outbuffer, "   <TblColumn", "    <TblColumnNum $col>");
            if ($width =~ /([-=])/) {
                $lower = $`;
                $sep   = $1;
                $upper = $';
                $lower = ($` * $unit_width) . 'pt' if $lower =~ /\%$/;
                $upper = ($` * $unit_width) . 'pt' if $upper =~ /\%$/;
                push(@outbuffer, "    <TblColumnWidthA $lower $upper>");
                push(@equal_cols, $col) if $sep eq '=';
            }
            elsif ($width =~ /\*$/) {
                push(@outbuffer, "    <TblColumnWidthP $`>");
            }
            else {
                $width = ($` * $unit_width) . 'pt' if $width =~ /\%$/;
                push(@outbuffer, "    <TblColumnWidth $width>");
            }
            push(@outbuffer, "   > # end of TblColumn");
        }
        push(@outbuffer, "  > # end of TblFormat");

        # Output the column details (those not already in the table format)
        push(@outbuffer, "  <TblNumColumns $columns>");
        if (@equal_cols) {
            push(@outbuffer, "  <EqualizeWidths");
            for $col (@equal_cols) {
                push(@outbuffer, "   <TblColumnNum $col>");
            }
            push(@outbuffer, "  > # end of EqualizeWidths");
        }
    }

    # Output the table title, if any
    if ($tbl_title) {
        push(@outbuffer, "  <TblTitleContent");
        &_MifParaAdd(*outbuffer, 'TT', $tbl_title);
        push(@outbuffer, "  > # end of TblTitleContent");
    }    
}

#
# >>_Description::
# {{Y:_MifHandlerRow}} handles the 'row' directive.
#
sub _MifHandlerRow {
    local(*outbuffer, $text, %attr) = @_;
#   local();
    local($state);

    # Finalise the old cell/row, if any
    $state = $_mif_tbl_state[$#_mif_tbl_state];
    if ($state eq $_MIF_INCELL) {
        push(@outbuffer,
            "     > # end of CellContent",
            "    > # end of Cell",
            "   > # end of Row",
            "  > # end of TblH/TblBody/TblF");
    }
    elsif ($state eq $_MIF_INROW) {
        push(@outbuffer,
            "   > # end of Row",
            "  > # end of TblH/TblBody/TblF");
    }

    # Update the state
    $_mif_tbl_state[$#_mif_tbl_state] = $_MIF_INROW;
    $_mif_row_type[$#_mif_row_type] = $text;

    # Update the output buffer
    push(@outbuffer,
            "  <Tbl$_MIF_ROW_SUFFIX{$text}",
            "   <Row");
    push(@outbuffer, "    <RowWithNext Yes>") if $text eq 'Group';
}

#
# >>_Description::
# {{Y:_MifHandlerCell}} handles the 'cell' directive.
#
sub _MifHandlerCell {
    local(*outbuffer, $text, %attr) = @_;
#   local();
    local($state);
    local($fill, $color, $cols, $rows, $angle);
    local($lruling, $rruling, $truling, $bruling);

    # Finalise the old cell, if any
    $state = $_mif_tbl_state[$#_mif_tbl_state];
    if ($state eq $_MIF_INCELL) {
        push(@outbuffer,
            "     > # end of CellContent",
            "    > # end of Cell");
    }

    # Update the state
    $_mif_tbl_state[$#_mif_tbl_state] = $_MIF_INCELL;
    $_mif_cell_align = $attr{'align'};
    $_mif_cell_valign = $attr{'valign'};
    if ($_mif_cell_valign eq 'Baseline') {
        $_mif_cell_valign = '';
    }
    $_mif_cell_tmargin = $attr{'tmargin'};
    $_mif_cell_bmargin = $attr{'bmargin'};
    $_mif_cell_lmargin = $attr{'lmargin'};
    $_mif_cell_rmargin = $attr{'rmargin'};

    # Get the attributes
    $color = $_MIF_COLOR{$attr{'bgcolor'}};
    $fill = $attr{'fill'} ne '' ? $_MIF_FILL_CODE{$attr{'fill'}} :
            ($color ne '' ? 0 : '');
    $cols = $attr{'cols'};
    $rows = $attr{'rows'};
    $angle = $attr{'angle'};
    $lruling = $attr{'lruling'};
    $lruling = 'Very Thin' if $lruling eq 'Vthin';
    $rruling = $attr{'rruling'};
    $rruling = 'Very Thin' if $rruling eq 'Vthin';
    $truling = $attr{'truling'};
    $truling = 'Very Thin' if $truling eq 'Vthin';
    $bruling = $attr{'bruling'};
    $bruling = 'Very Thin' if $bruling eq 'Vthin';

    # For tables of style "columns", the default top ruling of
    # group rows is 'Thin'
    if ($_mif_row_type[$#_mif_row_type] eq 'Group' && $truling eq '') {
        $truling = 'Thin' if $_mif_tbl_style[$#_mif_tbl_style] eq 'columns';
    }

    # Update the output buffer
    push(@outbuffer, "    <Cell");
    push(@outbuffer, "     <CellFill $fill>") if $fill ne '';
    push(@outbuffer, "     <CellColor `$color'>") if $color ne '';
    push(@outbuffer, "     <CellColumns $cols>") if $cols > 1;
    push(@outbuffer, "     <CellRows $rows>") if $rows > 1;
    push(@outbuffer, "     <CellAngle $angle>") if $angle != 0;
    push(@outbuffer, "     <CellLRuling `$lruling'>") if $lruling ne '';
    push(@outbuffer, "     <CellRRuling `$rruling'>") if $rruling ne '';
    push(@outbuffer, "     <CellTRuling `$truling'>") if $truling ne '';
    push(@outbuffer, "     <CellBRuling `$bruling'>") if $bruling ne '';
    push(@outbuffer, "     <CellContent");
}

#
# >>_Description::
# {{Y:_MifHandlerEndTable}} handles the 'endtable' directive.
#
sub _MifHandlerEndTable {
    local(*outbuffer, $text, %attr) = @_;
#   local();
    local($state, $start, $tbl_id, $tbl_title, $tbl_wide);
    local($nested, $angle);

    # Finalise the table
    $state = pop(@_mif_tbl_state);
    if ($state eq $_MIF_INCELL) {
        push(@outbuffer,
            "     > # end of CellContent",
            "    > # end of Cell",
            "   > # end of Row",
            "  > # end of TblH/TblBody/TblF");
    }
    elsif ($state eq $_MIF_INROW) {
        push(@outbuffer,
            "   > # end of Row",
            "  > # end of TblH/TblBody/TblF");
    }
    push(@outbuffer,
            " > # end of Tbl");

    # Move the table to the table buffer
    $start = pop(@_mif_tbl_start);
    push(@_mif_table, join("\n", @outbuffer[$start .. $#outbuffer]));
    $#outbuffer = $start - 1;

    # Update the main text flow
    $tbl_id = pop(@_mif_tbl_id);
    $tbl_wide = pop(@_mif_tbl_wide);
    $tbl_title = pop(@_mif_tbl_title);
    $landscape = pop(@_mif_tbl_landscape);
    if (@_mif_tbl_id) {
        &'AppMsg("warning", "ignoring nested MIF table");
    }
    else {
        if ($landscape) {
            $nested = $landscape;
            $angle = 90;
        }
        &_MifUpdateMainFlow(*outbuffer, "table", $tbl_id, $tbl_title, $tbl_wide,
          $nested, $angle);
    }

    # Cleanup the state
    pop(@_mif_tbl_style);
    pop(@_mif_row_type);
}

#
# >>_Description::
# {{Y:_MifHandlerInline}} handles the inline directive.
#
sub _MifHandlerInline {
    local(*outbuffer, $text, %attr) = @_;
#   local();

    # Check we can handle this format
    my $target = $attr{'target'};
    return unless $target eq 'mif' || $target eq 'ps';

    # Build the result
    push(@outbuffer, $text);
}

#
# >>_Description::
# {{Y:_MifHandlerOutput}} handles the output directive.
#
sub _MifHandlerOutput {
    local(*outbuffer, $text, %attr) = @_;
#   local();
    local($offset, @component_data);
    local($component_type);
    local($file);

    # Finalise the current component, if requested
    if ($text eq '-') {
        # If there is no current component, do nothing
        return unless @_mif_component_offset;

        # Find the component type
        $component_type = $_mif_component_type[$_mif_component_cursor++];

        # Generate the mif
        $offset = pop(@_mif_component_offset);
        @component_data = splice(@outbuffer, $offset + 1);
        @component_data = &_MifFinalise(*component_data, $component_type);

        # Output the mif
        $file = pop(@_mif_component_file);
        unless (open(CHAPTER, ">$file")) {
            &AppMsg("error", "unable to write to component file '$file'");
            return;
        }
        print CHAPTER join("\n", @component_data), "\n";
        close(CHAPTER);
    }

    # Otherwise, save the output filename and the current offset
    # Note: the type is pushed onto @_mif_component_type by MifNewComponent.
    else {
        push(@_mif_component_file, $text);
        push(@_mif_component_offset, $#outbuffer);
    }
}

#
# >>_Description::
# {{Y:_MifHandlerImport}} handles the import directive.
#
sub _MifHandlerImport {
    local(*outbuffer, $filepath, %attr) = @_;
#   local();
    local($ref_id);

    # Add the figure to the internal buffers
    $ref_id = &_MifAddFigure($filepath, *attr);

    # Reference this object in the main flow
    &_MifUpdateMainFlow(*outbuffer, 'figure', $ref_id, $attr{'title'},
      $attr{'wide'});
}

#
# >>_Description::
# {{Y:_MifAddFigure}} adds a figure to the internal buffers.
# The reference id of the figure is returned.
#
sub _MifAddFigure {
    local($filepath, *attr) = @_;
    local($ref_id);
    local($fullname);
    local($ext);

    # Get the complete pathname and the file extension
    $fullname = $attr{'fullname'};
    $ext = (&NameSplit($fullname))[2];

    # Get the reference in the output buffer
    if ($ext eq 'mif') {
        $ref_id = &_MifAdd($fullname, 'figure', 1, *attr);
    }
    elsif ($attr{'mif_figure'}) {
        $ref_id = &_MifAdd($fullname, 'figure', $attr{'mif_figure'}, *attr);
    }
    else {
        $attr{'position'} = 'RunIntoParagraph' if $attr{'wrap_text'};
        $attr{'position'} = 'below' unless $attr{'position'};
        $ref_id = &_MifAddRef($filepath, %attr);
    }

    # Return result
    return $ref_id;
}

#
# >>_Description::
# {{Y:_MifHandlerObject}} handles the 'object' directive.
#
sub _MifHandlerObject {
    local(*outbuffer, $type, %attrs) = @_;
#   local();
    local($fn);
    local($name, $parent);

    # Find the object handler, if any
    $fn = "_MifObjectHandler$type";
    if (defined &$fn) {

        # Get the name and parent
        $name = $attrs{'Name'};
        delete $attrs{'Name'};
        $parent = $attrs{'Parent'};
        delete $attrs{'Parent'};

        # Jump to the routine which handles this object
        &$fn(*outbuffer, $name, $parent, %attrs);
    }
}

#
# >>_Description::
# {{Y:_MifAddToCatalog}} adds an object to a catalog of objects.
# If {{$parent}} and {{$root}} are set and equal, then {{%root_attr}} is
# used instead of retrieving the parent attributes from the catalog.
# This is done to improve performance.
#
sub _MifAddToCatalog {
    local(*catalog, $type, $name, $parent, *attr, *root, *root_attr) = @_;
#   local();
    local(%parent_attr);

    # Get the parent definition, if any
    %parent_attr = ();
    if ($parent ne '') {
        if ($parent eq $root) {
            %parent_attr = %root_attr;
        }
        else {
            %parent_attr = &_MifAttrSplit($catalog{$parent});
        }
        unless (%parent_attr) {
            &AppMsg("warning", "unknown parent '$parent' in definition of mif $type '$name'");
            return;
        }
    }

    # Merge in the new attributes
    @parent_attr{keys %attr} = values %attr;

    # Store the new definition
    $catalog{$name} = &_MifAttrJoin(*parent_attr);

    # Save the root, if necessary
    if ($root eq '' && $parent eq '') {
        $root = $name;
        %root_attr = %attr;
    }
}

#
# >>_Description::
# {{Y:_MifObjectHandlerVariable}} defines 'Variable' objects.
#
sub _MifObjectHandlerVariable {
    local(*outbuffer, $name, $parent, %attr) = @_;
#   local();
    local($value);

    $name = $_MIF_VAR_MAP{$name} if $_MIF_VAR_MAP{$name};
    $value = $attr{'value'};
    if ($name =~ /^MIF_/) {
        return if $name eq 'MIF_TABLE_UNIT';
        return if $name eq 'MIF_TABLE_UNIT_WIDE';
        if ($name eq 'MIF_COVER') {
            $_mif_cover = $value;
        }
        else {
            $name = 'D' . &MiscUpperToMixed($');
            $_mif_ctrls{$name} = $value;
        }
    }
    else {
        $_mif_vars{$name} = $value;
    }
}

#
# >>_Description::
# {{Y:_MifObjectHandlerXref}} defines 'Xref' objects.
#
sub _MifObjectHandlerXref {
    local(*outbuffer, $name, $parent, %attr) = @_;
#   local();

    $_mif_xrefs{$name} = $attr{'value'};
}

#
# >>_Description::
# {{Y:_MifObjectHandlerPara}} defines 'Para' objects,
# i.e. it generates a new paragraph format in the output.
#
sub _MifObjectHandlerPara {
    local(*outbuffer, $name, $parent, %attr) = @_;
#   local();

    &_MifAddToCatalog(*_mif_paras, 'paragraph', $name, $parent, *attr,
      *_mif_pararoot_name, *_mif_pararoot_attr);
}

#
# >>_Description::
# {{Y:_MifObjectHandlerPhrase}} defines 'Phrase' objects,
# i.e. it generates a new font format in the output.
#
sub _MifObjectHandlerPhrase {
    local(*outbuffer, $name, $parent, %attr) = @_;
#   local();

    &_MifAddToCatalog(*_mif_fonts, 'font', $name, $parent, *attr,
      *_mif_fontroot_name, *_mif_fontroot_attr);
}

#
# >>_Description::
# {{Y:_MifObjectHandlerTable}} defines 'Table' objects,
# i.e. it generates a new table format in the output.
# {{tags}} contains the new and base tags separated by a space.
#
sub _MifObjectHandlerTable {
    local(*outbuffer, $name, $parent, %attr) = @_;
#   local();

    &_MifAddToCatalog(*_mif_tbls, 'table', $name, $parent, *attr,
      *_mif_tblroot_name, *_mif_tblroot_attr);
}

#
# >>_Description::
# {{Y:_MifObjectHandlerFrame}} defines 'Frame' objects,
# i.e. it generates a reference frame in the output.
#
sub _MifObjectHandlerFrame {
    local(*outbuffer, $name, $parent, %attr) = @_;
#   local();

    &_MifAddToCatalog(*_mif_frames, 'frame', $name, $parent, *attr,
      *_mif_frameroot_name, *_mif_frameroot_attr);
}

#
# >>_Description::
# {{Y:_MifObjectHandlerList}} defines 'List' objects.
# i.e. it defines the layout of the TOC (Table of Contents), etc.
#
sub _MifObjectHandlerList {
    local(*outbuffer, $name, $parent, %attr) = @_;
#   local();

    &_MifAddToCatalog(*_mif_lists, 'lists', $name, $parent, *attr,
      *_mif_listroot_name, *_mif_listroot_attr);
}

#
# >>_Description::
# {{Y:_MifObjectHandlerIndex}} defines 'Index' objects.
# i.e. it defines the layout of an index
#
sub _MifObjectHandlerIndex {
    local(*outbuffer, $name, $parent, %attr) = @_;
#   local();

    &_MifAddToCatalog(*_mif_indexes, 'indexes', $name, $parent, *attr,
      *_mif_indexroot_name, *_mif_indexroot_attr);
}

#
# >>_Description::
# {{Y:_MifPhraseHandlerChar}} handles the 'char' phrase directive.
#
sub _MifPhraseHandlerChar {
    local(*para, $text, %attr) = @_;
#   local();
    local($char);
    local($hex);

    $char = $_MIF_CHAR{$text};
    if ($text =~ /^\d+/) {
        $hex = sprintf("%x", $text);
        $para .= "  <String `\\x$hex '>\n";
    }
    elsif ($char =~ /^\W/) {
        $para .= "  <String `$char'>\n";
    }
    elsif ($char) {
        $para .= "  <Char $char>\n";
    }
    else {
        &AppMsg("warning", "ignoring unknown character '$text'");
    }

    # Hard returns must be the last thing in a ParaLine
    if ($char eq 'HardReturn' || $text == $_MIF_HARDRETURN_CODE) {
        $para .= " > # end of ParaLine\n" .
            " <ParaLine\n";
    }
}

#
# >>_Description::
# {{Y:_MifPhraseHandlerInline}} handles the 'inline' phrase directive.
#
sub _MifPhraseHandlerInline {
    local(*para, $text, %attr) = @_;
#   local();

    # Build the result
    $para .= $text;
}

#
# >>_Description::
# {{Y:_MifPhraseHandlerImport}} handles the 'import' phrase directive.
#
sub _MifPhraseHandlerImport {
    local(*para, $filepath, %attr) = @_;
#   local();

    # Add the figure to the internal buffers
    $attr{'position'} = 'inline' unless $attr{'position'};
    $ref_id = &_MifAddFigure($filepath, *attr);

    # Add the reference to the paragraph
    $para .= "  <AFrame $ref_id>\n";
}

#
# >>_Description::
# {{Y:_MifPhraseHandlerVariable}} handles the 'variable' phrase directive.
#
sub _MifPhraseHandlerVariable {
    local(*para, $text, %attr) = @_;
#   local();

    $para .= "  <Variable\n" .
             "   <VariableName `$text'>\n" .
             "  > # end of Variable\n";
}

#
# >>_Description::
# {{Y:_MifPhraseHandlerXRef}} handles the 'xref' phrase directive.
#
sub _MifPhraseHandlerXRef {
    local(*para, $para_text, %attr) = @_;
#   local();
    local($format, $text, $file);

    # Get the text and file from the jump attribute.
    $format = $attr{'xref'};
    ($file, $text) = split(/#/, $attr{'jump'}, 2);

    # Assume the Frame file, if any, has a doc extension.
    if ($file ne '') {
        $file = &NameSubExt($file, 'doc');
    }

    # Build the cross-reference
    $para .= "  <XRef\n" .
             "   <XRefName `$format'>\n" .
             "   <XRefSrcText `$text'>\n" .
             "   <XRefSrcFile `$file'>\n" .
             "  > # end of XRef\n";
}

#
# >>_Description::
# {{Y:_MifPhraseHandlerPageNum}} handles the 'pagenum' phrase directive.
#
sub _MifPhraseHandlerPageNum {
    local(*para, $para_text, %attr) = @_;
#   local();

    &_MifPhraseHandlerVariable(*para, 'Current Page #');
}

#
# >>_Description::
# {{Y:_MifPhraseHandlerPageCount}} handles the 'pagecount' phrase directive.
#
sub _MifPhraseHandlerPageCount {
    local(*para, $para_text, %attr) = @_;
#   local();

    &_MifPhraseHandlerVariable(*para, 'Page Count');
}

#
# >>_Description::
# {{Y:_MifPhraseHandlerParaText}} handles the 'paratext' phrase directive.
#
sub _MifPhraseHandlerParaText {
    local(*para, $tags, %attr) = @_;
#   local();

    &_MifRunningHF(*para, 'paratext', $tags);
}

#
# >>_Description::
# {{Y:_MifPhraseHandlerParaNum}} handles the 'paranum' phrase directive.
#
sub _MifPhraseHandlerParaNum {
    local(*para, $tags, %attr) = @_;
#   local();

    &_MifRunningHF(*para, 'paranum', $tags);
}

#
# >>_Description::
# {{Y:_MifPhraseHandlerParaNumOnly}} handles the 'paranumonly' phrase directive.
#
sub _MifPhraseHandlerParaNumOnly {
    local(*para, $tags, %attr) = @_;
#   local();

    &_MifRunningHF(*para, 'paranumonly', $tags);
}

#
# >>_Description::
# {{Y:_MifPhraseHandlerParaShort}} handles the 'parashort' phrase directive.
#
sub _MifPhraseHandlerParaShort {
    local(*para, $tags, %attr) = @_;
#   local();

    &_MifRunningHF(*para, 'marker1');
}

#
# >>_Description::
# {{Y:_MifPhraseHandlerParaLast}} handles the 'paralast' phrase directive.
#
sub _MifPhraseHandlerParaLast {
    local(*para, $tags, %attr) = @_;
#   local();

    &_MifRunningHF(*para, 'paratext', "+,$tags");
}

#
# >>_Description::
# {{Y:_MifRunningHF}} defines and inserts a Running H/F variable.
# {{type}} is one of paratext, paranum, paranumonly,
# marker1 or marker2. For the first 3 of these, {{tags}} is a
# comma separated list of paragraph tags.
#
sub _MifRunningHF {
    local(*para, $type, $tags) = @_;
#   local();
    local($defn);
    local(@tags, $tag, $fmtag);
    local($num);
    local($varname);

    # Build the definition
    if ($tags eq '') {
        $defn = "<\$$type>";
    }
    else {
        # Convert the SDF tag names to Frame ones
        @tags = split(/,/, $tags);
        for $tag (@tags) {
            $fmtag = $SDF_USER'parastyles_to{$tag};
            $tag =  $fmtag if $fmtag ne '';
        }
        $defn = "<\$$type\[" . join(",", @tags) . "]>";
    }

    # If the definition matches an existing running h/f variable, reuse it
    for ($num = 1; $num <= $_mif_runninghf_cnt; $num++) {
        last if $_mif_vars{"Running H/F $num"} eq $defn;
    }

    # If necessary, update the running h/f counter,
    # checking we haven't used them all
    if ($num  > 4) {
        &AppMsg("warning", "ignoring MIF directive '$type' - Running H/F 4 already used");
        return;
    }
    elsif ($num > $_mif_runninghf_cnt) {
        $_mif_runninghf_cnt++;
    }

    # Insert the variable
    $varname = "Running H/F $num";
    $_mif_vars{$varname} = $defn;
    &_MifPhraseHandlerVariable(*para, $varname);
}

#
# >>_Description::
# {{Y:_MifParaAppend}} merges {{para}} into the last paragraph
# in {{@result}}.
# (This is used to workaround Frame putting blank lines between
# each example paragraph when it converts documents to text.)
#
sub _MifParaAppend {
    local(*result, $para) = @_;
#   local();
    local($body_start);

    # find the location of the first ParaLine in the paragraph
    $body_start = index($para, " <ParaLine");

    # append the paragraph
    if ($body_start >= 0) {
        substr($result[$#result], - $_MIF_PARA_END_LEN) = 
          "  <Char HardReturn>\n >\n" . substr($para, $body_start) .
          $_MIF_PARA_END;
    }
    else {
        &AppMsg("failed", "bad paragraph format in '_MifParaAppend'");
    }
}
       
#
# >>_Description::
# {{Y:_MifAdd}} adds an object to the internal lists. These
# lists are merged with the converted text in {{Y:_MifFinalise}}
# to produce the final MIF file. {{id}} can be either:
#
# * a number (the internal object number in the file), or
# * a string (a pattern matched in the text just before the object
# is referenced in the main text flow of the file)
#
sub _MifAdd {
    local($file, $what, $id, *attr) = @_;
    local($ref_id);
    local($ok);
    local(@file);
    local($obj_id, $tag, $tbl_begin, $fmt_id, $fmt_ok);

    # Fetch the file
    ($ok, @file) = &_MifFetchAlbum($file);
    unless ($ok) {
        &AppMsg("warning", "failed to fetch file '$file'");
        return 0;
    }

    # If a pattern is passed as the id, first convert it to an
    # object reference
    if ($id =~ /^\d+$/) {
        $obj_id = $id;
    }
    else {
        $obj_id = &MifIdLookupBySymbol(*file, $_MIF_REF{$what}, $id);
    }

    # Add the object itself & format, if any, onto our stacks
    if ($obj_id) {
        if ($what eq 'table') {
            ($ref_id, $tbl_begin) = &_MifAddObject(*file,
              'Tbl', 'TblID', $obj_id, 'stack', *_mif_table);

            # Assume the table format id is the second attribute
            if ($ref_id) {
                $file[$tbl_begin + 2] =~ /TblTag (.*)\>/;
                $fmt_id = $1;
                $_mif_tblstyle_used{$fmt_id}++;
                ($fmt_ok) = &_MifAddObject(*file, 'TblFormat',
                  'TblTag', $fmt_id, 'byname', *_mif_tbls);
                unless ($fmt_ok) {
                    &AppMsg("warning", "MIF table format clash ($file, $id, $fmt_id)");
                }
            }
        }
        else {
            ($ref_id) = &_MifAddObject(*file,
              'Frame', 'ID', $obj_id, 'stack', *_mif_figure, *attr);
        }
    }

    # Check object was found
    unless ($ref_id) {
        &AppMsg("warning", "mif object '$what $id' not found in file '$file'");
    }

    # Return result
    return $ref_id;
}

#
# >>_Description::
# {{Y:_MifAddRef}} adds a referenced figure to the internal lists. These
# lists are merged with the converted text in {{Y:_MifFinalise}}
# to produce the final MIF file.
# {{%attr}} contains tuning attributes.
#
sub _MifAddRef {
    local($name, %attr) = @_;
    local($ref_id);
    local($fullname);
    local($width, $height);
    local($mif_path);
    local($shape_rect_params);
    local(@frame);

    # Default the height and width, if we can
    $fullname = $attr{'fullname'};
    ($width, $height) = &SdfSizeGraphic($fullname);
    $attr{'width'}  = $width  ? $width  : 20 unless $attr{'width'};
    $attr{'height'} = $height ? $height : 20 unless $attr{'height'};

    # points is the default measurement
    $width = $attr{'width'};
    $height = $attr{'height'};
    $width  .= "pt" if $width  =~ /^[\d\.]+$/;
    $height .= "pt" if $height =~ /^[\d\.]+$/;

    # Convert the name into a MIF device-independent pathname
    #if (! &NameIsAbsolute($name) && $attr{'root'} ne '') {
        #$name = &NameJoin($attr{'root'}, $name);
    #}
    if ($SDF_USER'var{'OPT_TARGET'} eq 'hlp') {
        $mif_path = &_MifPathName($name);
    }
    else {
        $mif_path = &_MifPathName($fullname);
    }

    # Build the Frame body
    $shape_rect_params = "0\" 0\" $width $height";
    @body = (
        "  <ImportObject",
        "   <ImportObFileDI `$mif_path'>",
        "   <ShapeRect $shape_rect_params>",
        "  > # end of ImportObject");

    # Build the frame
    $ref_id = scalar(@_mif_figure) + $_MIF_OBJ_REF_START;
    @frame = &_MifBuildFrame($ref_id, $shape_rect_params, *attr, *body);

    # Add the frame to the internal list
    push(@_mif_figure, join("\n", @frame));

    # Return result
    return $ref_id;
}

#
# >>_Description::
# {{_MifBuildFrame}} build a 'Frame' object, given its id, size, attributes
# and body.
#
sub _MifBuildFrame {
    local($ref_id, $shape_rect_params, *attr, *body) = @_;
    local(@frame);
    local($frametype);

    # Map the attributes to MIF names
    $frametype = $attr{'position'};
    $frametype = 'Below' unless $frametype;
    substr($frametype, 0, 1) =~ tr/a-z/A-Z/;

    # Build the figure frame header
    @frame = (
        " <Frame",
        "  <ID $ref_id>",
        "  <ShapeRect $shape_rect_params>",
        "  <FrameType $frametype>");

    # Add the optional stuff
    if ($attr{'align'}) {
        substr($attr{'align'}, 0, 1) =~ tr/a-z/A-Z/;
        push(@frame, "  <AnchorAlign $attr{'align'}>");
    }
    if ($attr{'clipped'}) {
        push(@frame, "  <Cropped Yes>");
    }
    if ($attr{'floating'}) {
        push(@frame, "  <Float Yes>");
    }
    if ($attr{'bl_offset'}) {
        $attr{'bl_offset'}  .= "pt" if $attr{'bl_offset'}  =~ /^[\d\.]+$/;
        push(@frame, "  <BLOffset $attr{'bl_offset'}>");
    }
    if ($attr{'ns_offset'}) {
        $attr{'ns_offset'}  .= "pt" if $attr{'ns_offset'}  =~ /^[\d\.]+$/;
        push(@frame, "  <NSOffset $attr{'ns_offset'}>");
    }

    # Return result
    return (@frame, @body, " > # end of Frame");
}

#
# >>_Description::
# {{Y:_MifUpdateMainFlow}} adds a reference to the main text flow.
# If {{nested}} is set, the object is nested inside a TectRect
# which is allocated that percentage of the text column height and
# rotated by {{angle}}.
#
sub _MifUpdateMainFlow {
    local(*outbuffer, $what, $ref_id, $title, $wide, $nested, $angle) = @_;
#   local();
    local($tag);
    local(@para);

    # Get the paragraph tag: 'Title' or 'Body'?
    if ($title ne '') {
        $tag = $SDF_USER'parastyles_to{$_MIF_TITLE_TAG{$what}};

        # Escape special characters
        $title =~ s/([\>\\])/\\$1/g;
        $title =~ s/([\t])/\\t/g;
        $title =~ s/(['])/\\q/g;
        $title =~ s/([`])/\\Q/g;
    }
    else {
        $tag = $SDF_USER'parastyles_to{$_MIF_NOTITLE_TAG{$what}};
    }

    # Build the paragraph
    $_mif_parastyle_used{$tag}++;
    @para = (
        "<Para\n" .
        " <PgfTag `$tag'>\n" .
        " <Pgf\n");
    push(@para, "  <PgfPlacementStyle Straddle>\n") if $wide;
    push(@para, "  <PgfAlignment Center>\n") if $angle;
    push(@para,
        " >\n" .
        " <ParaLine\n" .
        "  <String `$title'>\n" .
        "  <$_MIF_REF{$what} $ref_id>\n" .
        " >\n" .
        "> # end of Para");

    # Handle nested objects
    if ($nested ne '') {
        @para = &_MifAddNestedText(*para, $nested, $angle);
    }

    # Add a reference directly into the output
    push(@outbuffer, @para);
}

#
# >>_Description::
# {{Y:_MifAddObject}} adds an object to the nominated internal list.
# {{lookup_id}} is the object reference id (numeric).
# If {{%attr}} is passed and {{how}} is stack, the object
# is assumed to be a figure and the Frame header is built
# from the attributes passed in.
#
sub _MifAddObject {
    local(*source, $type, $id_str, $lookup_id, $how, *where, *attr) = @_;
    local($new_id, $first, $last);
    local(@this_obj, $this_index, $i);
    local($shape_rect_params);
    local(@body);

    # Search for object using lookup_id
    record:
    for ($i = 0; $i < $#source; $i++) {
        if ($first && $source[$i] =~ /\> \# end of $type\s*$/) {
            $last = $i;
            last record;
        }
        if ($source[$i] =~ /\<$type\s*$/ &&
          $source[$i + 1] =~ /\<$id_str $lookup_id\>/) {
            $first = $i;
            $i += 2;
        }
    }
    return 0 unless $last;

    # Save object
    if ($how eq 'stack') {
        $this_index = scalar(@where) + $_MIF_OBJ_REF_START;
        if (%attr) {
            ($shape_rect_params, @body) =
                &_MifRemoveFrameAttrs(@source[$first + 2 .. $last - 1]);
            @this_obj = &_MifBuildFrame($this_index, $shape_rect_params, *attr,
                *body);
        }
        else {
            @this_obj = (" <$type", "  <$id_str $this_index>",
              @source[$first + 2 .. $last]);
        }
        push(@where, join("\n", @this_obj));
    }
    elsif ($how eq 'byname') {
        $this_index = $lookup_id;
        $this_obj = join("\n", @source[$first .. $last]);
        if ($where{$this_index}) {
            if ($where{$this_index} ne $this_obj) {
                $this_index = "";
            }
        }
        else {
            $where{$this_index} = $this_obj;
        }
    }

    # Return result
    return $this_index, $first, $last;
}

#
# >>_Description::
# {{_MifRemoveFrameAttrs}} removes attributes from a Frame object.
#
sub _MifRemoveFrameAttrs {
    local(@frame) = @_;
    local($shape_rect_params, @body);
    local($junk);
    local($index);

    # Copy across the lines except those between ShapeRect and Cropped
    @body = ();
    $junk = 0;
    for ($index = 0; $index <= $#frame; $index++) {
        $line = $frame[$index];
        last if $line =~ /^\s*<Cropped /;

        if ($line =~ /^\s*<ShapeRect\s*([^\>]+)\>/) {
            $shape_rect_params = $1;
            $junk = 1;
        }
        elsif (! $junk) {
            push(@body, $line);
        }
    }
    push(@body, @frame[$index + 1 .. $#frame]);

    # Return result
    return ($shape_rect_params, @body);
}

#
# >>_Description::
# {{Y:_MifAddNestedText}} adds paragraph text as a nested object.
# {{@text}} is the text to add. The new text to add into the main text
# flow is returned. {{nested}} is the percentage of the text column
# to allocate to the object and {{angle}} is the angle.
#
sub _MifAddNestedText {
    local(*text, $nested, $angle) = @_;
    local(@result);
    local($textflow_id);
    local($width, $height, $adj_height);
    local($ref_id);
    local(@frame);
    local($tag);

    # Create the new text flow
    $textflow_id = &_MifAddTextFlow(*text, '', 1);

    # Calculate the width and height of the rotated text column.
    # For simplicity, the width is always the column width.
    # The height is calculated as a percentage of the text column
    # height. We also need an "adjusted height" for the embedded
    # text rectangle, otherwise Frame crops the table border.
    $width = $SDF_USER'var{'DOC_TEXT_WIDTH'};
    if ($nested == 1) {
        $height = $SDF_USER'var{'DOC_TEXT_HEIGHT'};
    }
    elsif ($nested =~ /^(\d+)\%?$/) {
        $height = $SDF_USER'var{'DOC_TEXT_HEIGHT'} * $1 / 100;
    }
    else {
        $height = &SdfPoints($nested);
    }
    $adj_height = $height - 2;

    # Build the rotated text column
    $ref_id = scalar(@_mif_figure) + $_MIF_OBJ_REF_START;
    @frame = (
        " <Frame",
        "  <ID $ref_id>",
        "  <ShapeRect 0\" 0\" ${width}pt ${height}pt>",
        "  <FrameType Below>",
        "  <Float Yes>",
        "  <TextRect",
        "   <ID $textflow_id>");
    push(@frame,
        "   <Angle $angle>") if $angle != 0;
    push(@frame,
        "   <BRect 0\" 0\" ${width}pt ${adj_height}pt>",
        "  > # end of TextRect",
        " > # end of Frame");

    # Add it to the internal buffers
    push(@_mif_figure, join("\n", @frame));

    # Build the new text
    $tag = $SDF_USER'parastyles_to{'N'};
    $_mif_parastyle_used{$tag}++;
    @result = (
        "<Para\n" .
        " <PgfTag `$tag'>\n" .
        " <ParaLine\n" .
        "  <AFrame $ref_id>\n" .
        " >\n" .
        "> # end of Para");

    # return result
    return @result;
}

#
# >>Description::
# {{Y:MifIdLookupBySymbol}} searches in {{@source}}
# for {{symbol}} closely followed by a reference of type {{ref}}.
# If found, the ID of the object is returned. Otherwise, 0 is returned.
#
sub MifIdLookupBySymbol {
    local(*source, $ref, $symbol) = @_;
    local($id);
    local($safe, $i);

    # escape any metacharacters if symbol
    $safe = $symbol;
    $safe =~ s/(\W)/\\\1/g;

    # search
    for ($i = 0; $i < $#source; $i++) {
        if ($source[$i] =~ /\<String\s+\`.*$safe.*\'\>/ &&
          $source[$i + 1] =~ /\<$ref\s+(\d+)\>/) {
            return $1;
        }
    }

    # If reach here, no luck
    return 0;
}

#
# >>_Description::
# {{Y:_MifPathName}} converts a pathname into a MIF device-independent
# pathname.
# (Thanks to Prachin Ranavat for the initial code.)
#
sub _MifPathName {
    local($name) = @_;
    local($mif);
    local($k);
	my ($is_absolute, $os_name);
	my @components = NamePathComponentSplit($name);

    # check if path is absolute
	$is_absolute = &NameIsAbsolute($name);
	$os_name = &NameOS;
	
	SWITCH_OS: {
		$mif = '<r\>', last SWITCH_OS if $os_name eq 'unix' && $is_absolute;
		$mif = '<v\>' . shift @components, last SWITCH_OS if $os_name eq 'mac' && $is_absolute;
		$mif = '<v\>' . shift @components, last SWITCH_OS if $os_name eq 'dos' && $is_absolute;
	}
    foreach $k (@components) {
		next if !$k;
	    if ($k eq '..' || $k eq '::') {
    	    # parent directory in path - replace by <u\>
	        $mif .= "<u\\>";
        }
        else {
	        # directory name in path - replace by <c\>directory_name
	        $mif .= "<c\\>".$k;
    	}
    }

    # Return result
    return ($mif);
}

#
# >>Description::
# {{Y:MifLink}} converts a hypertext link in URL format to a frame one.
# {{mif_ext}} is the extension to use on Frame files in hypertext jumps.
# The default value is {{fvo}}.
#
sub _MifLink {
    local($url, $mif_ext) = @_;
    local($mif_link);
    local($file, $topic);
    local($spec_char);

    # Setup special characters match string
    $spec_char = "\\>\\\\";

    # Default the file extension to fvo, if necessary
    $mif_ext = 'fvo' unless $mif_ext ne '';

    if ($url =~ /^([-\w\/\.]*)#/) {
        ($file, $topic) = ($1, $');
        if ($file ne '') {
            $file =~ s/\.html$//;
            $file .= ".$mif_ext";
        }
        $topic =~ s/([$spec_char])/\\$1/g;
        $mif_link = "gotolink " . ($file ? "$file:$topic" : $topic);
    }
    elsif ($url =~ /^([-\w\/\.]*)$/) {
        $url =~ s/\.html$//;
        $url .= ".$mif_ext";
        $mif_link = "gotopage $url:firstpage";
    }
    else {
        $mif_link = "gotourl $url";
        #$mif_link = "sdf url=$url";    # once TJH fixes fm2html
    }

    # Return result
    return $mif_link;
}

#
# >>_Description::
# {{Y:MifEscapeNewlink}} escapes a newlink.
# (Thanks to Tim Hudson for the code.)
#
sub _MifEscapeNewlink {
    local($link) = @_;
    local($result);
    local($spec_char);

    ##print STDERR "NEWLINK-IN: $link\n";

    # Assign default special characters match string, if necessary
    $spec_char = "\\>\\\\" if $spec_char eq '';

    $link =~ s/([$spec_char])/\\$1/g;

    # escape quotes
    $link =~ s/\'/\\q/g;

    # strip backquotes 
    $link =~ s/\`//g;

    1 while $link =~ s/{{.:([^}]*)}}/$1/e;

    $link =~ s/^\s+//;

    ##print STDERR "NEWLINK-OUT: $link\n";

    return $link;
}

#
# >>Description::
# {{Y:MifNewComponent}} is an event processing routine for
# paragraphs which begin a new component.
#
sub MifNewComponent {
    local($type) = @_;
    local($cname);

    # Save away the component details (so a book can be constructed later)
    $cname = &_MifComponentName($SDF_USER'var{'DOC_BASE'});
    $type = 'chapter' if $type eq '1';
    push(@_mif_component_tbl, "$cname|$type");
    push(@_mif_component_type, "\U$type");

    # Ensure that each component gets placed into its own output file.
    # (stdlib/mif.sdt takes care of the first part, so ignore it)
    if (scalar(@_mif_component_tbl) > 2) {
        &SDF_USER'PrependText(
            "!DOC_COMPONENT_END",
            "!output '-'",
            "!output '$cname'",
            "!define DOC_COMPONENT '$type'",
            "!DOC_COMPONENT_BEGIN");
    }
    else {
        $SDF_USER'var{'DOC_COMPONENT'} = $type;
    }

    # Return the component name (needed for stdlib/mif.sdt)
    return $cname;
}

#
# >>_Description::
# {{Y:_MifComponentName}} generates a name for a component,
# given the basename of the document.
#
sub _MifComponentName {
    local($base) = @_;
    local($cname);

    $_mif_component_cntr++;
    $cname = $SDF_USER'var{'MIF_COMPONENT_PATTERN'};
    $cname = '$b_$n.$o' if $cname eq '';
    $cname =~ s/\$b/$base/g;
    $cname =~ s/\$n/$_mif_component_cntr/;
    $cname =~ s/\$o/$out_ext/;
    return $cname;
}

#
# >>_Description::
# {{Y:_MifBookBuild}} builds a book from information collected
# during the generation of components.
#
sub _MifBookBuild {
    local(*book, $base) = @_;
#   local(@result);
    local(@newbook);
    local(@batch);
    local($added_toc);
    local(@flds, %values, $i);
    local($mif_file, $type);

    # Build a new book table which includes the derived components.
    # As we go, we also:
    # * generate the mif for each derived component
    # * build a set of fmbatch commands which
    #   generate binary documents for each part
    # * collect the set of mif files so we can delete them later.
    @newbook = ($book[0]);
    @batch = ();
    @sdf_book_files = ();
    $added_toc = 0;
    @flds = &TableFields($book[0]);
    for ($i = 1; $i <= $#book; $i++) {
        %values = &TableRecSplit(*flds, $book[$i]);
        $type = $values{'Type'};
        if ($added_toc == 0 && $type ne 'front' && $type ne 'pretoc') {
            if ($SDF_USER'var{'DOC_TOC'}) {
                $mif_file = &_MifBookDerived($base, 'toc', 'Table of Contents');
                &_MifBookAddPart(*newbook, *batch, $mif_file, 'toc');
                push(@sdf_book_files, $mif_file);
            }
            if ($SDF_USER'var{'DOC_LOF'}) {
                $mif_file = &_MifBookDerived($base, 'lof', 'List of Figures');
                &_MifBookAddPart(*newbook, *batch, $mif_file, 'lof');
                push(@sdf_book_files, $mif_file);
            }
            if ($SDF_USER'var{'DOC_LOT'}) {
                $mif_file = &_MifBookDerived($base, 'lot', 'List of Tables');
                &_MifBookAddPart(*newbook, *batch, $mif_file, 'lot');
                push(@sdf_book_files, $mif_file);
            }
            $added_toc = 1;
        }

        # Add this part
        $mif_file = $values{'Part'};
        &_MifBookAddPart(*newbook, *batch, $mif_file, $type);
        push(@sdf_book_files, $mif_file);
    }
    if ($SDF_USER'var{'DOC_IX'}) {
        $mif_file = &_MifBookDerived($base, 'ix', 'Index');
        &_MifBookAddPart(*newbook, *batch, $mif_file, 'ix');
        push(@sdf_book_files, $mif_file);
    }

    # Pass the batch commands to fmbatch
    &_MifRunBatch(*batch, $verbose);

    # Cleanup the MIF for each part
    &SDF_USER'SdfBookClean();

    # Return result
    return &MifBook(*newbook, $SDF_USER'var{'OPT_NUMBER_PER_COMPONENT'});
}

#
# >>_Description::
# {{Y:_MifBookDerived}} creates a derived component for a book.
# {{mainbase}} is the base component (e.g. ug_doc) of the main file.
# {{type}} is the type of derived component (e.g. toc).
# The {{default_title}} is used if the appropriate SDF variable is not set.
# The name of the new file is returned.
#
sub _MifBookDerived {
    local($mainbase, $type, $default_title) = @_;
    local($newfile);
    local($upper_type, $tag, $title);
    local(@sdf_text, @mif_data);

    # Build the sdf
    $upper_type = "\U$type";
    $tag = $upper_type . 'T';
    $title = $SDF_USER'var{"DOC_${upper_type}_TITLE"};
    $title = $default_title if $title eq '';
    @sdf_text = ("$tag:$title");

    # Convert the sdf to mif
    @mif_data = ();
    &_MifAddSection(*mif_data, *sdf_text);
    @mif_data = &_MifFinalise(*mif_data, $upper_type);

    # Output the mif
    $newfile = &NameJoin('', $mainbase . "_$type", $out_ext);
    if (open(DERIVED, ">$newfile")) {
        print DERIVED join("\n", @mif_data), "\n";
    }
    else {
        &AppMsg("warning", "unable to create file '$newfile'");
    }
    close(DERIVED);

    # Return result
    return $newfile;
}

#
# >>_Description::
# {{_MifBookAddPart}} is the common processing required in {{_MifBookBuild}}
# to add a part to a book for each mif file.
#
sub _MifBookAddPart {
    local(*newbook, *batch, $mif_file, $type) = @_;
#   local();
    local($doc_file);

    $doc_file = &NameSubExt($mif_file, 'doc');
    push(@newbook, &TableRecJoin(*flds, 'Part', $doc_file, 'Type', $type));
    push(@batch, "Open \"$mif_file\"");
    push(@batch, "SaveAs d \"$mif_file\" \"$doc_file\"");
    push(@batch, "Quit \"$mif_file\"");
#print STDERR "adding $doc_file,$type.\n";
}

#
# >>_Description::
# {{_MifRunBatch}} executes a set of fmbatch commands ({{@batch}}).
# If {{verbose}} is set, the results are keep in a temporary file.
#
sub _MifRunBatch {
    local(*batch, $verbose) = @_;
#   local();
    local($fmbatch, $tmp_file);

    $fmbatch = "fmbatch -i";
    $tmp_file = "/tmp/sdf$$";
    if (open(FMBATCH, "|$fmbatch > $tmp_file")) {
        printf FMBATCH "%s\n", join("\n", @batch);
    }
    else {
        &AppMsg("error", "failed to pipe data to fmbatch");
    }
    close(FMBATCH);
    unlink($tmp_file) unless $verbose;
}

#
# >>Description::
# {{Y:MifBook}} returns a mif book built from the components given in
# {{@book}}. If {{number_per_component}} is set:
#
# * parts before the first chapter have roman page numbering
# * remaining parts are numbered per section (i.e. 1-1, 1-2, etc.)
#
sub MifBook {
    local(*book, $number_per_component) = @_;
    local(@mif);
    local(@flds, %values, $i);
    local($partfile, $type);
    local($suffix, @tags, %settings);
    local($j);
    local($sectnum, $chapter_cnt, $appendix_cnt);

    # Build the title
    $title = sprintf("<Book 5.0> # Generated by %s %s",
            $app_product_name, $app_product_version);
    @mif = ($title);

    # Add the paragraph catalog so that the PDF table of contents works
    #push(@mif, &_MifParasToText(*_mif_tpl_paras));

    # Process the list of parts
    @flds = &TableFields($book[0]);
    $chapter_cnt = 0;
    $appendix_cnt = 0;
    for ($i = 1; $i <= $#book; $i++) {

        # Get the attributes
        %values = &TableRecSplit(*flds, $book[$i]);
        $partfile = $values{'Part'};
        $type = $values{'Type'};

        # For derived components, get the suffix, list of tags and settings.
        $suffix = '';
        @tags = ();
        %settings = ();
        if ($type eq 'toc') {
            $suffix = 'TOC';
            @tags = ();
            for ($j = 1; $j <= $SDF_USER'var{'DOC_TOC'}; $j++) {
                push(@tags, $SDF_USER'parastyles_to{"H$j"},
                  $SDF_USER'parastyles_to{"A$j"}, $SDF_USER'parastyles_to{"P$j"});
            }
            push(@tags, $SDF_USER'parastyles_to{"LOFT"});
            push(@tags, $SDF_USER'parastyles_to{"LOTT"});
            push(@tags, $SDF_USER'parastyles_to{"IXT"});
        }
        elsif ($type eq 'lof') {
            $suffix = 'LOF';
            @tags = ($SDF_USER'parastyles_to{"FT"});
            $settings{'StartPageSide'} = 'NextAvailableSide';
        }
        elsif ($type eq 'lot') {
            $suffix = 'LOT';
            @tags = ($SDF_USER'parastyles_to{"TT"});
            $settings{'StartPageSide'} = 'NextAvailableSide';
        }
        elsif ($type eq 'ix') {
            $suffix = 'IX';
            @tags = ('Index');
            %settings = ();
        }

        # If requested, number per component once a chapter is found
        if ($number_per_component) {
            if ($type eq 'chapter') {
                $sectnum = ++$chapter_cnt;
            }
            elsif ($type eq 'appendix') {
                $sectnum = sprintf("%c", ord('A') + $appendix_cnt++);
            }
            elsif ($type eq 'ix') {
                $sectnum = "Index";
            }
            elsif (! $_MIF_FRONT_PART{$type}) {
                $sectnum = "\u$type";
            }
            if ($sectnum ne '') {
                # Note: "\\x15 " is FrameMaker's nonbreaking hyphen
                $settings{'PageNumbering'} = 'Restart';
                $settings{'PageNumPrefix'} = "$sectnum\\x15 ";
            }
        }

        # Build result
        push(@mif, &MifBookComponent($partfile, $suffix, *tags, %settings));
    }

    # Add a closing comment (to match output as generated by Frame)
    push(@mif, "# End of Book");

    # Return result
    return @mif;
}

#
# >>Description::
# {{Y:MifBookComponent}} returns a book component object
# for {{file}}. If {{suffix}} is supplied, a derived book
# component is returned which includes derived tags for each
# member in {{@derived}}. The book attributes can be
# changed from the defaults using {{attrs}}. No checking
# is done on {{attrs}} so take care.
#
# >>Limitations::
# {{Y:MifBookComponent}} currently assumes the referenced file will
# be in the same directory as the output. i.e. only the file's
# local name (including extension) is stored.
#
sub MifBookComponent {
    local($file, $suffix, *derived, %attrs) = @_;
    local(@result);
    local(%book_attrs);
    local($dir, $base, $ext, $short_name, $tag);
    local($derive_type);

    # Generate the book attributes to be used
    %book_attrs = %_MIF_DFLT_BOOK_ATTRS;
    @book_attrs{keys %attrs} = values %attrs;

    # Build the header
    ($dir, $base, $ext) = &NameSplit($file);
    $short_name = &NameJoin('', $base, $ext);
    @result = ("<BookComponent ", sprintf(" <FileName `<c\\>%s'>",
      $short_name));

    # Add the derived stuff, if any
    $derive_type = $suffix eq 'IX' ? 'IDX' : $suffix;
    if ($suffix) {
        push(@result, " <FileNameSuffix `$suffix\'>",
          " <DeriveLinks Yes >",
          " <DeriveType $derive_type >");
        for $tag (@derived) {
            push(@result, " <DeriveTag `$tag\'>");
        }
    }

    # Add the attributes
    push(@result,
      sprintf(" <StartPageSide %s >", $book_attrs{'StartPageSide'}),
      sprintf(" <PageNumbering %s >", $book_attrs{'PageNumbering'}),
      sprintf(" <PgfNumbering %s >", $book_attrs{'PgfNumbering'}),
      sprintf(" <PageNumPrefix `%s'>", $book_attrs{'PageNumPrefix'}),
      sprintf(" <PageNumSuffix `%s'>", $book_attrs{'PageNumSuffix'}),
      sprintf(" <DefaultPrint %s >", $book_attrs{'DefaultPrint'}),
      sprintf(" <DefaultApply %s >", $book_attrs{'DefaultApply'}));

    # Add more derived stuff, if applicable.
    # Note that we add this here rather than above
    # to keep the same ordering as Frame uses.
    if ($suffix) {
        push(@result, " <DefaultDerive Yes >");
    }

    # End the object
    push(@result, "> # end of BookComponent");
    
    # Return result
    return @result;
}

# package return value
1;
