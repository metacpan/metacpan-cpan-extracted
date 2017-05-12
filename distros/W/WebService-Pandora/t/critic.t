use strict;
use warnings;

use Test::More;

# rt108500
if ( !$ENV{'RELEASE_TESTING'} ) {

   plan( skip_all => "RELEASE_TESTING not set in environment" );
}

eval { 

     require Test::Perl::Critic;
};

if ( $@ ) {

   plan( skip_all => "Test::Perl::Critic required" );
}

Test::Perl::Critic->import();
all_critic_ok();