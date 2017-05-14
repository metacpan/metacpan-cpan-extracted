#!/usr/bin/perl -pi.x4p.old
#
# Convert scripts from prior versions of Xforms4Perl to Xforms4Perl 0.7
#

s/Forms_BASIC/X11::Xforms/g;
if (/^\s*use\s\s*Forms_\w*/) {
	s/^(\s*use\s\s*Forms_\w*)/#$1/;
} else {
	s/^\s*use\s\s*Xforms/use X11::Xforms/;
	s/^\s*use\s\s*XEvent/use X11::XEvent/;
	s/^\s*use\s\s*XFontStruct/use X11::XFontStruct/;
}
