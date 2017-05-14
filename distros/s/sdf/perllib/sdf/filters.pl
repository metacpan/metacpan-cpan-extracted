# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     SDF Filters Library
#
# >>Copyright::
# Copyright (c) 1992-1996, Ian Clatworthy (ianc@mincom.com).
# You may distribute under the terms specified in the LICENSE file.
#
# >>History::
# -----------------------------------------------------------------------
# Date      Who     Change
# 23-Oct-98 ianc    Add datestrings filter
# 29-Jul-97 peterh  Add 'noslide' parameter to topics filter.
# 29-Feb-96 ianc    SDF 2.000
# -----------------------------------------------------------------------
#
# >>Purpose::
# This library provides the built-in filters for
# [[SDF]] files.
#
# >>Description::
# A filter called {{xxx}} maps to:
#
# * a parameter table called {{_xxx_FilterParams}}
# * a subroutine called {{xxx_Filter}}.
#
# The routine interface is:
#
# =  &xxx_Filter(*text, %param);
#
# :where:
#
# * {{@text}} is the text (original in and result out)
# * {{%param}} is the parameters.
#
# If the text is a table, the filter also has a data model
# (i.e. validation table) called {{xxx_FilterModel}}.
# For mapping tables, the convention is to name
# each associative array xxx_yyy where:
#
# * {{xxx}} is the filter name
# * {{yyy}} is the column name (all in lowercase).
#
# >>Limitations::
# The 'proxy' idea is only supported for phrase styles at the moment.
# Should this be generalised to other configurable entities?
#
# The configuration filters should be rationalised to use one or two
# common support routines.
#
# >>Resources::
#
# >>Implementation::
#


# Switch to the user package
package SDF_USER;

##### Constants #####

##
## >>Description::
## {{Y:TBL_FORMAT}} is the lookup table for default table formats.
## The key is the number of columns.
##
#%TBL_FORMAT = (
#    1,      9,
#    2,      37,
#    3,      334,
#    4,      3331,
#    5,      22222,
#);

#
# >>Description::
# {{Y:DEFAULT_LANG_STYLE}} is the default lookup table for styles used to
# format different parts of a language. The key is the state:
#
# * c - comment
# * a - additional comment
# * s - string
# * l - literal
# * kw - keywords.
#
# By default, comments are placed in italics, keywords in bold and
# strings/literals are fixed-width.
#
# Note: The style must be a single letter as [A-Z]<> style phrases are used.
#
%DEFAULT_LANG_STYLE = (
    'c',    'I',
    'a',    'I',
    's',    'C',
    'l',    'C',
    'kw',   'B',
);

# These are the lookup tables for alignment characters
%_ALIGN_NAMES = (
    'L',    'Left',
    'C',    'Center',
    'R',    'Right',
);
%_VALIGN_NAMES = (
    'T',    'Top',
    'M',    'Middle',
    'B',    'Bottom',
    'L',    'Baseline',
);

##### Variables #####

# flag for table validation
$validate = 0;

# tables of topic info and the jumps for a section
@topics = ();
@levels = ();
%topic_label = ();
%topic_level = ();
%topic_prev = ();
%topic_next = ();
%topic_up = ();
%jump = ();
%jump_label = ();

# state of formatting attributes for the sdf filter
%sdf_attrs = ();
@sdf_attr_stk = ();

# lookup table for language styles & definitions
%languages = ();
%lang_aliases = ();
%lang_style = %DEFAULT_LANG_STYLE;
%lang_keywords = ();
%lang_tokens = ();

# mapping tables for document styles/variables
%docstyles_name = ();
%docstyles_to = ();
%docstyles_vars = ();
%variables_name = ();
%variables_type = ();
%variables_rule = ();

# mapping tables for paragraph styles/attributes
%parastyles_name = ();
%parastyles_category = ();
%parastyles_to = ();
%parastyles_attrs = ();
%paraattrs_name = ();
%paraattrs_type = ();
%paraattrs_rule = ();
%paraattrs_to = ();
%paraattrs_map = ();
%paraattrs_attrs = ();

# mapping tables for phrase styles/attributes
%phrasestyles_name = ();
%phrasestyles_category = ();
%phrasestyles_to = ();
%phrasestyles_attrs = ();
%phraseattrs_name = ();
%phraseattrs_type = ();
%phraseattrs_rule = ();
%phraseattrs_to = ();
%phraseattrs_map = ();
%phraseattrs_attrs = ();

# mapping tables for table styles/parameters
%tablestyles_name = ();
%tablestyles_to = ();
%tablestyles_params = ();
%tableparams_name = ();
%tableparams_type = ();
%tableparams_rule = ();
%tableparams_to = ();
%tableparams_map = ();
%tableparams_params = ();

# mapping tables for row parameters
%rowparams_name = ();
%rowparams_type = ();
%rowparams_rule = ();
%rowparams_to = ();
%rowparams_map = ();
%rowparams_params = ();

# mapping tables for cell parameters
%cellparams_name = ();
%cellparams_type = ();
%cellparams_rule = ();
%cellparams_to = ();
%cellparams_map = ();
%cellparams_params = ();


##### Initialisation #####

#
# >>Description::
# {{Y:InitFilters}} initialises the global variables in this module.
#
sub InitFilters {

    @topics = ();
    @levels = ();
    %topic_label = ();
    %topic_level = ();
    %topic_prev = ();
    %topic_next = ();
    %topic_up = ();
    %jump = ();
    %jump_label = ();

    $validate = $'verbose;
    %sdf_attrs = ();
    @sdf_attr_stk = ();

    %languages = ();
    %lang_aliases = ();
    %lang_style = %DEFAULT_LANG_STYLE;

    %docstyles_name = ();
    %docstyles_to = ();
    %docstyles_vars = ();
    %variables_name = ();
    %variables_type = ();
    %variables_rule = ();

    %parastyles_name = ();
    %parastyles_to = ();
    %parastyles_attrs = ();
    %parastyles_category = ();
    %paraattrs_name = ();
    %paraattrs_type = ();
    %paraattrs_rule = ();
    %paraattrs_to = ();
    %paraattrs_map = ();
    %paraattrs_attrs = ();

    %phrasestyles_name = ();
    %phrasestyles_category = ();
    %phrasestyles_to = ();
    %phrasestyles_attrs = ();
    %phraseattrs_name = ();
    %phraseattrs_type = ();
    %phraseattrs_rule = ();
    %phraseattrs_to = ();
    %phraseattrs_map = ();
    %phraseattrs_attrs = ();

    %tablestyles_name = ();
    %tablestyles_to = ();
    %tablestyles_params = ();
    %tableparams_name = ();
    %tableparams_type = ();
    %tableparams_rule = ();
    %tableparams_to = ();
    %tableparams_map = ();
    %tableparams_params = ();

    %rowparams_name = ();
    %rowparams_type = ();
    %rowparams_rule = ();
    %rowparams_to = ();
    %rowparams_map = ();
    %rowparams_params = ();

    %cellparams_name = ();
    %cellparams_type = ();
    %cellparams_rule = ();
    %cellparams_to = ();
    %cellparams_map = ();
    %cellparams_params = ();
}

##### Support Routines #####

#
# >>_Description::
# {{Y:_FilterValidate}} validates the data for a filter which
# expects a table.
#
sub _FilterValidate {
    local(*data, *model) = @_;
#   local();
    local(@parsed_model);

    # It would be better not to parse this each time, but
    # as it only happens during validate mode, its not worth
    # caching the results just yet
    @parsed_model = &'TableParse(@model);
    &'TableValidate(*data, *parsed_model);
}

#
# >>_Description::
# {{Y:_SkipHeader}} skips the top comment in a block of text where
# the commenting conventions are derived from the language ({{lang}}).
# The default language is {{sdf}}. The top comment must be the first
# thing on the first line of the file (except for {{sdf}} files where
# it may start on the second line if the first line is a {{!init}} line).
#
sub _SkipHeader {
    local(*text, $lang) = @_;
#   local();

    # Get the comment conventions for the nominated language
    $lang = 'sdf' if $lang eq '';
    &_SetLang($lang);
    my $start1 = $lang_tokens{'cb'};
    my $end1   = $lang_tokens{'ce'};
    my $start2 = $lang_tokens{'ab'};
    my $end2   = $lang_tokens{'ae'};

    # For SDF files, ignore the !init line for now, if any
    my $init_line = shift(@text) if $text[0] =~ /^\!init/;


    # Remove the line-based comment, if any
    if ($end1 eq "\n") {
        while ($text[0] =~ /^$start1/) {
            shift(@text);
        }
    }               
    elsif ($end2 eq "\n") {
        while ($text[0] =~ /^$start2/) {
            shift(@text);
        }
    }               

    # Remove the stream-based comment, if any
    elsif ($text[0] =~ /^$start1/) {
        while (@text && $text[0] !~ /$end1/) {
            shift(@text);
        }
        shift(@text) if @text;
    }               
    elsif ($text[0] =~ /^$start2/) {
        while (@text && $text[0] !~ /$end2/) {
            shift(@text);
        }
        shift(@text) if @text;
    }               

    # Restore the !init line, if any
    unshift(@text, $init_line) if $init_line;
}

#
# >>_Description::
# {{Y:_Pure}} escapes special symbols within example text.
# Note that it isn't necessary to escape leading characters or
# patterns as the line will be explicitly tagged later.
#
sub _Pure {
    local(*text) = @_;
#   local();
    local($line);

    # Escape phrase patterns
    for $line (@text) {
        $line =~ s/[<>]/$& eq '>' ? 'E<gt>' : 'E<lt>'/eg;
        if ($line =~ s/\[\[/E<2[>/g) {
            $line =~ s/\]\]/E<2]>/g;
        }
        if ($line =~ s/\{\{/E<2{>/g) {
            $line =~ s/\}\}/E<2}>/g;
        }
    }
}

#
# >>_Description::
# {{Y:_SetLang}} sets the current language to be {{lang}}, i.e. it
# resets the {{lang_token}} and {{lang_keyword}} lookup tables.
# (Thanks to Prachin Ranavat for the initial code.)
#
sub _SetLang {
    local($lang) = @_;
#   local();
    local($x, $name, $value);

    # Get the language tokens
    %lang_tokens = ();
    foreach $x (split(':',$languages{$lang_aliases{$lang}})) {
        ($name, $value) = split('=', $x, 2);

        # Covert vgrind definition metasymbols to perl metasymbols
        $value =~ s/\\d/\\b/g;
        $value =~ s/\\a/.*/g;
        $value =~ s/\\p/\\w+/g;
        $value =~ s/\\e/[^\\\\]?/g;
        $value =~ s/\*/\\*/g;
    	$value = "\n" if $value eq '$';
        $lang_tokens{$name} = $value;
    }

    # Get the keywords
    %lang_keywords = ();
    foreach $x (split(/\s+/, $lang_tokens{'kw'})) {
        $lang_keywords{$x} = 1;
    }
}

#
# >>_Description::
# {{Y:_FmtLang}} formats {{@text}} for the specified language.
# (Thanks to Prachin Ranavat for the initial code.)
#
sub _FmtLang {
    local(*text, $lang) = @_;
#   local();
    local($line);
    local($state);
    local($prefix);

    # Set the current language
    &_SetLang($lang);

    # Process each line of code that needs to be pretty formatted.
    # As each line is a separate paragraph and comments, etc. can
    # be multi-line (but SDF phrases cannot cross paragraph boundaries),
    # we need to end/restart phrases accordingly.
    $state = '';
    for $line (@text) {
        $prefix = $state ? "$lang_style{$state}<" : '';
    	$line =~ s/([^ \r\t\f\(\)\[\]\,\;\=\+\:]+)/&_WordFmt($1, *state)/eg;

        if ($state) {
            $line .= '>';
            $state = '' if $lang_tokens{$state.'e'} eq "\n";
        }
        $line =~ s/(\S)/$prefix$1/ if $prefix;
    }        
}

#
# >>_Description::
# {{Y:_WordFmt}} formats a word of a programming language.
# This routine is used by {{Y:_FmtLang}}.
# (Thanks to Prachin Ranavat for the initial code.)
#
sub _WordFmt {
    local($word, *state) = @_;
    local($result);
    local($start, $token);
    local($keyword);

    # If we are already in a state, look for the ending token
    if ($state) {
        if (($word =~ /$lang_tokens{$state.'e'}$/)) {
            $word .= '>';
            $state = '';
        }
        return $word;
    }

    # Check for a single word within a state
    return "$lang_style{'c'}<$word>" if defined $lang_tokens{'cb'} &&
       $word =~ /^$lang_tokens{'cb'}.*$lang_tokens{'ce'}$/;
    return "$lang_style{'a'}<$word>" if defined $lang_tokens{'ab'} &&
       $word =~ /^$lang_tokens{'ab'}.*$lang_tokens{'ae'}$/;
    return "$lang_style{'s'}<$word>" if defined $lang_tokens{'sb'} &&
       $word =~ /^$lang_tokens{'sb'}.*$lang_tokens{'se'}$/;
    return "$lang_style{'l'}<$word>" if defined $lang_tokens{'lb'} &&
       $word =~ /^$lang_tokens{'lb'}.*$lang_tokens{'le'}$/;

    # Look for a starting token
    for $start ('c', 'a', 's', 'l') {
        $token = $lang_tokens{$start.'b'};
        if (defined $token && $word =~ /^$token/) {
            $state = $start;
            return "$lang_style{$start}<$word";
        }
    }

    # Convert the word to a keyword for matching purposes
    $keyword = $word;
    $keyword =~ tr/A-Z/a-z/ if $lang_tokens{'oc'};

    # Check for a keyword, potentially at the end of a line
    return "$lang_style{'kw'}<$word>\n" if $word =~ s/\n$// &&
      $lang_keywords{$word};
    return "$lang_style{'kw'}<$word>" if $lang_keywords{$word};

    # If we reach here, we found nothing special
    return $word;
}

#
# >>_Description::
# {{Y:_DefineLang}} stores a vgrind-like language definition.
# (Thanks to Prachin Ranavat for the initial code.)
#
sub _DefineLang {
    local(*lang_def) = @_;
#   local();
    local($i, $_, $virtual_line);
    local($langs, $rest, $main, @aliases);

    # Append lines to create a virtual line
    $virtual_line = '';
    for ($i = 0; $i <= $#lang_def; $i++) {
    	$_ = $lang_def[$i];
	    chop;
    	$_ =~ s/\s*\\$//;
    	#$_ =~ s/^\s+://;
    	$_ =~ s/^\s+/ /;
    	$virtual_line .= $_;
    }
    @lang_def = ();

    # Store the definition
    ($langs, $rest) = split(':', $virtual_line, 2);
    ($main, @aliases) = split('\|', $langs);
    $languages{$main} = $rest;
    for $_ ($main, @aliases) {
        $lang_aliases{$_} = $main;
    }
}

##### Topic Filters #####

# sdf - normal sdf
@_sdf_FilterParams = ('ANY');
sub sdf_Filter {
    local(*text, %param) = @_;

    # leave the text as it is, unless attributes are specified
    if (%param) {
        # Using a global variable like this seems like a hack but
        # it does this job nicely, provided with save and restore its value
        push(@sdf_attrs_stk, join("\000", %sdf_attrs));
        %sdf_attrs = %param;
        unshift(@text, "!on paragraph ''; __sdf; &DefaultAttrs(%sdf_attrs)");
        push   (@text, '!off paragraph __sdf',
            '!script %sdf_attrs = split("\000", pop(@sdf_attrs_stk))');
    }
}

# front - front section of (and configuration file for) a manual
@_front_FilterParams = ();
sub front_Filter {
    local(*text, %param) = @_;

    # leave the text as it is
}

# about - about section of a manual
@_about_FilterParams = ();
sub about_Filter {
    local(*text, %param) = @_;

    # For html, leave things as they are
    #return if $var{'OPT_DRIVER'} eq 'html';

    # Use plain headings & exclude them from the table of contents, if necessary
    unshift(@text, '!on paragraph \'H\d\'; __about;' .
                   '$style =~ s/H(\d)/"P" . ($1 + 1)/e;' .
                   'if ($1 == 1) { $attr{"component"} = "prechapter" }' .
                   'else { $attr{"notoc"} = 1 }');
    push   (@text, '!off paragraph __about');
}

# appendix - change headings to appendix style
@_appendix_FilterParams = ();
sub appendix_Filter {
    local(*text, %param) = @_;

    # change headings
    unshift(@text, '!on paragraph \'H\d\'; __appendix; $style =~ s/H/A/');
    push   (@text, '!off paragraph __appendix');
}

# plain - change headings to plain style
@_plain_FilterParams = ();
sub plain_Filter {
    local(*text, %param) = @_;

    # change headings
    unshift(@text, '!on paragraph \'H\d\'; __plain; $style =~ s/H/P/');
    push   (@text, '!off paragraph __plain');
}

##### General Filters #####

# verbatim - fixed width verbatim text
@_verbatim_FilterParams = (
    'Name       Type        Rule',
    'skipheader boolean',
    'lang       string',
    'wide       boolean',
    'listitem   integer',
);
sub verbatim_Filter {
    local(*text, %param) = @_;
    local($style, $attrs, $line);

    # Preprocess the text, if necessary
    my $lang = $param{'lang'};
    &_SkipHeader(*text, $lang) if $param{'skipheader'};

    # Prefix each line with the appropriate example style
    $style = "V";
    if ($param{'wide'} && $param{'listitem'}) {
        $attrs = "[wide;in=$param{'listitem'}]";
    }
    elsif ($param{'wide'}) {
        $attrs = '[wide]';
    }
    else {
        $attrs = $param{'listitem'} ? "[in=$param{'listitem'}]" : ':';
    }
    for $line (@text) {
        $line = "$style$attrs$line";
    }
}

# example - fixed width text
@_example_FilterParams = (
    'Name       Type        Rule',
    'skipheader boolean',
    'lang       string',
    'wide       boolean',
    'listitem   integer',
    'pure       boolean',
);
sub example_Filter {
    local(*text, %param) = @_;
    local($style, $attrs, $line);

    # Preprocess the text, if necessary. Note that pretty printing
    # implies pure processing, so that special characters within the
    # source code are protected.
    my $lang = $param{'lang'};
    $lang = "\L$lang";
    &_SkipHeader(*text, $lang) if $param{'skipheader'};
    &_Pure(*text)              if $param{'pure'} || $lang ne '';
    &_FmtLang(*text, $lang)    if $lang ne '';

    # Prefix each line with the appropriate example style
    $style = $param{'wide'} ? 'E80' : 'E';
    $attrs = $param{'listitem'} ? "[in=$param{'listitem'}]" : ':';
    for $line (@text) {
        $line = $line =~ /^\f/ ? "PB:$'" : "$style$attrs$line";
    }
}

# note - a notice
@_note_FilterParams = (
    'Name       Type        Rule',
    'label      string',
);
sub note_Filter {
    local(*text, %param) = @_;

    # surround the note with the right stuff
    unshift(@text, $param{'label'} ? "NB[label='$param{'label'}']" : "NB:");
    push   (@text, 'NE:');
}

# table - table in [[TBL]] format
# Parameters are given below.
#
# !block table
# Parameter     Description
# style         overall look of the table
# format        column widths
# title         table caption
# headings      headings (if not the first row in the text)
# tags          colon separated list of phrase styles to apply to columns
# niceheadings  set to 0 to disable _ to space conversion
# noheadings    suppress headings in output
# groups        pattern of group-style rows (default is /:$/)
# type          same as style (provided for backwards compatibility)
# wide          table straddles the side head area of the page
# bgcolor       background colour for a table (HTML only)
# cellpadding   padding size for table cells (HTML only)
# cellspacing   spacing size between table cells (HTML only)
# !endblock
#
@_table_FilterParams = (
    'Name           Type        Rule',
    'align          string',
    'bgcolor        string',
    'bmargin        integer',
    'cellpadding    integer',
    'cellspacing    integer',
    'colaligns      string',
    'coltags        string',
    'colvaligns     string',
    'delete         string',
    'footings       integer',
    'format         string',
    'groups         string',
    'headings       integer',
    'landscape      string',
    'listitem       integer',
    'lmargin        integer',
    'narrow         boolean',
    'niceheadings   boolean',
    'nocalcs        boolean',
    'noheadings     boolean',
    'objects        string',
    'oncell         string',
    'parseline      string',
    'placement      string',
    'rmargin        integer',
    'select         string',
    'sort           string',
    'style          string',
    'tags           string',
    'title          string',
    'tmargin        integer',
    'type           string',
    'where          string',
    'wide           boolean',
    'wrap           integer',
);
sub table_Filter {
    local(*text, %param) = @_;
    local($style, @tbl);
    local($grp_search, @body_tags, $noheadings, $nocalcs, $nice_hdgs, $on_cell);
    local($tbl_header, @flds);
    local(@sort_by);
    local(@delete, @select);
    local(@col_aligns, $align);
    local(@col_valigns, $valign);
    local($bgcolor);
    local($body_start, $footing_count, $footing_start, %default_heading);
    local(@headings, @footings);
    local($row_type, $row_text);
    local($format, $tbl_cols, $fmt_cols);
    local(@sdf, %values, $tag, $cell, %cell);
    local($fld, $width, $height, $row, $col, $last_row, $last_col);
    local(%cover, $hidden, $rowspan, $colspan, $i, $j);
    local($wrap, $wrap_counter);
    local($actual_cols);

    # Get the table style (type is supported for backwards compatibility)
    $style = $param{'style'} ne '' ? $param{'style'} : $param{'type'};
    delete $param{'type'};
    $style = &Var('DEFAULT_TABLE_STYLE') if $style eq '';
    $param{'style'} = $style;

    # Activate event processing
    &ReportEvents('table') if @'sdf_report_names;
    &ExecEventsStyleMask(*evcode_table, *evmask_table);
    &ReportEvents('table', 'Post') if @'sdf_report_names;

    # Parse the text into a table
    if (defined $param{'parseline'}) {
        unshift(@text, $param{'parseline'});
        delete $param{'parseline'};
    }
    @tbl = &'TableParse(@text);

    # Filter and sort the table, if requested
    if ($param{'where'} ne '') {
        @tbl = &'TableFilter(*tbl, $param{'where'}, *var);
        delete $param{'where'};
    }
    if ($param{'sort'} ne '') {
        @sort_by = $param{'sort'} == 1 ? () : split(/,/, $param{'sort'});
        @tbl = &'TableSort(*tbl, @sort_by);
        delete $param{'sort'};
    }
    if ($param{'delete'} ne '') {
        @delete = split(/,/, $param{'delete'});
        @tbl = &'TableDeleteFields(*tbl, @delete);
        delete $param{'delete'};
    }
    if ($param{'select'} ne '') {
        @select = split(/,/, $param{'select'});
        @tbl = &'TableSelectFields(*tbl, @select);
        delete $param{'select'};
    }
    
    # The groups attribute is the pattern to match for groups
    if ($param{'groups'} ne '') {
        $grp_search = $param{'groups'};
        $grp_search = ':$' if $grp_search == 1;
        delete $param{'groups'};
    }

    # Get the phrase styles for the columns, if any
    # (tags and objects are supported for backwards compatibility)
    @body_tags = split(",", $param{'coltags'} || $param{'tags'} || $param{'objects'});
    delete $param{'coltags'};
    delete $param{'tags'};
    delete $param{'objects'};

    # Get the alignments for the columns
    if ($param{'colaligns'} =~ /^[LCR]+$/) {
        @col_aligns = ();
        for $align (split(//, $param{'colaligns'})) {
            push(@col_aligns, $_ALIGN_NAMES{$align});
        }
        $param{'colaligns'} = join(',', @col_aligns);
    }
    else {
        @col_aligns = split(/,/, $param{'colaligns'});
    }

    # Get the vertical alignments for the columns
    if ($param{'colvaligns'} =~ /^[TMBL]+$/) {
        @col_valigns = ();
        for $valign (split(//, $param{'colvaligns'})) {
            push(@col_valigns, $_VALIGN_NAMES{$valign});
        }
    }
    else {
        @col_valigns = split(/,/, $param{'colvaligns'});
    }
    delete $param{'colvaligns'};

    # Get the noheadings flag
    $noheadings = $param{'noheadings'};
    delete $param{'noheadings'};

    # Get the nocalcs flag
    $nocalcs = $param{'nocalcs'};
    delete $param{'nocalcs'};

    # Get the niceheadings flag
    $nice_hdgs = defined($param{'niceheadings'}) ? $param{'niceheadings'} : 1;
    delete $param{'niceheadings'};

    # Get the background colour
    $bgcolor = $param{'bgcolor'};
    delete $param{'bgcolor'};

    # Get the oncell processing code
    $oncell = $param{'oncell'};
    delete $param{'oncell'};

    # Get the number of logical rows displayed on a physical row
    if (defined $param{'wrap'}) {
        $wrap = $param{'wrap'};
        $wrap_counter = $wrap;
        delete $param{'wrap'};
    }
    else {
        $wrap = 0;
    }

    # Check the column count in the format is ok
    # (Note: TableFieldsCheck checks for duplicate columns)
    $tbl_header = shift @tbl;
    @flds = &'TableFieldsCheck($tbl_header);
    $tbl_cols = scalar(@flds);

    # Calculate the row number of the first body row
    if (defined $param{'headings'}) {
        $body_start = $param{'headings'};
        delete $param{'headings'};
    }
    elsif ($noheadings) {
        $body_start = 0;
    }
    else {
        # Build the default heading:
        # * get a copy of the data so we don't corrupt the fields array
        # * niceheadings => a single _ becomes a space; multiple become 1 less
        %default_heading = ();
        for $fld (@flds) {
            $cell = $fld;
            $cell =~ s/_(_*)/$& eq '_' ? ' ' : $1/eg if $nice_hdgs;
            $default_heading{$fld} = $cell;
        }
        unshift(@tbl, &'TableRecJoin(*flds, %default_heading));
        $body_start = 1;
    }

    # If there are multiple records per rows and heading rows, we
    # duplicate the heading rows as one would expect
    if ($wrap && $body_start) {
        @headings = ();
        for $rec (@tbl[0 .. $body_start - 1]) {
            for $i (1 .. $wrap) {
                push(@headings, $rec);
            }
        }
        splice(@tbl, 0, $body_start, @headings);
        $body_start = scalar(@headings);
    }

    # Calculate the row number of the first footing row,
    # taking care to ignore macro rows
    $footing_start = scalar(@tbl);
    if (defined $param{'footings'}) {
        $footing_count = $param{'footings'};
        delete $param{'footings'};
        if ($footing_count >= 1) {
            $i = $footing_count;
            for ($row = $#tbl; $row > 0; $row--) {
                next if $tbl[$row] =~ /^!/;
                $i--;
                last if $i == 0;
            }
        }
        $footing_start = $row;
    }

    # If there are multiple records per rows and footing rows, we
    # duplicate the footing rows as one would expect
    if ($wrap && $footing_count) {
        @footings = ();
        for $rec (@tbl[$footing_start .. $#tbl]) {
            for $i (1 .. $wrap) {
                push(@footings, $rec);
            }
        }
        splice(@tbl, $footing_start, $footing_count, @footings);
    }

    # Initialise the variables exported for oncell processing
    $last_col = $tbl_cols - 1;
    $last_row = scalar(@tbl) - 1;
    $row = 0;
    $col = 0;

    # Build the output
    %cover = ();
    $actual_cols = $tbl_cols;
    $actual_cols *= $wrap if $wrap;
    @sdf = ("!table $actual_cols;" . &'SdfAttrJoin(*param));
    for $rec (@tbl) {
        if ($rec =~ /^!/) {
            push(@sdf, $rec);
            next;
        }
 
        %values = &'TableRecSplit(*flds, $rec);
        cell:
        for ($col = 0; $col <= $#flds; $col++) {
            $fld = $flds[$col];
            $hidden = $cover{$row,$col};
            $cell = $values{$fld};

            # Decide what type of row this is
            if ($col == 0) {
                if ($row < $body_start) {
                    $row_type = 'Heading';
                }
                elsif ($row == $footing_start) {
                    $wrap_counter = $wrap;
                    $row_type = 'Footing';
                }
                elsif ($row >  $footing_start) {
                    $row_type = 'Footing';
                }
                elsif ($grp_search ne '' && $cell =~ /$grp_search/) {
                    $row_type = 'Group';
                    # group rows reset row wrapping, if any
                    $wrap_counter = $wrap;
                }
                else {
                    $wrap_counter = $wrap if $row_type eq 'Group';
                    $row_type = '';
                }
                $row_text = $row_type ? "!row '$row_type'" : "!row";
                if ($wrap) {
                    if ($wrap_counter++ >= $wrap) {
                        $wrap_counter = 1;
                    }
                    else {
                        $row_text = '';
                    }
                }
                push(@sdf, $row_text) if $row_text;
            }

            # If this cell is covered by the span of another,
            # check that it is blank
            if ($hidden && $cell ne '') {
                &'AppMsg("warning", "ignoring hidden cell ($row,$col)='$cell'");
            }

            # Get the custom cell attributes, if any.
            # Multi-line cells are implicitly 'sdf' already,
            # although the top line may contain other cell attributes
            %cell = ();
            if (substr($cell, 0, 1) eq "\n") {
                ($cell, %cell) = &'SdfParseCell(substr($cell, 1));
                $cell{'sdf'} = 1;
            }
            else {
                ($cell, %cell) = &'SdfParseCell($cell);
            }

            # Enable spreadsheet-like access/calculations
            &calc_table() unless $nocalcs;

            # Handle hidden cells
            if ($hidden) {
                push(@sdf, "!cell hidden");
                next cell;
            }

            # Add the default cell attributes
            unless (defined($cell{'align'})) {
                $cell{'align'} = $col_aligns[$col] if $col_aligns[$col];
            }
            unless (defined($cell{'valign'})) {
                $cell{'valign'} = $col_valigns[$col] if $col_valigns[$col];
            }
            unless (defined($cell{'tag'})) {
                $cell{'tag'} = $row_type eq '' ? $body_tags[$col] : 2;
            }
            unless (defined($cell{'bgcolor'})) {
                $cell{'bgcolor'} = $bgcolor if $bgcolor ne '';
            }
            $cell{'cols'} = 1 unless defined($cell{'cols'});
            $cell{'rows'} = 1 unless defined($cell{'rows'});

            # Activate 'oncell' processing
            if ($oncell) {
                eval $oncell;
                if ($@) {
                    &'AppMsg("error", "oncell processing failed: $@");
                }
            }

            # Cover the cells hidden by this one
            $rowspan = $cell{'rows'};
            $colspan = $cell{'cols'};
            for ($i = 0; $i < $rowspan; $i++) {
                for ($j = 0; $j < $colspan; $j++) {
                    $cover{$row+$i,$col+$j} = 1;
                }
            }

            # Convert the cell contents to SDF, if necessary
            if ($cell{"sdf"}) {
                delete $cell{"sdf"};
            }
            else {
                if ($cell{'tag'} ne '') {
                    $cell = "{{" . $cell{'tag'} . ":$cell}}";
                }
                $cell = ":$cell";
            }

            # Add the cell
            delete $cell{'tag'};
            push(@sdf, "!cell " . &'SdfAttrJoin(*cell), split("\n", $cell));
        }

        # We only increment the row number for non-macro rows
        $row++;
    }
    push(@sdf, "!endtable");

    # Update the buffer
    @text = scalar(@sdf) > 2 ? @sdf : ();
}


# ascii_graphic - format a text diagram
sub ascii_graphic_Filter {
    local(*text, %param) = @_;

    @text = grep(s/^/E80:/, @text);
}

# abstract - format a paper abstract
@_abstract_FilterParams = ();
sub abstract_Filter {
    local(*text, %param) = @_;

    # indent margins (18 pts = 1/4 inch) and emphasise the text
    unshift(@text, '!on paragraph \'\'; __abstract; ' .
        '@attr{"left", "right", "first", "obj"} = (18, 18, 18, 1)');
    push   (@text, '!off paragraph __abstract');

    # For HTML and HLP, add a heading
    if ($var{'OPT_TARGET'} eq 'html' || $var{'OPT_TARGET'} eq 'hlp') {
        unshift(@text, 'P1: Abstract');
    }
}

# quote - format a quote
sub quote_Filter {
    local(*text, %param) = @_;

    # indent margins (18 pts = 1/4 inch) and emphasise the text
    unshift(@text, '!on paragraph \'\'; __quote; ' .
        '@attr{"left", "right", "first", "obj"} = (18, 18, 18, 1)');
    push(@text, '!off paragraph __quote');
}

# address - format an address
sub address_Filter {
    local(*text, %param) = @_;
#   local();
    local($line);

    for $line (@text) {
        $line = "Addr:$line";
    }
}

# nofill - format a set of lines
sub nofill_Filter {
    local(*text, %param) = @_;
#   local();
    local($para);

    $para = join('{{CHAR:nl}}', @text);
    @text = ($para);
}

# sections - convert text of paragraphs to sections (for HTML and help)
@_sections_FilterParams = ();
sub sections_Filter {
    local(*text, %param) = @_;

    if ($var{'OPT_TARGET'} eq 'html' || $var{'OPT_TARGET'} eq 'hlp') {
        unshift(@text, '!on paragraph \'\'; __sections; $attr{"obj"} = "SECT"');
        #unshift(@text, '!on paragraph \'\'; __sections; $attr{"obj"} = "SECT";'.
        #               '$attr{"text"} = $text; $text =~ s/\\.$//');
        push   (@text, '!off paragraph __sections');
    }
}

# topics - include topics
@_topics_FilterParams = (
    'Name           Type        Rule',
    'intro          string',
    'noslide        boolean',
    'data           boolean',
);
@_topics_FilterModel = (
    'Field      Category    Rule',
    'Topic      mandatory',
    'Label      optional',
    'Level      optional',
    'Next       optional',
    'Prev       optional',
    'Up         optional',
);
sub topics_Filter {
    local(*text, %param) = @_;
    local(@tbl, @flds, $rec, %values);
    local($topic);
    local($label);
    local($file);

    # Parse and validate the data
    @tbl = &'TableParse(@text);
    @text = ();
    &_FilterValidate(*tbl, *_topics_FilterModel) if $validate;

    # Get the list of fields
    @flds = &'TableFields(shift @tbl);

    # If this is topics data, store it
    if ($param{'data'}) {
        for $rec (@tbl) {
            %values = &'TableRecSplit(*flds, $rec);
            $file = $values{'Topic'};
            $topic_label{$file} = $values{'Label'};
            $topic_level{$file} = $values{'Level'};
            $topic_next{$file} = $values{'Next'};
            $topic_prev{$file} = $values{'Prev'};
            $topic_up{$file} = $values{'Up'};
        }
        return;
    }

    # When we're building the sub-topics,
    # display the labels as jumps to the sub-topics
    if ($var{'HTML_SUBTOPICS_MODE'}) {
        push(@text, $param{'intro'}) if $param{'intro'} ne '';
        for $rec (@tbl) {
            %values = &'TableRecSplit(*flds, $rec);
            $topic = $values{'Topic'};
            $file = $topic;
            # this next line is needed once topics mode supports files
            # outside the current directory
            #$file = &'NameAbsolute(&FindFile("$topic.sdf"));
            $label = $values{'Label'} ? $values{'Label'} : $topic_label{$file};
            $label = $topic if $label eq '';
            #push(@text, "L1[jump='$topic.html'] $label");

            # Build the topic file
            push(@text, "!include '$topic.sdf'");
        }
    }

    # Otherwise, include the topics as subsections
    else {
        for $rec (@tbl) {
            %values = &'TableRecSplit(*flds, $rec);
            $topic = $values{'Topic'};
            push(@text, "!include '$topic.sdf'");
        }
    }

    unless ($param{'noslide'}) {
        unshift(@text, "!slide_down");
        push(@text, "!slide_up");
    }
}

# jumps - include jumps data
@_jumps_FilterParams = ();
@_jumps_FilterModel = (
    'Field      Category    Rule',
    'Jump       key',
    'Physical   mandatory',
);
sub jumps_Filter {
    local(*text, %param) = @_;
    local(@tbl, @flds, $rec, %values);
    local($jump);

    # Parse and validate the data
    @tbl = &'TableParse(@text);
    @text = ();
    &_FilterValidate(*tbl, *_jumps_FilterModel) if $validate;

    # Get the list of fields
    @flds = &'TableFields(shift @tbl);

    # Store the data
    for $rec (@tbl) {
        %values = &'TableRecSplit(*flds, $rec);
        $jump = $values{'Jump'};
        $jump{$jump} = $values{'Physical'};
    }
}

# title - title block for memos, faxes, etc.
@_title_FilterParams = (
    'Name           Type        Rule',
    'type           string',
    'toc            integer',
    'format         string',
);
sub title_Filter {
    local(*text, %param) = @_;
#   local();
    local($format);
    local($params);
    local($target);
    local($title);
    local($logo);

    # Turn the data into a name-values block
    $format = defined($param{'format'}) ? $param{'format'} : '28';
    $params = "format=$format";
    @text = ("!block namevalues; $params", @text, '!endblock');

    # Prepend a title box, if necessary
    $target = $var{'OPT_TARGET'};
    $title = $param{'type'} || $var{'DOC_TYPE'};
    if ($title ne '') {
        if ($target eq 'html') {
            unshift(@text, 'P2[notoc]' . $title);
        }
        else {
            $title = '{{B[family="Helvetica";size=14]' . $title . '}}';
            unshift(@text, '!block box; narrow; wide', $title, '!endblock', 'E:');
        }
    }

    # Prepend a logo, if necessary
    $logo = $var{'DOC_ADMIN_LOGO'} || $var{'DOC_LOGO'};
    $base = $var{'DOC_ADMIN_LOGO_BASE'} || $var{'DOC_LOGO_BASE'};
    if ($logo ne '') {
        unshift(@text, "!import '$logo'; wide; wrap_text; align=Right; base='$base'");
    }

    # Add a table of contents, if requested
    if ($param{'toc'}) {
        push(@text, "!default DOC_TOC $param{'toc'}");
        if ($target eq 'html') {
            push(@text,
                "!block inline; target='html'",
                "<!-- TOC -->",
                "<!-- ENDTOC -->",
                "!endblock");
        }
    }

    # Output a line after the title block
    push(@text, "Line[wide]");
}

# box - put a box around text
@_box_FilterParams = (
    'Name           Type        Rule',
    'align          string',
    'listitem       integer',
    'narrow         boolean',
    'wide           boolean',
    'lines          boolean',
    'bgcolor        string',
    'fill           integer',
);
sub box_Filter {
    local(*text, %param) = @_;
#   local();
    local($line);
    local($params);

    # Set up the default parameters for formatting the table
    $params = 'noheadings; nocalcs; style="columns"; tmargin=6';

    # If requested, turn the lines into a paragraph
    if ($param{'lines'}) {
        for ($line = 0; $line < $#text; $line++) {
            $text[$line] .= "[[nl]]";
        }
        delete $param{'lines'};
        $params .= '; colaligns="C"';
    }

    # Turn the data into a single cell table
    if ($param{'fill'}) {
        unshift(@text, '[fill=' . $param{'fill'} . ']');
        delete $param{'fill'};
    }
    if (%param) {
        $params .= '; ' . &'SdfAttrJoin(*param);
    }
    @text = ("!block table; $params", 'Dummy', '<<', @text, '>>', '!endblock');
}

# namevalues - table of names & values
@_namevalues_FilterParams = (
    'Name           Type        Rule',
    'format         string',
);
@_namevalues_FilterModel = (
    'Field      Category    Rule',
    'Name       optional',
    'Value      optional',
    #'Name2      optional',
    #'Value2     optional',
    #'Name3      optional',
    #'Value3     optional',
);
sub namevalues_Filter {
    local(*text, %param) = @_;
    local(@tbl, @flds, $rec, %values);
    local($target);
    local($format);
    local($width);

    # Parse and validate the data
    @tbl = &'TableParse(@text);
    &_FilterValidate(*tbl, *_namevalues_FilterModel) if $validate;

    # Decide on the format
    if ($param{'format'}) {
        $format = $param{'format'};
    }
    else {
        # The first column must be at least 90 points in size and
        # is sized so that the second column is aligned with either
        # normal paragraphs or progressively indented list paragraphs
        $width = $var{'OPT_SIDEHEAD_WIDTH'} + $var{'OPT_SIDEHEAD_GAP'} - 2;
        if ($var{'OPT_LIST_INDENT'} > 0) {
            $width += $var{'OPT_LIST_INDENT'} while $width <= 90;
        }
        $format = $width . 'pt';
    }

    # Process the data
    $target = $var{'OPT_TARGET'};
    if ($target eq 'html' || $target eq 'hlp' ||
        $target eq 'txt' || $target eq 'pod') {
        unshift(@text, "!block table; noheadings; style='plain'; tags='B,,B,,B'; wide; format='$format'");
        push(@text, "!endblock");
    }
    else {
        @text = ();
        (@flds) = &'TableFields(shift @tbl);
        for $rec (@tbl) {
            %values = &'TableRecSplit(*flds, $rec);
            push(@text, "NV[label='$values{'Name'}\\t']$values{'Value'}");
        }
    }
}

# define - variable definitions
@_define_FilterParams = (
    'Name       Type        Rule',
    'family     string      <\w+>',
    'export     boolean',
);
@_define_FilterModel = (
    'Field      Category    Rule',
    'Name       key         <\w+>',
    'Value      optional',
);
sub define_Filter {
    local(*text, %param) = @_;
    local(@tbl, @flds, $rec, %values);
    local($family, $export, $name);

    # Parse and validate the data
    @tbl = &'TableParse(@text);
    @text = ();
    &_FilterValidate(*tbl, *_define_FilterModel) if $validate;

    # Process the data
    $family = $param{'family'};
    $family .= '_' if $family ne '';
    $export = $param{'export'};
    (@flds) = &'TableFields(shift @tbl);
    for $rec (@tbl) {
        %values = &'TableRecSplit(*flds, $rec);
        $name = $family . $values{'Name'};
        push(@text, "!define $name $values{'Value'}");
        push(@text, "!export $name") if $export;
    }
}

# default - variable defaulting
@_default_FilterParams = (
    'Name       Type        Rule',
    'family     string      <\w+>',
    'export     boolean',
);
@_default_FilterModel = (
    'Field      Category    Rule',
    'Name       key         <\w+>',
    'Value      optional',
);
sub default_Filter {
    local(*text, %param) = @_;
    local(@tbl, @flds, $rec, %values);
    local($family, $export, $name);

    # Parse and validate the data
    @tbl = &'TableParse(@text);
    @text = ();
    &_FilterValidate(*tbl, *_default_FilterModel) if $validate;

    # Process the data
    $family = $param{'family'};
    $family .= '_' if $family ne '';
    $export = $param{'export'};
    (@flds) = &'TableFields(shift @tbl);
    for $rec (@tbl) {
        %values = &'TableRecSplit(*flds, $rec);
        $name = $family . $values{'Name'};
        push(@text, "!default $name $values{'Value'}");
        push(@text, "!export $name") if $export && !$export{$name};
    }
}

# script - embedded Perl
@_script_FilterParams = ();
sub script_Filter {
    local(*text, %param) = @_;

    # execute the code
    eval join("\n", @text);
    if ($@) {
        &'AppMsg("error", "script failed: $@");
    }
    @text = ();
}

# pod - embedded Pod
@_pod_FilterParams = (
    'Name       Type        Rule',
    'main       boolean',
);
sub pod_Filter {
    local(*text, %param) = @_;

    use Pod::Sdf;
    @text = pod2sdf(\@text, \%param);
}

# inline - embedded target code
@_inline_FilterParams = (
    'Name       Type        Rule',
    'target     string      <\w+>',
    'expand     boolean',
);
sub inline_Filter {
    local(*text, %param) = @_;
    local($line);

    # The default target is 'html'
    $target = $param{'target'} || 'html';

    # Prefix each line with the appropriate style
    for $line (@text) {
        if ($param{'expand'}) {
            next if $line =~ /\s*\!/;
            $line = &main::_SdfParaExpand($line);
        }
        $line = "__inline[target='$target']$line";
    }
}

# end - prepend finalisation text
@_end_FilterParams = ();
sub end_Filter {
    local(*text, %param) = @_;

    # We prepend a blank line so that multiple end sections remain separate.
    unshift(@'sdf_end, '', @text);
    @text = ();
}

# comment - ignore text
@_comment_FilterParams = ('ANY');
sub comment_Filter {
    local(*text, %param) = @_;

    @text = ();
}

# toc_html - format the table of contents for html
@_toc_html_FilterParams = ();
sub toc_html_Filter {
    local(*text, %param) = @_;
#   local();
    local($toc_text, $toc_tag);

    # Prepend a section separator and a title
    $toc_text = $var{'DOC_TOC_TITLE'};
    $toc_text = 'Table of Contents' unless $toc_text;
    $toc_tag = $parastyles_to{'TOCT'};
    $toc_tag = "P2" unless $toc_tag;
    unshift(@text, "!HTML_PRE_SECTION", $toc_tag . "[notoc]$toc_text");
}

# offices - format a set of office locations
@_offices_FilterParams = (
    'Name       Type        Rule',
    'style      string',
);
sub offices_Filter {
    local(*text, %param) = @_;
    local(@result);
    local($line, $cell_count);

    # Init things
    $style = $param{'style'} || 'plain';
    @result = ("!table 2; format=55; wide; tmargin=12; bmargin=4; style='$style'");

    # Place each address into a cell, 2 cells per row
    $cell_count = 0;
    for $line (@text) {
        $line =~ s/\s+$//;

        # Skip blank lines and comments
        next if $line eq '';
        next if $line =~ /^\s*#/;

        # Handle group entries
        if ($line =~ /^GROUP:\s*/) {
            $cell_count = 0;
            push(@result,
                "!row 'Group'",
                "!cell cols=2; tmargin=14; bmargin=6; truling=Thin; bruling=Thin",
                "N[size='11pt';bold]$'");
        }

        # Handle office titles
        elsif ($line =~ /:$/) {
            push(@result, "!row") if $cell_count++ % 2 == 0;
            push(@result, "!cell");
            push(@result, "N[size='10pt']{{B:$line}}");
        }

        # Handle phone and fax numbers
        elsif ($line =~ /^Ph:\s*/) {
            push(@result, "N[size='10pt';tabs='36pt']Ph:[[tab]]$'");
        }
        elsif ($line =~ /^Fax:\s*/) {
            push(@result, "[[nl]]Fax:[[tab]]$'");
        }

        # Handle address lines
        else {
            push(@result, "[[nl]]$line");
        }
    }

    # Finalise things
    @text = (@result, "!endtable");
}

##### Help Filters #####

# hlp_header - table of jumps in the non-scrolling region
@_hlp_header_FilterParams = ();
@_hlp_header_FilterModel = (
    'Field      Category    Rule',
    'Text       key',
    'Kind       optional    <popup|jump>'
);
sub hlp_header_Filter {
    local(*text, %param) = @_;
    local(@tbl, @flds, $rec, %values);
    local($item, @items,$thetext);

    # Parse and validate the data
    @tbl = &'TableParse(@text);
    @text = ();
    &_FilterValidate(*tbl, *_hlp_header_FilterModel) if $validate;

    # Unless we're generating help, skip the rest
    return unless $var{'OPT_TARGET'} eq 'hlp';

    # Process the data
    (@flds) = &'TableFields(shift @tbl);
    for $rec (@tbl) {
        %values = &'TableRecSplit(*flds, $rec);
        $thetext=$values{'Text'};
        if ($values{'Kind'} eq 'jump') {
            $item = "{{N[jump='#jump_${topic}_$thetext';size='8 pt'] $thetext}}";
        } else {
            $item = "{{N[hlp.popup='#jump_${topic}_$thetext';size='8 pt'] $thetext}}";
        }
        push(@items, $item);
    }

    # Format the output
    @text = ("[hlp.header]" . join("{{E:  }}", @items));
}

# hlp_window - contents of a popup window (by TJH)
@_hlp_window_FilterParams = ();
sub hlp_window_Filter {
    local(*text, %param) = @_;

    unshift(@text,'!on paragraph ; __window_filter; $attr{"hlp.window"} = "1"');
    push(@text,"!off paragraph __window_filter","[hlp.endwindow=1]");
}

##### Configuration Filters #####

# langdefs - load a set of (vgrind-like) language definitions
@_langdefs_FilterParams = ();
sub langdefs_Filter {
    local(*text, %param) = @_;
#   local();
    local($_, @language_definition);

    # append lines until each language definition is complete &
    # then process definition
    @language_definition = ();
    for $_ (@text) {
        next if (/^#/);
        push(@language_definition, $_);
#print "line:$_<\n";
        &_DefineLang(*language_definition) unless /\\$/;
    }    
    @text = ();
}

# docstyles - document style definitions
@_docstyles_FilterParams = ();
@_docstyles_FilterModel = (
    'Field      Category    Rule',
    'Name       key         <\w+>',
    'To         optional',
    'Variables  optional',
);
sub docstyles_Filter {
    local(*text, %param) = @_;
    local(@tbl, @flds, $rec, %values);
    local($name);
    local($to);

    # Parse and validate the data
    @tbl = &'TableParse(@text);
    @text = ();
    &_FilterValidate(*tbl, *_docstyles_FilterModel) if $validate;

    # Process the data
    (@flds) = &'TableFields(shift @tbl);
    for $rec (@tbl) {
        %values = &'TableRecSplit(*flds, $rec);

        # Update the declaration, if necessary
        $name = $values{'Name'};
        $docstyles_name{$name} = 1;

        # Update the definition, if any
        $to = $values{'To'};
        if ($to ne '') {
            $docstyles_to{$name} = $to;
            $docstyles_vars{$name} = $values{'Variables'};
        }
    }
}

# variables - variable declarations
@_variables_FilterParams = (
    'Name       Type        Rule',
    'family     string      <[\w,]+>',
    'export     boolean',
);
@_variables_FilterModel = (
    'Field      Category    Rule',
    'Name       key         <\w+>',
    'Type       mandatory   <\w+>',
    'Rule       optional',
);
sub variables_Filter {
    local(*text, %param) = @_;
    local(@tbl, @flds, $rec, %values);
    local(@family, $export);
    local($name);
    local($type, $rule);
    local($family, @fullname);

    # Parse and validate the data
    @tbl = &'TableParse(@text);
    @text = ();
    &_FilterValidate(*tbl, *_variables_FilterModel) if $validate;

    # Process the data
    @family = split(/,/, $param{'family'});
    $export = $param{'export'};
    (@flds) = &'TableFields(shift @tbl);
    for $rec (@tbl) {
        %values = &'TableRecSplit(*flds, $rec);

        # Update the declaration
        $name = $values{'Name'};
        $type = $values{'Type'};
        $rule = $values{'Rule'};
        if (@family) {
            for $family (@family) {
                $fullname = "${family}_$name";
                $variables_name{$fullname} = 1;
                $variables_type{$fullname} = $type;
                $variables_rule{$fullname} = $rule if $rule ne '';

                # Mark the variable as exported, if requested
                push(@text, "!export $fullname") if $export;
            }
        }
        else {
            $variables_name{$name} = 1;
            $variables_type{$name} = $type;
            $variables_rule{$name} = $rule if $rule ne '';

            # Mark the variable as exported, if requested
            push(@text, "!export $name") if $export;
        }
    }
}

# parastyles - paragraph style definitions
@_parastyles_FilterParams = ();
@_parastyles_FilterModel = (
    'Field      Category    Rule',
    'Name       key         <[A-Z_0-9]\w*>',
    'Category   optional    <example>',
    'To         optional    <[\w ]+>',
    'Attributes optional',
);
sub parastyles_Filter {
    local(*text, %param) = @_;
    local(@tbl, @flds, $rec, %values);
    local($name, $category);
    local($to);

    # Parse and validate the data
    @tbl = &'TableParse(@text);
    @text = ();
    &_FilterValidate(*tbl, *_parastyles_FilterModel) if $validate;

    # Process the data
    (@flds) = &'TableFields(shift @tbl);
    for $rec (@tbl) {
        %values = &'TableRecSplit(*flds, $rec);

        # Update the declaration, if necessary
        $name = $values{'Name'};
        $category = $values{'Category'};
        $parastyles_name{$name} = 1;
        $parastyles_category{$name} = $category if $category ne '';

        # Update the definition, if any
        $to = $values{'To'};
        if ($to ne '') {
            $parastyles_to{$name} = $to;
            $parastyles_attrs{$name} = $values{'Attributes'};
        }
    }
}

# paraattrs - paragraph attribute definitions
@_paraattrs_FilterParams = (
    'Name       Type        Rule',
    'family     string      <\w+>',
);
@_paraattrs_FilterModel = (
    'Field      Category    Rule',
    'Name       key         <\w+>',
    'To         optional    <\w+>',
    'Map        optional    <[\%\&]\w+>',
    'Attributes optional',
    'Type       optional    <\w+>',
    'Rule       optional',
);
sub paraattrs_Filter {
    local(*text, %param) = @_;
    local(@tbl, @flds, $rec, %values);
    local($family);
    local($name);
    local($type, $rule);
    local($to, $map, $attrs);

    # Parse and validate the data
    @tbl = &'TableParse(@text);
    @text = ();
    &_FilterValidate(*tbl, *_paraattrs_FilterModel) if $validate;

    # Process the data
    $family = $param{'family'} ne '' ? "$param{'family'}." : '';
    (@flds) = &'TableFields(shift @tbl);
    for $rec (@tbl) {
        %values = &'TableRecSplit(*flds, $rec);

        # Update the declaration, if necessary
        $name = $family . $values{'Name'};
        $type = $values{'Type'};
        $rule = $values{'Rule'};
        $paraattrs_name{$name} = 1;
        $paraattrs_type{$name} = $type if $type ne '';
        $paraattrs_rule{$name} = $rule if $rule ne '';

        # Update the definition, if any
        $to = $values{'To'};
        $map = $values{'Map'};
        $attrs = $values{'Attributes'};
        if ($to || $map || $attrs) {
            $paraattrs_to{$name} = $to;
            $paraattrs_map{$name} = $map;
            $paraattrs_attrs{$name} = $attrs;
        }
    }
}

# phrasestyles - phrase style definitions
@_phrasestyles_FilterParams = ();
@_phrasestyles_FilterModel = (
    'Field      Category    Rule',
    'Name       key         <[A-Z_0-9]\w*>',
    'Category   optional    <example|special>',
    'To         optional    <\=?\w+>',
    'Attributes optional',
);
sub phrasestyles_Filter {
    local(*text, %param) = @_;
    local(@tbl, @flds, $rec, %values);
    local($name, $category);
    local($to);
    local($proxy);

    # Parse and validate the data
    @tbl = &'TableParse(@text);
    @text = ();
    &_FilterValidate(*tbl, *_phrasestyles_FilterModel) if $validate;

    # Process the data
    (@flds) = &'TableFields(shift @tbl);
    for $rec (@tbl) {
        %values = &'TableRecSplit(*flds, $rec);

        # Update the declaration, if necessary
        $name = $values{'Name'};
        $category = $values{'Category'};
        $phrasestyles_name{$name} = 1;
        $phrasestyles_category{$name} = $category if $category ne '';

        # Update the definition, if any
        $to = $values{'To'};
        if ($to ne '') {
            if ($to =~ /^\=/) {
                $proxy = $';
                if ($phrasestyles_name{$proxy}) {
                    $to = $phrasestyles_to{$proxy};
                }
                else {
                    &'AppMsg("warning", "unknown phrase style $proxy '$proxy");
                    $to = $proxy;
                }
            }
            $phrasestyles_to{$name} = $to;
            $phrasestyles_attrs{$name} = $values{'Attributes'};
        }
    }
}

# phraseattrs - phrase attribute definitions
@_phraseattrs_FilterParams = (
    'Name       Type        Rule',
    'family     string      <\w+>',
    'para       string',
);
@_phraseattrs_FilterModel = (
    'Field      Category    Rule',
    'Name       key         <\w+>',
    'To         optional    <\w+>',
    'Map        optional    <[\%\&]\w+>',
    'Attributes optional',
    'Type       optional    <\w+>',
    'Rule       optional',
);
sub phraseattrs_Filter {
    local(*text, %param) = @_;
    local(@tbl, @flds, $rec, %values);
    local($family, $para);
    local($name, $paraname);
    local($type, $rule);
    local($to, $map, $attrs);

    # Parse and validate the data
    @tbl = &'TableParse(@text);
    @text = ();
    &_FilterValidate(*tbl, *_phraseattrs_FilterModel) if $validate;

    # Process the data
    $family = $param{'family'} ne '' ? "$param{'family'}." : '';
    $para = $param{'para'};
    (@flds) = &'TableFields(shift @tbl);
    for $rec (@tbl) {
        %values = &'TableRecSplit(*flds, $rec);

        # Update the declaration, if necessary
        $name = $family . $values{'Name'};
        $paraname = $family . $para . $values{'Name'};
        $type = $values{'Type'};
        $rule = $values{'Rule'};
        $phraseattrs_name{$name} = 1;
        $phraseattrs_type{$name} = $type if $type ne '';
        $phraseattrs_rule{$name} = $rule if $rule ne '';
        $paraattrs_name{$paraname} = 1;
        $paraattrs_type{$paraname} = $type if $type ne '';
        $paraattrs_rule{$paraname} = $rule if $rule ne '';

        # Update the definition, if any
        $to = $values{'To'};
        $map = $values{'Map'};
        $attrs = $values{'Attributes'};
        if ($to || $map || $attrs) {
            $phraseattrs_to{$name} = $to;
            $phraseattrs_map{$name} = $map;
            $phraseattrs_attrs{$name} = $attrs;
            $paraattrs_to{$paraname} = $to;
            $paraattrs_map{$paraname} = $map;
            $paraattrs_attrs{$paraname} = $attrs;
        }
    }
}

# tablestyles - table style definitions
@_tablestyles_FilterParams = ();
@_tablestyles_FilterModel = (
    'Field      Category    Rule',
    'Name       key         <\w+>',
    'To         optional    <\w+>',
    'Parameters optional',
);
sub tablestyles_Filter {
    local(*text, %param) = @_;
    local(@tbl, @flds, $rec, %values);
    local($name);
    local($to);

    # Parse and validate the data
    @tbl = &'TableParse(@text);
    @text = ();
    &_FilterValidate(*tbl, *_tablestyles_FilterModel) if $validate;

    # Process the data
    (@flds) = &'TableFields(shift @tbl);
    for $rec (@tbl) {
        %values = &'TableRecSplit(*flds, $rec);

        # Update the declaration, if necessary
        $name = $values{'Name'};
        $tablestyles_name{$name} = 1;

        # Update the definition, if any
        $to = $values{'To'};
        if ($to ne '') {
            $tablestyles_to{$name} = $to;
            $tablestyles_params{$name} = $values{'Parameters'};
        }
    }
}

# tableparams - table parameter definitions
@_tableparams_FilterParams = (
    'Name       Type        Rule',
    'family     string      <\w+>',
);
@_tableparams_FilterModel = (
    'Field      Category    Rule',
    'Name       key         <\w+>',
    'To         optional    <\w+>',
    'Map        optional    <[\%\&]\w+>',
    'Parameters optional',
    'Type       optional    <\w+>',
    'Rule       optional',
);
sub tableparams_Filter {
    local(*text, %param) = @_;
    local(@tbl, @flds, $rec, %values);
    local($family);
    local($name);
    local($type, $rule);
    local($to, $map, $params);

    # Parse and validate the data
    @tbl = &'TableParse(@text);
    @text = ();
    &_FilterValidate(*tbl, *_tableparams_FilterModel) if $validate;

    # Process the data
    $family = $param{'family'} ne '' ? "$param{'family'}." : '';
    (@flds) = &'TableFields(shift @tbl);
    for $rec (@tbl) {
        %values = &'TableRecSplit(*flds, $rec);

        # Update the declaration, if necessary
        $name = $family . $values{'Name'};
        $type = $values{'Type'};
        $rule = $values{'Rule'};
        $tableparams_name{$name} = 1;
        $tableparams_type{$name} = $type if $type ne '';
        $tableparams_rule{$name} = $rule if $rule ne '';

        # Update the definition, if any
        $to = $values{'To'};
        $map = $values{'Map'};
        $params = $values{'Parameters'};
        if ($to || $map || $params) {
            $tableparams_to{$name} = $to;
            $tableparams_map{$name} = $map;
            $tableparams_params{$name} = $params;
        }
    }
}

# rowparams - row parameter definitions
@_rowparams_FilterParams = (
    'Name       Type        Rule',
    'family     string      <\w+>',
);
@_rowparams_FilterModel = (
    'Field      Category    Rule',
    'Name       key         <\w+>',
    'To         optional    <\w+>',
    'Map        optional    <[\%\&]\w+>',
    'Parameters optional',
    'Type       optional    <\w+>',
    'Rule       optional',
);
sub rowparams_Filter {
    local(*text, %param) = @_;
    local(@tbl, @flds, $rec, %values);
    local($family);
    local($name);
    local($type, $rule);
    local($to, $map, $params);

    # Parse and validate the data
    @tbl = &'TableParse(@text);
    @text = ();
    &_FilterValidate(*tbl, *_rowparams_FilterModel) if $validate;

    # Process the data
    $family = $param{'family'} ne '' ? "$param{'family'}." : '';
    (@flds) = &'TableFields(shift @tbl);
    for $rec (@tbl) {
        %values = &'TableRecSplit(*flds, $rec);

        # Update the declaration, if necessary
        $name = $family . $values{'Name'};
        $type = $values{'Type'};
        $rule = $values{'Rule'};
        $rowparams_name{$name} = 1;
        $rowparams_type{$name} = $type if $type ne '';
        $rowparams_rule{$name} = $rule if $rule ne '';

        # Export the definition, if any
        $to = $values{'To'};
        $map = $values{'Map'};
        $params = $values{'Parameters'};
        if ($to || $map || $params) {
            $rowparams_to{$name} = $to;
            $rowparams_map{$name} = $map;
            $rowparams_params{$name} = $params;
        }
    }
}

# cellparams - cell parameter definitions
@_cellparams_FilterParams = (
    'Name       Type        Rule',
    'family     string      <\w+>',
);
@_cellparams_FilterModel = (
    'Field      Category    Rule',
    'Name       key         <\w+>',
    'To         optional    <\w+>',
    'Map        optional    <[\%\&]\w+>',
    'Parameters optional',
    'Type       optional    <\w+>',
    'Rule       optional',
);
sub cellparams_Filter {
    local(*text, %param) = @_;
    local(@tbl, @flds, $rec, %values);
    local($family);
    local($name);
    local($type, $rule);
    local($to, $map, $params);

    # Parse and validate the data
    @tbl = &'TableParse(@text);
    @text = ();
    &_FilterValidate(*tbl, *_cellparams_FilterModel) if $validate;

    # Process the data
    $family = $param{'family'} ne '' ? "$param{'family'}." : '';
    (@flds) = &'TableFields(shift @tbl);
    for $rec (@tbl) {
        %values = &'TableRecSplit(*flds, $rec);

        # Update the declaration, if necessary
        $name = $family . $values{'Name'};
        $type = $values{'Type'};
        $rule = $values{'Rule'};
        $cellparams_name{$name} = 1;
        $cellparams_type{$name} = $type if $type ne '';
        $cellparams_rule{$name} = $rule if $rule ne '';

        # Update the definition, if any
        $to = $values{'To'};
        $map = $values{'Map'};
        $params = $values{'Parameters'};
        if ($to || $map || $params) {
            $cellparams_to{$name} = $to;
            $cellparams_map{$name} = $map;
            $cellparams_params{$name} = $params;
        }
    }
}

# targetobjects - define target objects
@_targetobjects_FilterParams = (
    'Name       Type        Rule',
    'type       string      <\w+>',
);
@_targetobjects_FilterModel = (
    'Field      Category    Rule',
    'Name       key',
    'Parent     optional',
    'Attributes optional',
);
sub targetobjects_Filter {
    local(*text, %param) = @_;
    local(@tbl, @flds, $rec, %values);
    local($type);
    local(%attrs);

    # Parse and validate the data
    @tbl = &'TableParse(@text);
    @text = ();
    &_FilterValidate(*tbl, *_targetobjects_FilterModel) if $validate;

    # Process the data
    $type = $param{'type'};
    (@flds) = &'TableFields(shift @tbl);
    for $rec (@tbl) {
        %values = &'TableRecSplit(*flds, $rec);
        %attrs = &'SdfAttrSplit($values{'Attributes'});
        $attrs{'Name'} = $values{'Name'};
        $attrs{'Parent'} = $values{'Parent'};
        push(@text, &'SdfJoin("__object", $type, %attrs));
    }
}

# datestrings - date strings for month, weekday, etc.
@_datestrings_FilterParams = (
);
@_datestrings_FilterModel = (
    'Field      Category    Rule',
    'Symbol     key         <month|smonth|weekday|sweekday|ampm|AMPM>',
    'Values     optional',
);
sub datestrings_Filter {
    local(*text, %param) = @_;
    local(@tbl, @flds, $rec, %values);
    local($strings);

    # Parse and validate the data
    @tbl = &'TableParse(@text);
    @text = ();
    &_FilterValidate(*tbl, *_datestrings_FilterModel) if $validate;

    # Process the data
    (@flds) = &'TableFields(shift @tbl);
    for $rec (@tbl) {
        %values = &'TableRecSplit(*flds, $rec);
        $strings = [ split(/\s+/, eval $values{'Values'}) ];
        $main::misc_date_strings{$values{'Symbol'}} = $strings;
    }
}

# package return value
1;
