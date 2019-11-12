BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 10;
use strict;
use warnings;

use Thread::Status (); # cannot do a use_ok because we don't want to import
ok( defined( $Thread::Status::VERSION ),	'check whether loaded' );
can_ok( 'Thread::Status',qw(
 callers
 every
 encoding
 format
 import
 monitor_pid
 monitor_tid
 output
 report
 shorten
 signal
 start
 stop
) );

my $script = 'test1';
ok( open( my $handle,'>',$script ),	'create test script' );

ok( (print $handle <<EOD),		'write test script' );
print "\$\$\\n"; # let the world know which pid we need to kill
use threads;
use threads::shared;

my \$shared : shared;

sub run_the_threads {
    threads->new( sub {
        threads->new( sub {
            lock( \$shared );
            cond_wait( \$shared );
            print "something signalled ".threads->tid."\\n";
        } ) foreach 1..3;
        lock( \$shared );
        cond_wait( \$shared );
        print "something signalled ".threads->tid."\\n";
    } );
    lock( \$shared );
    cond_wait( \$shared );
    print "something signalled ".threads->tid."\\n";
}

run_the_threads();
EOD

ok( close( $handle ),			'close test script' );

my @inc = map {"-I$_"} @INC;
ok( open( $handle,"$^X @inc -MThread::Status=every,1,callers,2,output,STDOUT $script 2>/dev/null | " ),	'start the test script' );
my $pid = <$handle>;
chomp( $pid );
ok( $pid =~ m#^\d+$#,			'check the pid' );

my $output = <<EOD;
0: line 19 in test1 (main)
0: line 23 in test1 (main::run_the_threads in main)

2: line 15 in test1 (main)
  0: line 17 in test1 (threads::new in main)
  0: line 23 in test1 (main::run_the_threads in main)

3: line 11 in test1 (main)
  2: line 13 in test1 (threads::new in main)
    0: line 17 in test1 (threads::new in main)

4: line 11 in test1 (main)
  2: line 13 in test1 (threads::new in main)
    0: line 17 in test1 (threads::new in main)

5: line 11 in test1 (main)
  2: line 13 in test1 (threads::new in main)
    0: line 17 in test1 (threads::new in main)

EOD
my @output = split( m#(?<=$/)#,$output );
my $notok = 0;
while (defined(my $line = shift(@output))) {
    last if $notok = $line ne <$handle>;
}
ok( !$notok,'check if output correct' ) || warn <$handle>;

ok( kill( 'INT',$pid ),			'kill the test script' );
ok( unlink( $script ),			'remove test files' );
