# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     Name Processing Library
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
# This library provides support for file-name processing.
# With careful use, the routines provide portability across
# [[Unix]]-like and [[Windows]]-like file-naming systems.
#
# >>Description::
#
# >>Limitations::
#
# >>Resources::
#
# >>Implementation::
#

######### Constants #########

#
# >>Description::
# {{Y:NAME_OS}} returns the current operating system style, either
# {{unix}} or {{dos}}. {{Y:NAME_DIR_TABLE}} and {{Y:NAME_PATH_TABLE}}
# are lookup tables of directory and path separators for different
# operating system styles. {{Y:NAME_DIR_SEP}} and {{Y:NAME_PATH_SEP}}
# are the respective separators for {{NAME_OS}}.
#
$NAME_OS = $ENV{'COMSPEC'} ? 'dos' : 'unix';
$NAME_OS = 'mac' if $^O =~ /Mac/;
%NAME_DIR_TABLE  = (
    'unix', '/',
    'dos', '\\',
    'mac', ':',
);
%NAME_PATH_TABLE = (
    'unix', ':',
    'dos', ';',
    'mac', ';',
);
$NAME_DIR_SEP = $NAME_DIR_TABLE{$NAME_OS};
$NAME_PATH_SEP = $NAME_PATH_TABLE{$NAME_OS};

######### Variables #########

# Lookup tables of conversion rules built by NameLoadConversionRules()
%_name_conversion_sources = ();
%_name_conversion_actions = ();

######### Routines #########

#
# >>Description::
# {{Y:NameOS}} returns the SDF version of the OS name.
#
sub NameOS {
        return $NAME_OS;
}
#
# >>Description::
# {{Y:NameIsAbsolute}} returns 1 if the name is in absolute (or
# non-relative) format.
#
sub NameIsAbsolute {
    local($name) = @_;
    local($result);

    SWITCH: {
        $result = $name =~ m#^\/#, last SWITCH if $NAME_OS eq 'unix';
        $result = $name =~ m#^([A-Za-z]:)?[\\/]#, last SWITCH if $NAME_OS eq 'dos';
        $result = $name =~ m#^[^:]+:#, last SWITCH if $NAME_OS eq 'mac';
        die "Unknown OS: $NAME_OS";
    }
    return $result;
}
#
# >>Description::
# {{Y:NameAbsolute}} returns the absolute name for a file.
#
sub NameAbsolute {
    local($name) = @_;
    local($result);
    local($pwd);

    # If already absolute, do nothing
    return $name if &NameIsAbsolute($name);
    
    # Get & prepend the current directory
    $pwd = $NAME_OS eq 'unix' || $NAME_OS eq 'mac' ? `pwd` : `cd`;
    chop($pwd);
    return &NameJoin($pwd, $name);
}

#
# >>Description::
# {{Y:NameFind}} searches the directories for a file with the name
# given. If found, the combined name (directory + local name) is returned.
# If the name is absolute, the file is checked to exist. i.e. the directories
# are not searched.
# In either case, if the file is not found, an empty string is returned.
#
sub NameFind {
    local($name, @dirs) = @_;
    local($found_name);
    local($dir, $full);

    # handle "-": return itself
    return $name if $name eq "-";

    # handle absolute filenames
    if (&NameIsAbsolute($name)) {
        if (-r $name) {
            return $name;
        }
        else {
            return "";
        }
    }
    $DB::single = 1;
    if($NAME_OS eq 'mac') {
        $name =~ s#/#:#g ;
        $name =~ s#^:##;
    }

    # Otherwise, search for the name
    foreach $dir (@dirs) {
        if ($NAME_OS eq 'mac') {
            $dir = "" if $dir eq '.';
            $dir =~ s#/#:#g;
            $dir =~ s#:$##;
        }
        if ($dir eq $NAME_DIR_SEP) {
            $full = $dir . $name;
        }
        else {
            $full = $dir . $NAME_DIR_SEP . $name;
        }
        if (-r $full) {
            return $full;
        }
    }

    # If we reach here, we had no luck
    return "";
}

#
# >>Description::
# {{Y:NameSplit}} extracts components from a name.
# {{short}} is the name without the directory.
#
sub NameSplit {
    local($name) = @_;
    local($dir, $base, $ext, $short);

    # Ensure unix style
    $base = $name;
    $base =~ s#\\#/#g if $NAME_OS eq "dos";
    $base =~ s#\:#/#g if $NAME_OS eq "mac";

    # get directory and base.ext
    if ($base =~ m#/([^/]+)$#) {
        $dir = $`;
        $base = $1;
    }

    # get extension
    if ($base =~ m#\.([^\.]+)$#) {
        $base = $`;
        $ext = $1;
    }

    # Return result
    $dir =~ s#\/#:#g if $NAME_OS eq "mac";
    $short = &NameJoin("", $base, $ext);
    return ($dir, $base, $ext, $short);
}

#
# >>Description::
# {{Y:NamePathComponentSplit}} completely splits a path into its component parts.
# Returns a list of the parts.
#
sub NamePathComponentSplit {
    my $sep;
    my $path = shift @_;
    
    $sep = '/';
    $sep = '\\' if $NAME_OS eq 'dos';
    $sep = ':' if $NAME_OS eq 'mac';
    return split $sep, $path;
}


#
# >>Description::
# {{Y:NameJoin}} builds a name from its components. If the base name is
# already absolute, the directory is not prepended.
#
sub NameJoin {
    local($dir, $base, $ext) = @_;
    local($name);

    # handle "-": return itself
    $name = $base;
    return $name if $name eq "-";

    # prepend directory if present and name is not already absolute
    if ($dir && ! &NameIsAbsolute($name)) {
        $name = $dir . $NAME_DIR_SEP . $name;
    }

    # append extension, if any
    $name .= ".$ext" if $ext;

    return $name;
}

#
# >>Description::
# {{Y:NameSubExt}} substitutes the extension on a name.
#
sub NameSubExt {
    local($name, $new_ext) = @_;
    local($new_name);
    local($dir, $base, $ext);

    ($dir, $base, $ext) = &NameSplit($name);
    return &NameJoin($dir, $base, $new_ext);
}

#
# >>Description::
# {{Y:NameLoadConversionRules}} loads a table of conversion rules to
# be used by {{Y:NameFindOrGenerate}}. The fields in {{@table}} are:
#
# * {{Context}} - the driver for which this conversion applies
# * {{To}} - the destination figure format
# * {{From}} - the original figure format
# * {{Action}} - the command to use to do the conversion.
#
# Rules do not chain, so defining rules for A->B and B->C do not
# imply that A will be converted to C. If {{validate}} is set,
# the table is validated.
#
#
sub NameLoadConversionRules {
    local(*table, $validate) = @_;
#   local();

    # Validate the table
    &TableValidate(*table, *_SDF_CONVERSION_RULES) if $validate;

    # Load the rules
    local @flds;
    my $rec;
    my %values;
    my $context;
    my $to;
    my $from;
    my $action;
    @flds = &TableFields(shift(@table));
    for $rec (@table) {
        %values  = &TableRecSplit(*flds, $rec);
        $context = $values{'Context'};
        $to      = $values{'To'};
        $from    = $values{'From'};
        $action  = $values{'Action'};
        push(@{$_name_conversion_sources{$context,$to}}, $from);
        $_name_conversion_actions{$context,$from,$to} = $action;
    }

    ## Dump the table, if debugging
    #for $igc (sort keys %_name_conversion_sources) {
    #    $aref = $_name_conversion_sources{$igc};
    #    print "$igc: ";
    #    for $igc2 (@$aref) {
    #        print " $igc2";
    #    }
    #    print "\n";
    #}
}

#
# >>Description::
# {{Y:NameFindOrGenerate}} searches a list of directories for a file
# with one of the list of extensions. The extensions are searched
# for in the order given. If {{NameLoadConversionRules}} has been
# called, this routine will attempt to generate a file in the current
# directory using the nominated {{context}}, if any. If a file was found
# or generated, the combined name (directory + local name) is returned.
# If the name is absolute, the file is checked to exist. i.e. the directories
# are not searched.
# In either case, if the file is not found, an empty string is returned.
#
sub NameFindOrGenerate {
    local($name, $dir_list_ref, $ext_list_ref, $context) = @_;
    local($full);
    local($dir);

    # handle "-": return itself
    return $name if $name eq "-";

    # handle absolute filenames
    if (&NameIsAbsolute($name)) {
        if (-r $name) {
            return $name;
        }
        else {
            return "";
        }
    }

    # Otherwise, search for the name
    foreach $dir (@$dir_list_ref) {
        $dir =~ s#/#:#g if $NAME_OS eq 'mac';
        $dir = "" if $dir eq '.' && $NAME_OS eq 'mac';
        $full = &NameFindInDirectory($dir, $name, $ext_list_ref, $context);
        return $full if $full ne '';
    }

    # If we reach here, we had no luck
    return "";
}

#
# >>Description::
# {{Y:NameFindInDirectory}} attempts to find a file directory {{dir}}
# using {{base}} and the set of extensions given by {{$ext_list_ref}}.
# For each base.ext combination, if it doesn't find that file,
# it tries to generate a file of that name in the current
# directory using:
#
# * the conversion rules loaded by {{Y:NameLoadConversionRules}}
# * the files called {{base.*}} in the {{dir}} directory
# * the {{context}}
#
# If the file is found or generated, its name is returned,
# otherwise an empty string is returned.
#
# Note: If the base already has an extension, the extension list isn't used.
#
sub NameFindInDirectory {
    local($dir, $base, $ext_list_ref, $context) = @_;
    local($full);

    # If the base already has an extension, don't use the extension list
    my $ext  = (&'NameSplit($base))[2];
    my @exts = $ext ne '' ? ($ext) : @$ext_list_ref;
    $base    = &NameSubExt($base, '') if $ext ne '';

    # Find/generate the file
    my %rules = %{$_name_conversions{$context}};
    my $i;
    for ($i = 0; $i <= $#exts; $i++) {
        $ext = $exts[$i];
        $full = &NameJoin($dir, $base, $ext);
        return $full if -r $full;

        # Try generating the file
        my $source_ext;
        my $action;
        my $source;
        my $dest;
        for $source_ext (@{$_name_conversion_sources{$context,$ext}}) {
            $action = $_name_conversion_actions{$context,$source_ext,$ext};
            $source = &NameJoin($dir, $base, $source_ext);
            if (-r $source) {
                $dest = &NameJoin('.', $base, $ext);

                # Do parameter substitution on the action
                my $cmd = eval '"' . $action . '"';
                if ($@) {
                    &AppMsg('warning', "error in conversion action '$action': $@");
                    next;
                }

                # Generate the file and check it exists
                my $exit_code = system($cmd);
                if ($exit_code) {
                    &AppMsg('warning', "error in conversion from '$source' to '$dest': $@");
                }
                return $dest if -r $dest;
            }
        }
    }

    # If we reach here, we had no luck
    return "";
}

# package return value
1;
