#!/usr/bin/perl -w

use Test::ManyParams;
use Test::More tests => 10;
use Test::Differences;
use Test::Exception;

use constant PARAMETER_SIZE => 10_000;
use constant PARAMETER_PART =>    100;

my (@params1, @params2, @params3);

{
    import Test::ManyParams seed => 42;
    most_ok { push @params1, shift(); 1 } 
            [1 .. PARAMETER_SIZE] => PARAMETER_PART, 
            "Initialization call";
    is $Test::ManyParams::seed, 42, "... seed => 42";
}

{
    import Test::ManyParams seed => 7;
    most_ok { push @params3, shift(); 1 } 
            [1 .. PARAMETER_SIZE] => PARAMETER_PART, 
            "Initialization call";
    is $Test::ManyParams::seed, 7, "... seed => 7";
}    

{
    import Test::ManyParams seed => 42;
    most_ok { push @params2, shift(); 1 } 
            [1 .. PARAMETER_SIZE] => PARAMETER_PART, 
            "Initialization call";
    is $Test::ManyParams::seed, 42, "... seed => 42";    
}

eq_or_diff   \@params1, \@params2,  "Same seeding should produce same parameters";
ok !eq_array(\@params1, \@params3), "Different seeding should produce different parameters";

dies_ok { import Test::ManyParams seed => "forty two"}
        "Seed => NotANumber";

my ($seed1, $seed2);

{
    import Test::ManyParams;
    $seed1 = $Test::ManyParams::seed;
}

sleep 2;

{
    import Test::ManyParams;
    $seed2 = $Test::ManyParams::seed;
}

isnt $seed1, $seed2, "Two seeds should be different";

#throws_ok {import Test::ManyParams; $Test::ManyParams::seed = 3}
#          qr/read ?only/i,
#          '$Test::ManyParams::seed should be a readonly variable';
