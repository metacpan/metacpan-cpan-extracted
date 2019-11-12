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

our $count : shared;

eval <<'EOD';
use Thread::Bless
 package => 'Without',

 package => 'WithCloneCoderef',
   fixup => sub { $count++ },

 package => 'WithCloneName',
   fixup => 'fixup',

 package => 'WithCloneFQName',
   fixup => 'WithCloneFQName::fixup',

 initialize => 1,
;
EOD
ok (!$@, "Evalling Thread::Bless itself: $@" );

$count = 0;
eval { Thread::Bless->register( Without->new ) };
ok (!$@, "Object going out of scope: $@" );
is( $count,0,"Check # of fixups of Without" );

foreach (qw(WithCloneCoderef WithCloneName WithCloneFQName)) {
    $count = 0;
    eval { Thread::Bless->register( $_->new ) };
    ok (!$@, "Execution ok: $@" );
    is( $count,0,"Check # of fixups of $_" );

    $count = 0;
    eval {
        my $object = $_->new;
        Thread::Bless->register( $object );
        threads->new( sub {1} )->join foreach 1..5;
    };
    ok (!$@, "Execution ok: $@" );
    is( $count,5,"Check # of fixups of $_, with threads" );
}

package Without;
sub new { bless [],shift }

package WithCloneCoderef;
sub new { bless {},shift }

package WithCloneName;
sub new { bless {},shift }
sub fixup { $count++ }

package WithCloneFQName;
sub new { bless {},shift }
sub fixup { $count++ }
