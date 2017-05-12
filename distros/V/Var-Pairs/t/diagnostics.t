use 5.014;
use strict;
use Test::More tests => 6;

use Var::Pairs;

subtest 'pairs() expects hash or array' => sub {
    ok !eval{ my @pairs = pairs sub{} } => 'Failed when given bad ref';
    like $@, qr/Argument to pairs\(\) must be array or hash \(not code\)/
        => 'Correct error message';
};

subtest 'pairs expects a containers, not a scalar' => sub {
    ok !eval{ my @pairs = pairs 'string' } => 'Failed when given non-container';
    like $@, qr/Argument to pairs\(\) must be array or hash \(not scalar value\)/
        => 'Correct error message';
};

subtest "Pairs don't numerify when value is number" => sub {
    my @pairs = pairs { a=>1, b=>2, c=>3};

    ok !eval{ 0 + $pairs[0] } => 'Failed when numerifying pair';
    like $@, qr/Can't convert Pair\([abc] => [123]\) to a number/
        => 'Correct error message';
};

subtest "Pairs don't numerify when value is string" => sub {
    my @pairs = pairs { a=>'x', b=>'y', c=>'z'};

    ok !eval{ 0 + $pairs[0] } => 'Failed when numerifying pair';
    like $@, qr/Can't convert Pair\([abc] => "[xyz]"\) to a number/
        => 'Correct error message';
};

subtest "Pairs don't numerify when value is ref" => sub {
    my @pairs = pairs { a=>['x','y'], b=>['x','y'], c=>['x','y']};

    ok !eval{ 0 + $pairs[0] } => 'Failed when numerifying pair';
    like $@, qr/Can't convert Pair\([abc] => ARRAY\) to a number/
        => 'Correct error message';
};

subtest "Can't call pairs in non-list contexts" => sub {
    my $pairs = eval{ pairs { a=>['x','y'], b=>['x','y'], c=>['x','y']} };

    like $@, qr/Invalid call to pairs\(\) in scalar context/
        => 'Correct error message in scalar context';

    eval{ pairs [1..10] };

    like $@, qr/Useless use of pairs\(\) in void context/
        => 'Correct error message in void context';
};

