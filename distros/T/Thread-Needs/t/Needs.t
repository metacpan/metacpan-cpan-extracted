BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

BEGIN {
    warn <<EOD if -t STDERR; # warn only if someone is watching


During testing some warnings may appear, specifically from undefined values
being used in AutoLoader.  These seem to be a side-effect of the magic that
Thread::Needs is performing.  For now, the errors seem harmless but can
unfortunately not be fixed (yet).  Suggestions for a fix will be appreciated.

EOD
} #BEGIN

use strict;
use warnings;
use Test::More tests => 15;

BEGIN { use_ok( 'threads' ) }

ok( !scalar(Thread::Needs->import( qw(Storable) )), 'check import without' ); 

use_ok('Thread::Needs');

can_ok( 'Thread::Needs',qw(
 import
 unimport
) );

# should fail because Storable not loaded
my $thread = threads->new( sub { eval {Storable::freeze( \@_ )}; $@ } );
isa_ok( $thread,'threads',			'check object type' );
my $result = $thread->join;
like( $result,qr/^Undefined subroutine &Storable::freeze called at/,
 'check result of eval' );

use_ok('Storable');

# should fail because Storable removed from thread memory
$thread = threads->new( sub { eval {Storable::freeze( \@_ )}; $@ } );
isa_ok( $thread,'threads',			'check object type' );
$result = $thread->join;
like( $result,qr/^Undefined subroutine &Storable::freeze called at/,
 'check result of eval' );

my @notyet = Thread::Needs->import( qw(Storable) );
ok( (@notyet == 1 and $notyet[0] eq 'Storable'),	'check import with' ); 

# Fails because something Storable needs is not available
$thread = threads->new( sub { eval {Storable::freeze( \@_ )}; $@ } );
isa_ok( $thread,'threads',			'check object type' );
$result = $thread->join;
unlike( $result,qr/^Undefined subroutine &Storable::freeze called at/,
 'check result of eval' );

my @any = Thread::Needs->unimport( @notyet );
cmp_ok( scalar(@any),'==',0,			'check unimport with' ); 

# should fail because Storable removed from thread memory
$thread = threads->new( sub { eval {Storable::freeze( \@_ )}; $@ } );
isa_ok( $thread,'threads',			'check object type' );
$result = $thread->join;
like( $result,qr/^Undefined subroutine &Storable::freeze called at/,
 'check result of eval' );
