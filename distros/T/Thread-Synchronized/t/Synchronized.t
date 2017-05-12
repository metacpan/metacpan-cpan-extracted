BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 26;
use strict;
use warnings;

use_ok( 'Thread::Synchronized' );
can_ok( 'Thread::Synchronized',qw(
 import
) );

my $script = 'test1';

ok( open( my $handle,'>',$script ),	'create test script' );
ok( (print $handle <<'EOD'),		'write test script' );
use threads;
use threads::shared;
use Thread::Synchronized;

sub a : synchronized {
    my $tid = threads->tid;
    foreach (1..3) {
        print "$tid: $_\n";
        sleep 1;
    }
} #a

$| = 1;
my @thread;
push( @thread,threads->new( \&a ) ) foreach 1..3;

$_->join foreach @thread;
EOD

ok( close( $handle ),			'close test script' );

ok( open( $handle,"$^X -Ilib $script|" ),'run test script and fetch output');

my %seen = ();
my $tests = 0;
while (<$handle>) {
    last unless m#^(\d+):#; $tests++;
    my $seen = $1;
    last if $seen{$seen}; $tests++;
    $seen{$seen} = $seen;
    foreach my $times (1..2) {
        last unless <$handle> =~ m#^$seen:#; $tests++;
    }
}
is( "@{[sort keys %seen]}",'1 2 3','check if all threads returned' );
is( $tests,'12','check if all lines returned' );

close $handle;

ok( open( $handle,'>',$script ),	'create 2nd test script' );

ok( (print $handle <<'EOD'),		'write 2nd test script' );
use threads;
use threads::shared;
use Thread::Synchronized;

sub a : synchronized { 1 }
sub foo::a : synchronized { 1 }
package bar;
sub a : synchronized { 1 }

print "@{[sort keys %Thread::Synchronized::VERSION]}";
EOD

ok( close( $handle ),			'close 2nd test script' );

ok( open( $handle,"$^X -Ilib $script|" ),'run 2nd test script, fetch output');

is( (scalar <$handle>),'bar::a foo::a main::a','check if subs were found' );

close $handle;

ok( open( $handle,'>',$script ),	'create 3rd test script' );
ok( (print $handle <<'EOD'),		'write 3rd test script' );
use threads;
use threads::shared;
use Thread::Synchronized;

my $object : shared;

sub a : synchronized method {
    my $tid = threads->tid;
    foreach (1..3) {
        print "$tid: $_\n";
        sleep 1;
    }
} #a

$| = 1;
my @thread;
push( @thread,threads->new( \&a,$object ) ) foreach 1..3;

$_->join foreach @thread;
EOD

ok( close( $handle ),			'close 3rd test script' );

ok( open( $handle,"$^X -Ilib $script|" ),'run 3rd test script and fetch output');

%seen = ();
$tests = 0;
while (<$handle>) {
    last unless m#^(\d+):#; $tests++;
    my $seen = $1;
    last if $seen{$seen}; $tests++;
    $seen{$seen} = $seen;
    foreach my $times (1..2) {
        last unless <$handle> =~ m#^$seen:#; $tests++;
    }
}
is( "@{[sort keys %seen]}",'1 2 3','check if all threads returned' );
is( $tests,'12','check if all lines returned' );

close $handle;

SKIP: {
    skip( "load.pm not ready for ondemand source filters yet",6 ) if 1;
    eval {require load};
    skip( "load.pm not found",6 ) unless defined $load::VERSION;
    skip( "load.pm not recent enough",6 ) if $load::VERSION < 0.12;

    ok( open( $handle,'>',$script ),	'create 4th test script' );
    ok( (print $handle <<'EOD'),		'write 4th test script' );
package Foo;
BEGIN {$INC{'Foo'} = 'test1'} # so that load.pm can find the source
use threads;
use threads::shared;
use load;
use Thread::Synchronized;

a();

$| = 1;
my @thread;
push( @thread,threads->new( \&a ) ) foreach 1..3;

$_->join foreach @thread;

__END__
sub a : synchronized {
    my $tid = threads->tid;
    foreach (1..3) {
        print "$tid: $_\n";
        sleep 1;
    }
} #a
EOD

    ok( close( $handle ),			'close 4th test script' );

    ok( open( $handle,"$^X -Ilib -I. $script|" ),'run 4th test script and fetch output');

    %seen = ();
    $tests = 0;
    while (<$handle>) {
        last unless m#^(\d+):#; $tests++;
        my $seen = $1;
        last if $seen{$seen}; $tests++;
        $seen{$seen} = $seen;
        foreach my $times (1..2) {
            last unless <$handle> =~ m#^$seen:#; $tests++;
        }
    }
    is( "@{[sort keys %seen]}",'1 2 3','check if all threads returned' );
    is( $tests,'12','check if all lines returned' );

    close $handle;
}

ok( unlink( $script ),			'remove test files' );
