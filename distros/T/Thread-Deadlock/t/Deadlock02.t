BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}
 
use strict;
use warnings;
use Test::More tests => 7;

my $report = 'report';
my $trace = 'trace';
undef( $/ );

ok( open( my $handle,'<',$report ),	'check opening of report file' );
is( <$handle>,<<EOD,			'check report itself' );
*** Thread::Deadlock report ***
#0: cond_signal() at t/Deadlock01.t line 64

#2: cond_wait() at t/Deadlock01.t line 70 thread 2
	main::__ANON__() called at t/Deadlock01.t line 71 thread 2
	thread started at t/Deadlock01.t line 71 thread 2

EOD
ok( close( $handle ),			'check closing of file' );

ok( open( $handle,'<',$trace ),		'check opening of trace file' );
is( <$handle>,<<EOD,			'check trace itself' );
0: cond_signal() at t/Deadlock01.t line 64
2: cond_wait() at t/Deadlock01.t line 70 thread 2
EOD
ok( close( $handle ),			'check closing of file' );

ok( unlink( $report,$trace ),		'check removal of files' );
