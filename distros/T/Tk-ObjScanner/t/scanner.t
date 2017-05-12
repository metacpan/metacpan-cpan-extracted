# -*- cperl -*-

use warnings FATAL => qw(all);
use strict;
use ExtUtils::testlib;
use Test::More ;

use Tk ;

BEGIN { use_ok ('Tk::ObjScanner') ; };

my $trace = shift || 0 ;

my $data = { foo => 'bar', bar => 'baz' } ;
my $animate = $trace ? 0 : 1 ;

SKIP: {

    my $mw = eval { MainWindow-> new ; };

    # cannot create Tk window
    skip "Cannot create Tk window", 1 unless $mw;

    Tk::ObjScanner::scan_object($data,$animate, $mw) ;
    ok(1) ;
}

done_testing;
