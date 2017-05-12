use strict;
use warnings;
use Test::More tests => 8;

use vars qw/@warnings/;
BEGIN { $SIG{__WARN__} = sub { push @warnings, @_ } }

BEGIN { is(@warnings, 0, 'no warnings yet') }

use signatures;

sub with_proto ($x, $y, $z) : proto($$$) {
    return $x + $y + $z;
}

{
    my $foo;
    sub with_lvalue () : lvalue proto() { $foo }
}

is(prototype('with_proto'), '$$$', ':proto attribute');

is(prototype('with_lvalue'), '', ':proto with other attributes');
with_lvalue = 1;
is(with_lvalue, 1, 'other attributes still there');

BEGIN { is(@warnings, 0, 'no warnings with correct :proto declarations') }

sub invalid_proto ($x) : proto(invalid) { $x }

BEGIN {
    TODO: {
        local $TODO = ':proto checks not yet implemented';
        is(@warnings, 1, 'warning with illegal :proto');
        like(
            $warnings[0],
            qr/Illegal character in prototype for main::invalid_proto : invalid at /,
            'warning looks sane',
        );
    }
}

eval 'sub foo ($bar) : proto { $bar }';
like($@, qr/proto attribute requires argument/);
