#!perl -w

use strict;
use Test::More;

use File::Spec::Functions qw( catfile );
use Test::Vars;

unless ( eval { require Test::Output; Test::Output->import; 1 } ) {
    plan skip_all => 'This test requires Test::Output';
}

my $file = catfile(qw( t lib UndefAuxList.pm ));
stderr_is(
    sub { vars_ok($file); },
    q{},
    'no warning from 5.22 & 5.24 bug with multideref aux_list'
);

done_testing;
