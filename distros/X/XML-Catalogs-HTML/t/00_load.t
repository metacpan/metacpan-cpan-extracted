#!perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
   require_ok( 'XML::Catalogs::HTML' );
}

diag( "Testing XML::Catalogs::HTML $XML::Catalogs::HTML::VERSION" );
diag( "Using Perl $]" );

for (sort grep /\.pm\z/, keys %INC) {
   s{\.pm\z}{};
   s{/}{::}g;
   eval { diag(join(' ', $_, $_->VERSION || '<unknown>')) };
}
