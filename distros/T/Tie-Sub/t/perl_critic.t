#!perl -T

use strict;
use warnings;

use Test::More;

eval 'use Test::Perl::Critic -severity => 1; 1'
    or plan( skip_all => 'Test::Perl::Critic required' );

$ENV{AUTHOR_TESTING}
    or plan( skip_all => 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.' );

all_critic_ok( qw(
    lib
    example
) );
