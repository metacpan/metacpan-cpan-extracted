#
# $Id: 09_indent.t 4552 2010-09-23 10:40:29Z james $
#

use strict;
use warnings;

BEGIN {
    use Test::More;
    our $tests = 8;
    eval "use Test::NoWarnings";
    $tests++ unless( $@ );
    plan tests => $tests;
}

use_ok('Text::Indent');

my $i = Text::Indent->new;
is( $i->indent("foo"), "foo\n", "no indentation");
$i->increase;
is( $i->indent("foo"), "  foo\n", "indent level 1");
$i->spaces(4);
is( $i->indent("foo"), "    foo\n", "change spaces to 4");
$i->spacechar("+");
is( $i->indent("foo"), "++++foo\n", "change spacechar to +");
$i->add_newline(0);
is( $i->indent("foo"), "++++foo", "unset add_newline");
$i->reset;
is( $i->indent("foo"), "foo", "reset indent level");
$i->decrease;
is( $i->indent("foo"), "foo", "negative indent has no effect");

#
# EOF
