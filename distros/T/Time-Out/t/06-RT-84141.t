use strict;
use warnings;

use Test::More import => [ qw( is plan ) ];

BEGIN {
  plan eval { require Time::HiRes; Time::HiRes->VERSION( '1.9726' ); }
    ? ( tests => 2 )
    : ( skip_all => 'Time::HiRes 1.9726 needed but is not installed' );
}

use Time::Out qw( timeout );

for my $timeout ( ( 2148, 86400 ) ) {
  my $result = timeout $timeout => sub {
    alarm 0;
  };
  is $result, $timeout, "disable timer and return the amount of time remaining on it ($timeout seconds)";
}
