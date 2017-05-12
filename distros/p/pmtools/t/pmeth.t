# pmeth testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 2;

# ------ define variable
my $output = undef;	# output from pmeth

# ------ add other pmtools to PATH temporarily
$ENV{'PATH'} = 'blib/script:' . $ENV{PATH};

eval {
    $output = `bin/pmeth Tie::Hash 2>&1`;
};

is($?,        0,                   "pmeth runs");
like($output, qr/CLEAR.*EXISTS/ms, "list methods of a module");
