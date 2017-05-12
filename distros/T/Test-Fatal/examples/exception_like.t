use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Fatal;
use Carp 'confess';

sub exception_like(&$;$)
{   
  my ($code, $pattern, $name) = @_;
  like( &exception($code), $pattern, $name );
}

exception_like(sub { confess 'blah blah' }, qr/foo/, 'foo seems to appear in the exception');

# the test only passes when we invert it
unlike(
    ( exception { confess 'blah blah' } || '' ),
    qr/foo/,
    'foo does NOT ACTUALLY appear in the exception',
);

done_testing;
