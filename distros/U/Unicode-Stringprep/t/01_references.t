use strict;
use utf8;

use Test::More tests => 4;
use Test::NoWarnings;

use Unicode::Stringprep;

my $prep = Unicode::Stringprep->new(
  3.2,
  [ ],
  '',
  [ ],
  0
);

is(ref $prep, 'Unicode::Stringprep', 'bless you');

*prep = $prep;
is(eval { prep('TEST') }, 'TEST', 'direct call');
is(eval { $prep->('TEST') }, 'TEST', 'indirect call');
