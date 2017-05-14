# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     Text Format Driver
#
# >>Copyright::
# Copyright (c) 1992-1996, Ian Clatworthy (ianc@mincom.com).
# You may distribute under the terms specified in the LICENSE file.
#
# >>History::
# -----------------------------------------------------------------------
# Date      Who     Change
# 01-May-97 ianc    Applied patches from Tim MacKenzie
# 14-May-96 ianc    SDF 2.000
# -----------------------------------------------------------------------
#
# >>Purpose::
# This library provides an [[SDF_DRIVER]] which generates
# plain text files.
#
# >>Description::
#
# >>Limitations::
# All headings are output as plain. i.e. without numbering.
#
# A table of contents is not supported yet.
#
# Word wrapping is not applied to example paragraphs.
#
# Multi-line cells in tables (including nested tables) do not work.

# >>Resources::
#
# >>Implementation::
#

##### Constants #####

# Default right margin
$_TXT_DEFAULT_MARGIN = 70;

# Mapping of characters
%_TXT_CHAR = (
    'bullet',       '.',
    'c',            '(c)',
    'cent',         'c',
    'dagger',       '^',
    'doubledagger', '#',
    'emdash',       '-',
    'endash',       '-',
    'emspace',      ' ',
    'enspace',      ' ',
    'lbrace',       '{',
    'lbracket',     '[',
    'nbdash',       '-',
    'nbspace',      ' ',
    'nl',           "\n",
    'pound',        'L',
    'r',            '(r)',
    'rbrace',       '}',
    'rbracket',     ']',
    'tab',          "\t",
    'tm',           '(tm) ',
    'yen',          'y',

    # From Pod::Text.pm ...

    'amp'       =>      '&',    #   ampersand
    'lt'        =>      '<',    #   left chevron, less-than
    'gt'        =>      '>',    #   right chevron, greater-than
    'quot'      =>      '"',    #   double quote

    "Aacute"    =>      "\xC1", #   capital A, acute accent
    "aacute"    =>      "\xE1", #   small a, acute accent
    "Acirc"     =>      "\xC2", #   capital A, circumflex accent
    "acirc"     =>      "\xE2", #   small a, circumflex accent
    "AElig"     =>      "\xC6", #   capital AE diphthong (ligature)
    "aelig"     =>      "\xE6", #   small ae diphthong (ligature)
    "Agrave"    =>      "\xC0", #   capital A, grave accent
    "agrave"    =>      "\xE0", #   small a, grave accent
    "Aring"     =>      "\xC5", #   capital A, ring
    "aring"     =>      "\xE5", #   small a, ring
    "Atilde"    =>      "\xC3", #   capital A, tilde
    "atilde"    =>      "\xE3", #   small a, tilde
    "Auml"      =>      "\xC4", #   capital A, dieresis or umlaut mark
    "auml"      =>      "\xE4", #   small a, dieresis or umlaut mark
    "Ccedil"    =>      "\xC7", #   capital C, cedilla
    "ccedil"    =>      "\xE7", #   small c, cedilla
    "Eacute"    =>      "\xC9", #   capital E, acute accent
    "eacute"    =>      "\xE9", #   small e, acute accent
    "Ecirc"     =>      "\xCA", #   capital E, circumflex accent
    "ecirc"     =>      "\xEA", #   small e, circumflex accent
    "Egrave"    =>      "\xC8", #   capital E, grave accent
    "egrave"    =>      "\xE8", #   small e, grave accent
    "ETH"       =>      "\xD0", #   capital Eth, Icelandic
    "eth"       =>      "\xF0", #   small eth, Icelandic
    "Euml"      =>      "\xCB", #   capital E, dieresis or umlaut mark
    "euml"      =>      "\xEB", #   small e, dieresis or umlaut mark
    "Iacute"    =>      "\xCD", #   capital I, acute accent
    "iacute"    =>      "\xED", #   small i, acute accent
    "Icirc"     =>      "\xCE", #   capital I, circumflex accent
    "icirc"     =>      "\xEE", #   small i, circumflex accent
    "Igrave"    =>      "\xCD", #   capital I, grave accent
    "igrave"    =>      "\xED", #   small i, grave accent
    "Iuml"      =>      "\xCF", #   capital I, dieresis or umlaut mark
    "iuml"      =>      "\xEF", #   small i, dieresis or umlaut mark
    "Ntilde"    =>      "\xD1", #   capital N, tilde
    "ntilde"    =>      "\xF1", #   small n, tilde
    "Oacute"    =>      "\xD3", #   capital O, acute accent
    "oacute"    =>      "\xF3", #   small o, acute accent
    "Ocirc"     =>      "\xD4", #   capital O, circumflex accent
    "ocirc"     =>      "\xF4", #   small o, circumflex accent
    "Ograve"    =>      "\xD2", #   capital O, grave accent
    "ograve"    =>      "\xF2", #   small o, grave accent
    "Oslash"    =>      "\xD8", #   capital O, slash
    "oslash"    =>      "\xF8", #   small o, slash
    "Otilde"    =>      "\xD5", #   capital O, tilde
    "otilde"    =>      "\xF5", #   small o, tilde
    "Ouml"      =>      "\xD6", #   capital O, dieresis or umlaut mark
    "ouml"      =>      "\xF6", #   small o, dieresis or umlaut mark
    "szlig"     =>      "\xDF", #   small sharp s, German (sz ligature)
    "THORN"     =>      "\xDE", #   capital THORN, Icelandic
    "thorn"     =>      "\xFE", #   small thorn, Icelandic
    "Uacute"    =>      "\xDA", #   capital U, acute accent
    "uacute"    =>      "\xFA", #   small u, acute accent
    "Ucirc"     =>      "\xDB", #   capital U, circumflex accent
    "ucirc"     =>      "\xFB", #   small u, circumflex accent
    "Ugrave"    =>      "\xD9", #   capital U, grave accent
    "ugrave"    =>      "\xF9", #   small u, grave accent
    "Uuml"      =>      "\xDC", #   capital U, dieresis or umlaut mark
    "uuml"      =>      "\xFC", #   small u, dieresis or umlaut mark
    "Yacute"    =>      "\xDD", #   capital Y, acute accent
    "yacute"    =>      "\xFD", #   small y, acute accent
    "yuml"      =>      "\xFF", #   small y, dieresis or umlaut mark

    "lchevron"  =>      "\xAB", #   left chevron (double less than)
    "rchevron"  =>      "\xBB", #   right chevron (double greater than)
);

# Directive mapping table
%_TXT_HANDLER = (
    'tuning',         '_TxtHandlerTuning',
    'endtuning',      '_TxtHandlerEndTuning',
    'table',            '_TxtHandlerTable',
    'row',              '_TxtHandlerRow',
    'cell',             '_TxtHandlerCell',
    'endtable',         '_TxtHandlerEndTable',
    'import',           '_TxtHandlerImport',
    'inline',           '_TxtHandlerInline',
    'output',           '_TxtHandlerOutput',
    'object',           '_TxtHandlerObject',
);

# Phrase directive mapping table
%_TXT_PHRASE_HANDLER = (
    'char',             '_TxtPhraseHandlerChar',
    'import',           '_TxtPhraseHandlerImport',
    'inline',           '_TxtPhraseHandlerInline',
    'variable',         '_TxtPhraseHandlerVariable',
);

# Table states
$_TXT_INTABLE = 1;
$_TXT_INROW   = 2;
$_TXT_INCELL  = 3;

##### Variables #####

# Right margin position
$_txt_margin = $SDF_USER'var{'TXT_MARGIN'} || $_TXT_DEFAULT_MARGIN;

# Counters for ordered lists - index is the level
@_txt_list_num = 0;

# Table states and row types
@_txt_tbl_state = ();
@_txt_row_type = ();

# Column number & starting positions for current table
$_txt_col_num = 0;
@_txt_col_posn = ();

# Location of the first line of the current row
$_txt_first_row = 0;

# The current cell text
$_txt_cell_current = '';

##### Routines #####

#
# >>Description::
# {{Y:TxtFormat}} is an SDF driver which outputs plain text files.
#
sub TxtFormat {
    local(*data) = @_;
    local(@result);
    local(@contents);

    # Initialise defaults
    $_txt_margin = $SDF_USER'var{'TXT_MARGIN'} || $_TXT_DEFAULT_MARGIN;

    # Format the paragraphs
    @contents = ();
    @result = &_TxtFormatSection(*data, *contents);

    # Turn into final form and return
    return &_TxtFinalise(*result, *contents);
}

#
# >>_Description::
# {{Y:_TxtFormatSection}} formats a set of SDF paragraphs into text.
# If a parameter is passed to contents, then that array is populated
# with a generated Table of Contents.
#
sub _TxtFormatSection {
    local(*data, *contents) = @_;
    local(@result);
    local($prev_tag, $prev_indent);
    local($para_tag, $para_text, %para_attrs);
    local($directive);

    # Process the paragraphs
    @result = ();
    $prev_tag = '';
    $prev_indent = '';
    while (($para_text, $para_tag, %para_attrs) = &SdfNextPara(*data)) {

        # handle directives
        if ($para_tag =~ /^__(\w+)$/) {
            $directive = $_TXT_HANDLER{$1};
            if (defined &$directive) {
                &$directive(*result, $para_text, %para_attrs);
            }
            else {
                &AppMsg("warning", "ignoring internal directive '$1' in TXT driver");
            }
            next;
        }

        # Add the paragraph
        &_TxtParaAdd(*result, $para_tag, $para_text, *para_attrs, $prev_tag,
          $prev_indent, *contents);
    }

    # Do this stuff before starting next loop iteration
    continue {
        unless ($para_tag eq 'PB') {
            $prev_tag = $para_tag;
            $prev_indent = $para_attrs{'in'};
        }
    }

    # Return result
    return @result;
}
       
#
# >>_Description::
# {{Y:_TxtParaAdd}} adds a paragraph.
#
sub _TxtParaAdd {
    local(*result, $para_tag, $para_text, *para_attrs, $prev_tag, $prev_indent, *contents) = @_;
#   local();
    local($in_example);
    local($para_fmt);
    local($para_override);
    local($para);
    local($hdg_level);
    local($toc_jump);
    local($label);

    # Set the example flag
    $in_example = $SDF_USER'parastyles_category{$para_tag} eq 'example';

    # Enumerated lists are the same as list paragraphs at the previous level
    if ($para_tag =~ /^LI(\d)$/) {
        $para_tag = $1 > 1 ? "L" . ($1 - 1) : 'N';
    }

    # Get the target format name
    $para_fmt = $SDF_USER'parastyles_to{$para_tag};
    $para_fmt = $para_tag if $para_fmt eq '';

    # Map the attributes
    &SdfAttrMap(*para_attrs, 'txt', *SDF_USER'paraattrs_to,
      *SDF_USER'paraattrs_map, *SDF_USER'paraattrs_attrs,
      $SDF_USER'parastyles_attrs{$para_tag});

    # Build the Table of Contents as we go
    $toc_jump = '';
    if ($para_tag =~ /^([HAP])(\d)$/) {
        $hdg_level = $2;
        $para_text = &SdfHeadingPrefix($1, $2) . $para_text;
        if ($hdg_level <= $SDF_USER'var{'DOC_TOC'} && !$para_attrs{'notoc'}) {

            # Build a plain list in SDF
            $toc_jump = $para_attrs{'id'};
            $toc_jump = "HDR" . ($#contents + 1) if $toc_jump eq '';
            push(@contents, "L${hdg_level}[jump='#$toc_jump']$para_text");
        }
    }

    # Handle lists (is this needed for text format?)
    elsif ($para_tag =~ /^(L[FUN]?)(\d)$/) {
        $para_attrs{'in'} = $2;
    }

    # Prepend the label, if any (replacing tabs with spaces)
    $label = $para_attrs{'label'};
    $label = 'Note: ' if ($para_tag eq 'Note' || $para_tag eq 'NB') &&
             $label eq '';
    $label =~ s/\\t/ /g;
    $para_text = "{{2:$label}}$para_text" if $label ne '';

    # Indent examples, if necessary
    if ($in_example && $para_attrs{'in'}) {
        $para_text = " " x ($para_attrs{'in'} * 5) . $para_text;
        delete $para_attrs{'in'};
    }

    # Format the paragraph body
    if ($para_attrs{'verbatim'}) {
        $para = $para_text;
        delete $para_attrs{'verbatim'};
    }
    else {
        $para = &_TxtParaText($para_text);
    }

    # If we're in a table, prepend the paragraph onto the current cell
    if (@_txt_tbl_state) {
        if ($para_fmt eq "Line") {
            $_txt_cell_current .= "-" x $_txt_cell_width;
            return;
        }
        $_txt_cell_current .= $para;
        return;
    }

    # Build result
    if ($para_tag eq 'PB') {
        $para = &_TxtElement($para_fmt, $para, %para_attrs);
        &_TxtParaAppend(*result, $para);
    }
    elsif ($in_example && $para_tag eq $prev_tag) {
        &_TxtParaAppend(*result, $para);
    }
    else {
        $para = &_TxtElement($para_fmt, $para, %para_attrs);
        push(@result, $para);
    }
}

#
# >>_Description::
# {{Y:_TxtParaText}} converts SDF paragraph text into TXT.
# 
sub _TxtParaText {
    local($para_text) = @_;
    local($para);
    local($state);
    local($sect_type, $char_tag, $text, %sect_attrs);
    local($added_anchors);
    local(@char_fonts);
    local($char_font);
    local($directive);

    # Process the text
    $para = '';
    $state = 0;
    while (($sect_type, $text, $char_tag, %sect_attrs) =
      &SdfNextSection(*para_text, *state)) {
#print "char_tag:$char_tag.\n";

        # Build the paragraph
        if ($sect_type eq 'special') {
            $directive = $_TXT_PHRASE_HANDLER{$char_tag};
            if (defined &$directive) {
                &$directive(*para, $text, %sect_attrs);
            }
            else {
                &AppMsg("warning", "ignoring special phrase '$1' in TXT driver");
            }
        }

        elsif ($sect_type eq 'string') {
            $para .= $text;
        }

        elsif ($sect_type eq 'phrase') {
            ($text) = &SDF_USER'ExpandLink($text) if $char_tag eq 'L';
            $para .= $text;
        }

        elsif ($sect_type eq 'phrase_end') {
            # do nothing
        }

        else {
            &AppMsg("warning", "unknown section type '$sect_type' in TXT driver");
        }
    }

    # Return result
    return $para;
}

#
# >>_Description::
# {{Y:_TxtFinalise}} generates the final TXT file.
#
sub _TxtFinalise {
    local(*body, *contents) = @_;
#   local(@result);

    # Return result
    return @body;
}

#
# >>_Description::
# {{Y:_TxtElement}} formats a TXT element from a
# tag, text and set of attributes.
#
sub _TxtElement {
    local($tag, $text, %attr) = @_;
    local($txt);
    local($prefix, $label);
    local($cnt);

    # Handle page breaks
    if ($tag eq 'PB') {
        return "\f";
    }

    # For examples, don't word wrap the lines
    if ($tag eq 'E') {
        $txt =  "$text\n";
    }

    # For lines, output a 'line'
    elsif ($tag eq 'Line') {
        $txt =  ("_" x $_txt_margin) . "\n";
    }

    # For headings, underline the text unless requested not to
    elsif ($tag =~ /^[HAP](\d)/) {
        $txt = "$text\n";
        unless ($SDF_USER'var{'TXT_HDG_UL_OFF'}){
            $char = $1 == 1 ? "=" : "-";
            $txt .= ($char x length($text)) . "\n";
        }
    }

    # For list items, add the necessary "label"
    elsif ($tag =~ /^(L[FUN]?)(\d)$/) {
        $prefix = " " x ($2 * 5);
        $label  = " " x (($2 - 1) * 5);
        if ($1 eq 'LU') {
            $label .= "o    ";
        }
        elsif ($1 eq 'L') {
            $label .= "     ";
        }
        elsif ($1 eq 'LF') {
            $label .= "1.   ";
            $_txt_list_num[$2] = 1;
        }
        else {
            $cnt = ++$_txt_list_num[$2];
            $label .= substr("$cnt.   ", 0, 5);
        }
        $txt = &MiscTextWrap($label . $text, $_txt_margin, $prefix,
          '', 1) . "\n";
    }

    # Otherwise, format as a plain paragraph
    else {
        $txt = &MiscTextWrap($text, $_txt_margin, '', '', 1) . "\n";
    }

    # Handle the top attribute
    return $para{'top'} ? "\f\n$txt" : $txt;
}

#
# >>_Description::
# {{Y:_TxtParaAppend}} merges {{para}} into the last paragraph
# in {{@result}}. Both paragraphs are assumed to be examples.
#
sub _TxtParaAppend {
    local(*result, $para) = @_;
#   local();

    $result[$#result] .= "$para\n";
}

#
# >>_Description::
# {{Y:_TxtHandlerTuning}} handles the 'tuning' directive.
#
sub _TxtHandlerTuning {
    local(*outbuffer, $style, %attr) = @_;
#   local();

    # do nothing
}

#
# >>_Description::
# {{Y:_TxtHandlerEndTuning}} handles the 'endtuning' directive.
#
sub _TxtHandlerEndTuning {
    local(*outbuffer, $style, %attr) = @_;
#   local();

    # do nothing
}

#
# >>_Description::
# {{Y:_TxtHandlerTable}} handles the 'table' directive.
#
sub _TxtHandlerTable {
    local(*outbuffer, $columns, %attr) = @_;
#   local();
    local($tbl_title);

    # Update the state
    push(@_txt_tbl_state, $_TXT_INTABLE);
    push(@_txt_row_type, '');

    # Calculate the column positions (rounded)
    @_txt_col_posn = &SdfColPositions($columns, $attr{'format'}, $_txt_margin);

    # Add the title, if any
    $tbl_title = $attr{'title'};
    if ($tbl_title ne '') {
        push(@outbuffer, "$tbl_title\n");
    }
}

#
# >>_Description::
# {{Y:_TxtHandlerRow}} handles the 'row' directive.
#
sub _TxtHandlerRow {
    local(*outbuffer, $text, %attr) = @_;
#   local();
    local($current_state);

    # Finalise the previous row, if any
    $current_state = $_txt_tbl_state[$#_txt_tbl_state];
    unless ($current_state == $_TXT_INTABLE) {
        &_TxtFinalisePrevRow(*outbuffer, $_txt_row_type[$#_txt_row_type]);
    }

    # Start the new row
    push(@outbuffer, "");
    $_txt_col_num = 0;
    $_txt_first_row = $#outbuffer;

    # Update the state
    $_txt_tbl_state[$#_txt_tbl_state] = $_TXT_INROW;
    $_txt_row_type[$#_txt_row_type] = $text;
}

#
# >>_Description::
# {{Y:_TxtHandlerCell}} handles the 'cell' directive.
#
sub _TxtHandlerCell {
    local(*outbuffer, $text, %attr) = @_;
#   local();
    local($state);
    local($padding);
    local($tmp);

    # Finalise the old cell, if any
    $state = $_txt_tbl_state[$#_txt_tbl_state];
    if ($state eq $_TXT_INCELL) {
        &_TxtFinishCell(*outbuffer);
        if ($_txt_col_num > 0) {
            foreach $tmp ($_txt_first_row .. $#outbuffer) {
                $padding = $_txt_col_posn[$_txt_col_num - 1] -
                  length($outbuffer[$tmp]);
                $padding = 1 if ($padding <= 0);
                $outbuffer[$tmp] .= " " x $padding;
            }
        }
    }

    # Update the state
    $_txt_tbl_state[$#_txt_tbl_state] = $_TXT_INCELL;
    $_txt_cell_margin = ($_txt_col_num>0?$_txt_col_posn[$_txt_col_num-1]:0);
    $_txt_col_num+=$attr{cols};
    if ($_txt_col_num > $#_txt_col_posn + 1) {
        $_txt_cell_width = $_txt_margin - $_txt_cell_margin - 1;
    } else {
        $_txt_cell_width = $_txt_col_posn[$_txt_col_num-1] -
             $_txt_cell_margin - 1;
    }
    %_txt_cell_attrs = %attr;
    $_txt_cell_current = "";
}

#
# >>_Description::
# {{Y:_TxtFinishCell}} adds the cell text to the output
#
sub _TxtFinishCell {
    local(*outbuffer) = @_;
    $_txt_cell_current =~ s/\s+/ /g;
    local @lines = split(/\n/,
        &MiscTextWrap($_txt_cell_current, $_txt_cell_width,"",'',1));
    local $tmp;
    foreach $tmp ($#outbuffer+1..$_txt_first_row+$#lines) {
        push(@outbuffer, " " x $_txt_cell_margin);
    }
    foreach $tmp (0..$#lines) {
        if ($_txt_cell_attrs{'align'} eq "Center") {
            $outbuffer[$_txt_first_row+$tmp] .=
                " " x (($_txt_cell_width - length($lines[$tmp]))/2);
        } elsif ($_txt_cell_attrs{'align'} eq "Right") {
            $outbuffer[$_txt_first_row+$tmp] .=
                " " x ($_txt_cell_width - length($lines[$tmp]));
        }
        $outbuffer[$_txt_first_row+$tmp] .= $lines[$tmp];
    }
    $_txt_cell_current = "";
}

#
# >>_Description::
# {{Y:_TxtHandlerEndTable}} handles the 'endtable' directive.
#
sub _TxtHandlerEndTable {
    local(*outbuffer, $text, %attr) = @_;
#   local();
    local($state);
    local($row_type);

    # Finalise the table
    $state = pop(@_txt_tbl_state);
    $row_type = pop(@_txt_row_type);
    if ($state eq $_TXT_INCELL) {
        &_TxtFinalisePrevRow(*outbuffer, $row_type);
        $outbuffer[$#outbuffer] .= "\n";
    }
    elsif ($state eq $_TXT_INROW) {
        &_TxtFinalisePrevRow(*outbuffer, $row_type);
        $outbuffer[$#outbuffer] .= "\n";
    }
}

#
# >>_Description::
# {{Y:_TxtFinalisePrevRow}} finalises the previous row, if any.
#
sub _TxtFinalisePrevRow {
    local(*outbuffer, $row_type) = @_;
#   local();
    local($line_row);
    local($prefix);
    local($tmp);
    local($_);

    &_TxtFinishCell(*outbuffer);
    foreach $tmp ($_txt_first_row..$#outbuffer) {
        $outbuffer[$tmp] =~ s/ *(\n*)$/$1/;
    }

    # If the last row was a heading, underline it
    if ($row_type eq 'Heading') {
        $line_row = "";
        $tmp = 0;
        foreach (@_txt_col_posn) {
            $line_row .= ("."x($_-$tmp-1))." ";
            $tmp = $_;
        }
        push(@outbuffer, $line_row);
    }
}

#
# >>_Description::
# {{Y:_TxtHandlerImport}} handles the import directive.
#
sub _TxtHandlerImport {
    local(*outbuffer, $filepath, %attr) = @_;
#   local();
    local($para);

    # Build the result
    &_TxtPhraseHandlerImport(*para, $filepath, %attr);
    push(@outbuffer, "$para\n");
}

#
# >>_Description::
# {{Y:_TxtHandlerInline}} handles the inline directive.
#
sub _TxtHandlerInline {
    local(*outbuffer, $text, %attr) = @_;
#   local();

    # Check we can handle this format
    my $target = $attr{'target'};
    return unless $target eq 'txt' || $target eq 'text';

    # Build the result
    push(@outbuffer, $text);
}

#
# >>_Description::
# {{Y:_TxtHandlerOutput}} handles the 'output' directive.
#
sub _TxtHandlerOutput {
    local(*outbuffer, $text, %attrs) = @_;
#   local();

    # do nothing
}

#
# >>_Description::
# {{Y:_TxtHandlerObject}} handles the 'object' directive.
#
sub _TxtHandlerObject {
    local(*outbuffer, $text, %attrs) = @_;
#   local();

    # Save the margin, if necessary
    if ($text eq 'Variable' && $attrs{'Name'} eq 'TXT_MARGIN') {
        $_txt_margin = $attrs{'value'};
    }
}

#
# >>_Description::
# {{Y:_TxtPhraseHandlerChar}} handles the 'char' phrase directive.
#
sub _TxtPhraseHandlerChar {
    local(*para, $text, %attr) = @_;
#   local();

    # Map those we know about it
    if (defined($_TXT_CHAR{$text})) {
        $para .= $_TXT_CHAR{$text};
    }
    else {
        $para .= $text;
    }
}

#
# >>_Description::
# {{Y:_TxtPhraseHandlerImport}} handles the 'import' phrase directive.
#
sub _TxtPhraseHandlerImport {
    local(*para, $filepath, %attr) = @_;
#   local();
    local($name, $value);

    $para .= "** Unable to import figure $filepath **";
}

#
# >>_Description::
# {{Y:_TxtPhraseHandlerInline}} handles the 'inline' phrase directive.
#
sub _TxtPhraseHandlerInline {
    local(*para, $text, %attr) = @_;
#   local();

    # Build the result
    $para .= $text;
}

#
# >>_Description::
# {{Y:_TxtPhraseHandlerVariable}} handles the 'variable' phrase directive.
#
sub _TxtPhraseHandlerVariable {
    local(*para, $text, %attr) = @_;
#   local();

    # do nothing
}

# package return value
1;
