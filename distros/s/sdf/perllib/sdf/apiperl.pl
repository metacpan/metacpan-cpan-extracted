# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     Perl API Extraction Driver
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
# This library provides a driver for extracting the API from
# [[Perl]] libraries.
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

##### Variables #####
$_perl_cnt = 0;

##### Routines #####

#
# >>Description::
# {{Y:PerlFetch}} returns ($success, @records). {{success}} is 1
# if the file is opened successfully. Each record is a perl
# line of code. i.e. blank lines are removed.
#
sub PerlFetch {
    local($file) = @_;
    local($success, @records);
    local(
      $strm,
      $state
    );

    # Get the input stream
    $strm = sprintf("perl_s%d", $_perl_cnt++);

    # Open the file
    $success = open($strm, $file);

    # Input the records
    @records = ();
    if ($success) {

        $state = 0;
        perl_record:
        while (<$strm>) {

            # remove the trailing new-line
            chop($_);

            # skip blank lines
            if (/^\s*$/) {
                $state = 0;
                next;
            }

            push(@records, $_);
        }
        close($strm);

    }

    # return results
    return ($success, @records);
}

#
# >>Description::
# {{Y:PerlSymbols}} returns the list of perl symbols in a file.
# Supported symbol types are:
#
# * {{sub}} - subroutines
# * {{var}} - variables
#
# If {{symbol_type}} is supplied, only symbols of those types are
# returned. Otherwise, all symbols are returned. If {{pattern}} is
# supplied, only symbols matching that pattern are returned.
# Each symbol is returned as a record in the format:
#
# =     symbol_type:name:result:parameters
#
# The {{result}} and {{parameters}} fields are only present for
# subroutine symbols.
#
# >>Limitations::
# {{Y:PerlSymbols}} doesn't handle packages yet. i.e. doesn't append
# current package name to the front of each name.
#
sub PerlSymbols {
    local(*perl, $pattern, @symbol_type) = @_;
    local(@symbol);
    local($i, $sub_name, $sub_args, $sub_result);
    local($get_subs, $get_vars);
    local($var_name);

    # Decide on what symbols to extract
    if (@symbol_type) {
        $get_subs = grep(/^sub$/, @symbol_type);
        $get_vars = grep(/^var$/, @symbol_type);
    }
    else {
        $get_subs = 1;
        $get_vars = 1;
    }

    # Extract Interface
    line:
    for ($i = 0; $i < $#perl - 1; $i++) {

        if ($get_subs && $perl[$i] =~ /^sub\s+(\w+)\s*\{/) {
            $sub_name = $1;
            if ($pattern && $sub_name !~ /$pattern/) {
                next line;
            }
            $perl[$i + 1] =~ /local\((.*)\)\s*\=\s*\@\_\;/;
            $sub_args = $1;
            $perl[$i + 2] =~ /local\((.*)\)\s*\;/;
            $sub_result = $1;
            if ($sub_result =~ /,/) {
                $sub_result = "($sub_result)";
            }
            push(@symbol, join(':', 'sub', $sub_name,
              $sub_result, $sub_args));
            $i += 2;
        }
        elsif ($get_vars && $perl[$i] =~ /^([\$\@\%])(\w+)\s+/) {
            $var_type = $1;
            $var_name = $2;
            if ($pattern && $var_name !~ /$pattern/) {
                next line;
            }
            push(@symbol, join(':', 'var', "$var_type$var_name"));
        }
    }

    # return result
    return @symbol;
}

# package return value
1;
