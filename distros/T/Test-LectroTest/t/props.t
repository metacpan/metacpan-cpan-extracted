#! perl

# the following tests exercise properties
# within the default LT harness


use Test::LectroTest trials => 10;

my $intgen = Int;

Property {
    ##[ ]##
    1;
}, name => "0-arg always succeeds" ;

Property {
    ##[ #]##
    1;
}, name => "0-arg, alt-syntax always succeeds" ;

Property {
    ##[ x <- $intgen ]##
    $tcon->label("negative") if $x < 0;
    $tcon->label("odd")      if $x % 2;
    1;
}, name => "1-arg always succeeds (labels, too)" ;

Property {
    ##[ 
        x <- $intgen
    #]##
    1;
}, name => "1-arg, alt-syntax always succeeds" ;

Property {
    ##[ 
        x <- $intgen
    # ]##
    1;
}, name => "1-arg, alt2-syntax always succeeds" ;

Property {
    ##[ 
        x <- $intgen
    ####]##
    1;
}, name => "1-arg, alt3-syntax always succeeds" ;

Property {
    ##[ 
        x <- $intgen
    #### ]##
    1;
}, name => "1-arg, alt4-syntax always succeeds" ;

Property {
    ##[ x <- Float, y <- Int ]##
    1;
}, name => "2-arg always succeeds" ;

Property {
    ##[ x <- Unit(1), a <- Unit(2), c <- Unit(3), y <-Unit(4) ]##
    $x == 1 && $a == 2 && $c == 3 && $y == 4;
}, name => "argument order is preserved";

Property {
    ##[ r <- Unit(1), a <- Unit(2), w <- Unit(3), t <-Unit(4) ]##
    $r == 1 && $a == 2 && $w == 3 && $t == 4;
}, name => "argument order is preserved (2)";

Property {
    ##[ f <- Float ]##
    $tcon->dump( $f, "f" ) == $f;
}, name => "tcon->dump returns its value arg as its result";
