# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     HTML Format Driver
#
# >>Copyright::
# Copyright (c) 1992-1996, Ian Clatworthy (ianc@mincom.com).
# You may distribute under the terms specified in the LICENSE file.
#
# >>History::
# -----------------------------------------------------------------------
# Date      Who     Change
# 29-Feb-96 ianc    SDF 2.000
# -----------------------------------------------------------------------
#
# >>Purpose::
# This library provides an [[SDF_DRIVER]] which generates
# [[HTML]] files.
#
# >>Description::
#
# >>Limitations::
# Center alignment of tables should probably be done via <CENTER>
# and </CENTER> around the whole table. (The HTML 3.2 spec supports
# align=center but most browsers do not yet?)
#
# Lists which have ordered items, then unordered items, then
# ordered items all at the same level are output as three
# separate lists. As a result, the numbering in the third list
# restarts even if you don't want it to.
#
# After hypertext jumps have been added throughout a paragraph,
# we should go back over the paragraph and unnest any nested jumps.
#
# Frames and other goodies are still a while off yet.
#
# >>Resources::
#
# >>Implementation::
#

##### Constants #####

# Mapping table for characters
%_HTML_CHAR = (
    'bullet',       '.',
    'c',            '&#169; ',
    'cent',         '&cent; ',
    'dagger',       '^',
    'doubledagger', '#',
    'emdash',       '--',
    'endash',       '-',
    'emspace',      '&nbsp; ',
    'enspace',      '&nbsp; ',
    'lbrace',       '{',
    'lbracket',     '[',
    'nbdash',       '-',
    'nbspace',      '&nbsp; ',
    'nl',           '<BR>',
    'pound',        '&#163; ',
    'r',            '&#174; ',
    'rbrace',       '}',
    'rbracket',     ']',
    'tab',          '&#9; ',
    'tm',           '&#153; ',       # not sure about this
    'yen',          '&#165; ',
);

# Directive mapping table
%_HTML_HANDLER = (
    'tuning',         '_HtmlHandlerTuning',
    'endtuning',      '_HtmlHandlerEndTuning',
    'table',            '_HtmlHandlerTable',
    'row',              '_HtmlHandlerRow',
    'cell',             '_HtmlHandlerCell',
    'endtable',         '_HtmlHandlerEndTable',
    'import',           '_HtmlHandlerImport',
    'inline',           '_HtmlHandlerInline',
    'output',           '_HtmlHandlerOutput',
    'object',           '_HtmlHandlerObject',
);

# Phrase directive mapping table
%_HTML_PHRASE_HANDLER = (
    'char',             '_HtmlPhraseHandlerChar',
    'import',           '_HtmlPhraseHandlerImport',
    'inline',           '_HtmlPhraseHandlerInline',
    'variable',         '_HtmlPhraseHandlerVariable',
);

# Table states
$_HTML_INTABLE = 1;
$_HTML_INROW   = 2;
$_HTML_INCELL  = 3;

# Attribute types - this is used to decide if an attribute is legal,
# and if it is, whether to quote the value (string) or not
%_HTML_ATTR_TYPES = (
    'align',    'string',
    'alt',      'string',
    'border',   'integer',
);

##### Variables #####

# Table/cell states
@_html_tbl_state = ();
@_html_tbl_endtokens = ();
@_html_tbl_previndent = ();
$_html_cell_paracnt = ();

# Stack of topic file offsets and filenames
@_html_topic_offset = ();
@_html_topic_file = ();

# Current topic and level
$_html_topic = '';
$_html_topic_level = 0;

# File/text combinations which start a new topic
%_html_topic_start = ();

# File/text lookup to a jump target
%_html_jump_id = ();

## Ordered list state
#$_html_in_olist = 0;

# Topic counter for building derived topic names
$_html_topic_cntr = 0;

##### Routines #####

#
# >>Description::
# {{Y:HtmlFormat}} is an SDF driver which outputs HTML.
#
sub HtmlFormat {
    local(*data) = @_;
    local(@result);
    local(@contents);
    local(@data2, @contents2, %var2, @result2);
    local($msg_cursor, %msg_counts);
    local($main);
    local(@topics_table, @jumps_table);

    # Init global data
    $_html_topic = '';
    $_html_topic_level = 0;
    $_html_topic_cntr = 0;
    %_html_topic_start = ();
    %_html_jump_id = ();

    # If we're building topics, save the data for a second pass later
    if ($SDF_USER'var{'HTML_TOPICS_MODE'}) {
        @data2 = @data;

        # Get the current message cursor - we skip the second pass
        # if errors are found
        $msg_cursor = &AppMsgNextIndex();

    }

    # Format the paragraphs
    @contents = ();
    @result = &_HtmlFormatSection(*data, *contents);

    # Save away any unclosed topics
    while (@_html_topic_file) {
        &_HtmlHandlerOutput(*result, '-');
    }

    # Build the final result.
    ## Note that we must do this AFTER the subtopics stuff in order
    ## to get the next/previous topic data needed for the default
    ## header/footer.
    @result = &_HtmlFinalise(*result, *contents);

    # If there were no problems in the first pass,
    # build the sub-topics, if requested
    %msg_counts = &AppMsgCounts($msg_cursor);
    if ($msg_counts{'error'} || $msg_counts{'abort'} || $msg_counts{'fatal'} ) {
        # do nothing
    }
    elsif ($SDF_USER'var{'HTML_TOPICS_MODE'}) {

        $main = $SDF_USER'var{'DOC_BASE'};
        @topics_table = ();
        @jumps_table = ();
        &_HtmlBuildTopicsData($main, *topics_table, *jumps_table);

        # Save the topics and jump data, so users can (eventually) rebuild
        # just a single topic.
        if ($SDF_USER'var{'HTML_SDJ'}) {
            &_HtmlSaveTopicsData($main, *topics_table, *jumps_table);
        }

        # Initialise things ready for the next pass
        %var2 = %convert_var;      # get the original set of variables
        $var2{'HTML_MAIN_TITLE'} = $SDF_USER'var{'DOC_TITLE'};
        $var2{'HTML_URL_CONTENTS'} = $SDF_USER'var{'DOC_BASE'} . ".html";
        $var2{'HTML_TOPICS_MODE'} = 0;
        $var2{'HTML_SUBTOPICS_MODE'} = 1;
        &SdfInit(*var2);
        &SDF_USER'topics_Filter(*topics_table, 'data', 1);
        &SDF_USER'jumps_Filter(*jumps_table, 'data', 1);

        # Build the sub-topics
        @contents2 = ();
#printf "DATA2:\n%s\nENDDATA2\n", join("\n", @data2);
        @result2 = &_HtmlFormatSection(*data2, *contents2);

        # Save away any unclosed topics
        while (@_html_topic_file) {
            &_HtmlHandlerOutput(*result2, '-');
        }
    }

    # Return the result
    return @result;
}

#
# >>_Description::
# {{Y:_HtmlBuildTopicsData}} builds the topics data
# needed for sub-topic building.
#
sub _HtmlBuildTopicsData {
    local($main, *topics_table, *jumps_table) = @_;
#   local();
    local($topic, $level, $label, $next, $prev, $up, %last_at);
    local($jump, $physical);

    # Ensure that the main topic is first and that it has the highest level
    if ($SDF_USER'topics[0] eq $main) {
        $SDF_USER'levels[0] = 0;
    }
    else {
        unshift(@SDF_USER'topics, pop(@SDF_USER'topics));
        pop(@SDF_USER'levels);
        unshift(@SDF_USER'levels, 0);
    }

    # Build the topics table
    @topics_table = ("Topic|Label|Level|Next|Prev|Up");
    $prev = $SDF_USER'topics[$#SDF_USER'topics];
    %last_at = ();
    for ($i = 0; $i <= $#SDF_USER'topics; $i++) {
        $topic = $SDF_USER'topics[$i];
        $level = $SDF_USER'levels[$i];
        $label = $SDF_USER'topic_label{$topic};
        $next  = $i < $#SDF_USER'topics ? $SDF_USER'topics[$i + 1] : $SDF_USER'topics[0];
        $up    = $last_at{$level - 1};
        push(@topics_table, "$topic|$label|$level|$next|$prev|$up");

        # Save state for later iterations
        $prev = $topic;
        $last_at{$level} = $topic;
    }

    # Build the jumps table
    @jumps_table = ("Jump|Physical");
    for $jump (sort keys %SDF_USER'jump) {
        $physical = $SDF_USER'jump{$jump};
        push(@jumps_table, "$jump|$physical");
    }
}

#
# >>_Description::
# {{Y:_HtmlSaveTopicsData}} dumps topic and jump data to a file.
#
sub _HtmlSaveTopicsData {
    local($main, *topics_table, *jumps_table) = @_;
#   local();
    local($file);

    # Save the topic and jump data
    $file = &NameJoin('', $main, 'sdj');
    unless (open(SDM, ">$file")) {
        &AppMsg("warning", "unable to update topics file '$file'");
    }
    else {
        # Output a warning message at the top
        print SDM "# WARNING: This file is automatically generated\n";
        print SDM "# by SDF, so any changes you make will be lost!\n";

        # Dump the topics data
        print SDM "\n";
        print SDM "!block topics; data\n";
        print SDM join("\n", @topics_table), "\n";
        print SDM "!endblock\n";

        # Dump the jumps data
        print SDM "\n";
        print SDM "!block jumps\n";
        print SDM join("\n", @jumps_table), "\n";
        print SDM "!endblock\n";

        # Close the file
        close(SDM);
    }
}

#
# >>_Description::
# {{Y:_HtmlFormatSection}} formats a set of SDF paragraphs into HTML.
# If a parameter is passed to contents, then that array is populated
# with a generated Table of Contents.
#
sub _HtmlFormatSection {
    local(*data, *contents) = @_;
    local(@result);
    local($prev_tag, $prev_indent);
    local($para_tag, $para_text, %para_attrs);
    local($directive);

    ## Reset the ordered list state. I'm not absolutely sure that
    ## this is the best place to do this, but TJH had it here
    ## and I trust him (most of the time :-)
    #$_html_in_olist = 0;

    # Process the paragraphs
    @result = ();
    $prev_tag = '';
    $prev_indent = '';
    while (($para_text, $para_tag, %para_attrs) = &SdfNextPara(*data)) {

        # handle directives
        if ($para_tag =~ /^__(\w+)$/) {
            $directive = $_HTML_HANDLER{$1};
            if (defined &$directive) {
                &$directive(*result, $para_text, %para_attrs);
            }
            else {
                &AppMsg("warning", "ignoring internal directive '$1' in HTML driver");
            }
            next;
        }

        # Add the paragraph
        &_HtmlParaAdd(*result, $para_tag, $para_text, *para_attrs, $prev_tag,
          $prev_indent, *contents);
    }

    # Do this stuff before starting next loop iteration
    continue {
        $prev_tag = $para_tag;
        $prev_indent = $para_attrs{'in'};
    }

    ## Filter out the dummy tag we use to get lists right
    #for ($i = 0; $i < $#result; $i++) {
    #    $result[$i] =~ s#</?xL>##g;
    #}

    # Return result
    return @result;
}
       
#
# >>_Description::
# {{Y:_HtmlParaAdd}} adds a paragraph.
#
sub _HtmlParaAdd {
    local(*result, $para_tag, $para_text, *para_attrs, $prev_tag, $prev_indent, *contents) = @_;
#   local();
    local($is_example);
    local($para_fmt);
    local($para_override);
    local($para);
    local($hdg_level);
    local($toc_jump);
    local($label);
    local($indent);
    local($list_tag);
    local($note_line_width);
    local($note_attrs);

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
    $para_fmt = $is_example ? 'PRE' : 'P' if $para_fmt eq '';

    # Map the attributes
    &SdfAttrMap(*para_attrs, 'html', *SDF_USER'paraattrs_to,
      *SDF_USER'paraattrs_map, *SDF_USER'paraattrs_attrs,
      $SDF_USER'parastyles_attrs{$para_tag});

    # Build the Table of Contents as we go
    $toc_jump = '';
    if ($para_tag =~ /^([HAP])(\d)$/) {
        $hdg_level = $2;
        my $orig_para_text = $para_text;
        $para_text = &SdfHeadingPrefix($1, $2) . $para_text;
        if ($SDF_USER'var{'HTML_SUBTOPICS_MODE'}) {
            $para_fmt = "H" . substr($para_attrs{'orig_style'}, 1);
        }
        else {
            $para_fmt = "H" . $hdg_level;
        }
        if ($hdg_level <= $SDF_USER'var{'DOC_TOC'} && !$para_attrs{'notoc'}) {

            # Build a plain list in SDF. If we're building topics and we're
            # building the contents, make sure the jumps go to the right spot.
            if ($SDF_USER'var{'HTML_TOPICS_MODE'}) {
                #$toc_jump = &NameJoin('', $SDF_USER'var{'FILE_BASE'}, "html");
                #if ($SDF_USER'topic_label{$SDF_USER'var{'FILE_BASE'}} ne $para_text) {
                #    $toc_jump .= "#" . $para_attrs{'id'};
                #}
                $toc_jump = $_html_jump_id{$SDF_USER'var{'FILE_BASE'},$orig_para_text};
            }
            else {
                $toc_jump = "#" . $para_attrs{'id'};
                $toc_jump = "#HDR" . ($#contents + 1) if $toc_jump eq '#';
            }
            #$toc_jump =~ s/(['\\])/\\$1/g;
            #push(@contents, "L${hdg_level}" . "[jump='$toc_jump']$para_text");
            push(@contents, &SdfJoin("L${hdg_level}", $para_text,
                "jump", $toc_jump));
        }
    }

    # Handle lists
    elsif ($para_tag =~ /^(L[FUN]?)(\d)$/) {
        $para_attrs{'in'} = $2;
        if ($1 eq 'LU') {
            $para_fmt = 'UL';
        }
        elsif ($1 eq 'L') {
            $para_fmt = 'UL PLAIN';
        }
        else {
            $para_fmt = 'OL';
        }
    }

    # Handle user-defined formatting
    if ($para_attrs{'out_style'}) {
        $para_fmt = $para_attrs{'out_style'};
        delete $para_attrs{'out_style'};
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
        $para = &_HtmlEscape($para_text);
        delete $para_attrs{'verbatim'};
    }
    else {
        $para = &_HtmlParaText($para_text);
    }

    # Add surrounding lines for a note
    $note_line_width = 80;              # Hard-coded for now
    $note_attrs = "WIDTH=\"$note_line_width%\" ALIGN=\"Left\"";
    if ($para_tag eq 'Note') {
        $para = "<HR $note_attrs>\n$para\n<HR $note_attrs>";
    }
    elsif ($para_tag eq 'NB') {
        $para = "<HR $note_attrs>\n$para";
    }
    elsif ($para_tag eq 'NE') {
        $para = "<HR $note_attrs>";
    }

    # Empty cells look ugly so the hack below
    # puts a space in empty paragraphs inside cells.
    # Unfortunately, this means truly empty paragraphs
    # inside cells are not handled. Is this an issue?
    $para = '&nbsp;' if $para eq '' && @_html_tbl_state;

    ## Examples with change bars currently come out as separate
    ## paragraphs - this fixes the problem, for now
    #delete $para_attrs{'changed'} if $para_attrs{'changed'};

    # Build result
    $indent = $para_attrs{'in'};
    #if ($is_example && $para_tag eq $prev_tag && !%para_attrs) {
    if ($is_example && $para_tag eq $prev_tag) {
        &_HtmlParaAppend(*result, $para);
    }
    elsif ($indent && $prev_indent != 0) {
        $item = &_HtmlElement($para_fmt, $para, %para_attrs);
        &_HtmlItemAppend(*result, $item, $indent, $prev_indent, $para_tag,
          $prev_tag, *para_attrs);
    }

    # If the first paragraph inside a table cell is a plain paragraph,
    # then we do not surrounded it by <P> and </P> as
    # Netscape then outputs too much whitespace.
    elsif (@_html_tbl_state && $_html_cell_paracnt++ == 0 && $para_fmt eq 'P') {
        push(@result, $para);
    }
    else {
        $para = &_HtmlElement($para_fmt, $para, %para_attrs);

        # Handle lists which begin at an indent greater than 1
        $list_tag = substr($para, 1, 2) if $indent;
        while (--$indent > 0) {
            $para = "<$list_tag>$para</$list_tag>";
        }

        # Prepend the table of contents jump id, if necessary
        if ($toc_jump =~ /^#HDR\d+$/) {
            $para = "<A NAME=\"$toc_jump\"> </A>\n$para";
        }
        push(@result, $para);
    }
}

#
# >>_Description::
# {{Y:_HtmlParaText}} converts SDF paragraph text into HTML.
# 
sub _HtmlParaText {
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
            $para .= &_HtmlEscape($text);
        }

        elsif ($sect_type eq 'phrase') {

            # Expand out link phrases
            if ($char_tag eq 'L') {
                ($text, $url) = &SDF_USER'ExpandLink($text);
                $sect_attrs{'jump'} = $url;
            }

            # Escape any special characters
            $text = &_HtmlEscape($text);

            # Expand non-breaking spaces, if necessary
            if ($char_tag eq 'S') {
                $text =~ s/ /&nbsp; /g;
            }

            # Empty cells look ugly so the hack below
            # puts a space in empty phrases inside cells.
            # Unfortunately, this means truly empty phrases
            # inside cells are not handled. Is this an issue?
            $text = '&nbsp;' if $text eq '' && @_html_tbl_state;

            # If this is a jump, ignore the style (i.e. make it 'as-is')
            #$char_tag = 'A' if $sect_attrs{'jump'} ne '';

            # Add hypertext stuff
            $added_anchors = &_HtmlAddAnchors(*text, *sect_attrs);

            # Process formatting attributes
            &SdfAttrMap(*sect_attrs, 'html', *SDF_USER'phraseattrs_to,
              *SDF_USER'phraseattrs_map, *SDF_USER'phraseattrs_attrs,
              $SDF_USER'phrasestyles_attrs{$char_tag});

            # Map the font
            $char_font = $SDF_USER'phrasestyles_to{$char_tag};
            $char_font = $char_tag if $char_font eq '' && !$added_anchors;

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
            $directive = $_HTML_PHRASE_HANDLER{$char_tag};
            if (defined &$directive) {
                &$directive(*para, $text, %sect_attrs);
            }
            else {
                &AppMsg("warning", "ignoring special phrase '$1' in HTML driver");
            }
        }

        else {
            &AppMsg("warning", "unknown section type '$sect_type' in HTML driver");
        }
    }

    # Return result
    return $para;
}

#
# >>_Description::
# {{Y:_HtmlFinalise}} generates the final HTML file.
#
sub _HtmlFinalise {
    local(*body, *contents) = @_;
#   local(@result);
    local($title, @sdf_title, @title);
    local($version, @head);
    local($body);
    local($macro, @header, @footer);
    local(@dummy);
    local($rec, @html_contents, $toc_posn);

    # Build the BODY opening stuff
    $body = "BODY";
    $body .= sprintf(' BACKGROUND="%s"', $SDF_USER'var{"HTML_BG_IMAGE"}) if
                                  defined($SDF_USER'var{"HTML_BG_IMAGE"});
    $body .= sprintf(' BGPROPERTIES="FIXED"') if $SDF_USER'var{"HTML_BG_FIXED"};
    $body .= sprintf(' BGCOLOR="%s"', $SDF_USER'var{"HTML_BG_COLOR"}) if
                               defined($SDF_USER'var{"HTML_BG_COLOR"});
    $body .= sprintf(' TEXT="%s"',    $SDF_USER'var{"HTML_TEXT_COLOR"}) if
                               defined($SDF_USER'var{"HTML_TEXT_COLOR"});
    $body .= sprintf(' LINK="%s"',    $SDF_USER'var{"HTML_LINK_COLOR"}) if
                               defined($SDF_USER'var{"HTML_LINK_COLOR"});
    $body .= sprintf(' VLINK="%s"',   $SDF_USER'var{"HTML_VLINK_COLOR"}) if
                               defined($SDF_USER'var{"HTML_VLINK_COLOR"});

    # Convert the title, if any, to HTML
    $title = $SDF_USER'var{'HTML_TITLE'};
    $title = $SDF_USER'var{'DOC_TITLE'} if !defined($title);
    if ($title) {
        @sdf_title = ("TITLE:$title");
        @title = &_HtmlFormatSection(*sdf_title, *dummy);
    }
    else {
        @title = ();
    }

    # Build the HEAD element (and append BODY opening)
    $version = $SDF_USER'var{'SDF_VERSION'};
    @head = (
        '<!doctype html public "-//W30//DTD W3 HTML 2.0//EN">',
        '',
        '<HTML>',
        '',
        "<!-- This file was generated using SDF $version by",
        '     Ian Clatworthy (ianc@mincom.com). SDF is freely',
        '     available from http://www.mincom.com/mtr/sdf. -->',
        '',
        '<HEAD>',
    );
    push(@head, @title) if @title;
    push(@head, '</HEAD>', "<$body>", '');

    # Add the pre-header, if any
    my $pre_header = $SDF_USER'var{'HTML_PRE_HEADER'};
    push(@head, $pre_header) if $pre_header ne '';

    # Convert the header, if any, to HTML
    $macro = 'HTML_HEADER';
    if ($SDF_USER'var{'HTML_SUBTOPICS_MODE'} &&
        $SDF_USER'macro{'HTML_TOPIC_HEADER'}) {
        $macro = 'HTML_TOPIC_HEADER';
    }
    if ($SDF_USER'macro{$macro} ne '') {
        @header = ("!$macro");
        push(@head, &_HtmlFormatSection(*header, *dummy));
    }

    # If requested, provide a Table of Contents
    if (@contents) {

        # Finish formatting the table of contents
        # Note: we use a filter so that experts can override things!
        &SDF_USER'toc_html_Filter(*contents);

        # Now convert it to HTML
        @html_contents = &_HtmlFormatSection(*contents, *dummy);

        # Insert it before the first entry in the contents so that
        # cover page stuff remains at the top. Alternatively, place
        # it at the top
        $toc_posn = 0;
        for $rec (@body) {
            if ($rec eq '<!-- TOC -->') {
                $rec = join("\n", $rec, @html_contents);
                @html_contents = ();
                last;
            }
            $toc_posn++;
        }
        if (@html_contents) {
            $toc_posn = 0;
            unshift(@body, join("\n", @html_contents));
        }

        # If this is a MAIN document, ditch the body after the contents.
        if ($SDF_USER'var{'HTML_TOPICS_MODE'}) {
            splice(@body, $toc_posn + 1);
        }
    }

    # Convert the footer, if any, to HTML
    $macro = 'HTML_FOOTER';
    if ($SDF_USER'var{'HTML_SUBTOPICS_MODE'} &&
        $SDF_USER'macro{'HTML_TOPIC_FOOTER'}) {
        $macro = 'HTML_TOPIC_FOOTER';
    }
    if ($SDF_USER'macro{$macro} ne '') {
        @footer = ("!$macro");
        push(@body, &_HtmlFormatSection(*footer, *dummy));
    }

    # Add the post-footer, if any
    my $post_footer = $SDF_USER'var{'HTML_POST_FOOTER'};
    push(@body, $post_footer) if $post_footer ne '';

    # Return result
    push(@body, '', '</BODY>', '</HTML>');
    return (@head, @body);
}

#
# >>_Description::
# {{Y:_HtmlEscape}} escapes special symbols in HTML text.
# 
sub _HtmlEscape {
    local($text) = @_;
#   local($result);
    local($old_match_flag);

    # Enable multi-line matching
    $old_match_flag = $*;
    $* = 1;

    # Escape the symbols
    $text =~ s/\&/&amp;/g;
    $text =~ s/\</&lt;/g;
    $text =~ s/\>/&gt;/g;
    $text =~ s/\"/&quot;/g;

    # Reset multi-line matching flag
    $* = $old_match_flag;

    # Return result
    $text;
}

#
# >>_Description::
# {{Y:_HtmlAttr}} formats a set of attributes into HTML.
# 
sub _HtmlAttr {
    local(*attrs) = @_;
    local($html);
    local($attr, $value, $type);

    for $attr (sort keys %attrs) {

        # get the attribute value
        $value = $attrs{$attr};

        # get the attribute type
        if ($attr =~ s/^html\.//) {
            $type = $_HTML_ATTR_TYPES{$attr};
            $type = "string" if $type eq '';
        }
        else {
            $type = $_HTML_ATTR_TYPES{$attr};
        }
        next unless $type;

        # Map the attribute name to uppercase
        $attr =~ tr/a-z/A-Z/;

        # build the result
        if ($type eq 'string') {
            $html .= " $attr=\"" . &_HtmlEscape($value) . '"';
        }
        else {
            $html .= " $attr=$value";
        }
    }

    # Return result
    $html;
}

#
# >>_Description::
# {{Y:_HtmlElement}} formats a HTML element from a
# tag, text and set of attributes.
#
sub _HtmlElement {
    local($tag, $text, %attr) = @_;
#   local($html);

    # For preformatted sections, tags go on separate lines
    $text = "\n$text\n" if $tag eq 'PRE';

    # Add hypertext stuff
    &_HtmlAddAnchors(*text, *attr);

    # Bold the text, if requested
    if ($attr{'bold'}) {
        $text = "<B>$text</B>";
    }

    # For list items, add the item stuff
    #$text = "\n<LI>$text" if $tag =~ /^[UOx]L$/;
    $text = "\n<LI>$text" if $tag =~ /^[UO]L$/;
    if ($tag eq 'UL PLAIN') {
        $tag = 'UL';
        $text = "\n$text";
    }

    # Return result
    if ($tag eq 'HR') {
        return "<$tag>$text";
    }
    else {
        return "<$tag" . &_HtmlAttr(*attr) . ">$text</$tag>";
    }
}

#
# >>_Description::
# {{Y:_HtmlAddAnchors}} adds hypertext jumps and ids to a section of text.
# of text. It returns true if anchors were added.
# 
sub _HtmlAddAnchors {
    local(*text, *attr) = @_;
    local($result);
    local($value);
    local($user_ext);
    local($old_match_flag);

    # Enable multi-line matching
    $old_match_flag = $*;
    $* = 1;

    # For hypertext jumps, surround the text. If the
    # text contains a jump, the existing jump is removed.
    if ($attr{'jump'} ne '') {

        # Get the jump value. If an extension other than html is
        # requested, change the jump value accordingly. Also,
        # we make sure than any special characters are escaped.
        $value = $attr{'jump'};
        $user_ext = $SDF_USER'var{'HTML_EXT'};
        if ($user_ext) {
            $value =~ s/\.html/.$user_ext/;
        }
        $value = &_HtmlEscape($value);

        $text =~ s/\<A HREF\=[^>]+\>(.*)\<\/A\>/$1/;
        $text = "<A HREF=\"$value\">$text</A>";
        delete $attr{'jump'};
        $result++;
    }

    # For hypertext ids, surround the text if it doesn't already contain
    # a jump. Otherwise, prefix the text with a dummy target so that
    # jump and id definitions don't clash.
    if ($attr{'id'} ne '') {
        $value = &_HtmlEscape($attr{'id'});
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
# {{Y:_HtmlParaAppend}} merges {{para}} into the last paragraph
# in {{@result}}. Both paragraphs are assumed to be PREformatted.
#
sub _HtmlParaAppend {
    local(*result, $para) = @_;
#   local();

    substr($result[$#result], -6) = "$para\n</PRE>";
}

#
# >>_Description::
# {{Y:_HtmlItemAppend}} merges a list item {{item}} into the current
# output. The item before is assumed to be a list item too.
#
sub _HtmlItemAppend {
    local(*result, $item, $indent, $prev_indent, $para_tag, $prev_tag, *para_attrs) = @_;
#   local();
    local($type, $prev_type);
    local($posn, $end_tokens);

    # Get the list type and previous type
    $type = substr($item, 1, 2);
    $prev_type = substr($result[$#result], -3, 2);

    # Indent is increasing
    if ($indent > $prev_indent) {
        $posn = -5 * $prev_indent;
        while (++$prev_indent < $indent) {
            $item = "<$type>$item</$type>";
        }
    }

    # Indent is descreasing or the same
    else {
        # plain items are compatible with both ordered and unordered lists, so
        # we need to handle them separately
        if (substr($item, 4, 5) ne "\n<LI>") {
            $posn = -5 * $indent;
            $item = substr($item, 4, length($item) - 9);
            $item = "\n<BR>$item";

            ## If the previous tag is the same but the indents differ,
            ## this is an enumerated list item so prepend another newline.
            #if ($para_tag eq $prev_tag && $prev_indent != $indent) {
            #    $item = "\n<BR>$item";
            #}
        }

        # handle items of an existing list
        elsif ($type eq $prev_type) {
            $posn = -5 * $indent;
            $item = substr($item, 4, length($item) - 9);
        }

        # item is not compatible with the current list - start a new one
        else {
            $indent--;
            $posn = $indent ? (-5 * $indent) : length($result[$#result]);
        }
    }

    # Merge the item
    $end_tokens = substr($result[$#result], $posn);
    substr($result[$#result], $posn) = "$item$end_tokens";
}

#
# >>_Description::
# {{Y:_HtmlHandlerTuning}} handles the 'tuning' directive.
#
sub _HtmlHandlerTuning {
    local(*outbuffer, $style, %attr) = @_;
#   local();

    # do nothing
}

#
# >>_Description::
# {{Y:_HtmlHandlerEndTuning}} handles the 'endtuning' directive.
#
sub _HtmlHandlerEndTuning {
    local(*outbuffer, $style, %attr) = @_;
#   local();

    # do nothing
}

#
# >>_Description::
# {{Y:_HtmlHandlerTable}} handles the 'table' directive.
#
sub _HtmlHandlerTable {
    local(*outbuffer, $columns, %attr) = @_;
#   local();
    local($indent, $previous_indent, $posn, $begin_tokens, $end_tokens);
    local($header);
    local($tbl_title);

    # Handle tables inside a list
    # Note: the previous indent is available as a dynamically
    # scoped variable in &HtmlFormatSection
    $indent = $attr{'listitem'};
    $begin_tokens = '';
    $end_tokens = '';
    if ($indent) {
        $previous_indent = $prev_indent;    # get dynamically scoped var
        if ($indent > $previous_indent) {
            $posn = -5 * $previous_indent;
            while ($previous_indent++ < $indent) {
                $begin_tokens .= "<UL>";
                $end_tokens .= "</UL>";
            }
        }
        else {
            $posn = -$indent * 5;
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
    push(@_html_tbl_state, $_HTML_INTABLE);
    push(@_html_tbl_endtokens, $end_tokens);
    push(@_html_tbl_previndent, $indent);

    # Build the header
    $header = $attr{'style'} eq 'plain' ? '' : " BORDER";
    if (defined($attr{'cellspacing'})) {
        $header .= " CELLSPACING='$attr{'cellspacing'}'";
    }
    if (defined($attr{'cellpadding'})) {
        $header .= " CELLPADDING='$attr{'cellpadding'}'";
    }
    if ($attr{'align'}) {
        my $align = $attr{'align'};
        $align = 'Left'  if $align eq 'Inner';
        $align = 'Right' if $align eq 'Outer';
        $header .= " ALIGN='$align'";
    }
    if ($attr{'bgcolor'}) {
        $header .= " BGCOLOR='$attr{'bgcolor'}'";
    }

    # Update the output buffer
    push(@outbuffer, "<TABLE" . $header . ">");

    # Add the title, if any
    $tbl_title = $attr{'title'};
    if ($tbl_title ne '') {
        push(@outbuffer, "<CAPTION ALIGN=top>" . $tbl_title . "</CAPTION>");
    }
}

#
# >>_Description::
# {{Y:_HtmlHandlerRow}} handles the 'row' directive.
#
sub _HtmlHandlerRow {
    local(*outbuffer, $text, %attr) = @_;
#   local();
    local($state);

    # Finalise the old cell/row, if any
    $state = $_html_tbl_state[$#_html_tbl_state];
    if ($state eq $_HTML_INCELL) {
        push(@outbuffer, "</TD>", "</TR>");
    }
    elsif ($state eq $_HTML_INROW) {
        push(@outbuffer, "</TR>");
    }

    # Update the state
    $_html_tbl_state[$#_html_tbl_state] = $_HTML_INROW;

    # Update the output buffer
    push(@outbuffer, "<TR>");
}

#
# >>_Description::
# {{Y:_HtmlHandlerCell}} handles the 'cell' directive.
#
sub _HtmlHandlerCell {
    local(*outbuffer, $text, %attr) = @_;
#   local();
    local($state);
    local($header);

    # Reset the paragraph conter for this cell
    $_html_cell_paracnt = ();

    # If the cell is hidden, output nothing
    return if $attr{'hidden'};

    # Finalise the old cell, if any
    $state = $_html_tbl_state[$#_html_tbl_state];
    if ($state eq $_HTML_INCELL) {
        push(@outbuffer, "</TD>");
    }

    # Update the state
    $_html_tbl_state[$#_html_tbl_state] = $_HTML_INCELL;

    # Build the header
    $header = '';
    if (defined($attr{'align'})) {
        $header .= " ALIGN='$attr{'align'}'";
    }
    if (defined($attr{'valign'})) {
        $header .= " VALIGN='$attr{'valign'}'";
    }
    if ($attr{'cols'} != 1) {
        $header .= " COLSPAN='$attr{'cols'}'";
    }
    if ($attr{'rows'} != 1) {
        $header .= " ROWSPAN='$attr{'rows'}'";
    }
    if (defined($attr{'nowrap'})) {
        $header .= " NOWRAP";
    }
    if (defined($attr{'bgcolor'})) {
        $header .= " BGCOLOR='$attr{'bgcolor'}'";
    }

    # Update the output buffer
    push(@outbuffer, "<TD$header>");
}

#
# >>_Description::
# {{Y:_HtmlHandlerEndTable}} handles the 'endtable' directive.
#
sub _HtmlHandlerEndTable {
    local(*outbuffer, $text, %attr) = @_;
#   local();
    local($state);
    local($end_tokens);

    # Finalise the table
    $state = pop(@_html_tbl_state);
    if ($state eq $_HTML_INCELL) {
        push(@outbuffer, "</TD>", "</TR>");
    }
    elsif ($state eq $_HTML_INROW) {
        push(@outbuffer, "</TR>");
    }
    push(@outbuffer, "</TABLE>");

    # Terminate the list, if any
    $end_tokens = pop(@_html_tbl_endtokens);
    push(@outbuffer, $end_tokens);

    # Restore the previous indent. We do this by hacking the
    # %para_attrs hash dynamically scoped in &HtmlFormatSection. :-(
    $para_attrs{'in'} = pop(@_html_tbl_previndent);
}

#
# >>_Description::
# {{Y:_HtmlHandlerImport}} handles the import directive.
#
sub _HtmlHandlerImport {
    local(*outbuffer, $filepath, %attr) = @_;
#   local();
    local($para);

    # Build the result
    &_HtmlPhraseHandlerImport(*para, $filepath, %attr);
    push(@outbuffer, &_HtmlElement('P', $para));
}

#
# >>_Description::
# {{Y:_HtmlHandlerInline}} handles the inline directive.
#
sub _HtmlHandlerInline {
    local(*outbuffer, $text, %attr) = @_;
#   local();

    # Check we can handle this format
    my $target = $attr{'target'};
    return unless $target eq 'html';

    # Build the result
    push(@outbuffer, $text);
}

#
# >>_Description::
# {{Y:_HtmlHandlerOutput}} handles the output directive.
#
sub _HtmlHandlerOutput {
    local(*outbuffer, $text, %attr) = @_;
#   local();
    local($offset, @topic_data, @dummy_contents);
    local($file);
    local($this_topic);

    # Finalise the current topic, if requested
    if ($text eq '-') {
        # If there is no current topic, do nothing
        return unless @_html_topic_offset;

        # Generate the html for the topic
        $offset = pop(@_html_topic_offset);
        @topic_data = splice(@outbuffer, $offset + 1);
#printf "TOPIC:\n%s\nENDTOPIC\n", join("\n", @topic_data);
        @topic_data = &_HtmlFinalise(*topic_data, *dummy_contents);

        # Output the topic
        $file = pop(@_html_topic_file);
#print STDERR "offset: $offset, file: $file.\n";
        unless (open(TOPIC, ">$file")) {
            &AppMsg("error", "unable to write to topic file '$file'");
            return;
        }
        print TOPIC join("\n", @topic_data), "\n";
        close(TOPIC);
    }

    # Otherwise, save the output filename and the current offset
    else {
        push(@_html_topic_file, $text);
        push(@_html_topic_offset, $#outbuffer);
    }

    # Update the current topic name (without the extension)
    $this_topic = $_html_topic_file[$#_html_topic_file];
    $this_topic =~ s/\.html$//;
    $SDF_USER'var{'HTML_TOPIC'} = $this_topic;
#print STDERR "HTML_TOPIC: $this_topic.\n";
}

#
# >>_Description::
# {{Y:_HtmlHandlerObject}} handles the 'object' directive.
#
sub _HtmlHandlerObject {
    local(*outbuffer, $text, %attrs) = @_;
#   local();

    # do nothing
}

#
# >>_Description::
# {{Y:_HtmlPhraseHandlerChar}} handles the 'char' phrase directive.
#
sub _HtmlPhraseHandlerChar {
    local(*para, $text, %attr) = @_;
#   local();

    # Map the symbolic names
    if (defined($_HTML_CHAR{$text})) {
        $para .= $_HTML_CHAR{$text};
    }
    else {
        # Numbers are ISO character codes
        $para .= $text =~ /\D/ ? "&$text;" : "&#$text;";
    }
}

#
# >>_Description::
# {{Y:_HtmlPhraseHandlerImport}} handles the 'import' phrase directive.
#
sub _HtmlPhraseHandlerImport {
    local(*para, $filepath, %attr) = @_;
#   local();
    local($name, $value);
    local($jump);
    local($pre, $post);

    if ( $attr{'align'} eq 'center' ) {
    	$pre='<CENTER>';
    	$post='</CENTER>';
    } else {
    	$pre='';
    	$post='';
    }

    # Map the attributes to HTML
    while (($name, $value) = each %attr) {
        # Simple for now
        delete $attr{$name} if $name eq 'fullname';
        delete $attr{$name} if $name eq 'width';
        delete $attr{$name} if $name eq 'height';
    }

    # Build the result
    $para .= $pre;
    if ($attr{'jump'} ne '') {
        $jump = $attr{'jump'};
        delete $attr{'jump'};

        # Disable the border unless it is explicitly asked for
        $attr{'border'} = 0 unless $attr{'border'};

        $para .= "<A HREF=\"$jump\">" .
                 "<IMG SRC=\"$filepath\"". &_HtmlAttr(*attr) . "></A>";
    }
    else {
        $para .= "<IMG SRC=\"$filepath\"". &_HtmlAttr(*attr) . ">";
    }
    $para .= $post;
}

#
# >>_Description::
# {{Y:_HtmlPhraseHandlerInline}} handles the 'inline' phrase directive.
#
sub _HtmlPhraseHandlerInline {
    local(*para, $text, %attr) = @_;
#   local();

    # Build the result
    $para .= $text;
}

#
# >>_Description::
# {{Y:_HtmlPhraseHandlerVariable}} handles the 'variable' phrase directive.
#
sub _HtmlPhraseHandlerVariable {
    local(*para, $text, %attr) = @_;
#   local();

    # do nothing
}
package SDF_USER;

#
# >>Description::
# {{Y:HtmlTopicsModeHeading}} is an event processing routine for
# headings when topics mode is enabled.
#
sub HtmlTopicsModeHeading {
#   local() = @_;
#   local();
    local($level, $file_base);
    local($jump);
    local($topic_base, $topic_file);
    local(@prepend);
    local($new_level, $close_count, $i);
    local($title);

    # As the heading for the main document might be built in the
    # "front" component, we explicitly ignore headings in sdm files
    return if $var{'FILE_EXT'} eq 'sdm';

    # If this heading doesn't have an id, ignore it
    return if $attr{'noid'};

    # Get the heading level and containing file
    $level = substr($style, 1, 1);
    $file_base = $var{'FILE_BASE'};

    # When processing the main file:
    # * detect the first heading in each SDF file or a
    #   certain level heading as a topic boundary (and save
    #   the heading text as the label for that topic)
    # * save the file each section lives in, so that
    #   section jumps work as expected
    if ($var{'HTML_TOPICS_MODE'}) {
        if (! $topic_label{$file_base}) {
            $'_html_topic = $file_base;
            push(@levels, $level);
            push(@topics, $'_html_topic);
            $topic_label{$'_html_topic} = $text;
            $topic_level{$'_html_topic} = $level;
            $jump = $'_html_topic . ".html";
            $'_html_topic_start{$file_base,$text} = $'_html_topic;
        }
        elsif ($level <= $var{'OPT_SPLIT_LEVEL'}) {
            if ($'_html_topic_start{$file_base,$text}) {
                &'AppMsg("warning", "file base '$file_base' & topic heading '$text' combination is not unique'");
                return;
            }
            $'_html_topic = &HtmlTopicName($var{'DOC_BASE'});
            push(@levels, $level);
            push(@topics, $'_html_topic);
            $topic_label{$'_html_topic} = $text;
            $topic_level{$'_html_topic} = $level;
            $jump = $'_html_topic . ".html";
            $'_html_topic_start{$file_base,$text} = $'_html_topic;
        }
        else {
            if ($attr{'id'} ne '') {
                $jump = $'_html_topic . ".html#" . $attr{"id"};
            }
            else {
                $jump = $'_html_topic . ".html#" . &TextToId($text);
            }
        }

        # Save the jump for this file/text combination.
        # This is used for TOC generation.
        $'_html_jump_id{$file_base,$text} = $jump;

        # Save the place to jump to for this text.
        # The jump table is used to resolve SECT jumps (in topics mode).
        if ($jump{$text} eq '') {
            $jump{$text} = $jump;
            $jump_level{$text} = $level;
        }
        else {
            # Override the jump if the new jump is more important
            if ($level < $jump_level{$text}) {
                $jump{$text} = $jump;
                $jump_level{$text} = $level;
            }
        }
    }

    # Otherwise, we're creating sub-topics
    else {
        # If this heading starts a topic:
        # * prepend the necessary output directives
        # * make it the title
        # * prevent a line above it by setting the notoc attribute.
        $topic_base = $'_html_topic_start{$file_base,$text};
        if ($topic_base) {
            $topic_file = "$topic_base.html";
            @prepend = ();
            $new_level = $topic_level{$topic_base};
            $close_count = $'_html_topic_level - $new_level + 1;
            $'_html_topic_level = $new_level;
            for ($i = 0; $i < $close_count; $i++) {
                push(@prepend, "!output '-'");
            }
            $title = $text;
            $title =~ s/(['\\])/\\$1/g;
            push(@prepend,
                "[jump='$topic_file'] $text",
                "!output '$topic_file'",
                #"!define HTML_TOPIC '$topic_base'",
                "!define DOC_TITLE '$title'",
                "!HTML_BUILD_TITLE");
            &PrependText(@prepend);
            $attr{'notoc'} = 1;
        }
    }
}

# Generate a name for a topic
sub HtmlTopicName {
    local($base) = @_;
    local($tname);

    $'_html_topic_cntr++;
    $tname = $var{'HTML_TOPIC_PATTERN'};
    $tname = '$b_$n' if $tname eq '';
    $tname =~ s/\$b/$base/g;
    $tname =~ s/\$n/$'_html_topic_cntr/;
    return $tname;
}

# package return value
1;
