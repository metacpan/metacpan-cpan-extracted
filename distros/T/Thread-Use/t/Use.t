BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 8;
use strict;
use warnings;

BEGIN { use_ok( 'threads' ) }
BEGIN { use_ok( 'Thread::Use' ) }

# should fail because Storable not loaded
eval {Storable::freeze( [1,2,3,4] )};
like( $@,qr/^Undefined subroutine &Storable::freeze called at/,
 'check result of eval' );

# should work because Storable now in thread memory
my $thread = threads->new(
 sub { useit Storable; eval {Storable::freeze( \@_ )}; $@ }
);
isa_ok( $thread,'threads',		'check object type' );
my $result = $thread->join;
is( $result,'',				'check result of eval' );

# should work because Storable now in thread memory
$thread = threads->new(
 sub { useit Storable qw(freeze); eval {freeze( \@_ )}; $@ }
);
isa_ok( $thread,'threads',		'check object type' );
$result = $thread->join;
is( $result,'',				'check result of eval' );

# should fail because Storable still not loaded
eval {Storable::freeze( [1,2,3,4] )};
like( $@,qr/^Undefined subroutine &Storable::freeze called at/,
 'check result of eval' );
