# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     SDF Special Phrases Library
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
# This library provides the built-in special phrases
# (implemented in [[Perl]]) for [[SDF]] files.
#
# >>Description::
#


# Switch to the user package
package SDF_USER;

##### General Special Tags #####

# CHAR - insert a character
sub CHAR_Special {
    local(*style, *text, *attr) = @_;
#   local();

    # Set the style name
    $style = '__char';
}

# INLINE - inline text
sub INLINE_Special {
    local(*style, *text, *attr) = @_;
#   local();

    # Set the style name
    $style = '__inline';
}

# IMPORT - insert a figure
sub IMPORT_Special {
    local(*style, *text, *attr) = @_;
#   local();

    # Process the filename and attributes
    &ProcessImageAttrs(*text, *attr);

    # Set the style name
    $style = '__import';
}

# PAGENUM - insert the current page number (into a header/footer)
sub PAGENUM_Special {
    local(*style, *text, *attr) = @_;
#   local();

    # Set the style name
    $style = '__pagenum';
}

# PAGECOUNT - insert the highest page number (into a header/footer)
sub PAGECOUNT_Special {
    local(*style, *text, *attr) = @_;
#   local();

    # Set the style name
    $style = '__pagecount';
}

# PARATEXT - insert paragraph text (into a header/footer)
sub PARATEXT_Special {
    local(*style, *text, *attr) = @_;
#   local();

    # Set the style name
    $style = '__paratext';
}

# PARANUM - insert paragraph number (into a header/footer)
sub PARANUM_Special {
    local(*style, *text, *attr) = @_;
#   local();

    # Set the style name
    $style = '__paranum';
}

# PARANUMONLY - insert paragraph number only (into a header/footer)
sub PARANUMONLY_Special {
    local(*style, *text, *attr) = @_;
#   local();

    # Set the style name
    $style = '__paranumonly';
}

# PARASHORT - insert paragraph short text (into a header/footer)
sub PARASHORT_Special {
    local(*style, *text, *attr) = @_;
#   local();

    # Set the style name
    $style = '__parashort';
}

# PARALAST - insert paragraph text last found on page (into a header/footer)
sub PARALAST_Special {
    local(*style, *text, *attr) = @_;
#   local();

    # Set the style name
    $style = '__paralast';
}

# package return value
1;
