BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

BEGIN {
    warn <<EOD if -t STDERR;


Some warnings may be displayed during testing.  This shouldn't happen, but
it does.  This seems to be an interaction between Thread::Exit, Test::More
and threads.  In normal usage, Thread::Exit should be clean running with
warnings enabled.  If you should find warnings in such a situation, please
report these.  Thank you for your attention.

EOD
} #BEGIN

use Thread::Exit; # cannot have Test use this, otherwise exit() isn't changed
use Test::More tests => 27;
use strict;
use warnings;

use threads;
use threads::shared;

use_ok( 'Thread::Exit' ); # just for the record
can_ok( 'Thread::Exit',qw(
 end
 import
 inherit
 ismain
) );

ok( \&threads::new eq \&threads::create,"check if create synonym ok" );

my $check = "This is the check string";

my $thread = threads->new( sub { exit( $check ) } );
is( scalar($thread->join),$check,	'check exit from thread' );

$thread = threads->new( sub { exit( [$check] ) } );
is( join('',@{$thread->join}),$check,	'check exit from thread' );

$thread = threads->new( sub { exit( $check,$check ) } );
is( join('',$thread->join),$check,	'check exit from thread' );

($thread) = threads->new( sub { exit( $check,$check ) } );
is( join('',$thread->join),$check.$check,'check exit from thread' );

$thread = threads->new( sub { exit( $check ) } );
is( join('',$thread->join),$check,	'check exit from thread' );

my $begin : shared = '';
my $end : shared = '';
ok( Thread::Exit->begin( 'begin' ),	'check begin() setting' );
ok( Thread::Exit->end( 'main::end' ),	'check end() setting' );

threads->new( sub { is( $begin,$check,'check result of BEGIN' ) } )->join;
is( $end,$check,				'check result of END' );

$begin = $end = '';
ok( !Thread::Exit->inherit( 0 ),	'check inherit() setting' );
threads->new( sub { is( $begin,'','check result of BEGIN' ) } )->join;
is( $end,'',					'check result of END' );

ok( Thread::Exit->inherit( 1 ),		'check inherit() setting' );
threads->new( sub { is( $begin,$check,'check result of BEGIN' ) } )->join;
is( $end,$check, 				'check result of END' );

$begin = $end = '';
ok( !Thread::Exit->end( undef ),	'check end() setting' );
threads->new( sub {
 Thread::Exit->end( \&end );
 is( $begin,$check,'check result of BEGIN' );
} )->join;
is( $end,$check, 			'check result of END' );

eval q(sub Apache::exit { $end = shift });
exit( '' );
is( $end,'', 				'check result of exit()' );

my $file = "script";
ok( open( my $handle,'>',$file ),	'check opening of file' );
ok( print( $handle (<<EOD)),		'check printing to file' );
\@INC = qw(@INC);
use Thread::Exit ();
threads->create( sub {Thread::Exit->ismain; exit( 1 )} )->join;
EOD
ok( close( $handle ),                   'check closing of pipe' );
cmp_ok( system( "$^X $file" ),'==',256, 'check exit result' );
ok( unlink( $file ),			'check unlinking' );

sub begin { $begin = $check}
sub end   { $end   = $check}
