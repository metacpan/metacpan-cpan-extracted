# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     SGML Format Driver
#
# >>Copyright::
# Copyright (c) 1992-1997, Ian Clatworthy (ianc@mincom.com).
# You may distribute under the terms specified in the LICENSE file.
#
# >>History::
# -----------------------------------------------------------------------
# Date      Who     Change
# 14-Aug-97 ianc    SDF 2.000
# -----------------------------------------------------------------------
#
# >>Purpose::
# This library provides an [[SDF_DRIVER]] which generates
# [[SGML]] files.
#
# >>Description::
#
# >>Limitations::
# Cross-references and URLs aren't there yet.
#
# Indented tables within a bulleted list don't work yet.
#
# Tagged lists aren't mapped as well as they could be.
#
# Special character support still needs some work (for dagger and
# doubledagger, if not a few others).
#
# Lists which have ordered items, then unordered items, then
# ordered items all at the same level are output as three
# separate lists. As a result, the numbering in the third list
# restarts even if you don't want it to.
#
# >>Resources::
#
# >>Implementation::
#

##### Constants #####

# These are the tags which don't have/need a closing tag
%_SGML_NOENDTAG = (
    'title',    1,
    'author',   1,
    'date',     1,
    'sect',     1,
    'sect1',    1,
    'sect2',    1,
    'sect3',    1,
    'sect4',    1,
    'sect5',    1,
    'p',        1,
);

# Mapping table for characters
%_SGML_CHAR = (
    'bullet',       '.',
    'c',            '&copy;',
    'cent',         '&cent;',
    'dagger',       '^',
    'doubledagger', '#',
    'emdash',       '&mdash;',
    'endash',       '&ndash;',
    'emspace',      '&emsp;',
    'enspace',      '&ensp;',
    'lbrace',       '{',
    'lbracket',     '[',
    'nbdash',       '-',
    'nbspace',      '&nbsp;',
    'nl',           '&nl;',
    'pound',        '&pound;',
    'r',            '&#174;',
    'rbrace',       '}',
    'rbracket',     ']',
    'tab',          '&#9;',
    'tm',           '&#153;',       # not sure about this
    'yen',          '&#165;',
);

# Directive mapping table
%_SGML_HANDLER = (
    'tuning',           '_SgmlHandlerTuning',
    'endtuning',        '_SgmlHandlerEndTuning',
    'table',            '_SgmlHandlerTable',
    'row',              '_SgmlHandlerRow',
    'cell',             '_SgmlHandlerCell',
    'endtable',         '_SgmlHandlerEndTable',
    'import',           '_SgmlHandlerImport',
    'inline',           '_SgmlHandlerInline',
    'output',           '_SgmlHandlerOutput',
    'object',           '_SgmlHandlerObject',
);

# Phrase directive mapping table
%_SGML_PHRASE_HANDLER = (
    'char',             '_SgmlPhraseHandlerChar',
    'import',           '_SgmlPhraseHandlerImport',
    'inline',           '_SgmlPhraseHandlerInline',
    'variable',         '_SgmlPhraseHandlerVariable',
);

# Table states
$_SGML_INTABLE = 1;
$_SGML_INROW   = 2;
$_SGML_INCELL  = 3;

##### Variables #####

# Table states
@_sgml_tbl_state = ();
@_sgml_tbl_endtokens = ();
@_sgml_tbl_previndent = ();
@_sgml_tbl_title = ();

##### Routines #####

#
# >>Description::
# {{Y:SgmlFormat}} is an SDF driver which outputs SGML.
#
sub SgmlFormat {
    local(*data) = @_;
    local(@result);

    # Format the paragraphs
    @result = &_SgmlFormatSection(*data);

    # Build the final result.
    @result = &_SgmlFinalise(*result);

    # Return the result
    return @result;
}

#
# >>_Description::
# {{Y:_SgmlFormatSection}} formats a set of SDF paragraphs into SGML.
#
sub _SgmlFormatSection {
    local(*data) = @_;
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
            $directive = $_SGML_HANDLER{$1};
            if (defined &$directive) {
                &$directive(*result, $para_text, %para_attrs);
            }
            else {
                &AppMsg("warning", "ignoring internal directive '$1' in SGML driver");
            }
            next;
        }

        # Add the paragraph
        &_SgmlParaAdd(*result, $para_tag, $para_text, *para_attrs, $prev_tag,
          $prev_indent);
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
# {{Y:_SgmlParaAdd}} adds a paragraph.
#
sub _SgmlParaAdd {
    local(*result, $para_tag, $para_text, *para_attrs, $prev_tag, $prev_indent) = @_;
#   local();
    local($is_example);
    local($para_fmt);
    local($para_override);
    local($para);
    local($hdg_level);
    local($label);
    local($indent);
    local($list_tag);

    # Get the example flag
    $is_example = $SDF_USER'parastyles_category{$para_tag} eq 'example';

    # Enumerated lists are the same as list paragraphs at the previous level,
    # except that we bold the text
    if ($para_tag =~ /^LI(\d)$/) {
        $para_tag = $1 > 1 ? "L" . ($1 - 1) : 'N';
        $para_attrs{'bold'} = 1;
    }

    # Get the target format name
    $para_fmt = $SDF_USER'parastyles_to{$para_tag};
    $para_fmt = $is_example ? 'tscreen' : 'p' if $para_fmt eq '';

    # Map the attributes
    &SdfAttrMap(*para_attrs, 'sgml', *SDF_USER'paraattrs_to,
      *SDF_USER'paraattrs_map, *SDF_USER'paraattrs_attrs,
      $SDF_USER'parastyles_attrs{$para_tag});

    # Handle headings
    if ($para_tag =~ /^[HAP](\d)$/) {
        $hdg_level = $1 - 1;
        $para_fmt = $hdg_level ? "sect$hdg_level" : "sect";
    }

    # Handle lists
    elsif ($para_tag =~ /^(L[FUN]?)(\d)$/) {
        $para_attrs{'in'} = $2;
        if ($1 eq 'LU') {
            $para_fmt = 'itemize';
        }
        elsif ($1 eq 'L') {
            $para_fmt = 'list';
        }
        else {
            $para_fmt = 'enum';
        }
    }

    # Prepend the label, if any (replacing tabs with spaces)
    $label = $para_attrs{'label'};
    $label = 'Note: ' if ($para_tag eq 'Note' || $para_tag eq 'NB') &&
             $label eq '';
    $label =~ s/\\t/ /g;
    $para_text = "{{2:$label}}$para_text" if $label ne '';

    # Indent examples, if necessary
    if ($is_example && $para_attrs{'in'}) {
        $para_text = " " x ($para_attrs{'in'} * 4) . $para_text;
        delete $para_attrs{'in'};
    }

    # Format the paragraph body
    if ($para_attrs{'verbatim'}) {
        $para = &_SgmlEscape($para_text);
        delete $para_attrs{'verbatim'};
    }
    else {
        $para = &_SgmlParaText($para_text);
    }

    ## Examples with change bars currently come out as separate
    ## paragraphs - this fixes the problem, for now
    #delete $para_attrs{'changed'} if $para_attrs{'changed'};

    # Build result
    $indent = $para_attrs{'in'};
    #if ($is_example && $para_tag eq $prev_tag && !%para_attrs) {
    if ($is_example && $para_tag eq $prev_tag) {
        &_SgmlParaAppend(*result, $para);
    }
    elsif ($indent && $prev_indent != 0) {
        $item = &_SgmlElement($para_fmt, $para, %para_attrs);
        &_SgmlItemAppend(*result, $item, $indent, $prev_indent, $para_tag,
          $prev_tag, *para_attrs);
    }

    # Plain paragraphs inside tables are not preceded by <p>
    elsif (@_sgml_tbl_state && $para_fmt eq 'p') {
        push(@result, $para);
    }
    else {
        # After a heading, make sure the next entity is another heading
        # or a plain paragraph
        if ($prev_tag =~ /^[HAP]\d$/ && $para_fmt ne 'p' &&
                $para_fmt !~ /^sect\d?$/) {
            push(@result, '<p>');
        }

        # Add this element, handling lists which begin at an indent
        # greater than 1
        $para = &_SgmlElement($para_fmt, $para, %para_attrs);
        $list_tag = $para_fmt;
        while (--$indent > 0) {
            $para = "<$list_tag>$para</$list_tag>";
        }
        push(@result, $para);
    }
}

#
# >>_Description::
# {{Y:_SgmlParaText}} converts SDF paragraph text into SGML.
# 
sub _SgmlParaText {
    local($para_text) = @_;
    local($para);
    local($state);
    local($sect_type, $char_tag, $text, %sect_attrs);
    local($url);
    local($added_anchors);
    local(@char_fonts);
    local($char_font);
    local($directive);

    # Process the text
    $para = '';
    $state = 0;
    while (($sect_type, $text, $char_tag, %sect_attrs) =
      &SdfNextSection(*para_text, *state)) {

        # Build the paragraph
        if ($sect_type eq 'string') {
            $para .= &_SgmlEscape($text);
        }

        elsif ($sect_type eq 'phrase') {

            # Expand out link phrases
            if ($char_tag eq 'L') {
                ($text, $url) = &SDF_USER'ExpandLink($text);
                $sect_attrs{'jump'} = $url;
            }

            # Escape any special characters
            $text = &_SgmlEscape($text);

            # Expand non-breaking spaces, if necessary
            if ($char_tag eq 'S') {
                $text =~ s/ /~/g;
            }

            # Add hypertext stuff
            $added_anchors = &_SgmlAddAnchors(*text, *sect_attrs);

            # Process formatting attributes
            &SdfAttrMap(*sect_attrs, 'sgml', *SDF_USER'phraseattrs_to,
              *SDF_USER'phraseattrs_map, *SDF_USER'phraseattrs_attrs,
              $SDF_USER'phrasestyles_attrs{$char_tag});

            # Map the font
            $char_font = $SDF_USER'phrasestyles_to{$char_tag};
            $char_font = 'em' if $char_font eq '' && !$added_anchors;

            # Add the text for this phrase
            push(@char_fonts, $char_font);
            if ($char_font ne '' && $char_font !~ /^SDF/) {
                $para .= "<$char_font>$text";
            }
            else {
                $para .= $text;
            }
        }

        elsif ($sect_type eq 'phrase_end') {
            $char_font = pop(@char_fonts);
            $para .= "</$char_font>" if $char_font ne '' && $char_font !~ /^SDF/;
        }

        elsif ($sect_type eq 'special') {
            $directive = $_SGML_PHRASE_HANDLER{$char_tag};
            if (defined &$directive) {
                &$directive(*para, $text, %sect_attrs);
            }
            else {
                &AppMsg("warning", "ignoring special phrase '$1' in SGML driver");
            }
        }

        else {
            &AppMsg("warning", "unknown section type '$sect_type' in SGML driver");
        }
    }

    # Return result
    return $para;
}

#
# >>_Description::
# {{Y:_SgmlFinalise}} generates the final SGML file.
#
sub _SgmlFinalise {
    local(*body) = @_;
#   local(@result);
    local(@head);

    # Build the preamble
    my $dtd = $var{'SGML_DTD'} || 'linuxdoc';
    my @head = (
        "<!doctype $dtd system>",
        '',
        '<article>',
        '',
    );

    # Add the ending stuff
    push(@body, '', '</article>');

    # Return result
    return (@head, @body);
}

#
# >>_Description::
# {{Y:_SgmlEscape}} escapes special symbols in SGML text.
# 
sub _SgmlEscape {
    local($text) = @_;
#   local($result);
    local($old_match_flag);

    # Enable multi-line matching
    $old_match_flag = $*;
    $* = 1;

    # Escape the special symbols. Note that it isn't exactly clear
    # from the SGML-Tools and/or QWERTZ DTD documentation as to
    # whether all of these are mandatory, but they shouldn't cause
    # any harm (I hope!)
    $text =~ s/\&/&amp;/g;
    $text =~ s/\</&lt;/g;
    $text =~ s/\>/&gt;/g;
    $text =~ s/\"/&dquot;/g;
    $text =~ s/\$/&dollar;/g;
    $text =~ s/\~/&tilde;/g;
    $text =~ s/\#/&num;/g;
    $text =~ s/\%/&percnt;/g;
    $text =~ s/\\/&bsol;/g;
    $text =~ s/\|/&verbar;/g;
    $text =~ s/\[/&ftag;/g;

    # Reset multi-line matching flag
    $* = $old_match_flag;

    # Return result
    $text;
}

#
# >>_Description::
# {{Y:_SgmlAttr}} formats a set of attributes into SGML.
# 
sub _SgmlAttr {
    local(*attrs) = @_;
    local($sgml);
    local($attr, $value, $type);

    for $attr (sort keys %attrs) {

        # get the attribute value
        $value = $attrs{$attr};

        # get the attribute type
        if ($attr =~ s/^sgml\.//) {
            $type = $_SGML_ATTR_TYPES{$attr};
            $type = "string" if $type eq '';
        }
        else {
            $type = $_SGML_ATTR_TYPES{$attr};
        }
        next unless $type;

        # Map the attribute name to uppercase
        $attr =~ tr/a-z/A-Z/;

        # build the result
        if ($type eq 'string') {
            $sgml .= " $attr=\"" . &_SgmlEscape($value) . '"';
        }
        else {
            $sgml .= " $attr=$value";
        }
    }

    # Return result
    $sgml;
}

#
# >>_Description::
# {{Y:_SgmlElement}} formats a SGML element from a
# tag, text and set of attributes.
#
sub _SgmlElement {
    local($tag, $text, %attr) = @_;
#   local($sgml);

    # For preformatted sections, tags go on separate lines
    $text = "\n$text\n" if $tag eq 'tscreen';

    # Add hypertext stuff
    &_SgmlAddAnchors(*text, *attr);

    # Bold the text, if requested
    if ($attr{'bold'}) {
        $text = "<bf>$text</bf>";
    }

    # For list items, add the item stuff
    $text = "\n<item>$text" if $tag =~ /^(itemize|enum|list)$/;

    # Return result
    if ($_SGML_NOENDTAG{$tag}) {
        return "<$tag>$text";
    }
    else {
        #return "<$tag" . &_SgmlAttr(*attr) . ">$text</$tag>";
        return "<$tag>$text</$tag>";
    }
}

#
# >>_Description::
# {{Y:_SgmlAddAnchors}} adds hypertext jumps and ids to a section of text.
# of text. It returns true if anchors were added.
# 
sub _SgmlAddAnchors {
    local(*text, *attr) = @_;
    local($result);
    local($value);
    local($user_ext);
    local($old_match_flag);

    # Skip this routine for now
    return 0;

    # Enable multi-line matching
    $old_match_flag = $*;
    $* = 1;

    # For hypertext jumps, surround the text. If the
    # text contains a jump, the existing jump is removed.
    if ($attr{'jump'} ne '') {

        # Get the jump value. If an extension other than sgml is
        # requested, change the jump value accordingly. Also,
        # we make sure than any special characters are escaped.
        $value = $attr{'jump'};
        $user_ext = $SDF_USER'var{'SGML_EXT'};
        if ($user_ext) {
            $value =~ s/\.sgml/.$user_ext/;
        }
        $value = &_SgmlEscape($value);

        $text =~ s/\<A HREF\=[^>]+\>(.*)\<\/A\>/$1/;
        $text = "<A HREF=\"$value\">$text</A>";
        delete $attr{'jump'};
        $result++;
    }

    # For hypertext ids, surround the text if it doesn't already contain
    # a jump. Otherwise, prefix the text with a dummy target so that
    # jump and id definitions don't clash.
    if ($attr{'id'} ne '') {
        $value = &_SgmlEscape($attr{'id'});
        if ($text =~ /\<A /) {
            $text = "<A NAME=\"$value\"> </A>$text";
        }
        else {
            $text = "<A NAME=\"$value\">$text</A>";
        }
        delete $attr{'id'};
        $result++;
    }

    # Reset multi-line matching flag
    $* = $old_match_flag;

    # Return result
    return $result;
}

#
# >>_Description::
# {{Y:_SgmlParaAppend}} merges {{para}} into the last paragraph
# in {{@result}}. Both paragraphs are assumed to be fixed-width.
#
sub _SgmlParaAppend {
    local(*result, $para) = @_;
#   local();

    #$para = "&nbsp;" if $para eq '';
    substr($result[$#result], -10) = "$para&nl;\n</tscreen>";
}

#
# >>_Description::
# {{Y:_SgmlItemAppend}} merges a list item {{item}} into the current
# output. The item before is assumed to be a list item too.
#
sub _SgmlItemAppend {
    local(*result, $item, $indent, $prev_indent, $para_tag, $prev_tag, *para_attrs) = @_;
#   local();
    local($type, $prev_type);
    local($posn, $end_tokens);

    # Get the list type and previous type
    if ($item =~ /^<(\w+)/) {
        $type = $1;
    }
    else {
        &AppMsg("warning", "unable to get list type during item merge");
    }
    if ($result[$#result] =~ /(\w+)>$/) {
        $prev_type = $1;
    }
    else {
        &AppMsg("warning", "unable to get previous type during item merge");
    }

    # Indent is increasing
    if ($indent > $prev_indent) {
        if ($result[$#result] =~ s/(<\/\w+>){$prev_indent}$//) {
            $end_tokens = $&;
        }
        else {
            &AppMsg("warning", "unable to get endtokens during item merge");
        }
        while (++$prev_indent < $indent) {
            $item = "<$type>$item</$type>";
        }
    }

    # Indent is descreasing or the same
    else {
        # handle items of an existing list
        if ($type eq $prev_type) {
            if ($result[$#result] =~ s/(<\/\w+>){$indent}$//) {
                $end_tokens = $&;
            }
            else {
                &AppMsg("warning", "unable to get endtokens during item merge");
            }
            if ($item =~ /^<\w+>(.+)<\/\w+>$/s) {
                $item = $1;
            }
            else {
                &AppMsg("warning", "unable to get item during item merge");
            }
        }

        # item is not compatible with the current list - start a new one
        else {
            $end_tokens = '';
            $indent--;
            if ($indent) {
                if ($result[$#result] =~ s/(<\/\w+>){$indent}$//) {
                    $end_tokens = $&;
                }
                else {
                    &AppMsg("warning", "unable to get endtokens during item merge");
                }
            }
        }
    }

    # Merge the item
    $result[$#result] .= "$item$end_tokens";
}

#
# >>_Description::
# {{Y:_SgmlHandlerTuning}} handles the 'tuning' directive.
#
sub _SgmlHandlerTuning {
    local(*outbuffer, $style, %attr) = @_;
#   local();

    # do nothing
}

#
# >>_Description::
# {{Y:_SgmlHandlerEndTuning}} handles the 'endtuning' directive.
#
sub _SgmlHandlerEndTuning {
    local(*outbuffer, $style, %attr) = @_;
#   local();

    # do nothing
}

#
# >>_Description::
# {{Y:_SgmlHandlerTable}} handles the 'table' directive.
#
sub _SgmlHandlerTable {
    local(*outbuffer, $columns, %attr) = @_;
#   local();
    local($indent, $previous_indent, $posn, $begin_tokens, $end_tokens);

    # Handle tables inside a list
    # Note: the previous indent is available as a dynamically
    # scoped variable in &SgmlFormatSection
    $indent = $attr{'listitem'};
    $begin_tokens = '';
    $end_tokens = '';
    if ($indent) {
        $previous_indent = $prev_indent;    # get dynamically scoped var
        if ($indent > $previous_indent) {
            $posn = -7 * $previous_indent;
            while ($previous_indent++ < $indent) {
                $begin_tokens .= "<list>";
                $end_tokens .= "</list>";
            }
        }
        else {
            $posn = -$indent * 7;
        }
        if ($posn < 0) {
            $end_tokens .= substr($outbuffer[$#outbuffer], $posn);
            substr($outbuffer[$#outbuffer], $posn) = $begin_tokens;
        }
        else {
            push(@outbuffer, $begin_tokens);
        }
    }
    
    # Update the state
    push(@_sgml_tbl_state, $_SGML_INTABLE);
    push(@_sgml_tbl_endtokens, $end_tokens);
    push(@_sgml_tbl_previndent, $indent);
    push(@_sgml_tbl_title, $attr{'title'});

    # Build the layout
    my @col_aligns = split(//, 'l' x $columns);
    my @user_aligns = split(/,/, $attr{'colaligns'});
    my $i;
    for ($i = 0; $i <= $#user_aligns; $i++) {
        $col_aligns[$i] = lc(substr($user_aligns[$i], 0, 1));
    }
    my $col_sep = $attr{'style'} eq 'plain' ? '' : "|";
    my $layout = join($col_sep, @col_aligns);

    # Update the output buffer
    push(@outbuffer, "<table>", "<tabular ca='$layout'>");
}

#
# >>_Description::
# {{Y:_SgmlHandlerRow}} handles the 'row' directive.
#
sub _SgmlHandlerRow {
    local(*outbuffer, $text, %attr) = @_;
#   local();
    local($state);

    # Finalise the old cell/row, if any
    $state = $_sgml_tbl_state[$#_sgml_tbl_state];
    if ($state eq $_SGML_INCELL) {
        push(@outbuffer, "@");
    }
    elsif ($state eq $_SGML_INROW) {
        push(@outbuffer, "@");
    }

    # Update the state
    $_sgml_tbl_state[$#_sgml_tbl_state] = $_SGML_INROW;
}

#
# >>_Description::
# {{Y:_SgmlHandlerCell}} handles the 'cell' directive.
#
sub _SgmlHandlerCell {
    local(*outbuffer, $text, %attr) = @_;
#   local();
    local($state);

    # If the cell is hidden, output nothing
    return if $attr{'hidden'};

    # Finalise the old cell, if any
    $state = $_sgml_tbl_state[$#_sgml_tbl_state];
    if ($state eq $_SGML_INCELL) {
        push(@outbuffer, "|");
    }

    # Update the state
    $_sgml_tbl_state[$#_sgml_tbl_state] = $_SGML_INCELL;
}

#
# >>_Description::
# {{Y:_SgmlHandlerEndTable}} handles the 'endtable' directive.
#
sub _SgmlHandlerEndTable {
    local(*outbuffer, $text, %attr) = @_;
#   local();

    # Update the state
    my $state = pop(@_sgml_tbl_state);
    my $tbl_title = pop(@_sgml_tbl_title);
    my $end_tokens = pop(@_sgml_tbl_endtokens);

    # Finalise the table
    push(@outbuffer, "</tabular>");
    if ($tbl_title ne '') {
        push(@outbuffer, "<caption>" . $tbl_title . "</caption>");
    }
    push(@outbuffer, "</table>");

    # Terminate the list, if any
    push(@outbuffer, $end_tokens);

    # Restore the previous indent. We do this by hacking the
    # %para_attrs hash dynamically scoped in &SgmlFormatSection. :-(
    $para_attrs{'in'} = pop(@_sgml_tbl_previndent);
}

#
# >>_Description::
# {{Y:_SgmlHandlerImport}} handles the import directive.
#
sub _SgmlHandlerImport {
    local(*outbuffer, $filepath, %attr) = @_;
#   local();
    local($para);

    # Build the result
    &_SgmlPhraseHandlerImport(*para, $filepath, %attr);
    push(@outbuffer, $para);
}

#
# >>_Description::
# {{Y:_SgmlHandlerInline}} handles the inline directive.
#
sub _SgmlHandlerInline {
    local(*outbuffer, $text, %attr) = @_;
#   local();

    # Check we can handle this format
    my $target = $attr{'target'};
    return unless $target eq 'sgml';

    # Build the result
    push(@outbuffer, $text);
}

#
# >>_Description::
# {{Y:_SgmlHandlerOutput}} handles the output directive.
#
sub _SgmlHandlerOutput {
    local(*outbuffer, $text, %attr) = @_;
#   local();

    # do nothing
}

#
# >>_Description::
# {{Y:_SgmlHandlerObject}} handles the 'object' directive.
#
sub _SgmlHandlerObject {
    local(*outbuffer, $text, %attrs) = @_;
#   local();

    # do nothing
}

#
# >>_Description::
# {{Y:_SgmlPhraseHandlerChar}} handles the 'char' phrase directive.
#
sub _SgmlPhraseHandlerChar {
    local(*para, $text, %attr) = @_;
#   local();

    # Map the symbolic names
    if (defined($_SGML_CHAR{$text})) {
        $para .= $_SGML_CHAR{$text};
    }
    else {
        # Numbers are ISO character codes
        $para .= $text =~ /\D/ ? "&$text;" : "&#$text;";
    }
}

#
# >>_Description::
# {{Y:_SgmlPhraseHandlerImport}} handles the 'import' phrase directive.
#
sub _SgmlPhraseHandlerImport {
    local(*para, $filepath, %attr) = @_;
#   local();

    # Trim the extension off the filepath
    $filepath =~ s/\.\w+$//;

    # Build the result
    $para .= "<figure>\n<eps file=\"$filepath\">\n</figure>";
}

#
# >>_Description::
# {{Y:_SgmlPhraseHandlerInline}} handles the 'inline' phrase directive.
#
sub _SgmlPhraseHandlerInline {
    local(*para, $text, %attr) = @_;
#   local();

    # Build the result
    $para .= $text;
}

#
# >>_Description::
# {{Y:_SgmlPhraseHandlerVariable}} handles the 'variable' phrase directive.
#
sub _SgmlPhraseHandlerVariable {
    local(*para, $text, %attr) = @_;
#   local();

    # do nothing
}

# package return value
1;
