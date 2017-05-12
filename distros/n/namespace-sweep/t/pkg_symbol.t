#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 11;

package Blurns; {
    no strict;
    use namespace::sweep;
    use Scalar::Util 'reftype';

    $ball = 'fun';
    @loaded = ( 1, 2, 3 );
    %infield_blurn = ( in_effect => 1 );

    $reftype = 42;
    
    sub method { 
        1;
    }

    sub method2 { 
        return 'the infield blurn rule is ' 
          . ( $infield_blurn{in_effect} ? 'in effect' : 'not in effect' );
    }
}


package main;

my $o = bless { }, 'Blurns';

ok $o;
isa_ok $o, 'Blurns';

ok $o->method;
is $o->method2, 'the infield blurn rule is in effect';

is $Blurns::ball, 'fun';
ok @Blurns::loaded;
is $Blurns::loaded[0], 1;
ok %Blurns::infield_blurn;
ok $Blurns::infield_blurn{in_effect};

ok !$o->can( 'reftype' );
is $Blurns::reftype, 42;
