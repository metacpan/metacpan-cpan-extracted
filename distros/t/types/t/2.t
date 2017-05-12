package bar;
use Test::More tests => 20;
BEGIN { use_ok('types') };
use types;
my int $int;
my float $float;
eval '$int = $float;';
like($@, qr/Type mismatch, can't sassign float \(\$float\) to int \(\$int\)/, "Check that we get type mismatch");
package foo;
{
    no types;
    eval '$int = $float;';
    use Test::More;
    is($@,"", "no type checking for this lexical scope");
}
package bar;
eval '$int = $float;';
is($@, 'Type mismatch, can\'t sassign float ($float) to int ($int) at (eval 8):1'."\n", "Check that we get type mismatch");
eval '$int = $float = $int;';
is($@, "Type mismatch, can't sassign float (\$float) to int (\$int) at (eval 10):1\n", "Workes nested aswell");

{
    my int $int = 1;
    eval '$int = 1.2';
    like($@, qr/sassign float \(constant '1.2'\) to int \(\$int\)/, "Can't sassign float constant to integer" );
    eval '$int = "hi"';
    like($@, qr/sassign string \(constant 'hi'\) to int \(\$int\)/, "Can't sassign string to integer" );
    my float $float = 2.3;
    eval '$float = 5';
    is($@, "", "Can assign integer constant to float");
    eval '$float = "hi"';
    like($@, qr/assign string \(constant 'hi'\) to float \(\$float\)/, "Can't assign string to float" );
    my number $number = 2;
    is($number, 2, "Number can be int (constant)");
    $number = 2.5;
    is($number, 2.5, "Number can be float (constant)");
    $number = $int;
    is($number, 1, "Number can be int");
    $number = $float;
    is($number, 5, "Number can float");
    eval '$number = "hi"';
    like($@, qr/assign string \(constant 'hi'\) to number \(\$number\)/, "Can't assign string to number" );
    
    my string $string = "hi";
    $string = $int;
    is($string, 1, "Int can be assigned to string");
    $string = 20;
    is($string, 20, "Constant int can be assigned to string");
    $string = $float;
    is($string, 5, "Float can be assigned to string");
    $string = 5.5;
    is($string, 5.5, "Constant float can be assigned to string");
    $string = $number;
    is($string, 5, "Number can be assigned to string");
    my $foo = 1;
    $foo = 2.2;
    $foo = "hi";
    pass("Untyped lexicals can still access constant");
}

