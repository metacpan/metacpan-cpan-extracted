#!/usr/bin/perl -w
use strict;
use Test::More;

# Note that the strategy for testing for thread failure here is not very good.
# It is very timing dependent. On some systems this test will pass even with a parser
# that is not thread safe. There is some amount of luck in getting the non-thread safe
# code to crash. As it is now, the test below sucessfully crashes version 0.45 of XML::Bare
# seemingly every time I run the test.

my $threads_ok = 0;
eval("use threads;");
if( !$@ ) { $threads_ok = 1; }

my $shared_ok = 0;
if( $threads_ok ) {
    eval("use threads::shared;");
    if( !$@ ) { $shared_ok = 1; }
}

my $numok = 0;

if( !$threads_ok || !$shared_ok ) {
     plan skip_all => 'Cannot load threads and/or threads::shared; skipping multithreading tests';
}
else {
    #plan 'no_plan';
    plan tests => 2;
    use_ok( 'XML::Bare' );
    threads::shared::share( \$numok );
    for( my $i=0;$i<20;$i++ ) {
        threads->create( \&single );
    }
    while( 1 ) {
        my @joinable = threads->list(0);#joinable
        my @running = threads->list(1);#running
        
        for my $thr ( @joinable ) { $thr->join(); }
        last if( !@running );
        sleep(1);
    }
    is( $numok, 20, 'All threads completed okay' );
}

sub single {
    my $xml = '<xml>';
    my @arr;
    for( my $i=0;$i<4000;$i++ ) {
        my $n = rand(1000);
        $arr[ $i ] = $n;
        $xml .= "<node><n>$n</n></node>";
    }
    $xml .= "</xml>";
    my ( $ob, $root ) = XML::Bare->new( text => $xml );
    $root = $root->{'xml'};
    my $nodes = $root->{'node'};
    my $ok = 1;
    my $i = 0;
    for my $node ( @$nodes ) {
        my $n = $node->{'n'}{'value'};
        $ok = 0 if( $n ne $arr[ $i ] ); # note ne here instead of !=. Because $a=405.69280607542502; $a!="$a"; But $a=405.69280607542501; $a=="$a"; :(
        $i++;
    }
    @arr = ();
    
    return if( !$ok );
    
    {
        lock( $numok );
        $numok++;
    }
}
