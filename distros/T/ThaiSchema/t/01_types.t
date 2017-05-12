use strict;
use warnings;
use utf8;
use Test::More;
use ThaiSchema;
use JSON ();

BEGIN { *describe = *context = *it = *Test::More::subtest }

sub strict_context(&) {
    local $ThaiSchema::STRICT = 1;
    $_[0]->();
}
sub normal_context(&) {
    local $ThaiSchema::STRICT = 0;
    $_[0]->();
}

describe 'int' => sub {
    normal_context {
        ok(type_int()->match(1));
        ok(type_int()->match(0), 'zero');
        ok(type_int()->match('1'));
        ok(!type_int()->match(3.14));
        ok(!type_int()->match('hoge'), 'hoge');
    };
    strict_context {
        ok(type_int()->match(1));
        ok(type_int()->match(0), 'zero');
        ok(!type_int()->match(3.14));
        ok(!type_int()->match('1'));
        ok(!type_int()->match('hoge'));
    };
};

describe 'str' => sub {
    normal_context {
        ok(type_str()->match(1));
        ok(type_str()->match(3.14));
        ok(type_str()->match('1'));
        ok(type_str()->match('hoge'));
    };
    strict_context {
        ok(!type_str()->match(1));
        ok(!type_str()->match(3.14));
        ok(type_str()->match('1'));
        ok(type_str()->match('hoge'));
    };
};

describe 'type_number' => sub {
    normal_context {
        ok(type_number()->match(1));
        ok(type_number()->match('1'));
        ok(type_number()->match(3.14));
        ok(type_number()->match('3.14'));
        ok(!type_number()->match('hoge'));
    };
    strict_context {
        ok(type_number()->match(1));
        ok(type_number()->match(3.14));
        ok(!type_number()->match('3.14'));
        ok(!type_number()->match('1'));
        ok(!type_number()->match('hoge'));
    };
};

describe 'type_hash' => sub {
    normal_context {
        ok(type_hash({})->match({}));
        ok(!type_hash({})->match(1));
        ok(type_hash({x => type_str})->match({x => 'hoge'}));
        it 'does not allow extra' => sub {
            ok(!type_hash({x => type_str})->match({x => 'hoge', y => 'fuga'}));
        };
        it 'can allow extra, optionally' => sub {
            local $ThaiSchema::ALLOW_EXTRA = 1;
            ok(type_hash({x => type_str})->match({x => 'hoge', y => 'fuga'}));
        };
        it 'can use complex data' => sub {
            ok(type_hash({x => { y => type_str}})->match({x => {y => 'fuga'}}));
        };
        it 'can detects missing key' => sub {
            ok(!type_hash({x => type_int})->match({}));
        };
    };
};

describe 'type_array' => sub {
    normal_context {
        ok(type_array()->match([]));
        ok(!type_array()->match({}));
    };
};

describe 'type_bool' => sub {
    normal_context {
        ok(type_bool()->match(JSON::true()));
        ok(type_bool()->match(JSON::false()));
        ok(type_bool()->match(\1));
        ok(type_bool()->match(\0));
        ok(!type_bool()->match(\"hoge"));
        ok(!type_bool()->match('hoge'));
    };
};

done_testing;

