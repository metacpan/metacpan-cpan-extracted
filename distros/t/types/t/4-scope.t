
use strict;
use Test::More tests => 4;

{ 
    use types;
    eval 'my int $int = 1.5';
    like($@, qr/can\'t sassign float \(constant \'1.5\'\) to int/, "use types is in effect");
    { 
	no types;
	eval 'my int $int = 1.5';
	is($@, "", "no types should be in effect");
    }
}

sub foo {
    use types;
    return "string";
}

my int $test = foo();
is($test, "string", "no type checking");
{
    use types;
    eval ' my int $int = foo()';
    like($@, qr/can\'t sassign string \(main::foo\(\)\) to int/, "Now type checking is on!");
    
}


