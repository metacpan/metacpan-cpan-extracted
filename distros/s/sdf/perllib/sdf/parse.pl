# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     Simple Document Format Library
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
# This library provides support for handling
# [[SDF]] files.
#
# >>Description::
# The following symbols are occasionally accessed from other modules
# but aren't really for public consumption:
#
# {{Y:SDF_IMAGE_EXTS}}, 
# {{Y:sdf_if_start}}, 
# {{Y:sdf_if_now}}, 
# {{Y:sdf_if_yet}}, 
# {{Y:sdf_if_else}}, 
# {{Y:sdf_block_start}}, 
# {{Y:sdf_block_type}}, 
# {{Y:sdf_block_text}}, 
# {{Y:sdf_block_param}}, 
# {{Y:sdf_tbl_start}}, 
# {{Y:sdf_tbl_state}}, 
# {{Y:sdf_end}}, 
# {{Y:sdf_cutting}}, 
# {{Y:sdf_sections}}, 
# {{Y:sdf_book_files}}, 
# {{Y:sdf_report_names}}, 
# {{Y:SdfSystem}}, 
# {{Y:SdfBatch}}, 
# {{Y:SdfDelete}}, 
# {{Y:SdfBookClean}}, 
# {{Y:SdfRenamePS}}.
#
# >>Limitations::
# Append/Prepend is not implemented for macros - is
# it needed for them?
#
# {{Y:SdfBookConvert}} currently generates (Unix) shell scripts.
# It should be generalised to support other operating systems?
#
# >>Resources::
#
# >>Implementation::
#

require "sdf/macros.pl";
require "sdf/podmacs.pl";
require "sdf/filters.pl";
require "sdf/specials.pl";
require "sdf/values.pl";
require "sdf/subs.pl";
require "sdf/calc.pl";

require Config;

##### Constants #####

# This should arguably be distributed into each driver.
# (At the moment, FindFile() defaults to ps if a target isn't found.)
%SDF_IMAGE_EXTS = (
        'ps'   => ['epsi', 'eps', 'wmf', 'mif', 'gif'],
        'html' => ['jpeg', 'jpg', 'png', 'gif'],
        'hlp ' => ['bmp'],
);

# Verbose phrase tag
$_SDF_VERBOSE_TAG = 'V';

# Enums for phrase section types
$_SDF_PHRASE_BEGIN   = "\001";
$_SDF_PHRASE_END     = "\002";
$_SDF_PHRASE_SPECIAL = "\003";

# Lookup table of syntax escapes
%_SDF_SYNTAX_ESCAPE = (
    'lt',       '<',
    'gt',       '>',
    '2{',       '{{',
    '2}',       '}}',
    '2[',       '[[',
    '2]',       ']]',
);

# Lookup table of phrase prefixes for list tag characters
%_SDF_LIST_ALIAS = (
    '*',        'LU',
    '-',        'LU',
    '.',        'L',
    '^',        'LF',
    '+',        'LN',
    '&',        'LI',
);

# Table of macros to execute inside an excluded section of conditional text
%_SDF_MACRO_COND = (
    'if',           1,
    'elsif',        1,
    'elseif',       1,
    'else',         1,
    'endif',        1,
    '_eof_',        1,
);

# Driver validation rules
@_SDF_DRIVER_RULES = &TableParse(
    'Field      Category',
    'Name       key',
    'Library    mandatory',
    'Subroutine mandatory',
);

# Page size validation rules
@_SDF_PAGESIZE_RULES = &TableParse(
    'Field      Category',
    'Name       key',
    'Width      mandatory',
    'Height     mandatory',
    'Comment    optional',
);

##### Variables #####

#
# >>Description::
# {{Y:sdf_driver}} is a lookup table of valid format drivers.
# This table is build by {{Y:SdfLoadDrivers}}.
#
%sdf_driver = ();
#
# >>Description::
# {{Y:sdf_report}} is a lookup table of valid reports.
# This table is build by {{Y:SdfLoadReports}}.
#
%sdf_report = ();

#
# >>Description::
# {{Y:sdf_pagesize}} is a lookup table of valid page sizes.
# This table is build by {{Y:SdfLoadPageSizes}}.
#
%sdf_pagesize = ();

# driver lookup tables
%_sdf_driver_library = ();
%_sdf_driver_subroutine = ();

# List of sections for the current paragraph
@_sdf_section_list = ();

#
# >>Description::
# {{Y:sdf_subtopic_cnt}} is the counter of subtopics left during
# topics mode processing.
#
$sdf_subtopic_cnt = 0;

#
# >>Description::
# {{Y:sdf_fmext}} is the extension of FrameMaker template files.
# Typically values are 'fm5' and 'fm4'.
#
$sdf_fmext = 'fm5';

#
# >>Description::
# {{Y:sdf_include_path}} contains the list of directories searched
# for to find files specified in {{include}} macros.
# {{Y:sdf_library_path}} contains the list of directories searched
# for to find libraries and modules.
# In both cases, the current directory and the document's directory
# are searched before these directories and
# {{Y:sdf_lib}} is searched last of all.
#
@sdf_include_path = ();
@sdf_library_path = ();
$sdf_lib = '';

# Stacks containing state of if macros:
# * start - starting line number for error messages
# * now - is the current text section to be included?
# * yet - has a section been included yet?
# * else - has the else macro been found yet?
@sdf_if_start = ();
@sdf_if_now = ();
@sdf_if_yet = ();
@sdf_if_else = ();

# State of current block, if any
$sdf_block_start = '';
$sdf_block_type = '';
@sdf_block_text = ();
%sdf_block_param = ();
$_sdf_block_cnt = 0;
$_sdf_block_char = '';

# Stacks of starts/states for table macros
@sdf_tbl_start = ();
@sdf_tbl_state = ();

# Buffer containing finalisation code (build via the 'end' filter)
@sdf_end = ();

# Ignoring text flag (ala POD)
$sdf_cutting = 0;

# Section counter
$sdf_sections = 0;

# Next $app_lineno buffer
$_sdf_next_lineno = 0;

# Buffer holding the init line from the main topic
$_sdf_init_line = '';

# Stack of strings to append to phrases
@_sdf_append_stack = ();

# Set of component files in a book
@sdf_book_files = ();

# Stack of running reports
@sdf_report_names = ();

# Counters for generating heading prefixes
@_sdf_heading_counters = ();
@_sdf_appendix_counters = ();

# Package SDF_USER contains data exported to the user world
%SDF_USER'var = ();
$SDF_USER'style = '';
$SDF_USER'text = '';
$SDF_USER'append = '';
%SDF_USER'attr = ();
$SDF_USER'level = 0;
$SDF_USER'prev_style = '';
$SDF_USER'prev_text = '';
%SDF_USER'prev_attr = ();
%SDF_USER'previous_text_for_style = ();

##### Routines #####

#
# >>Description::
# {{Y:SdfLoadDrivers}} loads a configuration table of drivers.
# The columns are:
#
# * {{Name}} - the driver name
# * {{Library}} - the library containing the subroutine
# * {{Subroutine}} - the subroutine name.
#
# Call this routine before calling {{Y:SdfConvert}}.
#
sub SdfLoadDrivers {
    local(@table) = @_;
#   local();
    local(@flds, $rec, %values);
    local($fmt);

    # Validate the table
    &TableValidate(*table, *_SDF_DRIVER_RULES) if $'verbose;

    # Load the drivers
    @flds = &TableFields(shift(@table));
    for $rec (@table) {
        %values = &TableRecSplit(*flds, $rec);
        $fmt = $values{'Name'};
        $sdf_driver{$fmt} = 1;
        $_sdf_driver_library{$fmt} = $values{'Library'};
        $_sdf_driver_subroutine{$fmt} = $values{'Subroutine'};

        # Is this still needed?
        #$fmt =~ tr/a-z/A-Z/;
        #$SDF_USER'restricted{$fmt} = 1;
    }
}

#
# >>Description::
# {{Y:SdfLoadPageSizes}} loads a configuration table of page sizes.
#
sub SdfLoadPageSizes {
    local(@table) = @_;
#   local();
    local(@flds, $rec, %values);
    local($size);

    # Validate the table
    &TableValidate(*table, *_SDF_PAGESIZE_RULES) if $'verbose;

    # Load the drivers
    @flds = &TableFields(shift(@table));
    for $rec (@table) {
        %values = &TableRecSplit(*flds, $rec);
        $size = $values{'Name'};
        $sdf_pagesize{$size} = join("\000", @values{'Width', 'Height'});

        # Add rotated page layouts
        $sdf_pagesize{$size . "R"} = join("\000", @values{'Height', 'Width'});
    }
}

#
# >>Description::
# {{Y:SdfFetch}} inputs an [[SDF]] file,
# ready for {{Y:SdfConvert}} (i.e. ready conversion to another format).
# It returns 1 if the file is opened successfully.
#
sub SdfFetch {
    local($file) = @_;
    local($success, @records);

    # Open the file
    open(SDF_FETCH, $file) || return (0, ());

    # Mark the start of a new file
    @records = ("!_bof_ '$file'");

    # Input the records
    while (<SDF_FETCH>) {
        s/[ \t\n\r]+$//;
        push(@records, $_);
    }

    # Check structured macros have all been terminated correctly
    push(@records, "!_eof_");

    # Close the stream (must occur after reference to $. above)
    close(SDF_FETCH);

    # Return result
    return (1, @records);
}

#
# >>Description::
# {{Y:SdfParse}} prepares an array of SDF strings
# for {{Y:SdfConvert}} (i.e. for conversion to another format).
#
sub SdfParse {
    local(@sdf_strs) = @_;
    local(@records);

    # Return result
    return ("!_bof_", @sdf_strs, "!_eof_");
}

#
# >>Description::
# {{Y:SdfConvert}} converts a list of sdf records to a list of
# target format paragraphs. The input records to this routine
# are usually read in by {{Y:SdfFetch}}. The output records
# are typically output to a file, separated by newlines.
# {{%convert_var}} is the initial set of variables.
#
sub SdfConvert {
    local(*p_sdf, $target, *uses, %convert_var) = @_;
    local(@result);
    local($orig_argv, $orig_context, $orig_lineno);
    local(@sdf);
    local($init_level, $i);
    local($first_line);
    local($library, $fn);

    # Init variables used in error messages.
    # $app_lineno is used as the line number as we cannot set $. - the
    # method assumes that $. is 0 (forcing AppMsg to use app_lineno instead)
    $orig_argv = $ARGV;
    $orig_context = $app_context;
    $orig_lineno = $app_lineno;

    # Init the global data
    $convert_var{'DOC_START'} = time;
    &SdfInit(*convert_var);

    # Load the standard stuff.
    # Notes:
    # 1. We 'use' rather than 'inherit' stdlib as the stdlib directory
    #    is explicitly placed last on the search list - inherit would
    #    put it first (or towards the front, at least).
    # 2. Some of this is currently based on the (target) driver name.
    #    It should really be controlled by driver and/or format
    #    "flags" configured in sdf.ini. :-(
    @sdf = ("!use 'stdlib/stdlib'");
    push(@sdf, "!_load_look_")     if     $target eq 'mif';
    push(@sdf, "!readonly 'OPT'");
    #push(@sdf, "!_load_tuning_") unless $target eq 'raw';
    push(@sdf, "!_load_tuning_");
    push(@sdf, "!_load_config_");

    # Load the required modules
    for $module (@uses) {
        push(@sdf, "!use '$module'");
    }

    # Adjust the initial heading level, if requested
    $init_level = $convert_var{'OPT_HEAD_LEVEL'};
    if ($init_level ne '') {
        for ($i = 1; $i < $init_level; $i++) {
            push(@sdf, "!slide_down");
        }
    }

    # Do the init macro, if any, for the file first
    $first_line = $p_sdf[1];
    if ($first_line =~ /^\!\s*init\s*/) {
        unshift(@sdf, $first_line);
        $p_sdf[1] = '';
    }

    # Call the line macro first to init DOC_PATH, etc.
    unshift(@sdf, "!line 0; '$ARGV'");

    # Enable report processing, if necessary
    $report = $convert_var{'OPT_REPORT'};
    if ($report) {
        push(@sdf,   "!_bor_ $report");
        push(@p_sdf, "!_eor_");
    }

    # Prepend the user document to the config stuff
    push(@sdf, @p_sdf);

    # Call the format driver
    $library = $_sdf_driver_library{$target};
    require $library;
    $fn = $_sdf_driver_subroutine{$target};
    @result = eval {&$fn(*sdf)};
    &AppMsg('failed', $@) if $@;

    # Restore program state
    $ARGV = $orig_argv;
    $app_context = $orig_context;
    $app_lineno = $orig_lineno;

    # Return result
    return @result;
}

#
# >>Description::
# {{Y:SdfInit}} initialises global data used during the conversion process.
#
sub SdfInit {
    local(*var) = @_;
#   local();

    # Initialise the user package
    package SDF_USER;
    #reset 'a-z';   # NOTE: THIS CLEARS THE MACRO/FILTER ARG/PARAM TABLES!
    &InitMacros;
    &InitPodMacros;
    &InitFilters;
    &InitSubs;

    # Initialise the user variables
    %var = %'var;
    @include_path = @'sdf_include_path;
    @library_path = @'sdf_library_path;
    @module_path = @'sdf_library_path;

    # Initialise global variables within this package
    package main;
    $sdf_block_start = '';
    $sdf_block_type = '';
    @sdf_block_text = ();
    %sdf_block_param = ();
    $_sdf_block_cnt = 0;
    $_sdf_block_char = '';
    @_sdf_section_list = ();
    @sdf_if_start = ();
    @sdf_if_now = ();
    @sdf_if_yet = ();
    @sdf_if_else = ();
    @sdf_tbl_start = ();
    @sdf_tbl_state = ();
    @sdf_end = ();
    $sdf_cutting = 0;
    $sdf_sections = 0;
    $_sdf_next_lineno = 0;
    @_sdf_append_stack = ();
    @sdf_report_names = ();
    @_sdf_heading_counters = ();
    @_sdf_appendix_counters = ();
    %SDF_USER'previous_text_for_style = ();
}

#
# >>Description::
# {{Y:SdfNextPara}} gets the next paragraph from an SDF buffer.
# Format drivers use this routine to process buffers.
# {{@sdf}} is the buffer which is updated ready for
# another call to this routine.
#
sub SdfNextPara {
    local(*sdf) = @_;
    local($text, $style, %attr);
    local($_);
    local($lines, $macro, $parameters);
    local(@eaten);
    local($exclude_text);
    local($ok);
    local($macro_char);

    # Get the starting line number
    $app_lineno = $_sdf_next_lineno;

    # Process lines until we get the next paragraph
    record:
    while (defined($_ = shift(@sdf))) {
$igc_cnt++;
#print "sdf: $_<\n";

        # Handle the beginning/end of section macros directly and asap
        # for performance. (These shouldn't appears inside a block.)
        if (/^\!_([be])os_ /) {
            package SDF_USER;   # Need this for Perl 4 and 5 to work the same
            &_bos__Macro($') if $1 eq 'b';
            &_eos__Macro($') if $1 eq 'e';
            next record;
        }

        # Update the line number
        $app_lineno++ unless $sdf_sections;

        # If we're "cutting" text as POD does, ignore lines until a
        # =-style macro or !_eof_ is found
        if ($sdf_cutting) {
            next record unless /^=/ || /^!_eof_/;
            $sdf_cutting = 0;
        }

        # For block sections, save the lines in a scratch buffer
        if ($sdf_block_type ne '') {

            # We handle the non-macro case first for performance
            push(@sdf_block_text, $_),next unless /^\!_eof_/ ||
                        /^\s*$_sdf_block_char(end)?$sdf_block_type/;

            # Fetch the macro
            ($lines, $macro, $parameters) = &_SdfFetchMacro($_, *sdf, *eaten);
            $app_lineno += $lines;

            # Detect block ends
            if ($macro eq "end$sdf_block_type" && --$_sdf_block_cnt == 0) {
                unshift(@sdf, &SDF_USER'ExecMacro($macro, $parameters, 'error'));
                if (@sdf_end) {
                    push(@sdf, @sdf_end);
                    @sdf_end = ();
                }
                next record;
            }

            # Make sure end-of-file processing is not missed
            elsif ($macro eq '_eof_') {
                unshift(@sdf, &SDF_USER'ExecMacro($macro, $parameters, 'error'));
                next record;
            }

            # Detect nested blocks
            $_sdf_block_cnt++ if $macro eq $sdf_block_type;

            # Save the text into a scratch buffer
            push(@sdf_block_text, @eaten);
            next record;
        }

        # Determine the exclude_text flag
        $exclude_text = @sdf_if_now && !$sdf_if_now[$#sdf_if_now];

        # Handle macros
        if (/^\s*([=!])/) {
            $macro_char = $1;
            ($lines, $macro, $parameters) = &_SdfFetchMacro($_, *sdf, *eaten);
            $app_lineno += $lines;

            # If we are inside an excluded section of an if macro,
            # ignore everything except conditional macros (and eof checking)
            next record if $exclude_text && !$_SDF_MACRO_COND{$macro};

            # Process the macro - if this macro starts a block, set the
            # nested count and starting character accordingly
            unshift(@sdf, &SDF_USER'ExecMacro($macro, $parameters, 'error'));
            if (@sdf_end) {
                push(@sdf, @sdf_end);
                @sdf_end = ();
            }
            if ($sdf_block_type ne '') {
                $_sdf_block_cnt = 1;
                $_sdf_block_char = "\\" . $macro_char;
            }
            next record;
        }

        # Ignore paragraphs inside an excluded section of an if macro
        next record if $exclude_text;

        # remove leading and trailing whitespace
        s/^\s+//;
        s/\s+$//;

        # skip comments and blank lines
        next record if /^#/ || /^\s*$/;

        # If we reach here, we have the start of the next paragraph
        $app_context = 'para. on ' unless $sdf_sections;
        ($lines, $ok, $style, $text, %attr) = &_SdfFetchPara($_, *sdf);
        $_sdf_next_lineno = $app_lineno + $lines;

        # Prepended text causes a failure, triggering re-processing.
        # Likewise, we return nothing if a report is running.
        next unless $ok;
        next if @sdf_report_names;

        return ($text, $style, %attr);
    }

print "lines: $igc_cnt\n" if $SDF_USER'var{'igc'};
    # If we reach here, the buffer is empty
    return ();
}

#
# >>_Description::
# {{Y:_SdfFetchMacro}} fetches the macro starting on the current line, if any.
# {{$_}} is the current line and
# {{@rest}} is the rest of the input buffer.
# {{$lines}} is the number of lines read from {{@rest}}.
# {{@eaten}} is the set of lines consumed.
#
sub _SdfFetchMacro {
    local($_, *rest, *eaten) = @_;
    local($lines, $macro, $parameters);
    local($line);

    # At a minimum, we consume the current line.
    @eaten = ($_);

    # Handle !-style - lines ending in \ are continued onto the next line,
    # unless there are exactly 2 backslashes at the end of the line
    if (s/^\s*\!\s*//) {
        s/\s+$//;
        return (0, split(/\s+/, $_, 2)) unless /\\$/;

        # Handle \\ case
        if (/[^\\]\\\\$/) {
            s/\\$//;
            return (0, split(/\s+/, $_, 2));
        }

        # Handle other cases (1, 3, 4 ..)
        s/\\$/ /;
        $line = $_;
        while (defined($_ = shift(@rest))) {
            push(@eaten, $_);
            $lines++ unless $sdf_sections;
            s/^\s+//;
            s/\s+$//;
            $line .= $_;
            last unless $line =~ s/\\$/ /;
        }
        return ($lines, split(/\s+/, $line, 2));
    }

    # Handle =-style - an empty line terminates the macro call
    if (s/^\s*\=\s*//) {
        s/\s+$//;
        $line = $_;
        while (defined($_ = shift(@rest))) {
            push(@eaten, $_);
            $lines++ unless $sdf_sections;
            s/^\s+//;
            s/\s+$//;
            last if $_ eq '';
            $line .= " $_";
        }
        return ($lines, split(/\s+/, $line, 2));
    }
}

#
# >>_Description::
# {{Y:_SdfFetchPara}} fetches the next paragraph.
# {{$_}} is the current line and
# {{@rest}} is the rest of the input buffer.
# {{$lines}} is the number of lines read from {{@rest}}.
#
sub _SdfFetchPara {
    local($_, *rest) = @_;
    local($lines, $ok, $style, $text, %attr);
    local($para);
    local($name);

    # Handle normal paragraphs
    $para = $_;
    if ($para !~ /^__/) {
        while (defined($_ = $rest[0])) {

            # Remove leading and trailing whitespace
            s/^\s+//;
            s/\s+$//;

            # Paragraphs are terminated by macros, comments, blank lines and new
            # paragraphs - the tests are ordered to match the most likely first.
            last if /^\!/;
            last if /^\#/;
            last if /^$/;
            last if /^[-*^+\.&]+/;
            last if /^\>/;
            last if /^\=/;
            last if /^([A-Z_0-9]\w*|)\:/;
            last if /^([A-Z_0-9]\w*|)\[[^\[]/;

            # A leading \ simply escapes special characters so strip it
            s/^\\//;

            # Append this line
            $para .= " $_";
            shift(@rest);

            # Update the line number
            $lines++ unless $sdf_sections;
        }
    }

    # Parse the paragraph
#print STDERR "fetch:$para<\n";
    ($style, $text, %attr) = &_SdfParsePara($para);

    # For directives, skip the rest
    return ($lines, 1, $style, $text, %attr) if $style =~ /^__/;

    # Activate event processing
    if ($attr{'noevents'}) {
        delete $attr{'noevents'};
    }
    else {
        package SDF_USER;
        local($style, $text, %attr, @_prepend, @_append);

        $'attr{'orig_style'} = $'style;
        $style = $'style;
        $text = $'text;
        %attr = %'attr;
        @_prepend = ();
        @_append = ();
        &ReportEvents('paragraph') if @'sdf_report_names;
        &ExecEventsStyleMask(*evcode_paragraph, *evmask_paragraph);
        &ReportEvents('paragraph', 'Post') if @'sdf_report_names;
        $'style = $style;
        $'text = $text;
        %'attr = %attr;
        $level = $1 if $style =~ /^[HAP](\d)$/;
        $prev_style = $style;
        $prev_text = $text;
        %prev_attr = %attr;
        $previous_text_for_style{$style} = $text unless $attr{'continued'};
        unshift(@'rest,
            "!_bos_ $'app_lineno;text appended to ",
            @_append,
            "!_eos_ $'app_lineno;$'app_context") if @_append;
        if (@_prepend) {
            $attr{'noevents'} = 1;
            unshift(@'rest,
                "!_bos_ $'app_lineno;text prepended to ",
                @_prepend,
                &'SdfJoin($style, $text, %attr),
                "!_eos_ $'app_lineno;$'app_context");
            return ();
        }
    }

    # Remove target-specific attributes for other targets
    &SdfAttrClean(*attr) if %attr;

    # Check the style is legal
    unless (defined($SDF_USER'parastyles_name{$style})) {
        &AppMsg("warning", "unknown paragraph style '$style'");
    }

    # Check the attributes are legal
    for $name (keys %attr) {
        &_SdfAttrCheck($name, $attr{$name}, "paragraph");
    }

    # Return result
#printf STDERR  "style:$style, text:$text.\n";
    return ($lines, 1, $style, $text, %attr);
}

#
# >>_Description::
# {{Y:_SdfParsePara}} parses an SDF paragraph into its components.
#
sub _SdfParsePara {
    local($para) = @_;
    local($style, $text, %attr);
    local($attrs);
    local($tab_size);
    local($level);
    local($special);
#print STDERR "para:$para.\n";

    # Handle paragraphs with normal styles
    if ($para =~ /^([A-Z_0-9]\w*|):/ || $para =~ /^([A-Z_0-9]\w*|)\[\s*\]/) {
        $style = $1;
        $attrs = '';
        $text = $';
    }
    elsif ($para =~ /^([A-Z_0-9]\w*|)\[([^\[][^\]]*)\]/) {
        $style = $1;
        $attrs = $2;
        $text = $';

        # If the ] was escaped, we need to find the real one
        # in a non-greedy way
        if ($attrs =~ s/\\$/]/) {
            if ($text =~ /(.*?[^\\])\]/) {
                $attrs .= $1;
                $text = $';
#print "attrs: $attrs.\n";
#print "text : $text.\n";
            }
            else {
                $attrs .= $text;
                $text = '';
                &AppMsg("warning", "] at end of attributes not found");
            }
        }
    }

    # Handle paragraphs with shorthand styles
    elsif ($para =~ /^(>)/) {
        $style = 'V';
        $attrs = '';
        $text = $';
    }
    elsif ($para =~ /^([-*^+\.&]{1,6})(\[\s*\])?/) {
        $special = $1;
        $attrs = '';
        $text = $';
    }
    elsif ($para =~ /^([-*^+\.&]{1,6})(\[([^\]][^\]]*)\])?/) {
        $special = $1;
        $level = length($1);
        $level++ if substr($1, 0, 1) eq '-' && $level < 6;
        $style = "$_SDF_LIST_ALIAS{$1}$level";
        $attrs = $3;
        $text = $';
    }

    # Handle normal paragraphs
    else {
        $style = '';
        $attrs = '';
        $text = $para;

        # A leading \ simply escapes special characters so strip it
        $text =~ s/^\\//;

    }

    # Parse the attributes
    %attr = &SdfAttrSplit($attrs) if $attrs ne '';

    # Convert the special tag to a style, if necessary
    if ($special) {
        $level = length($special);
        $special = substr($special, 0, 1);
        $level++ if $special eq '-' && $level < 6;
        $style = "$_SDF_LIST_ALIAS{$special}$level";
    }

    # If the style is not set, use the default style
    $style = 'N' if $style eq '';

    # Map aliases
    if ($style eq 'V') {
        $style = 'E';
        $attr{'verbatim'} = 1;
    }

    # Trim leading space except for examples and internal directives
    # For examples, convert tabs to spaces
    if ($SDF_USER'parastyles_category{$style} eq 'example') {
        $tab_size = $SDF_USER'var{'DEFAULT_TAB_SIZE'};
        1 while $text =~ s/\t+/' ' x (length($&) * $tab_size - length($`) % $tab_size)/e;
    }
    elsif ($style !~ /^__/) {
        $text =~ s/^\s+//;
    }

    # Return result
    return ($style, $text, %attr);
}

#
# >>Description::
# {{Y:SdfParseCell}} parses an SDF cell into its components.
#
sub SdfParseCell {
    local($cell) = @_;
    local($text, %attr);
    local($attrs);

    # Simple for now
    if ($cell =~ /^\s*\[\s*\]/) {
        $attrs = '';
        $text = $';
    }
    if ($cell =~ /^\s*\[\s*([a-z][^\]]*)\s*\]/) {
        $attrs = $1;
        $text = $';
    }
    else {
        $attrs = '';
        $text = $cell;
    }

    # Parse the attributes
    %attr = &SdfAttrSplit($attrs) if $attrs ne '';

    # Return result
    return ($text, %attr);
}

#
# >>_Description::
# {{Y:_SdfParaExpand}} expands embedded expressions
# within a paragraph.
#
sub _SdfParaExpand {
    local($text) = @_;
    local($expanded);
    local($pre, $mid, $begin, $end);

    # Handle embedded expressions
    $expanded = '';
    section:
    while ($text ne '') {
        # Get the next set of delimiters
        $begin = index($text, '[[');
        last section unless $begin >= 0;
        $end = index($text, ']]', $begin + 2);
        last section unless $end >= 0;

        # Get the sub-strings
        $pre = substr($text, 0, $begin);
        $mid = substr($text, $begin + 2, $end - $begin - 2);
        $mid = &_SdfEvaluate($mid, "warning");
        $text = substr($text, $end + 2);

        # handle nested expansion
        if (index($mid, '[[') >= 0) {
            $mid = &_SdfParaExpand($mid);
        }

        # Build the result
        $expanded .= $pre . $mid;
    }
    if ($text ne '') {
        # Build the result
        $expanded .= $text;
    }

    # return result
    return $expanded;
}

#
# >>_Description::
# {{Y:_SdfVerbosePhrases}} expands E<2{> style phrases within a paragraph.
#
sub _SdfVerbosePhrases {
    local($text) = @_;
    local($expanded);
    local($nested);
    my($begin_index, $end_index);

    # Convert the other escapes
    $nested = 0;
    while ($text ne '') {

        # A nested }} without a proceeding {{ is a phrase end
        $begin_index = ($text =~ /\{\{/) ? length($`) : length($text);
        $end_index =   ($text =~ /\}\}/) ? length($`) : length($text);
        if ($nested && ($end_index < $begin_index)) {
            $nested--;
            $text = $';
            $expanded .= &_SdfVerboseEscape($`) . '>';
        }

        # A phrase which may have something nested
        elsif ($text =~ /\{\{/) {
            $expanded .= "$`$_SDF_VERBOSE_TAG<";
            $text = $';
            $nested++;
        }

        # No sequences left
        else {
            $expanded .= $text;
            $text = '';
        }
    }

    # return result
    return $expanded;
}

#
# >>_Description::
# {{Y:_SdfVerboseEscape}} escapes chatacters within a E<2{> style phrase.
#
sub _SdfVerboseEscape {
    local($text) = @_;
    local($result);

    # If a [A-Z]< style phrase is found, do nothing
    return $text if $text =~ /[A-Z]\</;

    # Otherwise, escape > characters
    $result = $text;
    $result =~ s/\>/E<gt>/g;
    return $result;
}

#
# >>_Description::
# {{Y:_SdfTextToSections}} converts paragraph text to a list of sections.
#
sub _SdfTextToSections {
    local($text) = @_;
    local(@section);
    local(@nested);
    local($append);
    # The ones above are explicitly local so that *xxx works for
    # calls to SdfAddPhrase
    my($begin_index, $end_index);

    # Do expression and long phrase substitution on the text
#print "text 1:$text<\n";
    $text = &_SdfParaExpand($text);
#print "text 2:$text<\n";
    $text = &_SdfVerbosePhrases($text);
#print "text 3:$text<\n";

    # Parse the string into bits
    $append = 0;
    while ($text ne '') {

        # A > without a proceeding [A-Z]< is a sequence end marker
        $begin_index = ($text =~ /[A-Z]\</) ? length($`) : length($text);
        $end_index =   ($text =~ /\>/)      ? length($`) : length($text);
        if (@nested && ($end_index < $begin_index)) {
            $text = $';
            &_SdfAddPhrase($`, *text, *section, *nested, *append);
        }

        # A sequence which starts immediately
        elsif ($text =~ /^([A-Z])\</) {
            push(@section, $_SDF_PHRASE_BEGIN);
            push(@nested, $#section);
            push(@section, $1);
            $text = $';
            $append = 1;
        }

        # Some text before a sequence
        elsif ($text =~ /([A-Z])\</) {
            $append = 0 unless @section;
            if ($append) {
                $section[$#section] .= $`;
            }
            else {
                push(@section, $`);
            }
            $text = "$1<$'";
        }

        # No sequences left
        else {
            $append = 0 unless @section;
            if ($append) {
                $section[$#section] .= $text;
            }
            else {
                push(@section, $text);
            }
            $text = '';
        }
    }

    # Warn about unterminated phrases and terminate them
    my $tag;
    while (@nested) {
        $tag = substr($section[$nested[$#nested] + 1], 0, 1);
        if ($tag eq $_SDF_VERBOSE_TAG) {
            &'AppMsg("warning", "{{ phrase not terminated");
        }
        else {
            &'AppMsg("warning", "'$tag' phrase not terminated");
        }
        &_SdfAddPhrase('', *text, *section, *nested, *append);
    }

for $igc (@section) {
if ($igc =~ /^(\001|\002|\003)/) {
#print unpack('C*', $1) . ":\n";
}
else {
#print "$igc<\n";
}
}

    # Return result
    return @section;
}
sub _SdfAddPhrase {
    local($phrase, *text, *section, *nested, *append) = @_;
#   local();
    my($tag);
    my($sect_style, $sect_text, $sect_append, %sect_attr);
    my($start);
    my($escape);

    $start = pop(@nested);
    $tag = substr($section[$start + 1], 0, 1);
#print "tag:$tag,phrase:$phrase,start:$start.\n";
    if ($tag eq 'Z') {
        pop(@section);
        pop(@section);
    }
    elsif ($tag eq 'E' && ($escape = $_SDF_SYNTAX_ESCAPE{$phrase})) {
#print "escape:$escape.\n";
        pop(@section);
        pop(@section);
        if (@section && $section[$#section] ne $_SDF_PHRASE_END) {
            $section[$#section] .= $escape;
        }
        else {
            push(@section, $escape);
        }
    }
    else {
        if ($append) {
            $section[$#section] .= $phrase;
        }
        else {
            push(@section, $phrase);
        }
        $append = 0;

        ($sect_style, $sect_text, $sect_append, %sect_attr) =
          &_SdfPhraseProcess($tag, substr($section[$start + 1], 1));
#print "style:$sect_style,text:$sect_text,append:$sect_append<\n";
        if ($sect_style =~ /^__/) {
            $sect_style = substr($sect_style, 2);
            $section[$start] = $_SDF_PHRASE_SPECIAL;
        }
        else {
            push(@section, $_SDF_PHRASE_END);
        }
        $section[$start + 1] = [$sect_text, $sect_style, %sect_attr];
        $text = $sect_append . $text if $sect_append ne '';
    }
}

#
# >>Description::
# {{Y:SdfNextSection}} gets the next section of a paragraph.
# Format drivers use this routine to process paragraphs.
# {{$para}} is the paragraph text which is updated ready for
# another call to this routine. {{$state}} is a state variable
# which this routines uses to help it keep state.
# {{sect_type}} is one of:
#
# * {{string}} - a string normal paragraph text
# * {{phrase}} - a phrase
# * {{phrase_end}} - end of a phrase
# * {{special}} - a special phrase (e.g. CHAR, IMPORT, etc.)
# * an empty string - end of paragraph
#
# For a string, {{text}} is the string, {{style}} and {{attr}} are empty.
# At the end of a phrase, {{text}}, {{style}} and {{attr}} are empty.
#
sub SdfNextSection {
    local(*para, *state) = @_;
    local($sect_type, $text, $style, %attr);
    local($section);

    # Init things, if necessary
    if ($state == 0) {
        @_sdf_section_list = &_SdfTextToSections($para);
    }
#print "$para<\n", "state:$state,", $#_sdf_section_list, "\n";

    # Check for end of paragraph
    return () if $state > $#_sdf_section_list;

    # Get the next section
    $section = $_sdf_section_list[$state++];

    # Handle end of phrase
    if ($section eq $_SDF_PHRASE_END) {
        return ("phrase_end");
    }

    # Handle phrases
    elsif ($section eq $_SDF_PHRASE_BEGIN) {
        return ("phrase", @{$_sdf_section_list[$state++]});
    }

    # Handle special phrases
    elsif ($section eq $_SDF_PHRASE_SPECIAL) {
        return ("special", @{$_sdf_section_list[$state++]});
    }

    # Must be a normal paragraph
    else {
        return ("string", $section);
    }
}

#
# >>_Description::
# {{Y:_SdfPhraseProcess}} processes a phrase.
# It returns the style, text and attributes.
#
sub _SdfPhraseProcess {
    local($tag, $sdf) = @_;
    local($style, $text, $append, %attr);
    local($attrs);
    local($name);
    local($fn);

#print "phrase:$tag,$sdf<\n";
    # Get the components
    if ($tag ne $_SDF_VERBOSE_TAG) {
        $style = $tag eq 'E' ? 'CHAR' : $tag;
        $attrs = '';
        $text = $sdf;
    }
    elsif ($sdf =~ /^([A-Z_0-9]\w*|):/ || $sdf =~ /^([A-Z_0-9]\w*|)\[\s*\]/) {
        $style = $1;
        $attrs = '';
        $text = $';
    }
    elsif ($sdf =~ /^([A-Z_0-9]\w*|)(\[([^\[][^\]]*)\])/) {
        $style = $1;
        $attrs = $3;
        $text = $';

        # If the ] was escaped, we need to find the real one
        # in a non-greedy way
        if ($attrs =~ s/\\$/]/) {
            if ($text =~ /(.*?[^\\])\]/) {
                $attrs .= $1;
                $text = $';
#print "attrs: $attrs.\n";
#print "text : $text.\n";
            }
            else {
                $attrs .= $text;
                $text = '';
                &AppMsg("warning", "] at end of attributes not found");
            }
        }
    }
    else {
        $style = '';
        $attrs = '';
        $text = $sdf;
    }

    # If not set, use the default style
    $style = 1 if $style eq '';

    # Trim leading space except for examples
    if ($SDF_USER'phrasestyles_category{$style} ne 'example') {
        $text =~ s/^\s+//;
    }

    # Parse the attributes
    %attr = &SdfAttrSplit($attrs);

    # Handle special styles
    if ($SDF_USER'phrasestyles_category{$style} eq 'special') {
        $fn = "SDF_USER'${style}_Special";
        if (defined &$fn) {
            &$fn(*style, *text, *attr);
        }
        else {
            &AppMsg("warning", "unable to find handler for special style '$style'");
        }
        return ($style, $text, '', %attr);
    }

    # Activate event processing
    package SDF_USER;
    $style = $'style;
    $text = $'text;
    $append = '';
    %attr = %'attr;
    &ReportEvents('phrase') if @'sdf_report_names;
    &ExecEventsStyleMask(*evcode_phrase, *evmask_phrase);
    &ReportEvents('phrase', 'Post') if @'sdf_report_names;
    $'style = $style;
    $'text = $text;
    $'append = $append;
    %'attr = %attr;
    undef $style;
    undef $text;
    undef %attr;
    package main;

    # Check for hypertext
    #$style = 'JUMP' if $attr{'jump'} ne '';

    # Default index text, if necessary
    if ($attr{'index'} eq '1' ||
        $attr{'index_type'} ne '' && $attr{'index'} eq '') {
        $attr{'index'} = $text;
    }

    # Check the style is legal
    if ($style !~ /^__/) {
        unless (defined($SDF_USER'phrasestyles_name{$style})) {
            &AppMsg("warning", "unknown phrase style '$style'");
        }
    }

    # Remove target-specific attributes for other targets
    &SdfAttrClean(*attr);

    # check the attributes are legal
    for $name (keys %attr) {
        &_SdfAttrCheck($name, $attr{$name}, "phrase");
    }

    # Return result
    return ($style, $text, $append, %attr);
}

#
# >>Description::
# {{Y:SdfPoints}} converts a measurement to points.
# This is required for calculations involving measurements.
#
sub SdfPoints {
    local($measure) = @_;
#   local($pts);

    return 0 unless $measure =~ /^([\d\.]+)/;
    if ($' eq 'pt' || $' eq '') {
        # We put this first for performance reasons
        return $1;
    }
    elsif ($' eq 'in' || $' eq '"') {
        return $1 * 72;
    }
    elsif ($' eq 'mm') {
        return $1 * 2.835;
    }
    elsif ($' eq 'cm') {
        return $1 * 28.35;
    }
    else {
        return 0;
    }
}

#
# >>Description::
# {{Y:SdfVarPoints}} converts an variable to points.
#
sub SdfVarPoints {
    local($name) = @_;
#   local($pts);

    return &SdfPoints($SDF_USER'var{$name});
}

#
# >>Description::
# {{Y:SdfPageInfo}} returns information about a page.
#
sub SdfPageInfo {
    local($page, $attr, $category) = @_;
    local($info);
    local($part, $newpage);

    if ($category eq 'macro') {
        if (defined $SDF_USER'macro{"PAGE_${page}_$attr"}) {
            $info = $SDF_USER'macro{"PAGE_${page}_$attr"};
        }
        elsif ($page =~ /_/) {
            ($part, $newpage) = ($`, $');
            $newpage = 'RIGHT' if $newpage eq 'FIRST' && $part ne 'FRONT';
#printf STDERR "$page -> $newpage ($attr)\n";
            $info = $SDF_USER'macro{"PAGE_${newpage}_$attr"};
        }
    }
    else {
        if (defined $SDF_USER'var{"PAGE_${page}_$attr"}) {
            $info = $SDF_USER'var{"PAGE_${page}_$attr"};
        }
        elsif ($page =~ /_/) {
            ($part, $newpage) = ($`, $');
            $newpage = 'RIGHT' if $newpage eq 'FIRST' && $part ne 'FRONT';
#printf STDERR "$page -> $newpage ($attr)\n";
            $info = $SDF_USER'var{"PAGE_${newpage}_$attr"};
        }
        if ($category eq 'pt') {
            $info = &SdfPoints($info);
        }
    }

    # Return result
    return $info;
}

#
# >>_Description::
# {{Y:_SdfEvaluate}} evaluates and returns an SDF expression.
# If only a word is found which looks like an enumerated value (i.e.
# first character is uppercase & remaining characters are lowercase)
# and {{enum}} is true, then that word is returned as a string.
# If only a name is found, the result is the value of that variable.
# If only a '!' character followed by a name is found,
# the result is the negation of that variable.
# If the first character is + or =, then the rest is assumed to
# be an argument to the {{Calc}} subroutine.
# Otherwise, the expression is evaluated as Perl. If Perl cannot
# evaulate the expression, an error is output. If the expression
# looks like a name and it is not defined and {{msg_type}} is
# specified, then a message of that type is output explaining
# that the variable is unknown. In either case, we return an empty
# string if the variable is not found or the evaluation fails.
#
sub _SdfEvaluate {
    local($expr, $msg_type, $enum) = @_;
    local($result);
    local($format);
    local($action, $SDF_USER'_);

    # Get the format, if any
    $format = $1 if $expr =~ s/^(\w+)://;

    # Handle simple numbers and strings directly (i.e. skip the eval)
    if ($expr =~ /^"([^"\\\$]*)"$/ || $expr =~ /^'([^'\\]*)'$/) {
        $result = $1;
    }
    elsif ($expr =~ /^\d+$/) {
        $result = $expr;
    }

    # Enumerated values
    elsif ($enum && $expr =~ /^[A-Z][a-z]+$/) {
        $result = $expr;
    }

    # Variables
    elsif ($expr =~ /^\w+$/) {
        if (!defined($SDF_USER'var{$expr})) {
            if ($msg_type) {
                &AppMsg($msg_type, "variable '$expr' not defined");
            }
            $result = '';
        }
        else {
            $result = $SDF_USER'var{$expr};
        }
    }
    elsif ($expr =~ /^\!\s*(\w+)$/) {
        $result = $SDF_USER'var{$1} ? 0 : 1;
    }
    elsif ($expr =~ /^$/) {
        $result = '';
    }

    # Handle implicit calls to Calc
    elsif ($expr =~ /^[=+]\s*(.+)$/) {
        $result = &SDF_USER'Calc($1);
    }

    else {
        # evaluate the expression in "user-land"
        package SDF_USER;
        $main'result = eval $main'expr;
        package main;
        if ($@) {
            &AppMsg("warning", "evaluation of '$expr' failed: $@");
            $result = '';
        }
    }

    # Apply the format, if any
    if ($format ne '') {
        $action = $SDF_USER'var{"FORMAT_$format"};
        if ($action eq '') {
            &AppMsg("warning", "unknown format '$format'");
        }
        else {
            package SDF_USER;
            $_ = $main'result;
            $main'result = eval $main'action;
            package main;
            if ($@) {
                &AppMsg("warning", "format '$format' failed: $@");
            }
        }
    }

    # Return result
    return $result;
}

#
# >>Description::
# {{Y:SdfJoin}} formats a style, text and attributes into a paragraph.
#
sub SdfJoin {
    local($style, $text, %attr) = @_;
    local($sdf);

    # Return result
    return join('', $style, '[', &SdfAttrJoin(*attr), ']', $text);
}

#
# >>Description::
# {{Y:SdfAttrSplit}} parses a string of attributes into a set of
# name-value pairs.
#
sub SdfAttrSplit {
    local($attrs) = @_;
    local(%attrs);
    local(@attrs, $append);
    local($attr, $name, $value);

    # build the list of attributes, remembering that ';;' means ';', but
    # ignoring a leading ';'.
    $attrs =~ s/^\s*;\s*//;
    @attrs = ();
    $append = 0;
    for $attr (split(/\s*;\s*/, $attrs)) {
        if ($attr eq '') {
            $attrs[$#attrs] .= ';';
            $append = 1;
        }
        elsif ($append) {
            $attrs[$#attrs] .= $attr;
            $append = 0;
        }
        else {
            push(@attrs, $attr);
        }
    }

    # parse the attributes  
    for $attr (@attrs) {
        if ($attr =~ /^([^=]+)\=/) {
            $name = $1;
            $value = &_SdfEvaluate($', '', 1);
        }
        else {
            $name = $attr;
            $value = 1;
        }
        $attrs{$name} = $value;
    }

    # return result
    return %attrs;
}

#
# >>Description::
# {{Y:SdfAttrJoin}} formats a set of name-value pairs (%attr) into a string.
# {{sep}} is the separator to use between attributes. The default
# separator is semi-colon.
#
sub SdfAttrJoin {
    local(*attr, $sep) = @_;
    local($attrtext);
    local($key, $value, @attrtext);

    # default the separator
    $sep = ";" if $sep eq '';

    # convert the attributes to text
    @attrtext = ();
    for $key (keys %attr) {
        $value = $attr{$key};
        #$value =~ s/\\/\\\\/g;
        #$value =~ s/'/\\'/g;
        #$value =~ s/([\]])/\\]/g;
        $value =~ s/(['\]\\])/\\$1/g;
        if ($sep eq ";") {
            $value =~ s/\;+/$&;/g;
        }
        if ($value !~ /^\d+$/) {
            $value = "'" . $value . "'";
        }
        push(@attrtext, "$key=$value");
    }
    $attrtext = join($sep, @attrtext);

    # Return result
#print "attrs: $attrtext.\n";
    return $attrtext;
}

#
# >>Description::
# {{Y:SdfAttrJoinSorted}} formats a set of name-value pairs (%attr) into
# a string where the attributes are sorted by name.
# {{sep}} is the separator to use between attributes. The default
# separator is semi-colon.
#
sub SdfAttrJoinSorted {
    local(*attr, $sep) = @_;
    local($attrtext);
    local($key, $value, @attrtext);

    # default the separator
    $sep = ";" if $sep eq '';

    # convert the attributes to text
    @attrtext = ();
    for $key (sort keys %attr) {
        $value = $attr{$key};
        #$value =~ s/\\/\\\\/g;
        #$value =~ s/'/\\'/g;
        #$value =~ s/([\]])/\\]/g;
        $value =~ s/(['\]\\])/\\$1/g;
        if ($sep eq ";") {
            $value =~ s/\;+/$&;/g;
        }
        if ($value !~ /^\d+$/) {
            $value = "'" . $value . "'";
        }
        push(@attrtext, "$key=$value");
    }
    $attrtext = join($sep, @attrtext);

    # Return result
    return $attrtext;
}

#
# >>Description::
# {{Y:SdfAttrClean}} removes target-specific attributes (for other targets)
# from a set of attributes. However, if the driver is 'raw', all attributes
# are kept.
#
sub SdfAttrClean {
    local(*attr) = @_;
#   local();
    local($driver, $target);
    local($name);

    # Keep all attributes for raw format
    $driver = $SDF_USER'var{'OPT_DRIVER'};
    return if $driver eq 'raw';

    # Delete attributes in 'families' other than the current driver or target
    $target = $SDF_USER'var{'OPT_TARGET'};
    for $name (keys %attr) {
        delete $attr{$name} if $name =~ /^(\w+)\./ && $1 ne $driver &&
          $1 ne $target;
    }
}

#
# >>Description::
# {{Y:SdfAttrMap}} maps a set of attributes using the configuration tables
# {{%map_to}}, {{%map_map}} and {{%map_attrs}}.
# {{$defaults}} is a string of default attributes.
# This routine is used by format drivers to merge user-supplied
# attributes with those in 'attribute' and 'style' configuration tables.
#
sub SdfAttrMap {
    local(*attr, $target, *map_to, *map_map, *map_attrs, $defaults) = @_;
#   local();
    local($name, $value, $to, $map, %new, $new);

    # Map the user-supplied attributes
    for $name (keys %attr) {
        $value = $attr{$name};

        # Get the configuration details
        $to = $map_to{$name};
        $map = $map_map{$name};
        %new = &SdfAttrSplit($map_attrs{$name});

        # If 'To' is set, change the name
        #$name = "$target.$to" if $to ne '';
        if ($to ne '') {
            delete $attr{$name};    # delete the existing name
            $name = "$target.$to";
        }

        # If 'Map' is set, change the value
        &_SdfAttrValueMap(*value, $map) if $map;
 
        # Update the changes, if any
        if ($to || $map) {
            $attr{$name} = $value;
#print "new $name=$value<\n";
        }

        # Add implicit attributes, if any
        for $new (keys %new) {
            $attr{"$target.$new"} = $new{$new};
        }
    }

    # Merge in the defaults
    %new = &SdfAttrSplit($defaults);
    for $new (keys %new) {
        $name = "$target.$new";
        $attr{$name} = $new{$new} unless defined $attr{$name};
    }
}

#
# >>_Description::
# {{Y:_SdfAttrValueMap}} maps a value using either a lookup table or
# a subroutine.
#
sub _SdfAttrValueMap {
    local(*value, $map) = @_;
#   local();
    local($name, $action);
    local($newvalue);

    # Build the action
    $name = substr($map, 1);
    $action = ($map =~ /^\%/) ? "\$$name\{\$'value\}" : "&$name(\$'value)";

    # Get the new value
    package SDF_USER;
    $'newvalue = eval $'action;
    package main;
    &AppMsg("warning", "attribute mapping via '$map' failed: $@ (action: $action)") if $@;
    $value = $newvalue if defined $newvalue;
}

#
# >>_Description::
# {{Y:_SdfAttrCheck}} checks an attribute.
# {{kind}} should be either "phrase" or "paragraph".
#
sub _SdfAttrCheck {
    local($name, $value, $kind) = @_;
#   local();
    local($type, $rule);

    # check the attribute is known & get the type and rule, if any
    if ($kind eq 'paragraph') {
        unless ($SDF_USER'paraattrs_name{$name}) {
            &AppMsg("warning", "unknown paragraph attribute '$name'");
        }
        $type = $SDF_USER'paraattrs_type{$name};
        $rule = $SDF_USER'paraattrs_rule{$name};
    }
    else {
        unless ($SDF_USER'phraseattrs_name{$name}) {
            &AppMsg("warning", "unknown phrase attribute '$name'");
        }
        $type = $SDF_USER'phraseattrs_type{$name};
        $rule = $SDF_USER'phraseattrs_rule{$name};
    }


    # validate the rule, if any
    unless (&MiscCheckRule($value, $rule, $type)) {
        &AppMsg("warning", "bad value '$value' for $kind attribute '$name'");
    }
}

#
# >>Description::
# {{Y:SdfSizeGraphic}} returns the {{width}} and {{height}} of a graphic
# stored in {{file}}. Zero is returned for both values if the size could not
# be extracted. File types currently supported are EPSI, PICT, GIF and PCX.
#
sub SdfSizeGraphic {
    local($file) = @_;
    local($width, $height);
    local($ext);
    local($line);
    local($junk, $tlbr, $top, $left, $bottom, $right, $xy);
    local($xmin1, $xmin2, $ymin1, $ymin2, $xmax1, $xmax2, $ymax1, $ymax2);
    local($wh, $w1, $w2, $h1, $h2);
    local($upi1, $upi2, $scale);

    # Get the file extension
    $ext = (&'NameSplit($file))[2];

    # Open the file
    open(SDF_GRAPHIC, $file) || return (0,0);

    # EPSI files: look for BoundingBox statement
    if ($ext eq 'eps' || $ext eq 'epsi' || $ext eq 'ai') {
        while (($line = <SDF_GRAPHIC>) ne '') {
            if ($line =~ /^%%BoundingBox:\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)/) {
                $width = sprintf("%dpt", $3 - $1 + 1);
                $height = sprintf("%dpt", $4 - $2 + 1);
                last;
            }
        }
    }

    # PICT files: bytes 514+8 are Top,Left and Bottom,Right
    elsif ($ext eq 'pct' || $ext eq 'pict') {
        if (read(SDF_GRAPHIC, $junk, 514) && read(SDF_GRAPHIC, $tlbr, 8)) {
            ($top, $left, $bottom, $right) = unpack("S4", $tlbr);
            $width = sprintf("%dpt", $right - $left + 1);
            $height = sprintf("%dpt", $bottom - $top + 1);
        }
    }

    # GIF files: bytes 7-10 are width and height with low order byte 1st
    elsif ($ext eq 'gif') {
        if (read(SDF_GRAPHIC, $junk, 6) && read(SDF_GRAPHIC, $wh, 4)) {
            ($w1, $w2, $h1, $h2) = unpack("C4", $wh);
            $width  = sprintf("%dpt", $w2 * 256 + $w1);
            $height = sprintf("%dpt", $h2 * 256 + $h1);
        }
    }

    # PCX files: bytes 5-12 are Xmin,Ymin,Xmax,Ymax with low order byte 1st
    elsif ($ext eq 'pcx') {
        if (read(SDF_GRAPHIC, $junk, 4) && read(SDF_GRAPHIC, $xy, 8)) {
            ($xmin1, $xmin2, $ymin1, $ymin2,
             $xmax1, $xmax2, $ymax1, $ymax2) = unpack("C8", $xy);
            $top    = $ymin2 * 256 + $ymin1;
            $left   = $xmin2 * 256 + $xmin1;
            $right  = $xmax2 * 256 + $xmax1;
            $bottom = $ymax2 * 256 + $ymax1;
            $width = sprintf("%dpt", $right - $left + 1);
            $height = sprintf("%dpt", $bottom - $top + 1);
        }
    }

    # WMF files: bytes 7-16 are Xmin,Ymin,Xmax,Ymax,units_per_inch
    # with low order byte 1st
    elsif ($ext eq 'wmf') {
        if (read(SDF_GRAPHIC, $junk, 6) && read(SDF_GRAPHIC, $xy, 10)) {
            ($xmin1, $xmin2, $ymin1, $ymin2,
             $xmax1, $xmax2, $ymax1, $ymax2,
             $upi1, $upi2) = unpack("C10", $xy);
#print STDERR "$xmin1, $xmin2, $ymin1, $ymin2.\n";
#print STDERR "$xmax1, $xmax2, $ymax1, $ymax2.\n";
#print STDERR "$upi1, $upi2.\n";
            $top    = $ymin2 * 256 + $ymin1;
            $left   = $xmin2 * 256 + $xmin1;
            $right  = $xmax2 * 256 + $xmax1;
            $bottom = $ymax2 * 256 + $ymax1;
            $scale  = ($upi2  * 256 + $upi1) / 72;
#print STDERR "$top, $left, $right, $bottom, $scale.\n";
            if ($top > 32768) {
                # Assume central origin (as output by Powerpoint)
                $width = sprintf("%dpt", $right * 2 / $scale);
                $height = sprintf("%dpt", $bottom * 2 / $scale);
            }
            else {
                $width = sprintf("%dpt", ($right - $left + 1) / $scale);
                $height = sprintf("%dpt", ($bottom - $top + 1) / $scale);
            }
        }
    }

    # BMP files: bytes 19-23 and 24-27 are width and height
    elsif ($ext eq 'bmp') {
        if (read(SDF_GRAPHIC, $junk, 18) && read(SDF_GRAPHIC, $wh, 8)) {
            ($w1, $w2, $w3, $w4, $h1, $h2, $h3, $h4) = unpack("C8", $wh);
            $width  = sprintf("%dpt", $w3 * 256 + $w1);
            $height = sprintf("%dpt", $h3 * 256 + $h1);
        }
    }

    else {
        $width = 0;
        $height = 0;
    }

    # Close the file
    close(SDF_GRAPHIC);

    # Return result
    return ($width, $height);
}

#
# >>Description::
# {{Y:SdfColPositions}} returns a list of column positions
# given a total number of columns, a format attribute and
# a right margin.
#
sub SdfColPositions {
    local($columns, $format, $margin) = @_;
    local(@result);
    local($assigned);
    local($known);
    local($col);
    local($guess);
    local($ratio);

    # Find out how many columns are known
    $assigned = 0;
    $known = 0;
    for $col (split(/,/, $format)) {
        if ($col =~ s/^([\d\.]+)\%$/\1/) {
            $assigned += $col;
            $known++;
        }
        else {
            $col = 0;
        }
        push(@result, $col);
    }

    # Divide the rest of the space, if necessary
    if ($known < $columns) {
        $guess = (100 - $assigned)/($columns - $known);
        for ($col = 0; $col < $columns; $col++) {
            $result[$col] = $guess if $result[$col] == 0;
        }
    }

    # Convert the percentages to positions
    for ($col = 1; $col < $columns; $col++) {
        $result[$col] += $result[$col - 1];
    }
    $#result = $columns - 1;
    $ratio = $margin/100;
    for $col (@result) {
        $col = int ($col * $ratio + 0.5);
    }

    # Return result
    return @result;
}

#
# >>Description::
# {{Y:SdfHeadingPrefix}} returns the prefix for the next heading.
# {{type}} is H, A or P and {{level}} is the heading level.
#
sub SdfHeadingPrefix {
    local($type, $level) = @_;
    local($prefix);

    # For plain headings, we do nothing
    return '' if $type eq 'P';

    # The counter arrays start from 0, so adjust the level accordingly
    $level--;

    # For chapter headings, we number things as 1, 1.1, 1.2, etc.
    if ($type eq 'H') {
        $_sdf_heading_counters[$level]++;
        $#_sdf_heading_counters = $level;
        return join('.', @_sdf_heading_counters) . ". ";
    }

    # For appendix headings, we number things as A, A.1, A.2, etc.
    elsif ($type eq 'A') {
        if ($level == 0 && scalar(@_sdf_appendix_counters) == 0) {
            $_sdf_appendix_counters[$level] = 'A';
        }
        else {
            $_sdf_appendix_counters[$level]++;
        }
        $#_sdf_appendix_counters = $level;
        return join('.', @_sdf_appendix_counters) . ". ";
    }
}


########## Post Processing User Routines ##########

# switch to the user package
package SDF_USER;

# execute a system command
sub SdfSystem {
    local($cmd) = @_;
    local($exit_code);

    &'AppMsg("object", "executing '$cmd'\n") if $'verbose >= 1;
    $exit_code = system($cmd);
    if ($exit_code) {
        $exit_code = $exit_code / 256;
        &'AppMsg("warning", "'$action' exit code was $exit_code from '$cmd'");
    }
    return $exit_code;
}

# execute sdfbatch
sub SdfBatch {
    local($flags) = @_;
#   local();
    local($file, $cmd);
    local($tmp_file);

    # Check the file exists
    $file = "$short.$out_ext";
    unless (-f $file) {
        &'AppMsg("error", "cannot execute sdfbatch on nonexistent file '$file'");
        return;
    }

    # Build the default command
    ## xxx installscript resolution may be better done during build time
    #$cmd = "$Config::Config{installscript}/sdfbatch $flags $short.$out_ext";
    # IGC 23/Feb/98: assume sdfbatch is on the path rather than in the
    # same place Perl is installed.
    $cmd = "sdfbatch $flags $short.$out_ext";

    # Save the output in a temporary file
    $tmp_file = "/tmp/sdf$$";
    $cmd .= " > $tmp_file 2>&1";

    # Execute the command
    $exit_code = &SdfSystem($cmd);

    # If verbose mode is on, or something went wrong, show the output
    if ($verbose || $exit_code) {
        unless (open(TMPFILE, $tmp_file)) {
            &AppExit("app_warning", "unable to open tmp file '$tmp_file'");
        }
        else {
            print <TMPFILE>;
            close(TMPFILE);
        }
    }
    unlink($tmp_file);
}

# delete a file
sub SdfDelete {
    local($file) = @_;
#   local();
    local($cmd);

    # Build the command
    $cmd = "rm -f $file";

    # Execute the command
    &SdfSystem($cmd) if -f $file;
}

# delete a set of files after a book build
sub SdfBookClean {
    local($ext) = @_;
#   local();
    local(@files);
    local($_);
    local(@cannot);

    # Leave things alone if verbose mode is on or there is nothing to do
    return if $'verbose;
    return unless @'sdf_book_files;

    # If an extension is given, use that set of
    # files, rather than the known ones.
    @files = @'sdf_book_files;
    if ($ext ne '') {
        for $_ (@files) {
            $_ = &'NameSubExt($_, $ext);
        }
    }

    # Delete the files
    @cannot = grep(!unlink($_), @files);
    #if (@cannot) {
    #    &'AppMsg("object", "unable to delete '@cannot'");
    #}
}

# rename xx.out.ps to xx.ps if FrameMaker 5 is being used to
# generate PostScript
#### OBSOLETE - this is now done inside sdfbatch
sub SdfRenamePS {
    local($xx) = @_;
#   local();
    local($cmd);

    # Do nothing unless FrameMaker 5 is being used
    return unless $'sdf_fmext eq 'fm5';

    # Wait until the print driver has finished
    &'AppMsg("object", "waiting for the print driver\n");
    until (-f "$xx.$out_ext.ps") {
        sleep(1);
        print STDERR ".";
    }
    print STDERR "\n";

    # Rename the file
    $cmd = "/bin/mv $xx.$out_ext.ps  $xx.ps";
    &SdfSystem($cmd);
}

# package return value
1;
