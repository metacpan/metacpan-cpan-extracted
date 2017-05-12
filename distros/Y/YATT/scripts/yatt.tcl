#!/usr/bin/wish
# -*- mode: tcl; tab-width: 8 -*-
# $Id$

package require Tkhtml 3

package require tclperl
set perl [perl::interp new]

$perl eval [subst -novariable {
    our $ROOTNAME = "[file rootname [info script]]";
}]

set html [$perl eval {
    our $ROOTNAME;
    use File::Basename;
    BEGIN {unshift @INC, "$ROOTNAME.lib"}
    use base qw(YATT::Toplevel::CGI);
    sub MY () {__PACKAGE__}
    my ($instpkg, $trans, $config) = MY->create_toplevel('.');
    # $YATT->dispatch_captured("/index.html", $YATT->new_cgi);
    my ($sub, $pkg) = $trans->get_handler_to(render => 'index');
    YATT::Util::capture {
	$sub->($pkg);
    }
}]

puts "html=($html)"

pack [html .html]

.html parse $html
