# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings ;
use Test::More ;

use Tk ;
use ExtUtils::testlib ; 
BEGIN { use_ok ('Tk::ObjScanner') ; };

my $trace = shift || 0 ;

SKIP: {
    if ($] >= 5.009) {
        plan skip "Pseudo hashes are obsolete",1;
    }

    # define a class using pseudo hashes
    package Bla;

    use fields qw(a b c);

    sub new {
        my $class = shift;
        no strict 'refs';
        my $self = bless [\%{"$class\::FIELDS"}], $class;
        $self;
    }

    sub new2 {
        my $class = shift;
        bless {}, $class;
    }

}

package main;

SKIP: {
    my $top = eval { MainWindow-> new ; };

    if ($] >= 5.009) {
        plan skip "Pseudo hashes are obsolete",1;
    }
    # cannot create Tk window
    if (not $top) {
        skip "Cannot create Tk window", 1 ;
    }

    $top->geometry('+10+10');

    my $x = [{}, 1, 2, 3];             # not a pseudo hash
    my $y = [{a => 3}, 3, 4, 2, 3, 4]; # not a pseudo hash
    my $y3 = [{a => 1, c => 3}, 3, 4]; # not a pseudo hash # check not correct
    my $y2 = [{a => 1, b => 2}, 3, 4]; # a possible pseudo hash
    my $z = [{a => "bcd"}, 3, 4, 2, 3, 4]; # also not a pseudo hash
    my $o = new Bla;                       # a pseudo hash
    $o->{a} = "a";
    $o->{b} = ["b", "d", $y2, $x, $y, $y3, $z];
    my $b2 = $o->{c} =  new Bla;
    $b2->{a} = "a2";
    $b2->{b} = "b23";


    my $s = $top->ObjScanner(caller => $o , -view_pseudo => 1);
    $s->pack;

    ok(1,"created pseudo hash");

    $top->idletasks;

    sub scan {
        my $topName = shift ;
        $s->yview($topName) ;
        $top->after(200);       # sleep 300ms

        foreach my $c ($s->infoChildren($topName)) {
            $s->displaySubItem($c);
            scan($c);
        }
        $top->idletasks;
    }

    if ($trace) {
        MainLoop ;              # Tk's
    }
    else {
        scan('root');
    }

}
done_testing;

