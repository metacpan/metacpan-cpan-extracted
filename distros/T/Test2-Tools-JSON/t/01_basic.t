use Test2::V0;
use Test2::Tools::JSON;

use Test2::Compare::Custom;

is {
    foo  => 'bar',
    json => '{"a":1}',
}, {
    foo  => 'bar',
    json => json({ a => E }),
};

is {
    foo  => 'bar',
    json => '{"a":1}',
}, hash {
    field json => json({ a => 1 });
    etc;
};

subtest 'JSON cmp failure (expect raw hash)' => sub {
    my $hash = {a => 2};
    like intercept {
        is {
            json => '{"a":1}',
        }, {
            json => json($hash)
        };
    }, [
        event Fail => {
            info => [{
                table => {
                    header => [qw/PATH LNs GOT OP CHECK LNs/],
                    rows   => [
                        ['{json}', '', '{"a":1}', 'JSON', "$hash", '25'],
                        ['{json} <JSON>->{a}', '', '1', 'eq', '2'],
                    ],
                },
            }],
        },
    ];
};

subtest 'JSON cmp failure (expect Test2::Compare object)' => sub {
    like intercept {
        like {
            json => '{"a":1}',
        }, {
            json => { x => E },
        };
    }, [
        event Fail => {
            info => [{
                table => {
                    header => [qw/PATH LNs GOT OP CHECK LNs/],
                    rows   => [
                        ['{json}', '', '{"a":1}', '', '<HASH>'],
                    ],
                },
            }],
        },
    ];
};

subtest 'JSON parse error' => sub {
    like intercept {
        is {
            json => '{ invalid json }',
        }, {
            json => {},
        };
    }, [
        event Fail => {
            info => [{
                table => {
                    header => [qw/PATH LNs GOT OP CHECK LNs/],
                    rows   => [
                        ['{json}', '', '{ invalid json }', '', '<HASH>'],
                    ],
                },
            }],
        },
    ];
};

subtest 'failture on nested' => sub {
    my $cus = Test2::Compare::Custom->new(
        name => 'foo should be Y',
        code => sub {
            my %params = @_;
            my ($got) = @params{qw/got/};
            return $got->{foo} eq 'Y';
        },
    );

    is intercept {
        is {
            json => '{"foo":"X"}',
        }, {
            json => json($cus),
        };
    }, array {
        event 'Fail';
    };
};

subtest 'utf8' => sub {
    require Encode;

    is {
        json => Encode::encode_utf8('{"a":"あ"}'),
    }, {
        json => json({ 'a' => 'あ' }),
    };
};

done_testing;
