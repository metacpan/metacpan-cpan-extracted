#!/usr/bin/perl

# Tests on the behavior of objects when template elements resolve to undef.

use 5.008;
use strict;
use warnings;

use Test::More;

use YASF;

my $data = {
    a => 'a',
    b => 'b',
    c => 'c',
};

plan tests => 11;

my $with_warn = YASF->new(
    '{a}{b}{c}{unknown}',
    bindings => $data,
    on_undef => 'warn'
);
my $with_die = YASF->new(
    '{a}{b}{c}{unknown}',
    bindings => $data,
    on_undef => 'die'
);
my $with_ignore = YASF->new(
    '{a}{b}{c}{unknown}',
    bindings => $data,
    on_undef => 'ignore'
);
my $with_token = YASF->new(
    '{a}{b}{c}{unknown}',
    bindings => $data,
    on_undef => 'token'
);
my $with_default = YASF->new('{a}{b}{c}{unknown}', bindings => $data);

my $caught;
local $SIG{__WARN__} = sub { $caught = shift; };

# Test warn-type and default (which should be 'warn'):
is("$with_warn", 'abc', 'warn (1)');
like($caught, qr/No binding for reference to 'unknown'/, 'warn (2)');
$caught = q{};
is("$with_default", 'abc', '<default> (1)');
like($caught, qr/No binding for reference to 'unknown'/, '<default> (2)');

# Test 'ignore':
$caught = q{};
is("$with_ignore", 'abc', 'ignore (1)');
is($caught, q{}, 'ignore (2)');

# Test 'token':
$caught = q{};
is("$with_token", 'abc{unknown}', 'token (1)');
is($caught, q{}, 'token (2)');

# Test 'die':
$caught = q{};
my $retval = eval { "$with_die"; };
if ($retval) {
    fail('die (1)');
} else {
    pass('die (1)');
}
like($@, qr/No binding for reference to 'unknown'/, 'die (2)');

# From this point, just use 'token' and 'ignore' styles.
my $obj = YASF->new('{unknown{a}}', bindings => $data, on_undef => 'token');
is("$obj", '{unknowna}', 'compound key 1');

exit;
