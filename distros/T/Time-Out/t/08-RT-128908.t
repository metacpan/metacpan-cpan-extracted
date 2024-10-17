use strict;
use warnings;

use Scalar::Util qw( blessed  );
use Time::Out    qw( timeout );
use Try::Tiny    qw( catch try );

use Test::More import => [ qw( fail is ) ], tests => 1;

timeout 1, sub {
  try {
    select( undef, undef, undef, 5 );
    die "bad\n";
  } catch {
    # rethrow exception, if it refers to a timeout
    die $_ if defined blessed $_ and $_->isa( 'Time::Out::Exception' ); ## no critic (RequireCarping)
    fail( 'timeout should fire before die' );
  }
};

is $@, 'timeout', 'eval error was set to "timeout"';
