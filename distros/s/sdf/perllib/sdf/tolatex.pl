# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     LaTeX Format Driver
#
# >>Copyright::
# Copyright (c) 1997, Ian Clatworthy (ianc@mincom.com).
# You may distribute under the terms specified in the LICENSE file.
#
# >>History::
# -----------------------------------------------------------------------
# Date      Who     Change
# 12-Aug-97 ianc    Initial writing for Apache Documentation Project
# 14-May-96 ianc    SDF 2.000
# -----------------------------------------------------------------------
#
# >>Purpose::
# This library provides an [[SDF_DRIVER]] which generates
# LaTeX files.
#
# >>Description::
#
# >>Limitations::
#
# >>Resources::
#
# >>Implementation::
#

##### Constants #####

# Default right margin
$_LATEX_DEFAULT_MARGIN = 70;

# Mapping of characters
%_LATEX_CHAR = (
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

    # From pod2latex ...

    'amp'	=>	'&',	#   ampersand
    'lt'	=>	'<',	#   left chevron, less-than
    'gt'	=>	'>',	#   right chevron, greater-than
    'quot'	=>	'"',	#   double quote

    "Aacute"	=>	"\\'{A}",	#   capital A, acute accent
    "aacute"	=>	"\\'{a}",	#   small a, acute accent
    "Acirc"	=>	"\\^{A}",	#   capital A, circumflex accent
    "acirc"	=>	"\\^{a}",	#   small a, circumflex accent
    "AElig"	=>	'\\AE',		#   capital AE diphthong (ligature)
    "aelig"	=>	'\\ae',		#   small ae diphthong (ligature)
    "Agrave"	=>	"\\`{A}",	#   capital A, grave accent
    "agrave"	=>	"\\`{a}",	#   small a, grave accent
    "Aring"	=>	'\\u{A}',	#   capital A, ring
    "aring"	=>	'\\u{a}',	#   small a, ring
    "Atilde"	=>	'\\~{A}',	#   capital A, tilde
    "atilde"	=>	'\\~{a}',	#   small a, tilde
    "Auml"	=>	'\\"{A}',	#   capital A, dieresis or umlaut mark
    "auml"	=>	'\\"{a}',	#   small a, dieresis or umlaut mark
    "Ccedil"	=>	'\\c{C}',	#   capital C, cedilla
    "ccedil"	=>	'\\c{c}',	#   small c, cedilla
    "Eacute"	=>	"\\'{E}",	#   capital E, acute accent
    "eacute"	=>	"\\'{e}",	#   small e, acute accent
    "Ecirc"	=>	"\\^{E}",	#   capital E, circumflex accent
    "ecirc"	=>	"\\^{e}",	#   small e, circumflex accent
    "Egrave"	=>	"\\`{E}",	#   capital E, grave accent
    "egrave"	=>	"\\`{e}",	#   small e, grave accent
    "ETH"	=>	'\\OE',		#   capital Eth, Icelandic
    "eth"	=>	'\\oe',		#   small eth, Icelandic
    "Euml"	=>	'\\"{E}',	#   capital E, dieresis or umlaut mark
    "euml"	=>	'\\"{e}',	#   small e, dieresis or umlaut mark
    "Iacute"	=>	"\\'{I}",	#   capital I, acute accent
    "iacute"	=>	"\\'{i}",	#   small i, acute accent
    "Icirc"	=>	"\\^{I}",	#   capital I, circumflex accent
    "icirc"	=>	"\\^{i}",	#   small i, circumflex accent
    "Igrave"	=>	"\\`{I}",	#   capital I, grave accent
    "igrave"	=>	"\\`{i}",	#   small i, grave accent
    "Iuml"	=>	'\\"{I}',	#   capital I, dieresis or umlaut mark
    "iuml"	=>	'\\"{i}',	#   small i, dieresis or umlaut mark
    "Ntilde"	=>	'\\~{N}',	#   capital N, tilde
    "ntilde"	=>	'\\~{n}',	#   small n, tilde
    "Oacute"	=>	"\\'{O}",	#   capital O, acute accent
    "oacute"	=>	"\\'{o}",	#   small o, acute accent
    "Ocirc"	=>	"\\^{O}",	#   capital O, circumflex accent
    "ocirc"	=>	"\\^{o}",	#   small o, circumflex accent
    "Ograve"	=>	"\\`{O}",	#   capital O, grave accent
    "ograve"	=>	"\\`{o}",	#   small o, grave accent
    "Oslash"	=>	"\\O",		#   capital O, slash
    "oslash"	=>	"\\o",		#   small o, slash
    "Otilde"	=>	"\\~{O}",	#   capital O, tilde
    "otilde"	=>	"\\~{o}",	#   small o, tilde
    "Ouml"	=>	'\\"{O}',	#   capital O, dieresis or umlaut mark
    "ouml"	=>	'\\"{o}',	#   small o, dieresis or umlaut mark
    "szlig"	=>	'\\ss',		#   small sharp s, German (sz ligature)
    "THORN"	=>	'\\L',		#   capital THORN, Icelandic
    "thorn"	=>	'\\l',,		#   small thorn, Icelandic
    "Uacute"	=>	"\\'{U}",	#   capital U, acute accent
    "uacute"	=>	"\\'{u}",	#   small u, acute accent
    "Ucirc"	=>	"\\^{U}",	#   capital U, circumflex accent
    "ucirc"	=>	"\\^{u}",	#   small u, circumflex accent
    "Ugrave"	=>	"\\`{U}",	#   capital U, grave accent
    "ugrave"	=>	"\\`{u}",	#   small u, grave accent
    "Uuml"	=>	'\\"{U}',	#   capital U, dieresis or umlaut mark
    "uuml"	=>	'\\"{u}',	#   small u, dieresis or umlaut mark
    "Yacute"	=>	"\\'{Y}",	#   capital Y, acute accent
    "yacute"	=>	"\\'{y}",	#   small y, acute accent
    "yuml"	=>	'\\"{y}',	#   small y, dieresis or umlaut mark
);

# Directive mapping table
%_LATEX_HANDLER = (
    'tuning',           '_LatexHandlerTuning',
    'endtuning',        '_LatexHandlerEndTuning',
    'table',            '_LatexHandlerTable',
    'row',              '_LatexHandlerRow',
    'cell',             '_LatexHandlerCell',
    'endtable',         '_LatexHandlerEndTable',
    'import',           '_LatexHandlerImport',
    'inline',           '_LatexHandlerInline',
    'output',           '_LatexHandlerOutput',
    'object',           '_LatexHandlerObject',
);

# Phrase directive mapping table
%_LATEX_PHRASE_HANDLER = (
    'char',             '_LatexPhraseHandlerChar',
    'import',           '_LatexPhraseHandlerImport',
    'inline',           '_LatexPhraseHandlerInline',
    'variable',         '_LatexPhraseHandlerVariable',
);

# Table states
$_LATEX_INTABLE = 1;
$_LATEX_INROW   = 2;
$_LATEX_INCELL  = 3;

##### Variables #####

# Right margin position
$_latex_margin = $SDF_USER'var{'LATEX_MARGIN'} || $_LATEX_DEFAULT_MARGIN;

# Counters for ordered lists - index is the level
@_latex_list_num = 0;

# Table states and row types
@_latex_tbl_state = ();
@_latex_row_type = ();

# Column number & starting positions for current table
$_latex_col_num = 0;
@_latex_col_posn = ();

# Location of the first line of the current row
$_latex_first_row = 0;

# The current cell text
$_latex_cell_current = '';

##### Routines #####

#
# >>Description::
# {{Y:LatexFormat}} is an SDF driver which outputs plain text files.
#
sub LatexFormat {
    local(*data) = @_;
    local(@result);
    local(@contents);

    # Initialise defaults
    $_latex_margin = $SDF_USER'var{'LATEX_MARGIN'} || $_LATEX_DEFAULT_MARGIN;

    # Format the paragraphs
    @contents = ();
    @result = &_LatexFormatSection(*data, *contents);

    # Turn into final form and return
    return &_LatexFinalise(*result, *contents);
}

#
# >>_Description::
# {{Y:_LatexFormatSection}} formats a set of SDF paragraphs into text.
# If a parameter is passed to contents, then that array is populated
# with a generated Table of Contents.
#
sub _LatexFormatSection {
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
            $directive = $_LATEX_HANDLER{$1};
            if (defined &$directive) {
                &$directive(*result, $para_text, %para_attrs);
            }
            else {
                &AppMsg("warning", "ignoring internal directive '$1' in LATEX driver");
            }
            next;
        }

        # Add the paragraph
        &_LatexParaAdd(*result, $para_tag, $para_text, *para_attrs, $prev_tag,
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
# {{Y:_LatexParaAdd}} adds a paragraph.
#
sub _LatexParaAdd {
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
    &SdfAttrMap(*para_attrs, 'latex', *SDF_USER'paraattrs_to,
      *SDF_USER'paraattrs_map, *SDF_USER'paraattrs_attrs,
      $SDF_USER'parastyles_attrs{$para_tag});

    # Build the Table of Contents as we go
    $toc_jump = '';
    if ($para_tag =~ /^[HAP](\d)$/) {
        $hdg_level = $1;
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
        $para = &_LatexParaText($para_text);
    }

    # If we're in a table, prepend the paragraph onto the current cell
    if (@_latex_tbl_state) {
        if ($para_fmt eq "Line") {
            $_latex_cell_current .= "-" x $_latex_cell_width;
            return;
        }
        $_latex_cell_current .= $para;
        return;
    }

    # Build result
    if ($para_tag eq 'PB') {
        $para = &_LatexElement($para_fmt, $para, %para_attrs);
        &_LatexParaAppend(*result, $para);
    }
    elsif ($in_example && $para_tag eq $prev_tag && !%para_attrs) {
        &_LatexParaAppend(*result, $para);
    }
    else {
        $para = &_LatexElement($para_fmt, $para, %para_attrs);
        push(@result, $para);
    }
}

#
# >>_Description::
# {{Y:_LatexParaText}} converts SDF paragraph text into LATEX.
# 
sub _LatexParaText {
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
            $directive = $_LATEX_PHRASE_HANDLER{$char_tag};
            if (defined &$directive) {
                &$directive(*para, $text, %sect_attrs);
            }
            else {
                &AppMsg("warning", "ignoring special phrase '$1' in LATEX driver");
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
            &AppMsg("warning", "unknown section type '$sect_type' in LATEX driver");
        }
    }

    # Return result
    return $para;
}

#
# >>_Description::
# {{Y:_LatexFinalise}} generates the final LATEX file.
#
sub _LatexFinalise {
    local(*body, *contents) = @_;
#   local(@result);

    # Return result
    return @body;
}

#
# >>_Description::
# {{Y:_LatexElement}} formats a LATEX element from a
# tag, text and set of attributes.
#
sub _LatexElement {
    local($tag, $text, %attr) = @_;
    local($latex);
    local($prefix, $label);
    local($cnt);

    # Handle page breaks
    if ($tag eq 'PB') {
        return "\f";
    }

    # For examples, don't word wrap the lines
    if ($tag eq 'E') {
        $latex =  "$text\n";
    }

    # For lines, output a 'line'
    elsif ($tag eq 'Line') {
        $latex =  ("_" x $_latex_margin) . "\n";
    }

    # For headings, underline the text
    elsif ($tag =~ /^[HAP](\d)/) {
        $char = $1 == 1 ? "=" : "-";
        $latex = "$text\n" . ($char x length($text)) . "\n";
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
            $_latex_list_num[$2] = 1;
        }
        else {
            $cnt = ++$_latex_list_num[$2];
            $label .= substr("$cnt.   ", 0, 5);
        }
        $latex = &MiscTextWrap($label . $text, $_latex_margin, $prefix,
          '', 1) . "\n";
    }

    # Otherwise, format as a plain paragraph
    else {
        $latex = &MiscTextWrap($text, $_latex_margin, '', '', 1) . "\n";
    }

    # Handle the top attribute
    return $para{'top'} ? "\f\n$latex" : $latex;
}

#
# >>_Description::
# {{Y:_LatexParaAppend}} merges {{para}} into the last paragraph
# in {{@result}}. Both paragraphs are assumed to be examples.
#
sub _LatexParaAppend {
    local(*result, $para) = @_;
#   local();

    $result[$#result] .= "$para\n";
}

#
# >>_Description::
# {{Y:_LatexHandlerTuning}} handles the 'tuning' directive.
#
sub _LatexHandlerTuning {
    local(*outbuffer, $style, %attr) = @_;
#   local();

    # do nothing
}

#
# >>_Description::
# {{Y:_LatexHandlerEndTuning}} handles the 'endtuning' directive.
#
sub _LatexHandlerEndTuning {
    local(*outbuffer, $style, %attr) = @_;
#   local();

    # do nothing
}

#
# >>_Description::
# {{Y:_LatexHandlerTable}} handles the 'table' directive.
#
sub _LatexHandlerTable {
    local(*outbuffer, $columns, %attr) = @_;
#   local();
    local($tbl_title);

    # Update the state
    push(@_latex_tbl_state, $_LATEX_INTABLE);
    push(@_latex_row_type, '');

    # Calculate the column positions (rounded)
    @_latex_col_posn = &SdfColPositions($columns, $attr{'format'}, $_latex_margin);

    # Add the title, if any
    $tbl_title = $attr{'title'};
    if ($tbl_title ne '') {
        push(@outbuffer, "$tbl_title\n");
    }
}

#
# >>_Description::
# {{Y:_LatexHandlerRow}} handles the 'row' directive.
#
sub _LatexHandlerRow {
    local(*outbuffer, $text, %attr) = @_;
#   local();
    local($current_state);

    # Finalise the previous row, if any
    $current_state = $_latex_tbl_state[$#_latex_tbl_state];
    unless ($current_state == $_LATEX_INTABLE) {
        &_LatexFinalisePrevRow(*outbuffer, $_latex_row_type[$#_latex_row_type]);
    }

    # Start the new row
    push(@outbuffer, "");
    $_latex_col_num = 0;
    $_latex_first_row = $#outbuffer;

    # Update the state
    $_latex_tbl_state[$#_latex_tbl_state] = $_LATEX_INROW;
    $_latex_row_type[$#_latex_row_type] = $text;
}

#
# >>_Description::
# {{Y:_LatexHandlerCell}} handles the 'cell' directive.
#
sub _LatexHandlerCell {
    local(*outbuffer, $text, %attr) = @_;
#   local();
    local($state);
    local($padding);
    local($tmp);

    # Finalise the old cell, if any
    $state = $_latex_tbl_state[$#_latex_tbl_state];
    if ($state eq $_LATEX_INCELL) {
        &_LatexFinishCell(*outbuffer);
        if ($_latex_col_num > 0) {
            foreach $tmp ($_latex_first_row .. $#outbuffer) {
                $padding = $_latex_col_posn[$_latex_col_num - 1] -
                  length($outbuffer[$tmp]);
                $padding = 1 if ($padding <= 0);
                $outbuffer[$tmp] .= " " x $padding;
            }
        }
    }

    # Update the state
    $_latex_tbl_state[$#_latex_tbl_state] = $_LATEX_INCELL;
    $_latex_cell_margin = ($_latex_col_num>0?$_latex_col_posn[$_latex_col_num-1]:0);
    $_latex_col_num+=$attr{cols};
    if ($_latex_col_num > $#_latex_col_posn + 1) {
        $_latex_cell_width = $_latex_margin - $_latex_cell_margin - 1;
    } else {
        $_latex_cell_width = $_latex_col_posn[$_latex_col_num-1] -
             $_latex_cell_margin - 1;
    }
    %_latex_cell_attrs = %attr;
    $_latex_cell_current = "";
}

#
# >>_Description::
# {{Y:_LatexFinishCell}} adds the cell text to the output
#
sub _LatexFinishCell {
    local(*outbuffer) = @_;
    $_latex_cell_current =~ s/\s+/ /g;
    local @lines = split(/\n/,
        &MiscTextWrap($_latex_cell_current, $_latex_cell_width,"",'',1));
    local $tmp;
    foreach $tmp ($#outbuffer+1..$_latex_first_row+$#lines) {
        push(@outbuffer, " " x $_latex_cell_margin);
    }
    foreach $tmp (0..$#lines) {
        if ($_latex_cell_attrs{'align'} eq "Center") {
            $outbuffer[$_latex_first_row+$tmp] .=
                " " x (($_latex_cell_width - length($lines[$tmp]))/2);
        } elsif ($_latex_cell_attrs{'align'} eq "Right") {
            $outbuffer[$_latex_first_row+$tmp] .=
                " " x ($_latex_cell_width - length($lines[$tmp]));
        }
        $outbuffer[$_latex_first_row+$tmp] .= $lines[$tmp];
    }
    $_latex_cell_current = "";
}

#
# >>_Description::
# {{Y:_LatexHandlerEndTable}} handles the 'endtable' directive.
#
sub _LatexHandlerEndTable {
    local(*outbuffer, $text, %attr) = @_;
#   local();
    local($state);
    local($row_type);

    # Finalise the table
    $state = pop(@_latex_tbl_state);
    $row_type = pop(@_latex_row_type);
    if ($state eq $_LATEX_INCELL) {
        &_LatexFinalisePrevRow(*outbuffer, $row_type);
        $outbuffer[$#outbuffer] .= "\n";
    }
    elsif ($state eq $_LATEX_INROW) {
        &_LatexFinalisePrevRow(*outbuffer, $row_type);
        $outbuffer[$#outbuffer] .= "\n";
    }
}

#
# >>_Description::
# {{Y:_LatexFinalisePrevRow}} finalises the previous row, if any.
#
sub _LatexFinalisePrevRow {
    local(*outbuffer, $row_type) = @_;
#   local();
    local($line_row);
    local($prefix);
    local($tmp);
    local($_);

    &_LatexFinishCell(*outbuffer);
    foreach $tmp ($_latex_first_row..$#outbuffer) {
        $outbuffer[$tmp] =~ s/ *(\n*)$/$1/;
    }

    # If the last row was a heading, underline it
    if ($row_type eq 'Heading') {
        $line_row = "";
        $tmp = 0;
        foreach (@_latex_col_posn) {
            $line_row .= ("."x($_-$tmp-1))." ";
            $tmp = $_;
        }
        push(@outbuffer, $line_row);
    }
}

#
# >>_Description::
# {{Y:_LatexHandlerImport}} handles the import directive.
#
sub _LatexHandlerImport {
    local(*outbuffer, $filepath, %attr) = @_;
#   local();
    local($para);

    # Build the result
    &_LatexPhraseHandlerImport(*para, $filepath, %attr);
    push(@outbuffer, "$para\n");
}

#
# >>_Description::
# {{Y:_LatexHandlerInline}} handles the inline directive.
#
sub _LatexHandlerInline {
    local(*outbuffer, $text, %attr) = @_;
#   local();

    # Check we can handle this format
    my $target = $attr{'target'};
    return unless $target eq 'latex' || $target eq 'text';

    # Build the result
    push(@outbuffer, $text);
}

#
# >>_Description::
# {{Y:_LatexHandlerOutput}} handles the 'output' directive.
#
sub _LatexHandlerOutput {
    local(*outbuffer, $text, %attrs) = @_;
#   local();

    # do nothing
}

#
# >>_Description::
# {{Y:_LatexHandlerObject}} handles the 'object' directive.
#
sub _LatexHandlerObject {
    local(*outbuffer, $text, %attrs) = @_;
#   local();

    # Save the margin, if necessary
    if ($text eq 'Variable' && $attrs{'Name'} eq 'LATEX_MARGIN') {
        $_latex_margin = $attrs{'value'};
    }
}

#
# >>_Description::
# {{Y:_LatexPhraseHandlerChar}} handles the 'char' phrase directive.
#
sub _LatexPhraseHandlerChar {
    local(*para, $text, %attr) = @_;
#   local();

    # Map those we know about it
    if (defined($_LATEX_CHAR{$text})) {
        $para .= $_LATEX_CHAR{$text};
    }
    else {
        $para .= $text;
    }
}

#
# >>_Description::
# {{Y:_LatexPhraseHandlerImport}} handles the 'import' phrase directive.
#
sub _LatexPhraseHandlerImport {
    local(*para, $filepath, %attr) = @_;
#   local();
    local($name, $value);

    $para .= "** Unable to import figure $filepath **";
}

#
# >>_Description::
# {{Y:_LatexPhraseHandlerInline}} handles the 'inline' phrase directive.
#
sub _LatexPhraseHandlerInline {
    local(*para, $text, %attr) = @_;
#   local();

    # Build the result
    $para .= $text;
}

#
# >>_Description::
# {{Y:_LatexPhraseHandlerVariable}} handles the 'variable' phrase directive.
#
sub _LatexPhraseHandlerVariable {
    local(*para, $text, %attr) = @_;
#   local();

    # do nothing
}

# package return value
1;
