# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     POD Format Driver
#
# >>Copyright::
# Copyright (c) 1992-1996, Ian Clatworthy (ianc@mincom.com).
# You may distribute under the terms specified in the LICENSE file.
#
# >>History::
# -----------------------------------------------------------------------
# Date      Who     Change
# 10-May-96 ianc    SDF 2.000
# -----------------------------------------------------------------------
#
# >>Purpose::
# This library provides an [[SDF_DRIVER]] which generates
# [[POD]] files.
#
# >>Description::
#
# >>Limitations::
# SDF features which do not yet have a POD equivalent generally do not
# work, although some features (e.g. simple tables) are emulated with
# varying degrees of success.
#
# Multi-line cells in tables (including nested tables) do not work.
#
# >>Resources::
#
# >>Implementation::
#

##### Constants #####

# Default right margin (used for table wrapping)
$_POD_DEFAULT_MARGIN = 70;

# Mapping of characters
%_POD_CHAR = (
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
);

# Directive mapping table
%_POD_HANDLER = (
    'tuning',         '_PodHandlerTuning',
    'endtuning',      '_PodHandlerEndTuning',
    'table',            '_PodHandlerTable',
    'row',              '_PodHandlerRow',
    'cell',             '_PodHandlerCell',
    'endtable',         '_PodHandlerEndTable',
    'import',           '_PodHandlerImport',
    'inline',           '_PodHandlerInline',
    'output',           '_PodHandlerOutput',
    'object',           '_PodHandlerObject',
);

# Phrase directive mapping table
%_POD_PHRASE_HANDLER = (
    'char',             '_PodPhraseHandlerChar',
    'import',           '_PodPhraseHandlerImport',
    'inline',           '_PodPhraseHandlerInline',
    'variable',         '_PodPhraseHandlerVariable',
);

# Table states
$_POD_INTABLE = 1;
$_POD_INROW   = 2;
$_POD_INCELL  = 3;

##### Variables #####

# Right margin position
$_pod_margin = $_POD_DEFAULT_MARGIN;

# Counter for ordered lists
$_pod_list_num = 0;

# Table states
@_pod_tbl_state = ();

# Column number & starting positions for current table
$_pod_col_num = 0;
@_pod_col_posn = ();

# Flag to indicate current paragraph is an example
$_pod_in_example = 0;

# Lookup table for list types at each indent level
@_pod_list_type = ();

##### Routines #####

#
# >>Description::
# {{Y:PodFormat}} is an SDF driver which outputs POD.
#
sub PodFormat {
    local(*data) = @_;
    local(@result);
    local(@contents);

    # Init things
    $_pod_list_num = 0;
    @_pod_tbl_state = ();
    $_pod_col_num = 0;
    @_pod_col_posn = ();
    $_pod_in_example = 0;
    @_pod_list_type = ();

    # Format the paragraphs
    @contents = ();
    @result = &_PodFormatSection(*data, *contents);

    # Turn into final form and return
    return &_PodFinalise(*result, *contents);
}

#
# >>_Description::
# {{Y:_PodFormatSection}} formats a set of SDF paragraphs into POD.
# If a parameter is passed to contents, then that array is populated
# with a generated Table of Contents.
#
sub _PodFormatSection {
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

        # Set the indent for Item paragraphs
        #$para_attrs{'in'} = 1 if $para_tag eq 'Item';

        # handle directives
        if ($para_tag =~ /^__(\w+)$/) {
            $directive = $_POD_HANDLER{$1};
            if (defined &$directive) {
                &$directive(*result, $para_text, %para_attrs);
            }
            else {
                &AppMsg("warning", "ignoring internal directive '$1' in POD driver");
            }
            next;
        }

        # Add the paragraph
        &_PodParaAdd(*result, $para_tag, $para_text, *para_attrs, $prev_tag,
          $prev_indent, *contents);
    }

    # Do this stuff before starting next loop iteration
    continue {
        $prev_tag = $para_tag;
        $prev_indent = $para_attrs{'in'};
    }

    # Return result
    return @result;
}
       
#
# >>_Description::
# {{Y:_PodParaAdd}} adds a paragraph.
#
sub _PodParaAdd {
    local(*result, $para_tag, $para_text, *para_attrs, $prev_tag, $prev_indent, *contents) = @_;
#   local();
    local($para_fmt);
    local($para_override);
    local($para);
    local($hdg_level);
    local($toc_jump);
    local($label);
    local($indent);

    # Set the example flag
    $_pod_in_example = $SDF_USER'parastyles_category{$para_tag} eq 'example';

    # Get the target format name
    $para_fmt = $SDF_USER'parastyles_to{$para_tag};
    $para_fmt = $para_tag if $para_fmt eq '';

    # Map the attributes
    &SdfAttrMap(*para_attrs, 'pod', *SDF_USER'paraattrs_to,
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

    # Handle lists
    elsif ($para_tag =~ /^(L[FUNI]?)(\d)$/) {
        $para_attrs{'in'} = $2;
        if ($1 eq 'LU') {
            $para_fmt = "item *";
        }
        elsif ($1 eq 'L') {
            #$para_fmt = "item $para_attr{'label'}";
            $para_fmt = "item";
        }
        elsif ($1 eq 'LF') {
            $para_fmt = "item 1.";
            $_pod_list_num = 1;
        }
        elsif ($1 eq 'LI') {
            $para_fmt = "item " . &_PodParaText($para_text);
            $para_text = '';
        }
        else {
            $_pod_list_num++;
            $para_fmt = "item $_pod_list_num.";
        }
    }

    # Prepend the label, if any (replacing tabs with spaces)
    $label = $para_attrs{'label'};
    $label = 'Note: ' if ($para_tag eq 'Note' || $para_tag eq 'NB') &&
             $label eq '';
    $label =~ s/\\t/ /g;
    $para_text = "{{2:$label}}$para_text" if $label ne '';

    # Format the paragraph body
    if ($para_attrs{'verbatim'}) {
        $para = $para_text;
        delete $para_attrs{'verbatim'};
    }
    else {
        $para = &_PodParaText($para_text);
    }

    # If we're in a table, prepend the paragraph onto the current row
    if (@_pod_tbl_state) {
        $result[$#result] .= $para;
        return;
    }

    # Build result
    $indent = $para_attrs{'in'};
    if ($_pod_in_example) {
        &_PodAddExample(*result, $para, $para_tag, $prev_tag, $indent,
          $prev_indent);
    }
    elsif ($indent) {
        $item = &_PodElement($para_fmt, $para, %para_attrs);
        &_PodAddItem(*result, $item, $indent, $prev_indent, $para_tag);
    }
    else {
        $para = &_PodElement($para_fmt, $para, %para_attrs);
        push(@result, $para);
    }
}

#
# >>_Description::
# {{Y:_PodParaText}} converts SDF paragraph text into POD.
# 
sub _PodParaText {
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

        # Build the paragraph:
        # * if we're inside a table or example, just use the text
        # * otherwise, build things "normally"
        if (@_pod_tbl_state || $_pod_in_example) {
            $para .= $text;
        }

        elsif ($sect_type eq 'string') {
            $text = &_PodEscape($text, 0);
            $para .= $text;
        }

        elsif ($sect_type eq 'phrase') {

            # Escape any special characters
            $text = &_PodEscape($text, 1);

            # Process formatting attributes
            &SdfAttrMap(*sect_attrs, 'pod', *SDF_USER'phraseattrs_to,
              *SDF_USER'phraseattrs_map, *SDF_USER'phraseattrs_attrs,
              $SDF_USER'phrasestyles_attrs{$char_tag});

            # Map the font - italics is the default
            $char_font = $SDF_USER'phrasestyles_to{$char_tag};
            $char_font = 'I' if $char_font eq '';

            # Add the text for this phrase
            push(@char_fonts, $char_font);
            if ($char_font ne '') {
                $para .= "$char_font<$text";
            }
            else {
                $para .= $text;
            }
        }

        elsif ($sect_type eq 'phrase_end') {
            $char_font = pop(@char_fonts);
            $para .= ">" if $char_font ne '';
        }

        elsif ($sect_type eq 'special') {
            $directive = $_POD_PHRASE_HANDLER{$char_tag};
            if (defined &$directive) {
                &$directive(*para, $text, %sect_attrs);
            }
            else {
                &AppMsg("warning", "ignoring special phrase '$1' in POD driver");
            }
        }

        else {
            &AppMsg("warning", "unknown section type '$sect_type' in POD driver");
        }
    }

    # Return result
    return $para;
}

#
# >>_Description::
# {{Y:_PodFinalise}} generates the final POD file.
#
sub _PodFinalise {
    local(*body, *contents) = @_;
#   local(@result);

    # Return result
    return @body;
}

#
# >>_Description::
# {{Y:_PodEscape}} escapes special symbols in POD text.
# {{nested}} should be true if {{text}} will be nested
# within an interior sequence.
# 
sub _PodEscape {
    local($text, $nested) = @_;
#   local($result);
    local($old_match_flag);

    # Enable multi-line matching
    $old_match_flag = $*;
    $* = 1;

    # Escape the symbols
    my $gt = $nested ? 'E<gt>' : '>';
    $text =~ s/([A-Z])\<|\>/length($&) == 1 ? $gt : "$1E<lt>"/eg;

    # Reset multi-line matching flag
    $* = $old_match_flag;

    # Return result
    $text;
}

#
# >>_Description::
# {{Y:_PodAttr}} formats a set of attributes into POD.
# 
sub _PodAttr {
    local(*attrs) = @_;
    local($pod);

    # Currently, pod doesn't support attributes (other than jump -> L?)
    $pod = '';

    # Return result
    $pod;
}

#
# >>_Description::
# {{Y:_PodElement}} formats a POD element from a
# tag, text and set of attributes.
#
sub _PodElement {
    local($tag, $text, %attr) = @_;
#   local($pod);
    local($over);

    # For list items, add the over/back stuff
    $over = 4 * $attr{'in'};
    if ($tag =~ /^item/) {
        if ($text ne '') {
            $text = &MiscTextWrap($text, 70, '', '', 1);
            return "=over $over\n\n=$tag\n\n$text\n\n=back\n";
        }
        else {
            return "=over $over\n\n=$tag\n\n=back\n";
        }
    }

    # For lines, output a 'line'
    if ($tag eq 'Line') {
        return " " . ("_" x 40) . "\n";
    }

    # For headings, map the tag to a command
    if ($tag =~ /^head/) {
        return "=$tag $text\n";
    }

    # Otherwise, format as a plain paragraph
    return &MiscTextWrap($text, 70, '', '', 1) . "\n";
}

#
# >>_Description::
# {{Y:_PodAddExample}} adds an example paragraph to the result
#
sub _PodAddExample {
    local(*result, $para, $tag, $prev_tag, $indent, $prev_indent) = @_;
#   local();

    if ($prev_indent == 0) {
        if ($tag eq $prev_tag) {
            #$para =~ s/^\S/ $&/;    # Prepend a space if necessary
            $result[$#result] .= "$para\n";
        }
        else {
            $para =~ s/^\S/ $&/;    # Prepend a space if necessary
            push(@result, $para . "\n");
        }
    }
    else {
        # Insert the text before the old "=back\n"
        my $posn = -(6 * $prev_indent + $prev_indent - 1);
        my $end_tokens = substr($result[$#result], $posn);
        $posn-- if $tag eq $prev_tag;
        substr($result[$#result], $posn) = "$para\n\n$end_tokens";
    }
}

#
# >>_Description::
# {{Y:_PodAddItem}} adds an item paragraph to the result buffer.
#
sub _PodAddItem {
    local(*result, $item, $indent, $prev_indent, $para_tag) = @_;
#   local();
    local($type);
    local($i);
    local($over);
    local($posn, $end_tokens);
    local($in);

    # Get the list type
    $type = substr($para_tag, 0, 2);
    $type = 'LN' if $type eq 'LF';

    # Indent is increasing
    if ($indent > $prev_indent) {
        $_pod_list_type[$indent] = $type;
        $posn = -(6 * $prev_indent + $prev_indent - 1);
        for ($i = $indent - 1; $i > $prev_indent; $i--) {
            $_pod_list_type[$i] = $type;
            $over = $i * 4;
            $item = "=over $over\n\n$item\n=back\n";
        }
        if ($prev_indent == 0) {
            push(@result, $item);
            return;
        }
        else {
            $item .= "\n";
        }
    }

    # Indent is decreasing or the same
    else {
        # plain items are compatible with both ordered and unordered lists,
        # so handle them separately
        if ($para_tag =~ /^L\d$/) {
            # ignore the new "=item\n\n"
            $item = substr($item, 7);
            $posn = -(6 * $indent + $indent - 1);
            $item = substr($item, 9, length($item) - 15);
        }

        # handle items of an existing list
        elsif ($type eq $_pod_list_type[$indent]) {
            $posn = -(6 * $indent + $indent - 1);
            $item = substr($item, 9, length($item) - 15);
        }

        # item is not compatible with the current list - start a new one
        else {
            $item = "\n" . $item;
            if ($indent > 1) {
                $in = $indent - 1;
                $posn = -(6 * $in + $in - 1);
            }
            else {
                $posn = length($result[$#result]);
            }

            # Update the list type
            $_pod_list_type[$indent] = $type;

        }
    }

    # Merge the item
    $end_tokens = substr($result[$#result], $posn);
#print STDERR "indent: $indent.\n";
#print STDERR "posn: $posn.\n";
#print STDERR "item: $item.\n";
#print STDERR "end_tokens: $end_tokens.\n";
    substr($result[$#result], $posn) = "$item$end_tokens";
}

#
# >>_Description::
# {{Y:_PodHandlerTuning}} handles the 'tuning' directive.
#
sub _PodHandlerTuning {
    local(*outbuffer, $style, %attr) = @_;
#   local();

    # do nothing
}

#
# >>_Description::
# {{Y:_PodHandlerEndTuning}} handles the 'endtuning' directive.
#
sub _PodHandlerEndTuning {
    local(*outbuffer, $style, %attr) = @_;
#   local();

    # do nothing
}

#
# >>_Description::
# {{Y:_PodHandlerTable}} handlers the 'table' directive.
#
sub _PodHandlerTable {
    local(*outbuffer, $columns, %attr) = @_;
#   local();
    local($tbl_title);

    # Update the state
    push(@_pod_tbl_state, $_POD_INTABLE);

    # Calculate the column positions (rounded)
    @_pod_col_posn = &SdfColPositions($columns, $attr{'format'}, $_pod_margin);

    # Add the title, if any
    $tbl_title = $attr{'title'};
    if ($tbl_title ne '') {
        push(@outbuffer, "I<$tbl_title>\n");
    }
}

#
# >>_Description::
# {{Y:_PodHandlerRow}} handlers the 'row' directive.
#
sub _PodHandlerRow {
    local(*outbuffer, $text, %attr) = @_;
#   local();

    # Start the new row (a leading space makes it fixed-width text)
    push(@outbuffer, " ");
    $_pod_col_num = 0;

    # Update the state
    $_pod_tbl_state[$#_pod_tbl_state] = $_POD_INROW;
}

#
# >>_Description::
# {{Y:_PodHandlerCell}} handles the 'cell' directive.
#
sub _PodHandlerCell {
    local(*outbuffer, $text, %attr) = @_;
#   local();
    local($state);
    local($padding);

    # Finalise the old cell, if any
    $state = $_pod_tbl_state[$#_pod_tbl_state];
    if ($state eq $_POD_INCELL) {
        if ($_pod_col_num > 0) {
            $padding = $_pod_col_posn[$_pod_col_num - 1] -
              length($outbuffer[$#outbuffer]);
            $outbuffer[$#outbuffer] .= " " x $padding;
        }
    }

    # Update the state
    $_pod_tbl_state[$#_pod_tbl_state] = $_POD_INCELL;
    $_pod_col_num++;
}

#
# >>_Description::
# {{Y:_PodHandlerEndTable}} handles the 'endtable' directive.
#
sub _PodHandlerEndTable {
    local(*outbuffer, $text, %attr) = @_;
#   local();
    local($state);

    # Finalise the table
    $state = pop(@_pod_tbl_state);
    if ($state eq $_POD_INCELL) {
        $outbuffer[$#outbuffer] .= "\n";
    }
    elsif ($state eq $_POD_INROW) {
        $outbuffer[$#outbuffer] .= "\n";
    }
}

#
# >>_Description::
# {{Y:_PodHandlerImport}} handles the import directive.
#
sub _PodHandlerImport {
    local(*outbuffer, $filepath, %attr) = @_;
#   local();
    local($para);

    # Build the result
    &_PodPhraseHandlerImport(*para, $filepath, %attr);
    push(@outbuffer, "$para\n");
}

#
# >>_Description::
# {{Y:_PodHandlerInline}} handles the inline directive.
#
sub _PodHandlerInline {
    local(*outbuffer, $text, %attr) = @_;
#   local();

    # Tell POD this is for another format, if necessary
    my $target = $attr{'target'};
    $text = "=for $target $text\n" unless $target eq 'pod';

    # Build the result
    push(@outbuffer, $text);
}

#
# >>_Description::
# {{Y:_PodHandlerOutput}} handles the 'output' directive.
#
sub _PodHandlerOutput {
    local(*outbuffer, $text, %attrs) = @_;
#   local();

    # do nothing
}

#
# >>_Description::
# {{Y:_PodHandlerObject}} handles the 'object' directive.
#
sub _PodHandlerObject {
    local(*outbuffer, $text, %attrs) = @_;
#   local();


    # Save the margin, if necessary
    if ($text eq 'Variable' && $attrs{'Name'} eq 'POD_MARGIN') {
        $_pod_margin = $attrs{'value'};
    }
}

#
# >>_Description::
# {{Y:_PodPhraseHandlerChar}} handles the 'char' phrase directive.
#
sub _PodPhraseHandlerChar {
    local(*para, $text, %attr) = @_;
#   local();

    # Map those we know about it
    if (defined($_POD_CHAR{$text})) {
        $para .= $_POD_CHAR{$text};
    }
    else {
        # Assume character is to be escaped
        $para .= "E<$text>"
    }
}

#
# >>_Description::
# {{Y:_PodPhraseHandlerImport}} handles the 'import' phrase directive.
#
sub _PodPhraseHandlerImport {
    local(*para, $filepath, %attr) = @_;
#   local();
    local($name, $value);

    $para .= "** I<Unable to import figure $filepath> **";
}

#
# >>_Description::
# {{Y:_PodPhraseHandlerInline}} handles the 'inline' phrase directive.
#
sub _PodPhraseHandlerInline {
    local(*para, $text, %attr) = @_;
#   local();

    # Build the result
    $para .= $text;
}

#
# >>_Description::
# {{Y:_PodPhraseHandlerVariable}} handles the 'variable' phrase directive.
#
sub _PodPhraseHandlerVariable {
    local(*para, $text, %attr) = @_;
#   local();

    # do nothing
}

# package return value
1;
