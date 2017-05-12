use strict;
use warnings;
use File::Spec;
use Test::More tests => 2;
my $description = 1;
use Test::More::Strict description => sub { $description++ };

ok 1, 'ok still works';
is $description, 2, 'our handler was called';