# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     SDF Values Library
#
# >>Copyright::
# Copyright (c) 1992-1996, Ian Clatworthy (ianc@mincom.com).
# You may distribute under the terms specified in the LICENSE file.
#
# >>History::
# -----------------------------------------------------------------------
# Date      Who     Change
# 28-Aug-96 ianc    SDF 2.000
# -----------------------------------------------------------------------
#
# >>Purpose::
# This library provides the built-in value subroutines for
# [[SDF]] files.
#
# >>Description::
# Value functions are used to calculate derived attributes of a class.
# Values should be accessed via the {{SUB:Value}} subroutine.
# The interface of a value subroutine is:
#
# =     $value = class_attr_Value($name, $view);
#
# If a class-attr-specific routine is not found, {{SUB:Value}} looks for
# a class-specific routine. Its interface is:
#
# =     $value = class_Value($attr, $name, $view);
#
# >>Limitations::
#
# >>Resources::
#
# >>Implementation::
#


# Switch to the user package
package SDF_USER;

##### Constants #####

# Useful constants
$SECONDS_PER_DAY = 3600 * 24;

##### Variables #####


##### References #####

# Generate a "print document" icon (if the PostScript file exists)
sub references_Printdoc_Value {
    local($name, $view) = @_;
#   local($result);
    local($jump);
    local($root);
    local($back);
    local($title);

    # Get the filename and check it exists
    $jump = &Value("references", $name, "Jump", $view);
    $jump = &'NameSubExt($jump, "ps");
    return '' unless -f $jump;

    # Build the cgi call, using DIR_ABS_URL to get the absolute URL of
    # the directory ultimately holding this file. (This is required
    # because the CGI script doesn't have the same position in the
    # URL tree as the documents do.) DIR_ABS_URL is also provided
    # for backwards comptability.
    $root = $var{'PRINTDOC_ROOT'};
    $root = $var{'DIR_ABS_URL'} if $root eq '';
    $back = $var{'PRINTDOC_BACK'};
    $back = "$root$var{'DOC_BASE'}.html" if $back eq '';
    $title = &Value("references", $name, "Document", $view);
    $title =~ s/ /%20/g;
    $jump = "/cgi-bin/printdoc?$root$jump%20$back%20$title";
    return "{{IMPORT[alt=\"(PRINT)\";jump=\"$jump\";base='$var{'IMAGES_BASE'}';border] printer.gif}}";
}

# Generate a Printer icon - old name for Printdoc
sub references_Printer_Value {
    local($name, $view) = @_;
#   local($result);

    return &references_Printdoc_Value($name, $view);
}

#
# Default value routine for references:
# If the attribute is all uppercase (e.g. TXT), generate an image
# for a file with that (lowercase) extension (e.g. mydoc.txt),
# using an image matching the extension name (e.g. txt.gif).
# Likewise, an all uppercase attribute with a leading underscore (e.g. _DIR)
# generates an image for a HTML file with that suffix (e.g. mydoc_dir.html)
# using an image matching the extension name (e.g. dir.gif).
#
sub references_Value {
    local($attr, $name, $view) = @_;
#   local($result);

    return AttrToFile($attr, $name, 'references', $view);
}

# This routine maps an attribute to a filename.
# See the comments above references_Value for details.
sub AttrToFile {
    local($attr, $name, $class, $view) = @_;
    local($suffix);
    local($image);
    local($jump);
    local($dir, $base, $ext);

    # Do nothing unless the attribute matches the necessary pattern
    return (0) unless $attr =~ /^(_?)([A-Z0-9]+)$/;
    $suffix = $1 ne '';
    $image = $2;
    $image =~ tr/A-Z/a-z/;

    # Get the filename
    $jump = &Value($class, $name, "Jump", $view);
    if ($suffix) {
        ($dir, $base, $ext) = &'NameSplit($jump);
        $jump = &'NameJoin($dir, $base . "_$image", $ext);
    }
    else {
        $jump = &'NameSubExt($jump, $image);
    }

    # If the name looks like a URL, assume it exists.
    # Otherwise, we assume it a filename and only return an icon
    # if that file exists.
    return (1, '') unless ($jump =~ /^\w+:/ || -f $jump);

    # Build the result
    return (1,
      "{{IMPORT[alt=\"($attr)\";jump=\"$jump\";base='$var{'IMAGES_BASE'}'] $image.gif}}");
}

# Generate a PS icon (if the PostScript file exists)
sub references_PS_Value {
    local($name, $view) = @_;
#   local($result);
    local($jump);

    # Get the filename
    $jump = &Value("references", $name, "Jump", $view);
    $jump = &'NameSubExt($jump, "ps");

    # If the name looks like a URL, assume it exists.
    # Otherwise, we assume it a filename and only return an icon
    # if that file exists.
    return '' unless ($jump =~ /^\w+:/ || -f $jump);

    # Build the result
    return "{{IMPORT[alt=\"(PS)\";jump=\"$jump\";base='$var{'IMAGES_BASE'}';border] postscript.gif}}";
}

# Generate a PDF icon (if the PDF file exists)
sub references_PDF_Value {
    local($name, $view) = @_;
#   local($result);
    local($jump);

    # Get the filename
    $jump = &Value("references", $name, "Jump", $view);
    $jump = &'NameSubExt($jump, "pdf");

    # If the name looks like a URL, assume it exists.
    # Otherwise, we assume it a filename and only return an icon
    # if that file exists.
    return '' unless ($jump =~ /^\w+:/ || -f $jump);

    # Build the result
    return "{{IMPORT[alt=\"(PDF)\";jump=\"$jump\";base='$var{'IMAGES_BASE'}'] pdf.gif}}";
}

# Generate a TXT icon (if the text file exists)
sub references_TXT_Value {
    local($name, $view) = @_;
#   local($result);
    local($jump);

    # Get the filename
    $jump = &Value("references", $name, "Jump", $view);
    $jump = &'NameSubExt($jump, "txt");

    # If the name looks like a URL, assume it exists.
    # Otherwise, we assume it a filename and only return an icon
    # if that file exists.
    return '' unless ($jump =~ /^\w+:/ || -f $jump);

    # Build the result
    return "{{IMPORT[alt=\"(TXT)\";jump=\"$jump\";base='$var{'IMAGES_BASE'}'] text.gif}}";
}

# Generate a DOC icon (if the .doc file exists)
sub references_DOC_Value {
    local($name, $view) = @_;
#   local($result);
    local($jump);

    # Get the filename
    $jump = &Value("references", $name, "Jump", $view);
    $jump = &'NameSubExt($jump, "doc");

    # If the name looks like a URL, assume it exists.
    # Otherwise, we assume it a filename and only return an icon
    # if that file exists.
    return '' unless ($jump =~ /^\w+:/ || -f $jump);

    # Build the result
    return "{{IMPORT[alt=\"(DOC)\";jump=\"$jump\";base='$var{'IMAGES_BASE'}'] doc.gif}}";
}

# Get the last modified date (unformatted)
sub references_Date_Value {
    local($name, $view) = @_;
    local($modtime);
    local($jump);

    # Get the filename and check it exists
    $jump = &Value("references", $name, "Jump", $view);
    return '' unless -f $jump;

    # Build the result
    $modtime = time - (-M $jump) * $SECONDS_PER_DAY;
    return $modtime;
}

# Get the page count (formatted)
sub references_Pages_Value {
    local($name, $view) = @_;
    local($pages);
    local($jump);
    local($trailers);

    # Get the filename and check it exists
    $jump = &Value("references", $name, "Jump", $view);
    $jump = &'NameSubExt($jump, "ps");
    return '' unless -f $jump;

    # build the result
    if (open(PSSTRM, $jump)) {
        $trailers = 0;
        while (<PSSTRM>) {
            # Assume the page count is at the end as there
            # may be embedded PostScript found first
            if (/^%%Pages:\s+(\d+)/) {
                $pages = $1;
            }

            # Count the page trailers as Word doesn't support %%Pages
            if (/^%%PageTrailer/) {
                $trailers++;
            }
        }
        close(PSSTRM);

        # Format the result. If the page count is zero, guess the
        # count from the PageTrailer count
        $pages = $trailers if $pages == 0;
        $pages .= $pages == 1 ? " page" : " pages";
    }
    else {
        $pages = '';
    }

    # Return result
    return $pages;
}

# package return value
1;
