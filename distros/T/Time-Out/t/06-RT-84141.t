#<<<
use strict; use warnings;
#>>>

use Test::Needs { 'Time::HiRes' => 1.9726 };

use Time::Out qw( timeout );

use Test::More import => [ qw( is ) ], tests => 2;

for my $timeout ( ( 2148, 86400 ) ) {
  my $result = timeout $timeout => sub {
    alarm 0;
  };
  is $result, $timeout, "disable timer and return the amount of time remaining on it ($timeout seconds)";
}
