#!/usr/bin/perl -w

#
# $Id: Tcl.t,v 1.1 2003/10/14 16:35:25 mertz Exp $
# Author: Christophe Mertz
#

# Some Conversion tests.

use strict;
use Config;

use SVG::SVG2zinc::Backend::Tcl;

BEGIN {
    if (!eval q{
        use Test::More qw(no_plan);
        1;
    }) {
        print "# tests only work properly with installed Test::More module\n";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }

    use_ok( 'SVG::SVG2zinc::Backend::Tcl;' );
}

my $str;


$str = "'text','titi','toto'";
is ( &simplify (&perl2tcl ($str)),
     'text titi toto',
     $str);

$str = "'text', 'titi', 'toto'";
is ( &simplify (&perl2tcl ($str)),
     'text titi toto',
     $str);

$str = "->add('text', -position => [10,20], -text => \"the_text\");";
is ( &simplify (&perl2tcl ($str)),
     '$w.zinc add text -position {10 20} -text the_text',
     $str);

$str = "->add('group',1, -tags => ['__svg__1', 'width=0', 'height=0'], -priority => 10);";
is ( &simplify (&perl2tcl ($str)),
     '$w.zinc add group 1 -tags {__svg__1 width=0 height=0} -priority 10',
     $str);


# TODO:
TODO: {
    local $TODO = 'I do not know if this is legal';
#    is (&removeComment('blabla/* blibli /* blibli */ */ blublu'), 'blabla blublu', 'removing recursive comment');
}

diag ('############ perl2tcl conversions');

sub simplify {
    my $str = shift;
    $str =~ s/\s+/ /g; # removing multiple spaces
    return $str;
}

__END__
