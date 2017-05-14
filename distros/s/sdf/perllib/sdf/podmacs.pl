# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     POD Macros Library
#
# >>Copyright::
# Copyright (c) 1992-1997, Ian Clatworthy (ianc@mincom.com).
# You may distribute under the terms specified in the LICENSE file.
#
# >>History::
# -----------------------------------------------------------------------
# Date      Who     Change
# 17-Jun-97 ianc    SDF 2.000
# -----------------------------------------------------------------------
#
# >>Purpose::
# This library provides the built-in macros (implemented in [[Perl]]) for
# compatibility with POD.
#
# >>Description::
#
# >>Limitations::
#


# Switch to the user package
package SDF_USER;

##### Constants #####

##### Variables #####

# This contains the first item in each list
@_pod_item = ();

# This contains the indent (i.e. N within "over N") of each list
@_pod_over = ();

# This contains the style for each list
@_pod_style = ();

##### Initialisation #####

#
# >>Description::
# {{Y:InitPodMacros}} initialises the global variables in this module.
#
sub InitPodMacros {
#   local() = @_;
#   local();

    @_pod_item = ();
    @_pod_over = ();
    @_pod_style = ();
}

##### Support Routines #####


##### General Macros #####

# head1 - level 1 heading
@_head1_MacroArgs = (
    'Name       Type        Default     Rule',
    'text       rest        _NULL_',
);
sub head1_Macro {
    local(%arg) = @_;
    local(@text);

    # Return result
    return ("H1:$arg{'text'}");
}

# head2 - level 2 heading
@_head2_MacroArgs = (
    'Name       Type        Default     Rule',
    'text       rest        _NULL_',
);
sub head2_Macro {
    local(%arg) = @_;
    local(@text);

    # Return result
    return ("H2:$arg{'text'}");
}

# head3 - level 3 heading
@_head3_MacroArgs = (
    'Name       Type        Default     Rule',
    'text       rest        _NULL_',
);
sub head3_Macro {
    local(%arg) = @_;
    local(@text);

    # Return result
    return ("H3:$arg{'text'}");
}

# head4 - level 4 heading
@_head4_MacroArgs = (
    'Name       Type        Default     Rule',
    'text       rest        _NULL_',
);
sub head4_Macro {
    local(%arg) = @_;
    local(@text);

    # Return result
    return ("H4:$arg{'text'}");
}

# head5 - level 5 heading
@_head5_MacroArgs = (
    'Name       Type        Default     Rule',
    'text       rest        _NULL_',
);
sub head5_Macro {
    local(%arg) = @_;
    local(@text);

    # Return result
    return ("H5:$arg{'text'}");
}

# head6 - level 6 heading
@_head6_MacroArgs = (
    'Name       Type        Default     Rule',
    'text       rest        _NULL_',
);
sub head6_Macro {
    local(%arg) = @_;
    local(@text);

    # Return result
    return ("H6:$arg{'text'}");
}


# over - begin a list
@_over_MacroArgs = (
    'Name       Type        Default     Rule',
    'N          integer     4',
);
sub over_Macro {
    local(%arg) = @_;
    local(@text);

    # If this is the first level, switch on some special processing
    @text = ();
    if (scalar(@_pod_style) == 0) {
        # Indent examples using the level information
        push(@text, '!on paragraph \'E\'; POD_LIST_E; $attr{"in"} = scalar(@_pod_style)');

        # Set up the rule for paragraphs within a list
        push(@text, '!on paragraph \'N\'; POD_LIST_N; ' .
          '$style = $_pod_style[$#_pod_style]; ' .
          '$_pod_style[$#_pod_style] = "L" . scalar(@_pod_style)');
    }

    # Update the state
    push(@_pod_item, '');
    push(@_pod_over, $arg{'N'});
    push(@_pod_style, '');

    # Return result
    return @text;
}

# item - list item
@_item_MacroArgs = (
    'Name       Type        Default     Rule',
    'text       rest        _NULL_',
);
sub item_Macro {
    local(%arg) = @_;
    local(@text);

    # If an over hasn't been found, assume one
    @text = &over_Macro('N', 4) if scalar(@_pod_over) == 0;

    # Get the level
    my $level = scalar(@_pod_style);

    # If this is the first item, decide how to format the list
    unless ($_pod_item[$#_pod_item]) {
        $_pod_item[$#_pod_item] = $arg{'text'};
    }

    # Handle bulleted lists
    if ($_pod_item[$#_pod_item] eq '*') {
        $_pod_style[$#_pod_style] = "LU$level";
    }

    # Handle ordered lists
    elsif ($_pod_item[$#_pod_item] eq '1.') {
        $_pod_style[$#_pod_style] = $arg{'text'} eq '1.' ? "LF$level" : "LN$level";
    }

    # Handle enumerated lists
    else {
        $_pod_style[$#_pod_style] = "L$level";
        push(@text, "LI$level:$arg{'text'}");
    }

    # Return result
    return @text;
}

# back - end a list
@_back_MacroArgs = ();
sub back_Macro {
    local(%arg) = @_;
    local(@result);

    # Update the state
    pop(@_pod_item);
    pop(@_pod_over);
    pop(@_pod_style);

    # If this terminates the first level, switch off the special processing
    @result = ();
    if (scalar @_pod_style == 0) {
        @result = (
            '!off paragraph POD_LIST_N',
            '!off paragraph POD_LIST_E');
    }

    # Return result
    return @result;
}

# cut - ignore file until next = at start of line
@_cut_MacroArgs = ();
sub cut_Macro {
    local(%arg) = @_;
    local(@text);

    # Update the parser state
    $'sdf_cutting = 1;

    # Return result
    return ();
}

# pod - begin some POD
@_pod_MacroArgs = ();
sub pod_Macro {
    local(%arg) = @_;

    # Return result - nothing
    return ();
}

# for - paragraph is for format X only
@_for_MacroArgs = (
    'Name       Type        Default     Rule',
    'format     symbol',
    'text       rest        _NULL_',
);
sub for_Macro {
    local(%arg) = @_;
    local(@text);

    # Return result
    #return (&SdfJoin("__inline", $arg{'text'}, 'target', $arg{'format'}));
    return (
        "!block inline; target='$arg{'format'}'",
        $arg{'text'},
        '!endblock');
}

# begin - begin paragraphs for format X only
@_begin_MacroArgs = (
    'Name       Type        Default     Rule',
    'format     symbol',
);
sub begin_Macro {
    local(%arg) = @_;
    local(@text);

    # Return result
    return ();
}

# end - end paragraphs for format X
@_end_MacroArgs = (
    'Name       Type        Default     Rule',
    'format     symbol',
);
sub end_Macro {
    local(%arg) = @_;
    local(@text);

    # Return result
    return ();
}

# package return value
1;