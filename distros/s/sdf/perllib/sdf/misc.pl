# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     Miscellaneous Library
#
# >>Copyright::
# Copyright (c) 1992-1996, Ian Clatworthy (ianc@mincom.com).
# You may distribute under the terms specified in the LICENSE file.
#
# >>History::
# -----------------------------------------------------------------------
# Date      Who     Change
# 31-Dec-96 ianc    Added TJH's MiscFindImageFile
# 29-Feb-96 ianc    SDF 2.000
# -----------------------------------------------------------------------
#
# >>Purpose::
# This library provides miscellaneous routines.
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

# Default rules indexed on type
%_MISC_DEFAULT_RULE = (
    'boolean',      '<[01]>',
    'integer',      '<\d+>',
);

##### Variables #####

#
# >>Description::
# {{Y:misc_date_strings}} contains the string lists used by 
# {{Y:MiscDateFormat}} indexed by the symbols (e.g. 'month') used
# by that routine.
#
%misc_date_strings = (
  "month" =>    ["January", "February", "March", "April",
                 "May", "June", "July", "August",
                 "September", "October", "November", "December"],
  "smonth" =>   ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                 "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
  "weekday" =>  ["Sunday", "Monday", "Tuesday", "Wednesday",
                 "Thursday", "Friday", "Saturday"],
  "sweekday" => ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
  "ampm" =>     ["am", "pm"],
  "AMPM" =>     ["AM", "PM"]
);


##### Routines #####

#
# >>Description::
# {{Y:MiscCheckRule}} checks a {{rule}} for a value {{$_}}.
# If an execution error is detected, an appropriate error is output.
# The result of the code executed is returned as {{result}}.
# If {{rule}} is an empty string, {{type}} is used to lookup a
# default rule for that type, if any.
# If {{rule}} is still an empty string, 1 is returned.
#
sub MiscCheckRule {
    local($_, $rule, $type) = @_;
    local($result);

    # Get the default rule, if necessary
    $rule = $_MISC_DEFAULT_RULE{$type} if $rule eq '';

    # For performance, handle common cases directly
    return 1        if $rule eq '';
    return /^\d+$/  if $rule eq '<\d+>';
    return /^[01]$/ if $rule eq '<[01]>';

    # convert rule to Perl code, if necessary
    #$rule =~ s#^\s*\<(.*)\>\s*$#/^($1)\$/#;
    $rule =~ s#^\<(.*)\>$#/^($1)\$/#;

    # Return result
    &MiscDoAction($rule, "rule");
}

#
# >>Description::
# {{Y:MiscDoAction}} executes a block of Perl code ({{action}}).
# If an execution error is detected, an appropriate error is output
# using {{what}} to name the block of code that failed. The result
# of the code executed is returned as {{result}}. {{action}} is only
# executed if it exists. If it does not, 1 is returned.
#
sub MiscDoAction {
    local($action, $what) = @_;
    local($result) = 1;

    # Do the action, if any
    if ($action) {
        $result = eval $action;
        &AppMsg("error", "error executing $what: $@\nCODE IS:\n$action") if $@;
    }

    # Return result
    $result;
}

#
# >>Description::
# {{Y:MiscTextWrap}} wraps a text string at a margin given by {{wrap}}.
# {{prefix}} is the string to begin each wrapped line.
# {{suffix}} is the string to terminate each wrapped line.
# NB:
# * {{prefix}} is not added to the first line
# * {{suffix}} is not added to the last line
# * {{wrap}} includes {{prefix}} but excludes {{suffix}}
# NE:
#
sub MiscTextWrap {
    local($text, $wrap, $prefix, $suffix, $keep_spaces) = @_;
    local($newtext);
    local($word, @words);
    local($prefix_len, $length);

    # Prepare for looping through the words
    if ($keep_spaces) {
        @words = split(/ /, $text);
    }
    else {
        @words = split(/\s+/, $text);
    }
    $newtext = shift(@words);
    $length = length($newtext);
    $prefix_len = length($prefix);

    # Wrap the text
    while (defined($word = shift(@words))) {
        if ($length + length($word) < $wrap) {
            $newtext .= " $word";
            $length += length($word) + 1;
        }
        elsif (length($word) + length($prefix) > $wrap &&
               $length <= length($prefix)) {
            $newtext .= " $word";
            $length += length($word) + 1;
        }
        else {
            $newtext .= "$suffix\n$prefix$word";
            $length = length($word) + $prefix_len;
        }
    }

    # Return result
    return $newtext;
}

#
# >>Description::
# {{Y:MiscDateFormat}} formats a date-time value.
# {{fmt}} is a string containing the symbols below.
#
# !block table; format=352
# Symbol:Description:Example
# $day:day number in month:6 or 22
# $day0:day number in month zero-padded:06 or 22
# $month:month name:January
# $smonth:abbreviated month name:Jan
# $monthnum:month number (1..12):6 or 12
# $monthnum0:month number zero-padded (01..12):06 or 12
# $year:year:1995
# $syear:abbreviated year:95
# $weekday:weekday name:Monday
# $sweekday:abbreviated weekday name:Mon
# $hour:hour (1..24):6 or 14
# $hour0:hour zero-padded (01..24):06 or 14
# $shour:hour (1..12):6 or 12
# $shour0:hour zero-padded (01..12):06 or 12
# $ampm:am or pm:am
# $AMPM:AM or PM:PM
# $minute:minute (0..59):0 or 42
# $minute0:minute zero-padded (00..59):00 or 42
# $second:second (0..59):0 or 42
# $second0:second zero-padded (00..59):00 or 42
# !endblock
#
# {{time}} is a number of seconds since January 1, 1970.
# {{msg_type}} is the type of message, if any, to output
# when a bad format is found.
#
sub MiscDateFormat {
    local($fmt, $time, $msg_type) = @_;
    local($result);
    package USER_MISC;
    local($day, $day0);
    local($month, $smonth, $monthnum, $monthnum0, $_month);
    local($year, $syear);
    local($weekday, $sweekday, $_wday);
    local($hour, $hour0, $shour, $shour0);
    local($minute, $minute0);
    local($second, $second0);

    # Get the quantities
    ($second, $minute, $hour, $day, $_month, $syear, $_wday) =
      localtime($main'time);
    $day0 = sprintf("%02d", $day);
    $month = $main::misc_date_strings{"month"}[$_month];
    $smonth = $main::misc_date_strings{"smonth"}[$_month];
    $monthnum = $_month + 1;
    $monthnum0 = sprintf("%02d", $monthnum);
    $year = $syear + 1900;
    $syear = sprintf("%02d", $syear % 100) if $syear > 99;
    $weekday = $main::misc_date_strings{'weekday'}[$_wday];
    $sweekday = $main::misc_date_strings{'sweekday'}[$_wday];
    $hour0 = sprintf("%02d", $hour);
    $shour = $hour - 12 if $hour > 12;
    $shour = 12 if $shour == 0;
    $ampm = $main::misc_date_strings{'ampm'}[$hour >= 12];
    $AMPM = $main::misc_date_strings{'AMPM'}[$hour >= 12];
    $shour0 = sprintf("%02d", $shour);
    $minute0 = sprintf("%02d", $minute);
    $second0 = sprintf("%02d", $second);

    # format the date-time
    $main'result = eval '"' . $main'fmt . '"';
    package main;
    if ($msg_type && $@) {
        &AppMsg($msg_type, "bad datetime format '$fmt'");
    }

    # result result
    return $result;
}

#
# >>Description::
# {{Y:MiscUpperToMixed}} converts a name in an uppercase form (e.g. MY_STRING)
# to a mixed-case form (e.g. MyString).
#
sub MiscUpperToMixed {
    local($upper) = @_;
    local($mixed);

    $mixed = $upper;
    substr($mixed, 1) =~ tr/A-Z/a-z/;
    $mixed =~ s/_([a-z0-9])/\u$1/g;
    return $mixed;
}

#
# >>Description::
# {{Y:MiscMixedToUpper}} converts a name in a mixed-case form (e.g. MyString)
# to an uppercase form (e.g. MY_STRING).
#
sub MiscMixedToUpper {
    local($mixed) = @_;
    local($upper);

    $upper = $mixed;
    substr($upper, 1) =~ s/([A-Z])/_$1/g;
    $upper =~ tr/a-z/A-Z/;
    return $upper;
}

# package return value
1;
