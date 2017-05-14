# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     RAW-SDF Format Driver
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
# This library provides an [[SDF_DRIVER]] which generates
# RAW (i.e. fully-expanded) [[SDF]].
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
# {{Y:RawFormat}} is a format driver which outputs fully-expanded [[SDF]].
#
sub RawFormat {
    local(*data) = @_;
    local(@result);
    local($para_tag, $para_text, %para_attrs);
    local($attrtext);

    # Process the paragraphs
    while (($para_text, $para_tag, %para_attrs) = &SdfNextPara(*data)) {

        # Convert the attributes to text
        $attrtext = &SdfAttrJoinSorted(*para_attrs);

        # Format the text
        $para_text = &_RawFormatText($para_text) unless $para_attrs{'verbatim'};

        # Build result
        push(@result, "${para_tag}[$attrtext]$para_text");
    }

    # Return result
    return @result;
}

#
# >>_Description::
# {{Y:_RawFormatText}} formats the text of an SDF paragraph.
#
sub _RawFormatText {
    local($data) = @_;
    local($para);
    local($state);
    local($sect_type, $text, $char_tag, %sect_attrs);
    local($attrtext);
    local($spec_obj);

    # Build the paragraph body
    while (($sect_type, $text, $char_tag, %sect_attrs) =
      &SdfNextSection(*data, *state)) {
        if ($sect_type eq 'string') {
            $text = &_RawEscapeSpecialSymbols($text);
            $para .= $text;
        }
        elsif ($sect_type eq 'phrase') {
            # convert the attributes to text
            $attrtext = &SdfAttrJoinSorted(*sect_attrs);

            # Build the phrase
            $text = &_RawEscapeSpecialSymbols($text);
            $para .= "{{${char_tag}[$attrtext]$text";
        }
        elsif ($sect_type eq 'phrase_end') {
            $para .= "}}";
        }
        elsif ($sect_type eq 'special') {
            # convert the attributes to text
            $attrtext = &SdfAttrJoinSorted(*sect_attrs);

            # Build the phrase
            $para .= "{{__${char_tag}[$attrtext]$text}}";
        }
        else {
            &AppMsg("warning", "unknown section type '$sect_type'");
        }
    }

    # Return result
    return $para;
}

#
# >>_Description::
# {{Y:_RawEscapeSpecialSymbols}} escapes special symbols in [[SDF]].
#
sub _RawEscapeSpecialSymbols {
    local($text) = @_;
    local($result);

    # escape special symbols
    $text =~ s/\{(\\*)\{/'{\\' . ('\\' x length($1)) . '{'/eg;
    $text =~ s/\}(\\*)\}/'}\\' . ('\\' x length($1)) . '}'/eg;
    $text =~ s/\[(\\*)\[/'[\\' . ('\\' x length($1)) . '['/eg;
    $text =~ s/\](\\*)\]/']\\' . ('\\' x length($1)) . ']'/eg;

    # Return result
    return $text;
}

# package return value
1;
