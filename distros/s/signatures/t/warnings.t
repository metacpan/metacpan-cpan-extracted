use strict;
use warnings;
use Test::More tests => 4;

use vars qw/@warnings/;

BEGIN { $SIG{__WARN__} = sub { push @warnings, $_ } }

{
    use signatures;
    sub foo ($x) { }
}

BEGIN { is(@warnings, 0, 'no prototype warnings with signatures in scope') }

sub bar ($x) { }

BEGIN { is(@warnings, 1, 'warning without signatures in scope') }

use signatures;

sub baz ($x) { }

BEGIN { is(@warnings, 1, 'no more warnings') }

no signatures;

sub corge ($x) { }

BEGIN { is(@warnings, 2, 'disabling magic with unimport') }
