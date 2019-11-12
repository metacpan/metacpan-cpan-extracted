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

use Test::More tests => 15;
use strict;
use warnings;

use threads;
use threads::shared;

eval <<'EOD';
# package => [qw(Without WithDestroy)],
use Thread::Bless (
 package => [qw(Without WithDestroy)],

 package => 'WithDestroyAll',
  destroy => 1,

 initialize => 1,
);
EOD
ok (!$@, "Evalling Thread::Bless itself: $@" );

my $count : shared;

$count = 0;
eval { Thread::Bless->register( Without->new ) };
ok (!$@, "Without object going out of scope: $@" );
is( $count,0,"Check # of destroys of WithoutDestroy" );

$count = 0;
eval { Thread::Bless->register( NoBless->new ) };
ok (!$@, "NoBless object going out of scope: $@" );
is( $count,1,"Check # of destroys of NoBless" );

$count = 0;
eval {
    my $object = NoBless->new;
    Thread::Bless->register( $object );
    threads->new( sub {1} )->join foreach 1..5;
};
ok (!$@, "Threads with NoBless object: $@" );
is( $count,6,"Check # of destroys of NoBless, with threads" );

$count = 0;
eval { Thread::Bless->register( WithDestroy->new ) };
ok (!$@, "WithDestroy object going out of scope: $@" );
is( $count,1,"Check # of destroys of WithDestroy" );

$count = 0;
eval {
    my $object = WithDestroy->new;
    Thread::Bless->register( $object );
    threads->new( sub {1} )->join foreach 1..5;
};
ok (!$@, "Threads with WithDestroy object: $@" );
is( $count,1,"Check # of destroys of WithDestroy, with threads" );

$count = 0;
eval { Thread::Bless->register( WithDestroyAll->new ) };
ok (!$@, "WithDestroyAll object going out of scope: $@" );
is( $count,1,"Check # of destroys of WithDestroyAll" );

$count = 0;
eval {
    my $object = WithDestroyAll->new;
    Thread::Bless->register( $object );
    threads->new( sub {1} )->join foreach 1..5;
};
ok (!$@, "Threads with WithDestroyAll object: $@" );
is( $count,6,"Check # of destroys of WithDestroyAll, with threads" );


package Without;
sub new { bless [] }

package NoBless;
sub new { bless {} }
sub DESTROY { $count++ }

package WithDestroy;
sub new { bless {} }
sub DESTROY { $count++ }

package WithDestroyAll;
sub new { bless {} }
sub DESTROY { $count++ }
