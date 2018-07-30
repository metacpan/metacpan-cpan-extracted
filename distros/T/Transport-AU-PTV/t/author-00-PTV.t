#!perl -T

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use 5.010;
use strict;
use warnings;
use Test::More tests => 3;

BAIL_OUT('PERL_PTV_DEV_ID environment variable not set') unless $ENV{PERL_PTV_DEV_ID};
BAIL_OUT('PERL_PTV_API_KEY environment variable not set') unless $ENV{PERL_PTV_API_KEY};

use_ok( 'Transport::AU::PTV' ); 

# Authentication comes through in the environment variables
my $ptv = Transport::AU::PTV->new;
isa_ok( $ptv, 'Transport::AU::PTV' );
ok( !$ptv->error, 'PTV object created' ) or BAIL_OUT('Transport::AU::PTV creation error');
