use strict;
use warnings;
use utf8;
use Test::More;
use ThaiSchema::JSON;
use ThaiSchema;
use Data::Dumper;

BEGIN { *describe = *context = *it = *Test::More::subtest }

describe 'ThaiSchema::JSON#new' => sub {
    my $j = ThaiSchema::JSON->new();
    it 'creates new object' => sub {
        isa_ok($j, 'ThaiSchema::JSON');
    };
};

describe 'ThaiSchema::JSON#validate' => sub {
    context 'validate simple array' => sub {
        it 'can detects no error' => sub {
            ok validate('[]', type_array());
        };
        it 'can detects error' => sub {
            ok !validate('[]', type_hash({}));
        };
    };
    context 'validate simple hash' => sub {
        it 'can detects no error' => sub {
            ok validate('{}', type_hash({}));
        };
        it 'can detects error' => sub {
            ok !validate('{}', type_array());
        };
    };
    context 'validate number in array' => sub {
        it 'can detects no error' => sub {
            ok validate('[1]', type_array(type_int()));
        };
        it 'can detects error' => sub {
            ok !validate('[true]', type_array(type_int()));
            ok !validate('[[]]', type_array(type_int()));
            ok !validate('[{}]', type_array(type_int()));
            ok !validate('[""]', type_array(type_int()));
            ok !validate('[null]', type_array(type_int()));
            ok !validate('[false]', type_array(type_int()));
        };
    };
    context 'validate number in array in array' => sub {
        it 'can detects no error' => sub {
            ok validate('[[1]]', type_array(type_array(type_int())));
        };
        it 'can detects error' => sub {
            ok !validate('[[true]]', type_array(type_array(type_int())));
        };
    };
    context 'validate boolean in array' => sub {
        it 'can detects no error' => sub {
            ok validate('[true]', type_array(type_bool()));
            ok validate('[false]', type_array(type_bool()));
        };
        it 'can detects error' => sub {
            ok !validate('[[]]', type_array(type_bool()));
            ok !validate('[{}]', type_array(type_bool()));
            ok !validate('[""]', type_array(type_bool()));
            ok !validate('[3]', type_array(type_bool()));
            ok !validate('[null]', type_array(type_bool()));
        };
    };
    context 'validate int in object' => sub {
        it 'can detects no error' => sub {
            ok validate('{"x":3}', type_hash({x => type_int}));
        };
        it 'can detects error' => sub {
            ok !validate('{"x":"y"}', type_hash({x => type_int}));
            ok !validate('{"x":{}}', type_hash({x => type_int}));
        };
    };
    context 'validate object in object' => sub {
        it 'can detects no error' => sub {
            ok validate('{"x":{"y":true}}', type_hash({x => type_hash({ y => type_bool })}));
        };
        it 'can detects error' => sub {
            ok !validate('{"x":{"y":4}}', type_hash({x => type_hash({ y => type_bool })}));
        };
    };
    context 'validate extra keys in object' => sub {
        context 'allow extra' => sub {
            local $ThaiSchema::ALLOW_EXTRA = 1;
            ok validate('{"x":1,"y":3}', type_hash({x => type_int}));
            ok validate('{"x":1,"y":[true]}', type_hash({x => type_int}));
            ok validate('{"x":1,"y":[[true]]}', type_hash({x => type_int}));
            ok validate('{"x":1,"y":{"P":"Q"}}', type_hash({x => type_int}));
        };
        context 'not allow extra' => sub {
            local $ThaiSchema::ALLOW_EXTRA = 0;
            ok !validate('{"x":1,"y":3}', type_hash({x => type_int}));
        };
    };
    context 'missing key' => sub {
        ok !validate('{}', type_hash({x => type_int}));
    };
    context 'allow raw hashref' => sub {
        ok validate('{"x":1}', {x => type_int});
    };
    context 'allow raw arrayref' => sub {
        ok validate('{"x":[]}', {x => []});
    };
    context 'allow raw hashref in arrayref' => sub {
        ok validate('{"x":[{"foo":"bar"}]}', {x => [{foo => type_str()}]});
    };
    context 'validate int' => sub {
        it 'can detects no error' => sub {
            ok validate('[5963]', type_array(type_int()));
        };
        it 'can detects error' => sub {
            ok !validate('[3.14]', type_array(type_int()));
        };
    };
    context 'maybe' => sub {
        context 'matched' => sub {
            it 'can detects no error' => sub {
                ok validate('{"x":4}', {x => type_maybe(type_int)});
            };
            it 'allows null' => sub {
                ok validate('{"x":null}', {x => type_maybe(type_int)});
            };
            it 'fails on error' => sub {
                ok !validate('{"x":"agg"}', {x => type_maybe(type_int)});
            };
        };
    };
};

done_testing;

sub validate {
    my ($json, $schema) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $j = ThaiSchema::JSON->new();
    my ($ok, $errors) = $j->validate($json, $schema);
    if ($errors && @$errors) {
        note Dumper($errors);
    }
    return $ok;
}

