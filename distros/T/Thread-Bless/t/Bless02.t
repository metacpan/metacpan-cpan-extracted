BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

BEGIN {
    if ($ENV{FORKS_FOR_THREADS}) {
        eval {
            require forks; forks->import;
            require forks::shared; forks::shared->import;
        };
    }
} #BEGIN

use Test::More tests => 3 + (3 * 4 );
use strict;
use warnings;

use threads;
use threads::shared;

use_ok( 'Thread::Bless' );

our $count : shared;

$count = 0;
eval { Without->new };
ok (!$@, "Object going out of scope: $@" );
is( $count,0,"Check # of fixups of Without" );

foreach (qw(WithCloneCoderef WithCloneName WithCloneFQName)) {
    $count = 0;
    eval { $_->new };
    ok (!$@, "Execution ok: $@" );
    is( $count,0,"Check # of fixups of $_" );

    $count = 0;
    eval {
        my $object = $_->new;
        threads->new( sub {1} )->join foreach 1..5;
    };
    ok (!$@, "Execution ok: $@" );
    is( $count,5,"Check # of fixups of $_, with threads" );
}

package Without;
use Thread::Bless;
sub new { bless [],shift }

package WithCloneCoderef;
use Thread::Bless fixup => sub { $count++ };
sub new { bless {},shift }

package WithCloneName;
use Thread::Bless fixup => 'fixup';
sub new { bless {},shift }
sub fixup { $count++ }

package WithCloneFQName;
use Thread::Bless fixup => 'WithCloneFQName::fixup';
sub new { bless {},shift }
sub fixup { $count++ }
