# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     SDF Macros Library
#
# >>Copyright::
# Copyright (c) 1992-1996, Ian Clatworthy (ianc@mincom.com).
# You may distribute under the terms specified in the LICENSE file.
#
# >>History::
# -----------------------------------------------------------------------
# Date      Who     Change
# 24-Oct-98 ianc    added jump macro, variables parameter for classes
# 29-Feb-96 ianc    SDF 2.000
# -----------------------------------------------------------------------
#
# >>Purpose::
# This library provides the built-in macros (implemented in [[Perl]]) for
# [[SDF]] files.
#
# >>Description::
# For default values within argument tables:
#
# * the empty string means there is no default
# * the symbol _NULL_ means the default is the empty string.
#
# >>Limitations::
#
# >>Implementation::
# The block macros (i.e. block/endblock, macro/endmacro) work as follows:
#
# ^ the starting macro sets the following global variables:
#   - {{$sdf_block_start}} to the current line number
#   - {{$sdf_block_type}} to {{block}} or {{macro}}
#   - {{@sdf_block_text}} to empty
#   - {{%sdf_block_args}} to the arguments
# + the main parser then builds {{@sdf_block_text}} by searching
#   until it finds the end of the structure (i.e. the end-style macro
#   at the same nesting level)
# + the ending macro then:
#   - clears {{$sdf_block_type}}
#   - processes {{@sdf_block_text}} using {{%sdf_block_args}}
#
# This strategy minimises the work these macros have to do.
#
# The conditional text macros (i.e. if, elsif, etc.) work by changing
# the following global stacks:
#
# * {{@sdf_if_start}} - the starting line number (needed for errors)
# * {{@sdf_if_now}} - is the current text section to be included?
# * {{@sdf_if_yet}} - has a section been included yet?
# * {{@sdf_if_else}} - has the else directive been found yet?
#


# Switch to the user package
package SDF_USER;

##### Constants #####

@_CLASS_PARAMS = (
    'Name       Type        Rule',
    'data       boolean',
    'cited      boolean',
    'root       string',
    'columns    string',
    'style      string',
    'compact    boolean',
    'wide       boolean',
    'headings   boolean',
    'where      string',
    'sort       string',
    'select     string',
    'delete     string',
    'colaligns  string',
    'colvaligns string',
    'wrap       integer',
    'variables  boolean',
);

##### Variables #####

# Loaded modules
%_loaded = ();

# User variables, macros, export lookup table
%var = ();
%macro = ();
%export = ();

# Header/footer parts
%page_hf = ();

# Class definitions
%_class = ();

# Object properties
%obj_name = ();
%obj_long = ();

# Stack of file-related information
@_file_info = ();

# Subsection prefixes
%subsection_prefix = ();

# Event data - paragraphs
@evcode_paragraph = ();
@evmask_paragraph = ();
@evid_paragraph = ();

# Event data - phrases
@evcode_phrase = ();
@evmask_phrase = ();
@evid_phrase = ();

# Event data - variables
@evcode_variable = ();
@evmask_variable = ();
@evid_variable = ();

# Event data - macros
@evcode_macro = ();
@evmask_macro = ();
@evid_macro = ();

# Event data - filters
@evcode_filter = ();
@evmask_filter = ();
@evid_filter = ();

# Event data - tables
@evcode_table = ();
@evmask_table = ();
@evid_table = ();

# Lookup table of readonly & restricted variable families
%restricted = ();
%readonly = ();

##### Initialisation #####

#
# >>Description::
# {{Y:InitMacros}} initialises the global variables in this module.
#
sub InitMacros {
#   local() = @_;
#   local();
    local($name);

    %_loaded = ();
    %var = ();
    %macro = ();
    %export = ();
    %page_hf = ();
    %_class = ();
    %obj_name = ();
    %obj_long = ();
    @_file_info = ();
    %subsection_prefix = ();

    @evcode_paragraph = ();
    @evmask_paragraph = ();
    @evid_paragraph = ();
    @evcode_phrase = ();
    @evmask_phrase = ();
    @evid_phrase = ();
    @evcode_variable = ();
    @evmask_variable = ();
    @evid_variable = ();
    @evcode_macro = ();
    @evmask_macro = ();
    @evid_macro = ();
    @evcode_filter = ();
    @evmask_filter = ();
    @evid_filter = ();
    @evcode_table = ();
    @evmask_table = ();
    @evid_table = ();

    %readonly = ();
    %restricted = ();
    for $name (keys %'sdf_target) {
        $name =~ tr/a-z/A-Z/;
        $restricted{$name} = 1;
    }
}

##### Support Routines #####

#
# >>_Description::
# {{Y:_PageHF}} builds headers or footers.
# {{type}} is 'HEADER' or 'FOOTER'.
# If {{overwrite}} is true, the existing header/footer macros are cleared.
# Otherwise the existing macros are edited.
# {{pages}} is a comma separated list of page names (i.e. First,Right,Left).
# {{component}} is the manual component, if any.
# {{%parts}} is the assocative array of parts within the macro.
sub _PageHF {
    local($type, $overwrite, $component, *pages, *parts) = @_;
    local(@result);
    local($page, $comp_page);
    local($mac_name, $mac_value, %mac_parts);
    local($line, $first, $last);
    local($posn, @posns);
    local($sep, $part, $varname);

    # Build the pages
    for $page (@pages) {
        $comp_page = $component ne '' ? "\U${component}_$page" : "\U$page";
        $mac_name = "PAGE_${comp_page}_$type";

        # Get and save the parts within this macro
        if ($overwrite) {
            %mac_parts = %parts;
        }
        else {
            %mac_parts = &'SdfAttrSplit($page_hf{$comp_page});
            @mac_parts{keys %parts} = values %parts;
        }
        $page_hf{$comp_page} = &'SdfAttrJoin(*mac_parts);

        # Get the part ordering information
        $first = 1;
        $last  = $var{'OPT_HEADINGS'};
        if ($type eq 'HEADER') {
            $last = 2 if $last > 2;
        }
        elsif ($last > 3) {
            $first--;
            $last--;
        }
        @posns = "\U$page" eq 'LEFT' ?
                 ('outer', 'center', 'inner') :
                 ('inner', 'center', 'outer');

        # Build the macro value
        $mac_value = $last >= 3 ? "${type}[size='7pt']" : "$type:";
        $sep = '';
        for $line ($first .. $last) {
            for $posn (@posns) {
                $part = $posn . $line;
                $varname = $mac_name . "_\U$part";
                $var{$varname} = $mac_parts{$part};
                $var{$varname} = '' unless defined $var{$varname};
                $mac_value .= $sep . '[[' . $varname . ']]';
                $sep = '[[tab]]';
            }
            $sep = '[[nl]]';
        }
 
        # Add this macro to the result
#print STDERR "$mac_name macro is:\n$mac_value\n";
        push(@result, "!macro $mac_name", $mac_value, "!endmacro");
    }

    # Return result
    return @result;
}

#
# >>_Description::
# {{Y:_EventFind}} finds a name in a list of event names.
# The index of the event is returned, or -1 if the event is
# not found.
#
sub _EventFind {
    local(*stack, $name) = @_;
    local($index);

    # Search through the stack of names
    for ($index = $#stack; $index >= 0; $index--) {
        return $index if $stack[$index] eq $name;
    }

    # If we reach here, no luck
    return -1;
}

#
# >>_Description::
# {{Y:_ClassHandler}} is the implementation for class filters.
#
sub _ClassHandler {
    local($class, *rules, *text, %param) = @_;
    local(@tbl, @flds, $rec, %values);
    local($name_style, $name_fld, $long_fld);
    local($process);
    local(@out_fields, @out_styles, $out_values);
    local($field, $style, $value);
    local($root);
    local($name, $long, $jump);
    local($params);
    local($tbl_style);
    local($view);
    local($make_vars, $var_name);

    @tbl = &'TableParse(@text);
    @text = ();
    &'TableValidate(*tbl, *rules);

    # Get the class details
    $name_style = $_class{$class,'name_style'};
    $name_fld   = $_class{$class,'name_fld'};
    $long_fld   = $_class{$class,'long_fld'};

    # Get the processing action
    if ($param{'data'}) {
        $process = 'data';
    }
    elsif ($param{'cited'}) {
        $process = 'cited';
    }
    else {
        $process = 'display';
    }

    # Get the 'make variables' flag
    $make_vars = $param{'variables'};
    $var_name = '';

    # For display tables, get the fields to be output
    @out_fields = ();
    @out_styles = ();
    if ($process eq 'display') {
        if ($param{'columns'}) {
            for $field (split(/,/, $param{'columns'})) {
                if ($field =~ /^(\w+):(.+)$/) {
                    push(@out_fields, $2);
                    push(@out_styles, $1);
                }
                else {
                    push(@out_fields, $field);
                    push(@out_styles, '');
                }
            }
        }
        else {
            @out_fields = ($name_fld, $long_fld);
            @out_styles = ($name_style, '');
        }
    }

    # Process the data
    (@flds) = &'TableFields(shift @tbl);
    $root = $param{'root'};
    for $rec (@tbl) {
        if ($rec =~ /^!/) {
            push(@text, $rec);
            next;
        }
        %values = &'TableRecSplit(*flds, $rec);

        # Get the fields of interest
        $name = $values{$name_fld};
        $long = $values{$long_fld};
        $long = $obj_name{$class,$name,$long_fld} if $long eq '';
        $jump = $values{'Jump'};
        $jump = $root . $jump if $jump ne '';
        $jump = $obj_name{$class,$name,'Jump'} if $jump eq '';

        # Convert the name to a legal variable name, if necessary
        if ($make_vars) {
            $var_name = $name;
            $var_name =~ s/\W/_/g;
        }

        # Store the data - we call an internal macro to do this (rather
        # than doing it directly) as this approach ensures that macros
        # embedded in the original data table (e.g. !if) have the
        # expected effect.
        $values{'Jump'} = $jump;
        push(@text, "!_store_ " . join("\000", $class, $process ne 'data',
            $name_fld, $name, $long_fld, $long, %values));
        push(@text, "!define $var_name '{{$name_style:$name}}'") if $var_name ne '';

        # For display tables, build the output
        if ($process eq 'display') {
            if ($long_fld && $long eq '' && $jump eq '') {
                &'AppMsg("warning", "unknown object '$name' in class '$class'");
            }
            @out_values = ();
            for ($i = 0; $i <= $#out_fields; $i++) {
                $field = $out_fields[$i];
                $style = $out_styles[$i];

                # Get the view, if any.
                if ($field =~ /^(\w+)\&/) {
                    $field = $1;
                    $view = $';
                }
                else {
                    $view = '';
                }
        
                # Note: The logic below was originally put there for
                # speed reasons, I think? However, the introduction of
                # views means that Value should now always be called.
                # However, doing that breaks some tests at the moment?

                # Get the value
                if ($field eq $name_fld) {
                    $value = $name;
                }
                elsif ($field eq $long_fld) {
                    $value = $long;
                }
                elsif (defined($values{$field})) {
                    $value = $values{$field};
                }
                else {
                    my $ok_class = $class; $ok_class =~ s/['\\]/\\$&/g;
                    my $ok_name  = $name;  $ok_name  =~ s/['\\]/\\$&/g;
                    my $ok_field = $field; $ok_field =~ s/['\\]/\\$&/g;
                    my $ok_view  = $view;  $ok_view  =~ s/['\\]/\\$&/g;
                    $value = "[[&Value('$ok_class', '$ok_name', '$ok_field', '$ok_view')]]";
                }

                # Apply the format or style
                if ($style ne '') {
                    if (defined($var{"FORMAT_$style"})) {
                        if (substr($value, 0, 2) eq '[[') {
                            $value = "[[$style:" . substr($value, 2);
                        }
                        else {
                            $value = "[[$style:$value]]";
                        }
                    }
                    else {
                        $params = $view ? "[view='$view']" : ":";
                        $value = "{{$style$params$value}}";
                    }
                }

                push(@out_values, $value);
            }
            push(@text, join("~", @out_values));
        }
    }

    # Build the field parsing line.
    # We replace the & with a _ within the field name so that
    # column name parsing doesn't screw up if views are specified.
    my $fields_heading = join("~", @out_fields);
    $fields_heading =~ tr/&/_/;

    # For display tables, finish generating the table
    if ($process eq 'display') {
        $tbl_style = $param{'style'} ? $param{'style'} : 'plain';
        $params = "style='$tbl_style'";
        $params .= "; cellpadding=0; cellspacing=0" if $param{'compact'};
        $params .= "; wide" if $param{'wide'};
        $params .= "; noheadings" unless $param{'headings'};
        $params .= "; where='$param{'where'}'" if $param{'where'} ne '';
        $params .= "; sort='$param{'sort'}'" if $param{'sort'} ne '';
        $params .= "; select='$param{'select'}'" if $param{'select'} ne '';
        $params .= "; delete='$param{'delete'}'" if $param{'delete'} ne '';
        $params .= "; colaligns='$param{'colaligns'}'" if $param{'colaligns'} ne '';
        $params .= "; colvaligns='$param{'colvaligns'}'" if $param{'colvaligns'} ne '';
        $params .= "; wrap='$param{'wrap'}'" if $param{'wrap'} ne '';
        unshift(@text,
          "!block table; $params",
          $fields_heading);
        push(@text, "!endblock");
    }
#printf STDERR "%s<\n", join("<\n", @text);
}

#
# >>_Description::
# {{Y:_ObjectNameEP}} is the event processing for objects in a class.
#
sub _ObjectNameEP {
    local($class, $long_style, $long_fld) = @_;

    # Validate the object
    if (! $obj_name{$class,$text}) {
        &'AppMsg("warning", "unknown object '$text' in class '$class' (name EP)");
    }

    # Generate the hypertext, if any
    if ($attr{'jump'} eq '' && defined $obj_name{$class,$text,'Jump'}) {
        $attr{'jump'} = $obj_name{$class,$text,'Jump'};
    }

    # Expand the object name, if requested
    if ($attr{'expand'}) {
        delete $attr{'expand'};
        if ($long_fld && $obj_name{$class,$text,$long_fld} ne '') {
            $style = $long_style if $long_style ne '';
            $text = $obj_name{$class,$text,$long_fld};
        }
        else {
            &'AppMsg("warning", "unable to expand object '$text' in class '$class'");
        }
    }

    # Cite the object number, if requested
    elsif ($attr{'cite'}) {
        delete $attr{'cite'};
        $style = 'N';
        $text = &Value($class, $text, 'Cite', $attr{'view'});
    }
}

#
# >>_Description::
# {{Y:_ObjectLongEP}} is the event processing for object long names in a class.
#
sub _ObjectLongEP {
    local($class, $name_style, $name_fld) = @_;

    # Validate the object
    if (! $obj_long{$class,$text}) {
        &'AppMsg("warning", "unknown object '$text' in class '$class' (long EP)");
    }

    # Generate the hypertext, if any
    if ($attr{'jump'} eq '' && defined $obj_long{$class,$text,'Jump'}) {
        $attr{'jump'} = $obj_long{$class,$text,'Jump'};
    }

    # Shrink the object name, if requested
    if ($attr{'shrink'}) {
        delete $attr{'shrink'};
        if ($obj_long{$class,$text,$name_fld} ne '') {
            $style = $name_style;
            $text = $obj_long{$class,$text,$name_fld};
        }
        else {
            &'AppMsg("warning", "unable to shrink object '$text' in class '$class'");
        }
    }

    # Cite the object number, if requested
    elsif ($attr{'cite'}) {
        delete $attr{'cite'};
        $style = 'N';
        $text = &Value($class, $text, 'Cite', $attr{'view'});
    }
}

##### General Macros #####

# block - begin a block of text
@_block_MacroArgs = (
    'Name       Type        Default     Rule',
    'filter     filter',
    'params     rest        _NULL_',
);
sub block_Macro {
    local(%arg) = @_;
    local(@text);
#print STDERR "sb1 file: $'ARGV, lineno: $'app_lineno<\n";

    # Update the parser state
    $'sdf_block_start = $'app_lineno;
    $'sdf_block_type = 'block';
    @'sdf_block_text = ();
    %'sdf_block_arg = %arg;

    # Return result
    return ();
}

# endblock - end a block of text
@_endblock_MacroArgs = ();
sub endblock_Macro {
    local(%arg) = @_;
    local(@text);

    # Check the state
    if ($'sdf_block_type ne 'block') {
        &'AppMsg("error", "endblock macro not expected");
        return ();
    }

    # Update the parser state
    $'sdf_block_type = '';

    # Filter the text
    &ExecFilter($'sdf_block_arg{'filter'}, *'sdf_block_text,
      $'sdf_block_arg{'params'}, $'sdf_block_start, $'ARGV, 'filter on ');

    # Mark the text as a section, if necessary
    if (@'sdf_block_text) {
        unshift(@'sdf_block_text,
          "!_bos_ $'sdf_block_start;block on ");
        push(@'sdf_block_text, "!_eos_ $'app_lineno;$'app_context");
    }

    # Return result
    return @'sdf_block_text;
}

# include - include another file
@_include_MacroArgs = (
    'Name       Type        Default     Rule',
    'filename   string',
    'filter     filter      _NULL_',
    'params     rest        _NULL_',
);
sub include_Macro {
    local(%arg) = @_;
    local(@text);
    local($filename, $fullname);
    local($outfile);

    # Get the file location
    $filename = $arg{'filename'};
    $fullname = &FindFile($filename);
    if ($fullname eq '') {
        &'AppMsg("warning", "unable to find '$filename'");
        return ();
    }

    # Get the text
    unless (&FileFetch(*text, $fullname)) {
        &'AppMsg("warning", "unable to read '$fullname'");
        return ();
    }

    # Filter the text
    &ExecFilter($arg{'filter'}, *text, $arg{'params'});

    # Return result
    return ("!_bof_ '$fullname'", @text, "!_eof_");
}

# use - load a library module
@_use_MacroArgs = (
    'Name       Type        Default     Rule',
    'filename   string',
    'filter     filter      sdf',
    'params     rest        _NULL_',
);
sub use_Macro {
    local(%arg) = @_;
    local(@text);
    local($filename, $fullname);

    # Add the sdm extension, if there is none
    $filename = $arg{'filename'};
    $filename .= ".sdm" unless $filename =~ /\.\w+$/;

    # Get the file location
    $fullname = &FindModule($filename);
    if ($fullname eq '') {
        &'AppMsg("warning", "unable to find '$filename'");
        return ();
    }

    # If already loaded, do nothing
    return () if $_loaded{$fullname};

    # Get the text
    unless (&FileFetch(*text, $fullname)) {
        &'AppMsg("warning", "unable to read '$fullname'");
        return ();
    }

    # Mark the library as loaded
    $_loaded{$fullname} = 1;

    # Filter the text
    &ExecFilter($arg{'filter'}, *text, $arg{'params'});

    # Return result
    return ("!_bof_ '$fullname'", @text, "!_eof_");
}

# inherit - load a library
@_inherit_MacroArgs = (
    'Name       Type        Default     Rule',
    'library    string',
);
sub inherit_Macro {
    local(%arg) = @_;
    local(@text);
    local($library, $dos_library);
    local($module);

    # Add the library to the include and module paths
    $library = $arg{'library'};
    $dos_library = $library;
    $dos_library =~ s#/#\\#g;
    $module = (&'NameSplit($library))[1];
    if (-f "$module.sdm") {
        # Module is in the current directory
        $library = '.';
    }
    elsif (&'NameIsAbsolute($library)) {
        push(@include_path, $library);
        push(@module_path, $library);
        $var{'HLP_OPTIONS_ROOT'} .= ", $dos_library";
    }
    else {
        my $lib_dir = &FindLibrary($library);
        if ($lib_dir ne '') {
            push(@include_path, $lib_dir);
            push(@module_path, $lib_dir);
            $var{'HLP_OPTIONS_ROOT'} .= ", $var{'SDF_DOSHOME'}\\$dos_library";
        }
        else {
            &'AppMsg("warning", "unable to find library '$library'");
            return ();
        }
    }

    # Load the matching module
    @text = ("!use '$library/$module'");

    # Return result
    return @text;
}

# execute - include output from a command
@_execute_MacroArgs = (
    'Name       Type        Default     Rule',
    'cmd        string',
    'filter     filter      sdf',
    'params     rest        _NULL_',
);
sub execute_Macro {
    local(%arg) = @_;
    local(@text);
    local($cmd);

    # Get the text
    $cmd = $arg{'cmd'};
    unless (&FileFetch(*text, "$cmd|")) {
        &'AppMsg("error", "failed to execute '$cmd'");
        return ();
    }

    # Filter the text
    #&ExecFilter($arg{'filter'}, *text, $arg{'params'}, 0, "'$cmd'", 'line ');
    &ExecFilter($arg{'filter'}, *text, $arg{'params'});

    # Return result
    return ("!_bof_ '$cmd'", @text, "!_eof_");
}

# import - import an object (e.g. figure) from another package
@_import_MacroArgs = (
    'Name       Type        Default     Rule',
    'filename   string',
    'params     rest        _NULL_',
);
sub import_Macro {
    local(%arg) = @_;
#   local(@text);
    local($filename);
    local(%params);

    # Process the filename and attributes
    $filename = $arg{'filename'};
    %params = &'SdfAttrSplit($arg{'params'});
    &ProcessImageAttrs(*filename, *params);

    # Return result
    return (&'SdfJoin('__import', $filename, %params));
}

# jumps - create jump lines
@_jumps_MacroArgs = (
    'Name       Type        Default     Rule',
    'labels     string',
    'layout     string      Center      <Left|Center|Right|left|center|right>',
);
sub jumps_Macro {
    local(%arg) = @_;
    local(@text);
    local(@subs, $sub, $jump);
    local($sep);
    local($layout);

    # Build the jumps
    @subs = split(/,/, $arg{'labels'});
    $sep = '';
    for $sub (@subs) {
        if ($sub eq '') {
            $sub = "{{CHAR:nl}}";
            $sep = '';
        }
        else {
            $jump = &TextToId($sub);
            $sub = $sep . "{{[jump='#$jump']$sub}}";
            $sep = ' | ';
        }
    }

    # Build the output
    @text = ();
    $layout = $arg{'layout'};
    substr($layout, 0, 1) =~ tr/a-z/A-Z/;
    @text = ("[align='$layout']" . join("", @subs));

    # Return result
    return @text;
}

# subsections - list topic subsections (and create a jump line for HTML)
@_subsections_MacroArgs = (
    'Name       Type        Default     Rule',
    'labels     string',
    'prefix     string      Topic       <Topic|Noprefix|noprefix>',
    'layout     string      Left        <Left|Center|Right|None|left|center|right|none>',
);
sub subsections_Macro {
    local(%arg) = @_;
    local(@text);
    local(@subs, $sub, $jump);
    local($prefix);
    local($sep);
    local($layout);

    # Get the list of subsections
    @subs = split(/,/, $arg{'labels'});

    # Get the prefix, if any
    $prefix = '';
    if ($arg{'prefix'} eq 'Topic') {
        $prefix = $topic ne '' ? "$topic - " : '';
    }

    # Save the sub-section data and build the jumps
    $sep = '';
    for $sub (@subs) {
        if ($sub eq '') {
            $sub = "{{CHAR:nl}}";
            $sep = '';
        }
        else {
            $subsection_prefix{$sub} = $prefix;
            $jump = &TextToId($prefix . $sub);
            $sub = $sep . "{{[jump='#$jump']$sub}}";
            $sep = ' | ';
        }
    }

    # Build the output (HTML only for now)
    @text = ();
    if ($var{'OPT_TARGET'} eq 'html') {
        $layout = $arg{'layout'};
        substr($layout, 0, 1) =~ tr/a-z/A-Z/;
        if ($layout ne 'None') {
            @text = ("[align='$layout']" . join("", @subs));
        }
    }

    # Return result
    return @text;
}

# continued - continue a heading onto another page
@_continued_MacroArgs = (
    'Name       Type        Default             Rule',
    'style      string',
    'suffix     string      , {{N:Continued}}',
);
sub continued_Macro {
    local(%arg) = @_;
    local(@text);
    local($target);
    local($style, $suffix);

    # Build result
    $target = $var{'OPT_TARGET'};
    if ($target eq 'html' || $target eq 'hlp') {
        @text = ();
    }
    else {
        $style = $arg{'style'};
        $suffix = $arg{'suffix'};
        @text = $style . "[notoc;noid;continued][[&Previous($style)]]$suffix";
    }

    # Return result
    return @text;
}

# clear - insert a BR CLEAR for HTML
@_clear_MacroArgs = (
    'Name       Type        Default     Rule',
    'type       string      All         <Left|Right|All>',
);
sub clear_Macro {
    local(%arg) = @_;
    local(@text);

    # Build the result
    if ($var{'OPT_TARGET'} eq 'html') {
        @text = (
            "!block inline",
            "<BR CLEAR=\"" . $arg{'type'} . '">',
            "!endblock");
    }
    else {
        @text = ();
    }

    # Return result
    return @text;
}

# catalog - build a catalog of the objects already loaded for a class
@_catalog_MacroArgs = (
    'Name       Type        Default     Rule',
    'class      symbol',
    'mask       string',
    'params     rest        _NULL_',
);
sub catalog_Macro {
    local(%arg) = @_;
    local(@text);
    local($class, $name_fld);
    local($object, $mask);

    # Get the class and its name field
    $class    = $arg{'class'};
    $name_fld = $_class{$class,'name_fld'};

    # Build the output header
    @text = ("!block $class; $arg{'params'}", $name_fld);

    # Build the result
    $mask = $arg{'mask'};
    if ($mask eq 'cited') {
        for $object (split("\n", $_class{$class,'cited'})) {
            push(@text, $object);
        }
    }
    elsif ($mask =~ /^(\w+):/) {
        my $attr = $1;
        $mask = $';
        my $value;
        for $object (split("\n", $_class{$class,'catalog'})) {
            $value = &Value($class, $object, $attr);
            next if $mask ne '' && $value !~ /^$mask$/;
            push(@text, $object);
        }
    }
    else {
        for $object (split("\n", $_class{$class,'catalog'})) {
            next if $mask ne '' && $object !~ /^$mask$/;
            push(@text, $object);
        }
    }
    push(@text, "!endblock");

    # Return result
    return @text;
}

# namevalues - insert a set of object attributes using a namevalues filter
@_namevalues_MacroArgs = (
    'Name       Type        Default     Rule',
    'class      string',
    'object     string',
    'attributes string',
    'params     rest        _NULL_',
);
sub namevalues_Macro {
    local(%arg) = @_;
    local(@text);
    local($class, $object, @attrs, $attr);

    # Get the details
    $class = $arg{'class'};
    $object = $arg{'object'};
    @attrs = sort split(/,/, $arg{'attributes'});

    # Build result
    @text = ("!block namevalues; $arg{'params'}", "Name|Value");
    for $attr (@attrs) {
        push(@text, "$attr:|" . &Value($class, $object, $attr));
    }
    push(@text, "!endblock");

    # Return result
    return @text;
}

##### Variables Macros #####

# define - define a variable
@_define_MacroArgs = (
    'Name       Type        Default     Rule',
    'name       symbol',
    'value      string      1',
);
sub define_Macro {
    local(%arg) = @_;
    local(@text);
    local($name, $value);
    local($type, $rule);

    # Get the name and value
    $name = $arg{'name'};
    $value = $arg{'value'};

    ## If the variable looks like an enum, output an error
    #if ($name =~ /^[A-Z][a-z]+$/) {
    #    &'AppMsg("error", "'variable '$name' looks like an enumerated value");
    #    return ();
    #}

    # If the variable is in a family, check it has been declared
    if ($name =~ /^([A-Z]+)_/ && $restricted{$1} &&
      !$variables_name{$name}) {
        $status = (defined($var{$name}) || $readonly{$1}) ? 'read-only' : 'unknown';
        &'AppMsg("warning", "'$1' variable '$name' is $status - ignoring definition");
        return ();
    }

    # If the variable has been declared, validate it
    if ($variables_name{$name}) {
        $type = $variables_type{$name};
        $rule = $variables_rule{$name};
        unless (&'MiscCheckRule($value, $rule, $type)) {
            &'AppMsg("warning", "bad value '$value' for variable '$name'");
        }
    }

    # Save the definition
    $var{$name} = $value;

    # Export the variable, if necessary
    if ($export{$name}) {
        @text = (&'SdfJoin('__object', 'Variable',
                'Name',  $name,
                'value', $value));
    }

    # Return result
    return (@text);
}

# default - define a variable (if not already set)
@_default_MacroArgs = (
    'Name       Type        Default     Rule',
    'name       symbol',
    'value      string      1',
);
sub default_Macro {
    local(%arg) = @_;
    local(@text);
    local($name);

    $name = $arg{'name'};

    # Save the definition, if necessary
    &define_Macro(%arg) unless defined($var{$name});

    # Return result
    return ();
}

# undef - undefine a variable
@_undef_MacroArgs = (
    'Name       Type        Default     Rule',
    'name       symbol',
);
sub undef_Macro {
    local(%arg) = @_;
    local(@text);

    # Clear the definition
    delete $var{$arg{'name'}};

    # Return result
    return ();
}

# init - initialise a set of variables
@_init_MacroArgs = (
    'Name       Type        Default     Rule',
    'vars       rest        _NULL_',
);
sub init_Macro {
    local(%arg) = @_;
    local(@text);
    local(%vars, $name, $value);

    # Convert the name-value pairs to define macros
    %vars = &'SdfAttrSplit($arg{'vars'});
    for $name (sort keys %vars) {
        $value = $vars{$name};
        $value =~ s/'/\\'/g;
        push(@text, "!default $name '$value'");
    }

    # Return result
    return @text;
}

# export - mark a variable for export
@_export_MacroArgs = (
    'Name       Type        Default     Rule',
    'name       symbol',
);
sub export_Macro {
    local(%arg) = @_;
    local(@text);
    local($name);

    # Mark for export
    $name = $arg{'name'};
    $export{$name} = 1;

    # If already defined, export it immediately
    if (defined $var{$name}) {
        @text = (&'SdfJoin('__object', 'Variable',
                'Name',  $name,
                'value', $var{$name}));
    }

    # Return result
    return @text;
}

##### Configuration Macros #####

# macro - begin a macro definition
@_macro_MacroArgs = (
    'Name       Type        Default     Rule',
    'name       symbol',
);
sub macro_Macro {
    local(%arg) = @_;
    local(@text);

    # Update the parser state
    $'sdf_block_start = $'app_lineno;
    $'sdf_block_type = 'macro';
    @'sdf_block_text = ();
    %'sdf_block_arg = %arg;

    # Return result
    return ();
}

# endmacro - end a macro definition
@_endmacro_MacroArgs = ();
sub endmacro_Macro {
    local(%arg) = @_;
    local(@text);

    # Check the state
    if ($'sdf_block_type ne 'macro') {
        &'AppMsg("error", "endmacro macro not expected");
        return ();
    }

    # Update the parser state
    $'sdf_block_type = '';

    # Save the definition
    $macro{$'sdf_block_arg{'name'}} = join("\n", @'sdf_block_text);

    # Return result
    return ();
}

# class - declare a class of objects
@_class_MacroArgs = (
    'Name       Type        Default         Rule',
    'name       symbol',
    'styles     string',
    'ids        string      Name,Long',
    'properties string      Jump',
);
sub class_Macro {
    local(%arg) = @_;
    local(@text);
    local($name);
    local($name_style, $long_style);
    local($name_fld, $long_fld);
    local($fld, @rest, @rules);
    local($code);

    # Store the class details
    $name = $arg{'name'};
    ($name_style, $long_style) = split(/,/, $arg{'styles'});
    ($name_fld,   $long_fld)   = split(/,/, $arg{'ids'});
    $_class{$name} = 1;
    $_class{$name,'name_style'} = $name_style;
    $_class{$name,'long_style'} = $long_style;
    $_class{$name,'name_fld'} = $name_fld;
    $_class{$name,'long_fld'} = $long_fld;
    $_class{$name,'properties'}  = $arg{'properties'};

    # Build the rules table
    ($fld, @rest) = split(/,/, $arg{'ids'});
    push(@rest, split(/,/, $arg{'properties'}));
    @rules = ('Field:Category:Rule', "$fld:mandatory");
    push(@rules, "$fld:optional") while ($fld = shift(@rest));

    # Build the filter
    $code = <<end_of_code;
        \@_${name}_FilterParams = \@_CLASS_PARAMS;
        \@_${name}_FilterModel = &'TableParse(\@rules);
        sub ${name}_Filter {
            local(*text, %param) = \@_;

            &_ClassHandler('$name', *_${name}_FilterModel, *text, %param);
        }
end_of_code

    # Create the filter
    eval $code;
    if ($@) {
        &'AppMsg("error", "filter creation failed: $@");
    }

    # Declare the object styles
    @text = ("!block phrasestyles", "Name", $name_style);
    push(@text, $long_style) if $long_style ne '';
    push(@text, "!endblock");

    # Declare the event processing
    push(@text, "!on phrase '$name_style';;" .
      "&_ObjectNameEP('$name', '$long_style', '$long_fld')");
    push(@text, "!on phrase '$long_style';;" .
      "&_ObjectLongEP('$name', '$name_style', '$name_fld')") if $long_style;

    # Return result
    return @text;
}

# restrict - declare a restricted variable family
@_restrict_MacroArgs = (
    'Name       Type        Default     Rule',
    'name       string',
);
sub restrict_Macro {
    local(%arg) = @_;
    local(@text);

    $restricted{$arg{'name'}} = 1;
    return ();
}

# readonly - declare a readonly variable family
@_readonly_MacroArgs = (
    'Name       Type        Default     Rule',
    'name       string',
);
sub readonly_Macro {
    local(%arg) = @_;
    local(@text);

    $readonly{$arg{'name'}} = 1;
    return ();
}

# path_prepend - prepend a directory to the search path
@_path_prepend_MacroArgs = (
    'Name       Type        Default     Rule',
    'dir        string',
);
sub path_prepend_Macro {
    local(%arg) = @_;
    local(@text);
    local($dir);

    $dir = $arg{'dir'};
    unshift(@include_path, $dir) unless $include_path[0] eq $dir;
    return ();
}

# path_append - append a directory to the search path
@_path_append_MacroArgs = (
    'Name       Type        Default     Rule',
    'dir        string',
);
sub path_append_Macro {
    local(%arg) = @_;
    local(@text);
    local($dir);

    $dir = $arg{'dir'};
    push(@include_path, $dir) unless $include_path[$#include_path] eq $dir;
    return ();
}

# script - execute a Perl script
@_script_MacroArgs = (
    'Name       Type        Default     Rule',
    'code       rest',
);
sub script_Macro {
    local(%arg) = @_;
    local(@text);

    # execute the code
    eval $arg{'code'};
    if ($@) {
        &'AppMsg("error", "script failed: $@");
    }

    # Return result
    return ();
}

# targetobject - define a target object
@_targetobject_MacroArgs = (
    'Name       Type        Default     Rule',
    'type       string',
    'name       string',
    'parent     string      _NULL_',
    'attributes rest        _NULL_',
);
sub targetobject_Macro {
    local(%arg) = @_;
    local(@text);
    local($type, $name, $parent, $attrs);

    # Get the defails
    $type = $arg{'type'};
    $name = $arg{'name'};
    $parent = $arg{'parent'};
    $attrs = $arg{'attributes'};

    # Return result (efficiently)
    return ("__object[Name='$name';Parent='$parent';$attrs]$type");
}

##### Conditional Text Macros #####

# if - begin conditional text
@_if_MacroArgs = (
    'Name       Type        Default     Rule',
    'value      condition',
);
sub if_Macro {
    local(%arg) = @_;
    local(@text);
    local($expr_value);

    # If we are nested inside a section of an if macro which is not
    # to be included, we exclude all sections of this macro.
    push(@'sdf_if_start, $'app_lineno);
    if (@'sdf_if_now && ! $'sdf_if_now[$#main'sdf_if_now]) {
        push(@'sdf_if_now, 0);
        push(@'sdf_if_yet, 1);
        push(@'sdf_if_else, 0);
    }

    # Otherwise, evaluate the expression and process accordingly.
    else {
        $expr_value = $arg{'value'};
        push(@'sdf_if_now, $expr_value);
        push(@'sdf_if_yet, $expr_value);
        push(@'sdf_if_else, 0);
    }

    # Return result
    return ();
}

# elsif - begin a conditional section within conditional text
@_elsif_MacroArgs = (
    'Name       Type        Default     Rule',
    'value      condition',
);
sub elsif_Macro {
    local(%arg) = @_;
    local(@text);
    local($level);
    local($expr_value);

    # elsif not permitted outside an if macro
    unless (@'sdf_if_now) {
        &'AppMsg("error", "!elsif not expected");
        return ();
    }

    # Get the current nesting level
    $level = $#main'sdf_if_yet;

    # elsif after an else is not permitted
    if ($'sdf_if_else[$level]) {
        &'AppMsg("error", "!elsif found after else macro");
        return ();
    }

    # Only evaluate the expression if we haven't included a section yet
    if (! $'sdf_if_yet[$level]) {
        $expr_value = $arg{'value'};
        $'sdf_if_now[$level] = $expr_value;
        $'sdf_if_yet[$level] = $expr_value;
    }
    else {
        $'sdf_if_now[$level] = 0;
    }

    # Return result
    return ();
}

# elseif - begin a conditional section within conditional text
@_elseif_MacroArgs = @_elsif_MacroArgs;
sub elseif_Macro {
    local(%arg) = @_;
    local(@text);

    return &elsif_Macro(%arg);
}

# else - begin an else section within conditional text
@_else_MacroArgs = ();
sub else_Macro {
    local(%arg) = @_;
    local(@text);
    local($level);

    # else not permitted outside an if macro
    unless (@'sdf_if_now) {
        &'AppMsg("error", "!else not expected");
        return ();
    }

    # Get the current nesting level
    $level = $#main'sdf_if_yet;

    # record that we have encountered the else
    # (this is needed for checking that an elsif does not follow it)
    $'sdf_if_else[$level] = 1;

    # Only include this section if we haven't included a section yet
    if (! $'sdf_if_yet[$level]) {
        $'sdf_if_now[$level] = 1;
        $'sdf_if_yet[$level] = 1;
    }
    else {
        $'sdf_if_now[$level] = 0;
    }

    # Return result
    return ();
}

# endif - end conditional text
@_endif_MacroArgs = ();
sub endif_Macro {
    local(%arg) = @_;
    local(@text);

    # endif not permitted outside an if macro
    unless (@'sdf_if_now) {
        &'AppMsg("error", "!endif not expected");
        return ();
    }

    pop(@'sdf_if_start);
    pop(@'sdf_if_now);
    pop(@'sdf_if_yet);
    pop(@'sdf_if_else);

    # Return result
    return ();
}

##### Looping Macros #####

# for - begin a loop
@_for_MacroArgs = (
    'Name       Type        Default     Rule',
    'name       symbol',
    'values     rest',
);
sub for_Macro {
    local(%arg) = @_;
    local(@text);

    # Return result
    return ();
}

# endfor - end loop
@_endfor_MacroArgs = ();
sub endfor_Macro {
    local(%arg) = @_;
    local(@text);

    # Return result
    @text = ();
    return @text;
}

##### Table Macros #####

# table - begin a table
@_table_MacroArgs = (
    'Name       Type        Default     Rule',
    'columns    integer',
    'params     rest        _NULL_',
);
sub table_Macro {
    local(%arg) = @_;
    local(@text);
    local(@format, $format);
    local($lower, $sep, $upper);
    local(%param);
    local($col, $unspecified);

    # Update the state
    push(@'sdf_tbl_state, 1);
    push(@'sdf_tbl_start, $'app_lineno);

    # Validate and clean the parameters
    %param = &SdfTableParams('table', $arg{'params'}, *tableparams_name,
      *tableparams_type, *tableparams_rule);

    # Use the default style, if necessary
    $param{'style'} = &Var('DEFAULT_TABLE_STYLE') if $param{'style'} eq '';

    # Expand the format attribute to make processing within the driver
    # routines easier:
    # * % is appended for percentages
    # * '*' is expanded to '1*'
    # * '-' is expanded to '0%-100%' (likewise for =)
    # * '-d' is expanded to '0%-d' (likewise for =)
    # * 'd-' is expanded to 'd-100%' (likewise for =)
    # * defaults are applied for unspecified widths:
    #   - the last unspecified width is 1* (or 0%-100% for narrow tables)
    #   - other unspecified widths are 0%-100%.
    @format = ();
    if ($param{'format'} =~ /^\d+$/) {
        for $format (split(//, $param{'format'})) {
            push(@format, $format * 10 . "%");
        }
    }
    else {
        for $format (split(/\s*,\s*/, $param{'format'})) {
            if ($format =~ /^\d+$/) {
                $format .= '%';
            }
            elsif ($format eq '*') {
                $format = "1*";
            }
            elsif ($format =~ /([-=])/) {
                $lower = $` eq '' ? '0%' : $`;
                $sep   = $1;
                $upper = $' eq '' ? '100%' : $';
                $lower .= '%' if $lower =~ /^\d+$/;
                $upper .= '%' if $upper =~ /^\d+$/;
                $format = "$lower$sep$upper";
            }
            push(@format, $format);
        }
    }
    $unspecified = $param{'narrow'} ? '0%-100%' : '1*';
    for ($col = $arg{'columns'} - 1; $col >= 0; $col--) {
        if ($format[$col] eq '') {
            $format[$col] = $unspecified;
            $unspecified = '0%-100%';
        }
    }
    $param{'format'} = join(",", @format);
    delete $param{'narrow'};

    # Build the result
    @text = (&'SdfJoin("__table", $arg{'columns'}, %param));

    # Return result
    return @text;
}

# row - begin a table row
@_row_MacroArgs = (
    'Name       Type        Default     Rule',
    'type       string      Body        <Body|Heading|Footing|Group>',
    'params     rest        _NULL_',
);
sub row_Macro {
    local(%arg) = @_;
    local(@text);
    local(%param);

    # Check the state
    unless (@'sdf_tbl_state) {
        &'AppMsg("error", "!row not expected");
        return ();
    }

    # For performance, handle the empty parameters case first
    return ('__row[]Body') unless $arg{'type'}.$arg{'params'};

    # Validate and clean the parameters
    %param = &SdfTableParams('row', $arg{'params'}, *rowparams_name,
      *rowparams_type, *rowparams_rule);

    # Build the result
    @text = (&'SdfJoin("__row", $arg{'type'}, %param));

    # Return result
    return @text;
}

# cell - begin a table cell
@_cell_MacroArgs = (
    'Name       Type        Default     Rule',
    'params     rest        _NULL_',
);
sub cell_Macro {
    local(%arg) = @_;
    local(@text);
    local(%param);

    # Check the state
    unless (@'sdf_tbl_state) {
        &'AppMsg("error", "!cell not expected");
        return ();
    }

    # For performance, handle the empty parameters case first
    return ('__cell[]') if $arg{'params'} eq '';

    # Validate and clean the parameters
    %param = &SdfTableParams('cell', $arg{'params'}, *cellparams_name,
      *cellparams_type, *cellparams_rule);

    # Build the result
    @text = (&'SdfJoin("__cell", '', %param));

    # Return result
    return @text;
}

# endtable - end a table
@_endtable_MacroArgs = ();
sub endtable_Macro {
    local(%arg) = @_;
    local(@text);

    # Check the state
    unless (@'sdf_tbl_state) {
        &'AppMsg("error", "!endtable not expected");
        return ();
    }

    # Update the state
    pop(@'sdf_tbl_state);
    pop(@'sdf_tbl_start);

    # Build the result
    @text = (&'SdfJoin("__endtable", ''));

    # Return result
    return @text;
}

##### Header/footer Macros #####

# build_header - build a header macro
@_build_header_MacroArgs = (
    'Name       Type        Default     Rule',
    'pages      string',
    'component  string      _NULL_',
    'parts      rest        _NULL_',
);
sub build_header_Macro {
    local(%arg) = @_;
#   local(@text);
    local(@pages, %parts);

    # Get the arguments
    @pages = split(/,/, $arg{'pages'});
    %parts = &'SdfAttrSplit($arg{'parts'});

    # Return result
    return &_PageHF('HEADER', 1, $arg{'component'}, *pages, *parts);
}

# build_footer - build a footer macro
@_build_footer_MacroArgs = (
    'Name       Type        Default     Rule',
    'pages      string',
    'component  string      _NULL_',
    'parts      rest        _NULL_',
);
sub build_footer_Macro {
    local(%arg) = @_;
#   local(@text);
    local(@pages, %parts);

    # Get the arguments
    @pages = split(/,/, $arg{'pages'});
    %parts = &'SdfAttrSplit($arg{'parts'});

    # Return result
    return &_PageHF('FOOTER', 1, $arg{'component'}, *pages, *parts);
}

# edit_header - edit a header macro
@_edit_header_MacroArgs = (
    'Name       Type        Default     Rule',
    'pages      string',
    'component  string      _NULL_',
    'parts      rest        _NULL_',
);
sub edit_header_Macro {
    local(%arg) = @_;
#   local(@text);
    local(@pages, %parts);

    # Get the arguments
    @pages = split(/,/, $arg{'pages'});
    %parts = &'SdfAttrSplit($arg{'parts'});

    # Return result
    return &_PageHF('HEADER', 0, $arg{'component'}, *pages, *parts);
}

# edit_footer - edit a footer macro
@_edit_footer_MacroArgs = (
    'Name       Type        Default     Rule',
    'pages      string',
    'component  string      _NULL_',
    'parts      rest        _NULL_',
);
sub edit_footer_Macro {
    local(%arg) = @_;
#   local(@text);
    local(@pages, %parts);

    # Get the arguments
    @pages = split(/,/, $arg{'pages'});
    %parts = &'SdfAttrSplit($arg{'parts'});

    # Return result
    return &_PageHF('FOOTER', 0, $arg{'component'}, *pages, *parts);
}


##### Extraction Macros #####

# getdoc - get (SDF) documentation from a file
@_getdoc_MacroArgs = @_include_MacroArgs;
sub getdoc_Macro {
    local(%arg) = @_;
    local(@text);

    # Return result
    return &CommandMacro('sdfget -r', %arg);
}

# getcode - get source code (i.e. non-documentation) from a file
@_getcode_MacroArgs = @_include_MacroArgs;
sub getcode_Macro {
    local(%arg) = @_;
    local(@text);

    # Return result
    return &CommandMacro('sdfget -i', %arg);
}

# getusage - get the Command Line Interface for a script
@_getusage_MacroArgs = @_include_MacroArgs;
sub getusage_Macro {
    local(%arg) = @_;
    local(@text);

    # Return result
    return &CommandMacro('sdfcli', %arg);
}

# perlapi - get the Application Programming Interface for a Perl library
@_perlapi_MacroArgs = @_include_MacroArgs;
sub perlapi_Macro {
    local(%arg) = @_;
    local(@text);

    # Return result
    return &CommandMacro('sdfapi -j', %arg);
}

##### Event Processing Macros #####

# on - specify processing for an event
@_on_MacroArgs = (
    'Name       Type        Default     Rule',
    'type       symbol                  <paragraph|phrase|macro|filter|table>',
    'mask       string',
    'id         eventid     _NULL_      <\w+>',
    'code       rest',
);
sub on_Macro {
    local(%arg) = @_;
    local(@text);
    local($type);

    # Store the event
    $type = $arg{'type'};
    if ($type eq 'paragraph') {
        push(@evcode_paragraph, $arg{'code'});
        push(@evmask_paragraph, $arg{'mask'});
        push(@evid_paragraph, $arg{'id'});
    }
    elsif ($type eq 'phrase') {
        push(@evcode_phrase, $arg{'code'});
        push(@evmask_phrase, $arg{'mask'});
        push(@evid_phrase, $arg{'id'});
    }
    elsif ($type eq 'macro') {
        push(@evcode_macro, $arg{'code'});
        push(@evmask_macro, $arg{'mask'});
        push(@evid_macro, $arg{'id'});
    }
    elsif ($type eq 'filter') {
        push(@evcode_filter, $arg{'code'});
        push(@evmask_filter, $arg{'mask'});
        push(@evid_filter, $arg{'id'});
    }
    elsif ($type eq 'table') {
        push(@evcode_table, $arg{'code'});
        push(@evmask_table, $arg{'mask'});
        push(@evid_table, $arg{'id'});
    }

    # Return result
    return ();
}

# off - begin conditional text
@_off_MacroArgs = (
    'Name       Type        Default     Rule',
    'type       symbol                  <paragraph|phrase|macro|filter|table>',
    'id         eventid                 <\w+>',
);
sub off_Macro {
    local(%arg) = @_;
    local(@text);
    local($type, $id, $num);

    # Find & delete the event, if any
    $type = $arg{'type'};
    $id = $arg{'id'};
    if ($type eq 'paragraph') {
        $num = &_EventFind(*evid_paragraph, $id);
        if ($num != -1) {
            $evcode_paragraph[$num] = '';
            $evid_paragraph[$num] = '';
        }
    }
    elsif ($type eq 'phrase') {
        $num = &_EventFind(*evid_phrase, $id);
        if ($num != -1) {
            $evcode_phrase[$num] = '';
            $evid_phrase[$num] = '';
        }
    }
    elsif ($type eq 'macro') {
        $num = &_EventFind(*evid_macro, $id);
        if ($num != -1) {
            $evcode_macro[$num] = '';
            $evid_macro[$num] = '';
        }
    }
    elsif ($type eq 'filter') {
        $num = &_EventFind(*evid_filter, $id);
        if ($num != -1) {
            $evcode_filter[$num] = '';
            $evid_filter[$num] = '';
        }
    }
    elsif ($type eq 'table') {
        $num = &_EventFind(*evid_table, $id);
        if ($num != -1) {
            $evcode_table[$num] = '';
            $evid_table[$num] = '';
        }
    }

    # Check the event exists
    if ($num == -1) {
        &'AppMsg("warning", "unknown event '$id'");
    }

    # Return result
    return ();
}

##### Miscellaneous Macros #####

# insert - insert the output from a macro
@_insert_MacroArgs = (
    'Name       Type        Default     Rule',
    'macro      string',
    'missing    string      ok          <ok|error|warning>',
);
sub insert_Macro {
    local(%arg) = @_;
    local(@text);
    local($name, $args);

    # Return result
    ($name, $args) = split(/\s+/, $arg{'macro'}, 2);
    return &ExecMacro($name, $args, $arg{'missing'});
}

# output - change the output file
@_output_MacroArgs = (
    'Name       Type        Default     Rule',
    'outfile    string',
);
sub output_Macro {
    local(%arg) = @_;
    local(@text);

    # Return result
    return ("__output[]" . $arg{'outfile'});
}

# message - output a message during execution
@_message_MacroArgs = (
    'Name       Type        Default     Rule',
    'text       string',
    'type       string      Object      <Object|Warning|Error|warning|error>',
);
sub message_Macro {
    local(%arg) = @_;
    local(@text);
    local($type);

    # Output the message
    $type = "\L$arg{'type'}";
    &'AppMsg($type, $arg{'text'});

    # Return result
    return ();
}

# line - change message parameters
@_line_MacroArgs = (
    'Name       Type        Default     Rule',
    'lineno     integer',
    'filename   string      _NULL_',
    'context    string      line',
);
sub line_Macro {
    local(%arg) = @_;
    local(@text);

    # Update the message variables
    $'app_lineno = $arg{'lineno'};
    $'app_context = $arg{'context'};
    $'app_context .= " " unless $'app_context =~ / $/;
    if ($arg{'filename'} ne '') {
        $'ARGV = $arg{'filename'};
        $var{'FILE_PATH'} = &'NameAbsolute($'ARGV);
        @var{'FILE_DIR', 'FILE_BASE', 'FILE_EXT', 'FILE_SHORT'} =
          &'NameSplit($var{'FILE_PATH'});

        # Update the file and document modified times. Note that
        # we use a constant (1e9 = 09-Sep-2001) during regression
        # testing to minimise file differences.
        $var{'FILE_MODIFIED'} = $var{'SDF_TEST'} ? 1e9 : (stat($'ARGV))[9];
        $var{'DOC_MODIFIED'} = $var{'FILE_MODIFIED'} if
          $var{'DOC_MODIFIED'} < $var{'FILE_MODIFIED'};

        # For the first file, set the document wide values
        if (!defined $var{'DOC_BASE'}) {
            $var{'DOC_PATH'}  = $var{'FILE_PATH'};
            $var{'DOC_DIR'}   = $var{'FILE_DIR'};
            $var{'DOC_BASE'}  = $var{'FILE_BASE'};
            $var{'DOC_EXT'}   = $var{'FILE_EXT'};
            $var{'DOC_SHORT'} = $var{'FILE_SHORT'};
        }
    }

    # Return result
    return ();
}

# macro_interface - build the interface section for an SDF macro
@_macro_interface_MacroArgs = (
    'Name       Type        Default     Rule',
    'name       string',
    'sep_reqd   string      _NULL_',
);
sub macro_interface_Macro {
    local(%arg) = @_;
    local(@text);
    local($name, @arg_list);
    local($format, @rules);
    local(@flds, $rec, %values);
    local($sep_reqd, $sep, $arg, $type);

    # Build usage
    $name = $arg{'name'};
    @text = ("The general syntax is:",
             "E:  !{{2:$name}}");

    # Add the arguments, if any
    @arg_list = eval "\@_${name}_MacroArgs";
    if (@arg_list) {
        push(@text,
             "",
             "The arguments are:",
             "",
             "!block table; format='16,16,20,48'",
             @arg_list,
             "!endblock"
        );

        # Update the usage
        ($format, @rules) = &'TableParse(@arg_list);
        @flds = &'TableFields($format);
        $sep = '';
        $sep_reqd = $arg{'sep_reqd'};
        for $rec (@rules) {
            %values = &'TableRecSplit(*flds, $rec);
            $arg = $values{'Name'};
            if ($sep_reqd eq $arg) {
                $arg = "$sep [$arg]";
            }
            else {
                $arg = "$sep $arg" if $sep;
                $arg = "[$arg]" if $values{'Default'} ne '';
            }
            $text[1] .= " $arg";

            # Get the separator for the NEXT argument
            $type = $values{'Type'};
            $sep = ($type =~ /^symbol$|^rest$/) ? '' : ';';
        }
    }

    # Add the help text, if any
    unshift(@text, "!insert 'MACRO_INTERFACE_BEGIN'");
    push(@text,    "!insert 'MACRO_INTERFACE_END'");

    # Return result
    return @text;
}

# filter_interface - build the interface section for an SDF filter
@_filter_interface_MacroArgs = (
    'Name       Type        Default     Rule',
    'name       string',
);
sub filter_interface_Macro {
    local(%arg) = @_;
    local(@text);
    local($name, @params, @fields);

    # Build usage
    $name = $arg{'name'};
    @text = (
            "The general syntax is:",
            "E:  !block {{2:$name}}",
            "E:  ...",
            "E:  !endblock");

    # Add the parameters, if any
    @params = eval "\@_${name}_FilterParams";
    if (@params) {
        $text[1] .= "[; parameters]";
        if ($params[0] ne 'ANY') {
            push(@text,
                "",
                "The parameters are:",
                "",
                "!block table",
                @params,
                "!endblock"
            );
        }
    }

    # Add the fields, if any
    @fields = eval "\@_${name}_FilterModel";
    if (@fields) {
        $text[2] =~ s/\.\.\./{{table}}/;
        push(@text,
             "",
             "The table fields are:",
             "",
             "!block table",
             @fields,
             "!endblock"
        );
    }

    # Add the help text, if any
    unshift(@text, "!insert 'FILTER_INTERFACE_BEGIN'");
    push(@text,    "!insert 'FILTER_INTERFACE_END'");

    # Return result
    return @text;
}

# class - build the interface section for an SDF class
@_class_interface_MacroArgs = (
    'Name       Type        Default     Rule',
    'name       string',
);
sub class_interface_Macro {
    local(%arg) = @_;
    local(@text);
    local($name, @fields);

    # Build usage
    $name = $arg{'name'};
    @text = (
            "The general syntax is:",
            "E:  !block {{2:$name}}[; parameters]",
            "E:  table of objects",
            "E:  !endblock");

    # Add the fields, if any
    @fields = eval "\@_${name}_FilterModel";
    if (@fields) {
        push(@text,
             "",
             "The object attributes are:",
             "",
             "!block table",
             &'TableFormat(*fields),
             "!endblock"
        );
    }

    # Add the help text, if any
    unshift(@text, "!insert 'CLASS_INTERFACE_BEGIN'");
    push(@text,    "!insert 'CLASS_INTERFACE_END'");

    # Return result
    return @text;
}

##### Internal Macros #####

# _bof_ - beginning of file processing
@__bof__MacroArgs = (
    'Name       Type        Default     Rule',
    'filename   string      _NULL_',
);
sub _bof__Macro {
    local(%arg) = @_;
    local(@text);
    local($new_file);

    # Push the state stack
    push(@_file_info, join("\000", $'ARGV, $'app_lineno, $'app_context,
      scalar(@'sdf_if_now), scalar(@'sdf_tbl_state)));

    # Update the message state
    $new_file = $arg{'filename'};
    if ($new_file ne '') {
        @text = ("!line 0; '$new_file'");
    }
    
    # Return result
    return (@text);
}

# _eof_ - end of file processing
@__eof__MacroArgs = ();
sub _eof__Macro {
    local(%arg) = @_;
    local(@text);
    local($old_file, $old_line, $if_level, $tbl_level);
    local($start);
    local($missing, $last_index);

    # Pop the state stack
    ($old_file, $old_line, $old_context, $if_level, $tbl_level) =
      split(/\000/, pop(@_file_info));

    # Adjust the line number & set the context for messages
    $'app_lineno--;
    $'app_context = "EOF at ";

    # Check not in a block or macro
    if ($'sdf_block_type ne '') {
        $start = $'sdf_block_start;
        &'AppMsg("error", "!end$'sdf_block_type missing for !$'sdf_block_type on line $start");

        # restore the state to something safe
        $'sdf_block_type = '';
    }

    # Check if nesting level is ok
    $missing = scalar(@'sdf_if_now) - $if_level;
    if ($missing != 0) {
        $start = $'sdf_if_start[$#main'sdf_if_start];
        &'AppMsg("error", "!endif missing for !if on line $start");

        # pop unexpected ones so that things resync
        $last_index = $if_level - 1;
        $#main'sdf_if_start = $last_index;
        $#main'sdf_if_now = $last_index;
        $#main'sdf_if_yet = $last_index;
        $#main'sdf_if_else = $last_index;
    }

    # Check table nesting level is ok
    $missing = scalar(@'sdf_tbl_state) - $tbl_level;
    if ($missing != 0) {
        $start = $'sdf_tbl_start[$#main'sdf_tbl_start];
        &'AppMsg("error", "!endtable missing for !table on line $start");

        # pop unexpected ones so that things resync
        $last_index = $tbl_level - 1;
        $#main'sdf_tbl_start = $last_index;
        $#main'sdf_tbl_state = $last_index;
    }

    # Restore the message state
    @text = ("!line $old_line; '$old_file'; '$old_context'");
    
    # Return result
    return (@text);
}

# _bos_ - begin a section
# The performance of this routine is critical so it handles its own arguments
sub _bos__Macro {
    local($args) = @_;

    # Update the line number and context
    ($'app_lineno, $'app_context) = split(/\;/, $args, 2);

    # Update the section counter
    $'sdf_sections++;
}

# _eos_ - end of section
# The performance of this routine is critical so it handles its own arguments
sub _eos__Macro {
    local($args) = @_;

    # Update the line number and context
    ($'app_lineno, $'app_context) = split(/\;/, $args, 2);

    # Update the section counter
    $'sdf_sections--;
}

# _bor_ - beginning of report processing
@__bor__MacroArgs = (
    'Name       Type        Default     Rule',
    'name       symbol',
    'params     rest        _NULL_',
);
sub _bor__Macro {
    local(%arg) = @_;
#   local();
    local($name);
    local($rpt_file);
    local($begin_fn);

    # Update the state
    $name = $arg{'name'};
    push(@'sdf_report_names, $name);

    # Load the report
    $rpt_file = &FindModule(&'NameJoin('', $name, 'sdr'));
    if ($rpt_file) {
        unless (require $rpt_file) {
            &'AppMsg("error", "unable to load report '$rpt_file'");
            return ();
        }
    }
    else {
        &'AppMsg("error", "unable to find report '$name'");
        return ();
    }

    # Begin the report
    $begin_fn = $name . "_ReportBegin";
    if (defined &$begin_fn) {
        &$begin_fn(&SdfFilterParams($name, $params));
    }

    # Return result
    return ();
}

# _eor_ - end of report processing
@__eor__MacroArgs = ();
sub _eor__Macro {
    local(%arg) = @_;
    local(@text);
    local($name);
    local($end_fn);

    # Update the state
    $name = pop(@'sdf_report_names);

    # End the report
    $end_fn = $name . "_ReportEnd";
    if (defined &$end_fn) {
        @text = &$end_fn();
    }
    else {
        &'AppMsg("warning", "unable to find report end routine '$end_fn'");
    }

    # Return result
    return @text;
}

# _store_ - store an object
@__store__MacroArgs = (
    'Name       Type        Default     Rule',
    'object     rest',
);
sub _store__Macro {
    local(%arg) = @_;
#   local();
    local($args);
    local($class, $cited, $name_fld, $name, $long_fld, $long, %values);
    local($cite);
    local($prop, @properties);

    # Get the arguments. Note that Perl 5.004 explicitly warns about
    # an odd number of elements in a hash list, so we need to explicitly
    # check for this and work around it. :-(
    $args = $arg{'object'};
    ($class, $cited, $name_fld, $name, $long_fld, $long, %values) =
      $args =~ /\000$/ ?
      (split(/\000/, $args), '') :
      split(/\000/, $args);

    # Add the name to the catalog for the class, if not already done
    $_class{$class,'catalog'} .= "$name\n" unless $obj_name{$class,$name};

    # Mark the object as cited, if requested
    if ($cited && ! $obj_name{$class, $name, 'Cite'}) {
        $_class{$class,'cited'} .= "$name\n";
        $cite = ++$_class{$class,'cite_count'};
        $values{'Cite'} = "[$cite]";
    }
    
    # Store the name(s)
    $obj_name{$class,$name}           = 1;
    $obj_name{$class,$name,$long_fld} = $long;
    $obj_long{$class,$long}           = 1;
    $obj_long{$class,$long,$name_fld} = $name;

    # Store the properties, if any
    @properties = split(/,/, $_class{$class,'properties'});
    push(@properties, 'Cite') if $cited;
    for $prop (@properties) {
        if ($values{$prop} ne '') {
            $obj_name{$class,$name,$prop} = $values{$prop};
#printf STDERR "%s=%s<\n", "$class.$name.$prop", $values{$prop};
            $obj_long{$class,$long,$prop} = $values{$prop};
        }
    }
}

# _load_look_ - load the look library
@__load_look__MacroArgs = ();
sub _load_look__Macro {
    local(%arg) = @_;
    local(@text);
    local($look);
    local($style);

    # Get the look and style
    $look = $var{'OPT_LOOK'};
    $style = $var{'OPT_STYLE'};

    # Support old style names to improve backwards compatibility
    if ($look eq 'plain') {
        $look = 'simple';
        $var{'OPT_LOOK'} = $look;
    }
    if ($style eq 'newsletter') {
        $style = 'newslttr';
        $var{'OPT_STYLE'} = $style;
    }

    # Init the page size,
    # load the look library,
    # load the style module, and
    # calculate the layout variables.
    @text = (
        "!_init_page_size_",
        "!inherit 'look/$look'",
        "!use '$style.sds'",
        "!_calc_layout_vars_");

    # Return result
    return @text;
}

# _init_page_size - initialise the page width and height
@_init_page_size__MacroArgs = ();
sub _init_page_size__Macro {
#   local(%arg) = @_;
#   local(@text);
    local($page_size, $page_width, $page_height);

    $page_size = $'sdf_pagesize{$var{'OPT_PAGE_SIZE'}};
    if ($page_size ne '') {
        ($page_width, $page_height) = split(/\000/, $page_size, 2);
    }
    else {
        # Custom size
        ($page_width, $page_height) = split(/x/, $var{'OPT_PAGE_SIZE'}, 2);
    }
    $page_width = &'SdfPoints($page_width);
    $page_height = &'SdfPoints($page_height);
    $var{'DOC_PAGE_WIDTH'} = $page_width;
    $var{'DOC_PAGE_HEIGHT'} = $page_height;

    # Return result
    return ();
}

# _calc_layout_vars_ - calculate the layout information variables
@__calc_layout_vars__MacroArgs = ();
sub _calc_layout_vars__Macro {
#   local(%arg) = @_;
#   local(@text);
    local($h_top, $h_height, $f_height, $f_top, $m_top, $m_height);
    local($full_width, $text_width, $columns, $col_width);

    # Calculate the height information
    $h_top    = &'SdfVarPoints("OPT_MARGIN_TOP");
    $h_height = &'SdfPageInfo("RIGHT", "HEADER_HEIGHT", "pt");
    $f_height = &'SdfPageInfo("RIGHT", "FOOTER_HEIGHT", "pt");
    $f_top    = $var{'DOC_PAGE_HEIGHT'} - $f_height -
                &'SdfVarPoints("OPT_MARGIN_BOTTOM");
    $m_top    = $h_top + $h_height +
                &'SdfPageInfo("RIGHT", "HEADER_GAP", "pt");
    $m_height = $f_top - $m_top -
                &'SdfPageInfo("RIGHT", "FOOTER_GAP", "pt");

    # Initialise the number of columns
    $var{'OPT_COLUMNS'} = 1 if $var{'OPT_COLUMNS'} < 1;
    $columns = $var{'OPT_COLUMNS'};

    # Calculate the width information
    $full_width = $var{'DOC_PAGE_WIDTH'} - &'SdfVarPoints("OPT_MARGIN_OUTER") -
                  &'SdfVarPoints("OPT_MARGIN_INNER");
    $text_width = $full_width - &'SdfVarPoints("OPT_SIDEHEAD_WIDTH") -
                  &'SdfVarPoints("OPT_SIDEHEAD_GAP");
    $col_width  = ($text_width - ($columns - 1) * $var{"OPT_COLUMN_GAP"}) /
                  $columns;

    # Set the variables
    $var{'DOC_TEXT_HEIGHT'} = $m_height;
    $var{'DOC_FULL_WIDTH'} = $full_width;
    $var{'DOC_TEXT_WIDTH'} = $text_width;
    $var{'DOC_COLUMN_WIDTH'} = $col_width;

    # Return result
    return ();
}

# _load_tuning - load the tuning for a document
@_load_tuning__MacroArgs = ();
sub _load_tuning__Macro {
    local(%arg) = @_;
    local(@text);
    local($name);
    local($target_module);

    # Tell the output driver when we start
    $name = $var{'OPT_TUNING'};
    @text = (&'SdfJoin("__tuning", $name));

    # Add the driver-specific stuff, if any
    $target_module = &FindModule(&'NameJoin('', $var{'OPT_DRIVER'}, 'sdn'));
    if ($target_module) {
        push(@text, "!include '$target_module'");
    }

    # Tell the output driver when we reach the end
    push(@text, "__endtuning[]");

    # Return the result
    return @text;
}

# _load_config_ - load the configuration library
@_load_config__MacroArgs = ();
sub _load_config__Macro {
#   local(%arg) = @_;
#   local(@text);
    local($config);

    $config = $var{'OPT_CONFIG'};
    return ($config ne '') ? ("!inherit '$config'") : ();
}

# package return value
1;
