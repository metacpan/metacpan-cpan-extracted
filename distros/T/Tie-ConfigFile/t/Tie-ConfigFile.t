#!/usr/bin/env perl

#
# Copyright (C) 2015-2016 by Tomasz Konojacki
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.18.2 or,
# at your option, any later version of Perl 5 you may have available.
#

use utf8;
use strict;
use warnings;

use Test::More tests => 13;

use File::Temp qw(tempfile);

###############################################################################

BEGIN { use_ok('Tie::ConfigFile') };

###############################################################################

# create temporary file for tests
my($fh, $filename) = tempfile(UNLINK => 0);
binmode $fh, ':utf8';

# create test config file
print {$fh} <<'EOF';
val1 =2
;comment
ąś=gęś

;another comment
val=
key with spaces=foo bar
EOF

close $fh;

my %config;

ok(
    tie(%config, 'Tie::ConfigFile', filename => $filename, readonly => 1),
    'Tie hash (read-only)'
);

###############################################################################

is(
    $config{val1},
    '2',
    'check simple value'
);

###############################################################################

is(
    $config{ąś},
    'gęś',
    'check unicode key and value'
);

###############################################################################

is(
    $config{val},
    '',
    'check empty value'
);

###############################################################################

is(
    $config{does_not_exist},
    undef,
    'check not-existing value'
);

###############################################################################

is(
    $config{'key with spaces'},
    'foo bar',
    'check key with spaces'
);

###############################################################################

undef $@;
eval {
    $config{'something'} = 1;
};
ok($@, 'write fails when tied in read-only mode');

###############################################################################

untie %config;

ok(
    tie(%config, 'Tie::ConfigFile', filename => $filename, readonly => 0),
    'Tie hash (read-write)'
);

###############################################################################

$config{val} = 'foobar';

my($result, $exp);

$result = slurp_test_file();
$exp = <<'EOF';
val1 =2
;comment
ąś=gęś

;another comment
val=foobar
key with spaces=foo bar
EOF

is(
    $result,
    $exp,
    'value correctly changed, nothing was reformatted'
);

###############################################################################

$config{'new value'} = '1';

$result = slurp_test_file();
$exp = <<'EOF';
val1 =2
;comment
ąś=gęś

;another comment
val=foobar
key with spaces=foo bar
new value=1
EOF

is(
    $result,
    $exp,
    'value correctly added, nothing was reformatted'
);

###############################################################################

delete $config{val};
$result = slurp_test_file();
$exp = <<'EOF';
val1 =2
;comment
ąś=gęś

;another comment
key with spaces=foo bar
new value=1
EOF

is(
    $result,
    $exp,
    'value correctly removed, nothing was reformatted'
);

###############################################################################

delete $config{ąś};

is_deeply(
    [sort(keys %config)],
    ['key with spaces', 'new value', 'val1'],
    'test keys()'
);

###############################################################################

# clean-up
unlink $filename;

sub slurp_test_file {
    local $/; # slurp

    open my($s_fh), '<:utf8', $filename;
    my $contents = <$s_fh>;
    close $s_fh;

    return $contents;
}
