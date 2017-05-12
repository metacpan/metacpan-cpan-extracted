use strict;
use warnings;
use utf8;
use Test::More;
use ThaiSchema;
use Data::Dumper;

BEGIN { *describe = *context = *it = *Test::More::subtest }

describe 'match_schema' => sub {
    context 'no error' => sub {
        my ($ok, $errors) = match_schema({x => 1}, {x => type_int});
        it 'have no error' => sub {
            ok($ok);
            is_deeply($errors, []);
        };
    };
    context 'have one error in hash element' => sub {
        my ($ok, $errors) = match_schema({x => 'hoge'}, {x => type_int});
        it 'have no error' => sub {
            ok(not $ok);
            is_deeply($errors, ['x is not int']) or diag Dumper($errors);
        };
    };
    context 'have one error in deep hash element' => sub {
        my ($ok, $errors) = match_schema({x => { y => 'hoge'}}, {x => {y => type_int}});
        it 'have no error' => sub {
            ok(not $ok);
            is_deeply($errors, ['x.y is not int']) or diag Dumper($errors);
        };
    };
    context 'have one error in array' => sub {
        my ($ok, $errors) = match_schema(['x'], type_array(type_int));
        it 'have no error' => sub {
            ok(not $ok);
            is_deeply($errors, ['[0] is not int']) or diag Dumper($errors);
        };
    };
    context 'have one error in array, hash' => sub {
        my ($ok, $errors) = match_schema([{x => 'hoge'}], type_array({ x => type_int}));
        it 'have no error' => sub {
            ok(not $ok);
            is_deeply($errors, ['[0].x is not int']) or diag Dumper($errors);
        };
    };
};

done_testing;

