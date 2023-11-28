#<<<
use strict; use warnings;
#>>>

use Time::Out qw( timeout );
use Test::More import => [ qw( is ) ], tests => 2;

my $code = sub {
  wantarray ? 'array' : 'scalar';
};

my $expected_context = 'scalar';

{
  my $result = $code->();
  is $result, $expected_context, 'scalar context';
}

{
  my $result = timeout 100 => $code;
  is $result, $expected_context, 'no timeout: scalar context';
}
