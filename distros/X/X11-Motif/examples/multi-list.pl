#!/ford/thishost/unix/div/ap/bin/perl -w

use blib;

use strict;
use X11::Motif;

# This demo puts three lists under the control of one scrolled
# window.  It's a bit kludgy -- you can't use the set position
# routines of the lists for example -- but it does present a
# pretty nice display.  A better approach might be to use one of
# the table widgets, but that gets into non-standard Motif
# behavior, especially with respect to selection handling.

my $toplevel = X::Toolkit::initialize("MultiList");

my $form = give $toplevel -Form;

    my $view = give $form -ScrolledWindow,
	    -width => 500, -height => 100,
	    -scrollingPolicy => X::Motif::XmAUTOMATIC,
	    -visualPolicy => X::Motif::XmCONSTANT,
	    -scrollBarDisplayPolicy => X::Motif::XmSTATIC;

	my $list_group = give $view -Form;

	    my $list_1 = give $list_group -List;
	    my $list_2 = give $list_group -List;
	    my $list_3 = give $list_group -List;

	constrain $list_1 -top => -form, -bottom => -form, -left => -form;
	constrain $list_2 -top => -form, -bottom => -form, -left => $list_1;
	constrain $list_3 -top => -form, -bottom => -form, -left => $list_2, -right => -form;

constrain $view -top => -form, -bottom => -form, -left => -form, -right => -form;

my @info;
my $row = 1;
while (scalar(@info = getpwent())) {
    X::Motif::XmListAddItemUnselected($list_1, $info[0], $row);
    X::Motif::XmListAddItemUnselected($list_2, $info[5], $row);
    X::Motif::XmListAddItemUnselected($list_3, $info[7], $row);
    ++$row;
}

change $list_1 -visibleItemCount => $row;
change $list_2 -visibleItemCount => $row;
change $list_3 -visibleItemCount => $row;

handle $toplevel;
