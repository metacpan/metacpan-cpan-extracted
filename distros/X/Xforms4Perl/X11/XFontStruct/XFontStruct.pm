#    XFontStruct.pm - An extension to PERL to access XFontStruct structures.
#    Copyright (C) 1996-1997  Martin Bartlett
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

package X11::XFontStruct;

require Exporter;
require DynaLoader;
require AutoLoader;

=head1 NAME

XFontStruct - package to access XFontStruct structure fields

=head1 SYNOPSIS

	use <a package that returns XFontStructs>;
	use X11::XFontStruct;

	$xfontstruct = function_that_returns_xfontstruct(its, parms);
	$ascent = $xfontstruct->ascent;    

	# Any XFontStruct field can be read like this.

=head1 DESCRIPTION

This class/package provides an extension to perl that allows
Perl programs read-only access to the XFontStruct structure. So.
how do they get hold of an XFontStruct to read? Well, they use ANOTHER
Perl extension that blesses pointers to XFontStructs into the XFontStruct
class. Such an extension would do that by supplying a TYPEMAP as
follows:

     XFontStruct *    T_PTROBJ

and then returning XFontStruct pointers from appropriate function calls.

An extension that does this is the X11::Xforms extension. So, using these
two extensions the perl programmer can do some pretty powerful
XWindows application programming.

So whats in this package. Well, quite simply, every method in this
package is named after a field in the XFontStruct structure. 

ALL XFontStruct fields are catered for, except XExtData. 
ALL are returned as perl scalars or, in the case of substructures, as lists
of scalars, of various intuitively obvious types. Here is the syntax for
each field:

	$fid = $xf->$fid;
	$direction = $xf->direction;
	$min_char_or_byte2 = $xf->min_char_or_byte2;
	$max_char_or_byte2 = $xf->max_char_or_byte2;
	$min_byte1 = $xf->min_byte1;
	$max_byte1 = $xf->max_byte1;
	$all_chars_exist = $xf->all_chars_exist;
	$default_char = $xf->default_char;
	$n_properties = $xf->n_properties;
	@properties = $xf->properties;
		[or    ($name, $card32, @more_props) = $xf->n_properties;]	
	@min_bounds = $xf->min_bounds;
		[or    ($lbearing,
			$rbearing,
			$width,
			$ascent,
			$descent,
			$attributes) = $xf->min_bounds;]
	@max_bounds = $xf->max_bounds;
		[or    ($lbearing,
			$rbearing,
			$width,
			$ascent,
			$descent,
			$attributes) = $xf->max_bounds;]
	@per_char = $xf->per_char;
		[or    ($lbearing,
			$rbearing,
			$width,
			$ascent,
			$descent,
			$attributes,
			@more_chars) = $xf->per_char;]
	$ascent = $xf->ascent;
	$descent = $xf->descent;
}

=cut

@ISA = qw(Exporter DynaLoader);

$X11::XFontStruct::VERSION = '0.7';

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(

);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    local($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
        if ($! =~ /Invalid/) {
            $AutoLoader::AUTOLOAD = $AUTOLOAD;
            goto &AutoLoader::AUTOLOAD;
        }
        else {
            ($pack,$file,$line) = caller;
            die "Your vendor has not defined XFontStruct macro $constname, used at $file on $line.";
        }
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}


bootstrap X11::XFontStruct;

# Preloaded methods go here.

# Autoload methods go after __END__, and are processed by the autosplit program.

1;
__END__
