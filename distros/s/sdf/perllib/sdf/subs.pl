# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     SDF Subroutines Library
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
# This library provides the built-in subroutines for
# [[SDF]] files.
#
# >>Description::
#
# >>Limitations::
#
# >>Resources::
#
# >>Implementation::
#


# Make sure we can call the Value function from the main package
sub Value {&SDF_USER'Value;}

# Switch to the user package
package SDF_USER;

##### Constants #####

##### Variables #####

# Tables of macro arguments & filter parameters
%_sdf_macro_args_info = ();
@_sdf_macro_args_data = ();
%_sdf_filter_params_info = ();
@_sdf_filter_params_data = ();

# Cache of views
%_sdf_view_cache = ();

##### Initialisation #####

#
# >>Description::
# {{Y:InitSubs}} initialises the global variables in this module.
#
sub InitSubs {

    %_sdf_macro_args_info = ();
    @_sdf_macro_args_data = ();
    %_sdf_filter_params_info = ();
    @_sdf_filter_params_data = ();
    %_sdf_view_cache = ();
}

##### Routines #####

#
# >>Description::
# {{Y:Var}} returns the value of a variable.
#
sub Var {
    local($name) = @_;
    local($value);

    # Activate event processing
    $value = $var{$name};

    # Return result
    return $value;
}

#
# >>Description::
# {{Y:Escape}} escape special symbols within paragraph text.
# Note that it isn't necessary to escape leading characters or patterns.
#
sub Escape {
    local($text) = @_;
#   local();

    $text =~ s/[<>]/$& eq '>' ? 'E<gt>' : 'E<lt>'/eg;
    if ($text =~ s/\[\[/E<2[>/g) {
        $text =~ s/\]\]/E<2]>/g;
    }
    if ($text =~ s/\{\{/E<2{>/g) {
        $text =~ s/\}\}/E<2}>/g;
    }
    return $text;
}

#
# >>Description::
# {{Y:FormatVar}} formats a variable.
#
sub FormatVar {
    local($fmt, $data) = @_;
    local($result);

    $fmt = $var{$fmt} if &Var($fmt) ne '';
    return sprintf($fmt, &Var($data));
}

#
# >>Description::
# {{Y:FormatTime}} formats a datetime variable.
#
sub FormatTime {
    local($fmt, $time) = @_;
    local($result);

    $fmt = $var{$fmt} if $var{$fmt} ne '';
    $time = $var{$time} if $var{$time} ne '';
    return $time ? &'MiscDateFormat($fmt, $time) : '';
}

#
# >>Description::
# {{Y:PrependText}} is used within a paragraph event handler to
# add [[SDF]] before this paragraph.
#
sub PrependText {
    local(@sdf) = @_;
#   local();

    unshift(@_prepend, @sdf);
}

#
# >>Description::
# {{Y:AppendText}} is used within a paragraph event handler to
# add [[SDF]] after a paragraph.
#
sub AppendText {
    local(@sdf) = @_;
#   local();

    push(@_append, @sdf);
}

#
# >>Description::
# {{Y:DefineAttrs}} is used within a paragraph or phrase event handler to
# define attributes.
#
sub DefineAttrs {
    local(%new) = @_;
#   local();
    local($new);

    for $new (keys %new) {
        $attr{$new} = $new{$new};
    }
}

#
# >>Description::
# {{Y:DefaultAttrs}} is used within a paragraph or object event handler to
# define attributes not already set.
#
sub DefaultAttrs {
    local(%new) = @_;
#   local();
    local($new);

    for $new (keys %new) {
        $attr{$new} = $new{$new} unless defined($attr{$new});
    }
}

#
# >>Description::
# {{Y:FindFile}} searches the include path for the nominated file.
# If the file is found, the pathname of the file is returned,
# otherwise the empty string is returned. If {{image}} is true,
# a target-specific set of extensions is searched for,
# complete with implicit image format conversion.
#
sub FindFile {
    local($filename, $image) = @_;
    local($fullname);

    # Get the list of directories to search
    use Cwd;
    my @dirs = ('.');
    my $dir = $var{'DOC_DIR'};
    push(@dirs, $dir) if $dir ne cwd();
    push(@dirs, @include_path, $'sdf_lib);

    # Do the search
    if ($image) {
        my $context = $var{'OPT_TARGET'};
        my @exts = @{$'SDF_IMAGE_EXTS{$context} || $'SDF_IMAGE_EXTS{'ps'}};
        &'AppTrace("user", 5, "searching for image '$filename' in directories (" .
          join(",", @dirs) . ") with $context extensions (" .
          join(",", @exts) . ")");
        $fullname = &'NameFindOrGenerate($filename, \@dirs, \@exts, $context);
    }
    else {
        &'AppTrace("user", 5, "searching for file '$filename' in directories (" .
          join(",", @dirs) . ")");
        $fullname = &'NameFind($filename, @dirs);
    }

    # Return results
    &'AppTrace("user", 2, "file '$filename' -> '$fullname'") if
      $fullname ne '';
    return $fullname;
}

#
# >>Description::
# {{Y:FindModule}} searches the module path for the nominated file.
# If the file is found, the pathname of the file is returned,
# otherwise the empty string is returned.
#
sub FindModule {
    local($filename) = @_;
    local($fullname);

    # Get the list of directories to search
    use Cwd;
    my @dirs = ('.');
    my $dir = $var{'DOC_DIR'};
    push(@dirs, $dir) if $dir ne cwd();
    push(@dirs, @module_path, $'sdf_lib, "$'sdf_lib/stdlib");

    # Do the search
    &'AppTrace("user", 4, "searching for module '$filename' in directories (" .
      join(",", @dirs) . ")");
    $fullname = &'NameFind($filename, @dirs);

    # Return results
    &'AppTrace("user", 2, "module '$filename' -> '$fullname'") if
      $fullname ne '';
    return $fullname;
}

#
# >>Description::
# {{Y:FindLibrary}} searches the library path for a library and
# returns the directory name of the library. If the library is not
# found, an empty string is returned.
#
sub FindLibrary {
    local($lib) = @_;
    local($fullname);
    local($lib_path);

    # Get the list of directories to search
    use Cwd;
    my @dirs = ('.');
    my $dir = $var{'DOC_DIR'};
    push(@dirs, $dir) if $dir ne cwd();
    push(@dirs, @library_path, $'sdf_lib);

    # Do the search
    &'AppTrace("user", 3, "searching for library '$lib' in directories (" .
      join(",", @dirs) . ")");
    $fullname = '';
    for $dir (@dirs) {
        $lib_path = $dir eq $'NAME_DIR_SEP ? "$dir$lib" : "$dir$'NAME_DIR_SEP$lib";
        if (-d $lib_path) {
            $fullname = $lib_path;
            last;
        }
    }

    # Return results
    &'AppTrace("user", 2, "library '$lib' -> '$fullname'") if
      $fullname ne '';
    return $fullname;
}

#
# >>Description::
# {{Y:ExecMacro}} executes a macro.
# This routine validates the arguments and either:
#
# * gets the macro data (for macros implemented in [[SDF]]), or
# * calls the matching subroutine (for macros implemented in [[Perl]]).
#
# {{missing}} determines the action if the macro isn't found:
#
# * {{ok}} - do nothing
# * {{warning}} - report a warning
# * {{error}} - report an error.
#
sub ExecMacro {
    local($name, $args, $missing) = @_;
    local(@text);
    local($macro_fn);

    # Set the context for messages
    $'app_context = 'macro on ' unless $'sdf_sections;

    # Activate event processing
    &ReportEvents('macro') if @'sdf_report_names;
    &ExecEventsNameMask(*evcode_macro, *evmask_macro) if @evcode_macro;
    &ReportEvents('macro', 'Post') if @'sdf_report_names;

    # Macros implemented in Perl have a subroutine which can be called
    $macro_fn = $name . "_Macro";
    if (defined &$macro_fn) {

        # Validate the arguments and call the matching subroutine
        @text = &$macro_fn(&SdfMacroArgs($name, $args));

        # For macros which generate output which doesn't come from a file,
        # we need to make the output a section so that line numbers don't
        # increment within the generated output.
        return ()    unless @text;
        return @text if $name =~ /^_/ || $text[0] =~ /^\!_bof/;
        return ("!_bos_ $'app_lineno;macro on ", @text,
                "!_eos_ $'app_lineno;$'app_context");
    }

    # For macros implemented in SDF, the macro is stored in %macro
    elsif (defined($macro{$name})) {

        # Validate the arguments
        &'AppMsg("warning", "ignoring arguments for macro '$name'") if $args ne '';

        # Return the data
        return ("!_bos_ $'app_lineno;macro on ", split("\n", $macro{$name}),
                "!_eos_ $'app_lineno;$'app_context");
    }

    # If we reach here, macro is unknown
    if ($missing eq 'error') {
        &'AppMsg("error", "unknown macro '$name'");
    }
    elsif ($missing eq 'warning') {
        &'AppMsg("warning", "unknown macro '$name'");
    }
    return ();
}

#
# >>Description::
# {{Y:ExecFilter}} applies a filter to a block of text.
# This routine validates the parameters and calls the matching subroutine.
# {{lineno}}, {{filename}} and {{context}} are used for messages,
# if provided.
sub ExecFilter {
    local($name, *text, $params, $lineno, $filename, $context) = @_;
#   local();
    local($orig_lineno, $orig_filename, $orig_context);
    local($filter_fn);
    local($plug_in);

    # Do nothing unless there's a filter
    return if $name eq '';

    # Setup the message parameters, if necessary
    $orig_lineno   = $'app_lineno;
    $orig_filename = $'ARGV;
    $orig_context  = $'app_context;
    $'app_lineno   = $lineno    if defined $lineno;
    $'ARGV         = $filename  if defined $filename;
    $'app_context  = $context   if defined $context;

    # Activate event processing
    &ReportEvents('filter') if @'sdf_report_names;
    &ExecEventsNameMask(*evcode_filter, *evmask_filter) if @evcode_filter;
    &ReportEvents('filter', 'Post') if @'sdf_report_names;

    # If necessary, load the plug-in, if any
    $filter_fn = $name . "_Filter";
    if (defined &$filter_fn ||
        $lang_aliases{$name}) {
        # do nothing
    }
    else {
        $plug_in = &FindModule(&'NameJoin('', $name, 'sdp'));
        if ($plug_in) {
            unless (require $plug_in) {
                &'AppMsg("warning", "unable to load plug-in '$plug_in'");
            }
        }
    }

    # Call the filter. If a function is not defined for the filter,
    # it may be a programming language.
    if (defined &$filter_fn) {
        &$filter_fn(*text, &SdfFilterParams($name, $params));
    }
    elsif ($lang_aliases{"\L$name"}) {
        $params .= "; lang='$name'";
        &example_Filter(*text, &SdfFilterParams('example', $params));
    }
    else {
        &'AppMsg("error", "unknown filter '$name'");
    }

    # Restore the message parameters
    $'app_lineno  = $orig_lineno;
    $'ARGV        = $orig_filename;
    $'app_context = $orig_context;
}

#
# >>Description::
# {{Y:SdfMacroArgs}} parses and checks the arguments for a macro.
#
sub SdfMacroArgs {
    local($macro, $args) = @_;
    local(%arg);
    local($info, $index, $last);
    local($format, @rules);
    local($junk, $name, $type, $default, $rule);
    local($ok, $value);

    # Get the arguments info
    $info = $_sdf_macro_args_info{$macro};
    if ($info ne '') {
        ($index, $last) = split(/:/, $info, 2);
    }
    else {
        # Compile the arguments
        $index = $#_sdf_macro_args_data + 1;
        ($format, @rules) = &'TableParse(eval "\@_${macro}_MacroArgs");
        push(@_sdf_macro_args_data, @rules);
        $last = $#_sdf_macro_args_data;
        $_sdf_macro_args_info{$macro} = join(':', $index, $last);
    }

    # Process the argument table
    for (; $index <= $last; $index++) {
        ($junk, $name, $type, $default, $rule) =
             split(/\000/, $_sdf_macro_args_data[$index], 5);

        # If there is nothing left, use the default, if any
        if ($args eq '') {
            &'AppMsg("error", "argument '$name' missing for macro '$macro'")
              if $default eq '';
            $value = $default eq '_NULL_' ? '' : $default;
        }

        # Otherwise, get the next argument
        else {
            ($value, $args) = &_SdfMacroNextArg($args, $type);

            # Validate the rule, if any
            &'AppMsg("warning", "bad value '$value' for argument '$name' for macro '$macro'")
              if ($value ne '' && !&'MiscCheckRule($value, $rule, $type));
        }

        # Save the value
#print "$macro arg $name=$value<\n";
        $arg{$name} = $value;
    }

    # Return result
    %arg;
}

#
# >>_Description::
# {{Y:_SdfMacroNextArg}} parses the next argument from args.
#
sub _SdfMacroNextArg {
    local($args, $type) = @_;
    local($arg, $rest);

    # Get the next argument. For performance, we only check the
    # first character or two of the type:
    # * sy => symbol
    # * r => rest
    # * f => filter
    # * e => eventid
    $args =~ s/^\s+//;
    return split(/\s+/, $args, 2)   if $type =~ /^sy/;
    return ($args, '')              if $type =~ /^r/;
    return split(/\s*\;/, $args, 2) if $type =~ /^[ef]/;

    # If we reach here, we need to evaluate the argument
    ($arg, $rest) = split(/\s*\;/, $args, 2);
    $arg = &'_SdfEvaluate($arg, $type eq 'condition' ? '' : 'warning');
    return ($arg, $rest);
}

#
# >>Description::
# {{Y:SdfFilterParams}} checks the parameters for a filter.
# {{@rules}} is the table of rules.
#
sub SdfFilterParams {
    local($filter, $params) = @_;
    local(%param);
    local(@param_table);
    local($info, $index, $last);
    local($format, @rules);
    local($junk, $name, $type, $rule);
    local($value);
    local($unknown, %unknown);

    # Get the parameters
    %param = &'SdfAttrSplit($params);

    # Get the parameter table
    @param_table = eval "\@_${filter}_FilterParams";

    # Skip validation if arbitary parameters are permitted
    return %param if $param_table[0] eq 'ANY';

    # Get the parameters info
    $info = $_sdf_filter_params_info{$filter};
    if ($info ne '') {
        ($index, $last) = split(/:/, $info, 2);
    }
    else {
        # Compile the parameters
        $index = $#_sdf_filter_params_data + 1;
        ($format, @rules) = &'TableParse(@param_table);
        push(@_sdf_filter_params_data, @rules);
        $last = $#_sdf_filter_params_data;
        $_sdf_filter_params_info{$filter} = join(':', $index, $last);
    }

    # Validate each parameter, using the order in the rules table
    %unknown = %param;
    for (; $index <= $last; $index++) {
        ($junk, $name, $type, $rule) =
             split(/\000/, $_sdf_filter_params_data[$index], 4);
        $value = $param{$name};
#print "$filter param $name=$value<\n";
        delete $unknown{$name};

        # Validate the rule, if any
        if ($value ne '' && !&'MiscCheckRule($value, $rule, $type)) {
            &'AppMsg("warning", "bad value '$value' for '$name' for filter '$filter'");
        }
    }

    # Check for unknown parameters
    $unknown = join(',', sort keys %unknown);
    if ($unknown ne '') {
        &'AppMsg("warning", "unknown parameter(s) '$unknown' for filter '$filter'");
    }

    # Return result
    return %param;
}

#
# >>Description::
# {{Y:SdfTableParams}} checks the parameters for a table/record/cell macro.
# {{%names}}, {{%types}} and {{%rules}} are the tables of names, types and
# rules respectively.
#
sub SdfTableParams {
    local($macro, $params, *names, *types, *rules) = @_;
    local(%param);
    local($name, $value, $type, $rule);

    # Get the parameters
    %param = &'SdfAttrSplit($params);

    # Remove parameters which only apply to other targets
    &'SdfAttrClean(*param);

    # Check the parameters are legal
    for $name (sort keys %param) {
        $value = $param{$name};
        $type = $types{$name};
        $rule = $rules{$name};
#print "table param $name=$value<\n";

        # Check the parameter is known
        unless ($names{$name}) {
            &'AppMsg("warning", "unknown $macro parameter '$name'");
            delete $param{$name};
            next;
        }

        # Validate the rule, if any
        if ($value ne '' && !&'MiscCheckRule($value, $rule, $type)) {
            &'AppMsg("warning", "bad value '$value' for $macro parameter '$name'");
        }
    }

    # Return result
    return %param;
}

#
# >>Description::
# {{Y:ReportEvents}} calls the report event processing routines, if any.
#
sub ReportEvents {
    local($tag, $post) = @_;
#   local();
    local($rpt);
    local($fn);

    for $rpt (@'sdf_report_names) {
        $fn = "${rpt}_ReportEvent${post}";
        &$fn($tag) if defined &$fn;
    }
}

#
# >>Description::
# {{Y:ExecEventsStyleMask}} executes events of a particular type.
# {{@code}} is the stack of code; {{@mask}} is the stack of masks.
# Masking is done using {{$style}}.
#
sub ExecEventsStyleMask {
    local(*code, *mask) = @_;
#   local();
    local($event, $action, $mask);
    local($old_match_rule);

    # Ensure multi-line matching is enabled
    $old_match_rule = $*;
    $* = 1;

    for ($event = $#code; $event >= 0; $event--) {

        # get the action to execute, if any
        $action = $code[$event];
        next if $action eq '';

        # Mask out events
        $mask = $mask[$event];
        next if $mask ne '' && $style !~ /^$mask$/;
        return if $attr{'noevents'};

        # execute the action
        eval $action;
        &'AppMsg("warning", "execution of '$action' failed: $@") if $@;
    }

    # Restore the multi-line match flag setting
    $* = $old_match_rule;
}

#
# >>Description::
# {{Y:ExecEventsNameMask}} executes events of a particular type.
# {{@code}} is the stack of code; {{@mask}} is the stack of masks.
# Masking is done using {{$name}}.
#
sub ExecEventsNameMask {
    local(*code, *mask) = @_;
#   local();
    local($event, $action, $mask);
    local($old_match_rule);

    # Ensure multi-line matching is enabled
    $old_match_rule = $*;
    $* = 1;

    for ($event = $#code; $event >= 0; $event--) {

        # get the action to execute, if any
        $action = $code[$event];
        next if $action eq '';

        # Mask out events
        $mask = $mask[$event];
        next if $mask ne '' && $name !~ /^$mask$/;

        # execute the action
        eval $action;
        &'AppMsg("warning", "execution of '$action' failed: $@") if $@;
    }

    # Restore the multi-line match flag setting
    $* = $old_match_rule;
}
#
# >>Description::
# {{Y:FileFetch}} handles fetching of files for text inclusion macros.
# Files created under MS-DOS can be included on Unix without
# problems. i.e. trailing Ctrl-M characters are stripped.
#
sub FileFetch {
    local(*file, $fname) = @_;
    local($ok);
    local($_);

    # Fetch the file
    $ok = open(SDF_INCLUDE, $fname);
    if ($ok) {
        @file = <SDF_INCLUDE>;
        for $_ (@file) {
            s/[ \t\n\r]+$//;
        }
        close(SDF_INCLUDE);
    }

    # Return result
    return $ok;
}

#
# >>Description::
# {{Y:CommandMacro}} is the common processing for macros which
# execute a command on a file.
#
sub CommandMacro {
    local($cmd, %arg) = @_;
    local(@text);
    local($filename, $fullname);

    # Get the file location
    $filename = $arg{'filename'};
    $fullname = &FindFile($filename);
    if ($fullname eq '') {
        &'AppMsg("warning", "unable to find '$filename'");
        return ();
    }

    # Execute the command
    unless (&FileFetch(*text, "$cmd $fullname|")) {
        &'AppMsg("warning", "unable to execute command '$cmd' on '$fullname'");
        return ();
    }

    # Filter the text
    &ExecFilter($arg{'filter'}, *text, $arg{'params'});

    # Return result
    return ("!_bof_ '$fullname'", @text, "!_eof_");
}

#
# >>Description::
# {{Y:Related}} handles the related function.
#
sub Related {
    local($topic) = @_;
    local($newsdf);
    local(@groups, @excludes);
    local(@members, %already, $grp, $item);

    # Get the groups
    @groups = split(/\000/, $_sdf_jump_groups{$topic});
    @excludes = ($topic);

    # Get the ordered list of members from the groups
    # To exclude items, we pretend we have found them already
    @members = ();
    %already = ();
    grep($already{$_}++, @excludes);
    for $grp (@groups) {
        for $item (split(/\000/, $_sdf_jump_members{$grp})) {
            if ($already{$item} eq '') {
                push(@members, $item);
                $already{$item}++;
            }
        }
    }
    
    # Create the matching SDF
    $newsdf= '';
    for $item (@members) {
        $newsdf .= "L1:{{J:$item}}\n";
    }

    # Return result
    return $newsdf;
}

#
# >>Description::
# {{Y:CheckParaObject}} is a paragraph event handler which
# makes a paragraph an object if the {{PATTR:obj}} attribute
# is set.
#
sub CheckParaObject {
    local($obj);

    # Do nothing unless this is an object
    return unless defined $attr{'obj'};

    # Convert the paragraph to an object
    $obj = $attr{'obj'};
    delete $attr{'obj'};
    $text = '{{' . &'SdfJoin($obj, $text) . '}}';
}

#
# >>Description::
# {{Y:BuildSectJump}} is a event handler which
# builds the jump attribute for a SECT phrase.
#
sub BuildSectJump {
    local($doc);
    local($id);

    # Make it a cross-reference, but don't change the existing value, if any
    #$attr{'xref'} = 1 unless $attr{'xref'};

    # Do nothing if a jump already exists
    return if defined $attr{'jump'};

    # Convert the text to something which is safe as an id
    $id = &TextToId($text);

    # Convert reference codes to document titles as they are
    # just too long to be nice to use :-)
    if ($attr{'ref'}) {
        $attr{'doc'} = $obj_name{'references',$attr{'ref'},'Document'};
        delete $attr{'ref'};
    }

    # Handle sections in another document
    $doc = $attr{'doc'};
    if ($doc ne '') {
        delete $attr{'doc'};
        unless ($obj_long{'references',$doc}) {
            &'AppMsg('warning', "unknown document '$doc'");
        }
        else {
            #if ($var{'HTML_TOPICS_MODE'} || $var{'HTML_SUBTOPICS_MODE'}) {
            #    &'AppMsg('warning', "cross-document section jumps not yet supported in topics mode");
            #}
            $attr{'jump'} = $obj_long{'references',$doc,'Jump'} . "#$id";
        }
    }

    # Handle sections in this document
    else {
        if ($var{'HTML_TOPICS_MODE'} || $var{'HTML_SUBTOPICS_MODE'}) {
            $attr{'jump'} = $jump{$text} || $jump{$id};
        }
        else {
            $attr{'jump'} = "#$id";
        }
    }
}

#
# >>Description::
# {{Y:TextToId}} converts an arbitary text string to a string
# which is safe to use as an {{id}} attribute.
#
sub TextToId {
    local($text) = @_;

    $text =~ s/([\\'])/\\$1/g;
    $text =~ s/[\?\.]$//;
    return $text;
}

#
# >>Description::
# {{Y:ConvertXRef}} is a event handler which
# convert phrases with an xref attribute to a special style.
#
sub ConvertXRef {

    return unless $attr{'xref'};
    $style = '__xref';
    $text = $attr{'xref'};
    $text = $var{'DEFAULT_XREF_STYLE'} if $text == 1;
}

#
# >>Description::
# {{Y:Value}} returns the value of an attribute for an object ($name)
# in a class. $view is an optional {{view}} name.
# Within a view, the parameters supported are:
#
# * {{prefix_xxx}} - prefix for attribute {{xxx}}
# * {{suffix_xxx}} - suffix for attribute {{xxx}}.
#
sub Value {
    local($class, $name, $attr, $view) = @_;
    local($result);
    local($fn);
    local($fn2);
    local($known);
    local($ok, %param);

    # At the moment, we check the lookup function, then the data store.
    # This allows the function to override the stored value.
    # Is it better to check the stored value first?
    # If so, then should we cache the function results in the store?
    $known = 1;
    $fn = "${class}_${attr}_Value";
    if (defined &$fn) {
        $result = &$fn($name, $view);
    }
    elsif (!defined($result = $obj_name{$class,$name,$attr})) {
        $fn2 = "${class}_Value";
        if (defined &$fn2) {
            ($known, $result) = &$fn2($attr, $name, $view);
        }
    }

    # Apply view, if any
    if ($view) {
        ($ok, %param) = &LoadView($view);
        if ($ok) {
            $result = $param{"prefix_$attr"} . $result;
            $result .= $param{"suffix_$attr"};
        }
        else {
            &'AppMsg("warning", "load of view '$view' failed: $@");
        }
    }

    # Check the attribute is known and return
    unless ($known) {
        &'AppMsg("warning", "undefined attribute '$attr' for object '$name' in class '$class'");
        return '';
    }
#print STDERR "attr: $attr, view: $view, result: $result.\n" if $view;
    return $result;
}

#
# >>Description::
# {{Y:LoadView}} loads view {{name}}.
# The loading rules are:
#
# ^ If a view has already been loaded, it is returned.
# + If the name of a view is a file, then the view
#   is loaded from that file. The format is a same
#   as a set of name-value pairs in an {{FMT:INI}} file.
# + If the name of a view is a directory, then a view
#   with {{prefix_Jump=name/}} is returned.
# + Otherwise, {{ok}} is set to 0 and an empty view is returned.
# 
sub LoadView {
    local($name) = @_;
    local($ok, %params);

    # Check if the view has already been loaded
    if (defined $_sdf_view_cache{$name}) {
        return (1, %{$_sdf_view_cache{$name}});
    }

    # Load set from file, if possible
    if (-f $name) {
        if (open(CONV_SET, $name)) {
            my $nv_text = join("\n", <CONV_SET>);
            close(CONV_SET);
            %params = &main'AppSectionValues($nv_text);
#print STDERR "nv_text: $nv_text<\n";
#for $igc (sort keys %params) {
#print STDERR "$igc: $params{$igc}.\n";
#}
        }
        else {
            return (0);
        }
    }

    # Build set from directory, if possible
    elsif (-d $name) {
        %params = ('prefix_Jump', "$name/");
    }

    # No luck
    else {
        return (0);
    }

    # Save the view in the cache
    $_sdf_view_cache{$name} = { %params };

    # Return result
    return (1, %params);
}

#
# >>Description::
# {{Y:Previous}} returns the previous paragraph text for a given
# paragraph style.
#
sub Previous {
    local($style) = @_;
#   local($result);

    return $previous_text_for_style{$style};
}

#
# >>Description::
# {{Y:ExpandLink}} returns the expanded text and URL for an L phrase.
#
sub ExpandLink {
    local($text) = @_;
    local($expanded, $url);
    local($page, $sect, $entry);
    local($format);

    # Get the page and section
    ($page, $sect, $entry) = &ParseLink($text);

    # Get the format to use
    if ($page ne '') {
        if ($sect ne '') {
            $format = $var{'FORMAT_LINK_PAGE_SECTION'} ||
                      'the section on "$sect" in the $page manpage';
        }
        elsif ($entry ne '') {
            $format = $var{'FORMAT_LINK_PAGE_ENTRY'} ||
                      'the $entry entry in the $page manpage';
        }
        else {
            $format = $var{'FORMAT_LINK_PAGE'} ||
                      'the $page manpage';
        }
    }
    else {
        $format = $var{'FORMAT_LINK_SECTION'} ||
                  'the section on "$sect"';
    }

    # Expand the text
    $expanded = $format;
    $expanded =~ s/\$page/$page/g;
    $expanded =~ s/\$sect/$sect/g;
    $expanded =~ s/\$entry/$entry/g;

    # Get the URL
    $page =~ s/\s*\(\d\)$//;
    $url = &BuildLinkUrl($page, $sect, $entry);

    # Return the result
    return ($expanded, $url);
}

#
# >>Description::
# {{Y:ParseLink}} parses the text of an L phrase.
#
sub ParseLink {
    local($text) = @_;
    local($page, $sect, $entry);

    if ($text =~ m:/:) {
        ($page, $entry) = split(/\//, $text, 2);
        if ($entry =~ /^"(.*)"$/) {
            $sect = $1;
            $entry = '';
        }
    }
    elsif ($text =~ /^"/ || $text =~ / /) {
        $page = '';
        $sect = $text;
        $entry = '';
    }
    else {
        $page = $text;
        $sect = '';
        $entry = '';
    }
    $sect =~ s/^"//;
    $sect =~ s/"$//;

    return ($page, $sect, $entry);
}

#
# >>Description::
# {{Y:BuildLinkUrl}} generates a url from the parts of a L phrase.
# Special construction and/or searching rules can be provided
# by overriding the default implementation, which is simplistic
# by design.
#
sub BuildLinkUrl {
    local($page, $sect, $entry) = @_;
    local($url);

    $url = $page ne '' ? "$page.html" : '';
    if ($entry ne '') {
        $url .= "#$entry";
    }
    elsif ($sect ne '') {
        $url .= "#$sect";
    }
    return $url;
}

#
# >>Description::
# {{Y:ProcessImageAttrs}} processes a set of image attributes.
# This routine provides the common logic between the import macro
# and import special style.
#
sub ProcessImageAttrs {
    local(*filename, *attr) = @_;
#   local();
    local($fullname);
    local($base);

    # Search for an image file - the 2nd option switches on searching
    # (and converting) of an extension from a target-derived list
    $fullname = &FindFile($filename, 1);

    # take out any silly ./'s that are added  --tjh
    $fullname =~ s/^\.\///;

    # Check the figure exists
    if ($fullname eq '') {
        &'AppMsg("warning", "unable to find image '$filename'");
        $fullname = $filename;
    }
    $attr{'fullname'} = $fullname;

    # Update the filename
    $filename = (&'NameSplit($fullname))[3];

    # Prepend the base location, if necessary
    $base = $attr{'base'};
    if (defined($base)) {
        $filename = $base . $filename;
        delete $attr{'base'};
    }
}

# package return value
1;
