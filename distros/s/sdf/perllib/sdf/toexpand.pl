# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     Expand Output Driver
#
# >>Copyright::
# Copyright (c) 1992-1997, Ian Clatworthy (ianc@mincom.com).
# You may distribute under the terms specified in the LICENSE file.
#
# >>History::
# -----------------------------------------------------------------------
# Date      Who     Change
# 25-Jul-97 ianc    SDF 2.000
# -----------------------------------------------------------------------
#
# >>Purpose::
# This library provides an [[SDF_DRIVER]] which generates
# expanded text. The output is useful for passing to other programs
# like spell checkers.
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


#
# >>Description::
# {{Y:ExpandFormat}} is a format driver which outputs expanded text.
#
sub ExpandFormat {
    local(*data) = @_;
    local(@result);
    local($para_tag, $para_text, %para_attrs);

    # Process the paragraphs
    while (($para_text, $para_tag, %para_attrs) = &SdfNextPara(*data)) {

        # handle directives
        if ($para_tag =~ /^__(\w+)$/) {
            push(@result, $para_text) if $1 eq 'inline';
            next;
        }

        # Format the text
        $para_text = &_ExpandFormatText($para_text) unless $para_attrs{'verbatim'};

        # Build result
        push(@result, $para_text);
    }

    # Return result
    return @result;
}

#
# >>_Description::
# {{Y:_ExpandFormatText}} formats the text of a paragraph.
#
sub _ExpandFormatText {
    local($data) = @_;
    local($para);
    local($state);
    local($sect_type, $text, $char_tag, %sect_attrs);

    # Build the paragraph body
    while (($sect_type, $text, $char_tag, %sect_attrs) =
      &SdfNextSection(*data, *state)) {
        if ($sect_type eq 'string') {
            $para .= $text;
        }
        elsif ($sect_type eq 'phrase') {
            $para .= $text;
        }
        elsif ($sect_type eq 'phrase_end') {
            # do nothing
        }
        elsif ($sect_type eq 'special') {
            # do nothing
        }
        else {
            &AppMsg("warning", "unknown section type '$sect_type'");
        }
    }

    # Return result
    return $para;
}

# package return value
1;
