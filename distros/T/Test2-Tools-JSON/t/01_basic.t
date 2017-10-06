use Test2::V0;
use Test2::Tools::JSON;

use Test2::Util::Table ();
use Test2::Compare::Custom;

sub table { join "\n" => Test2::Util::Table::table(@_) }

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
    is intercept {
        is {
            json => '{"a":1}',
        }, {
            json => json($hash)
        };
    }, array {
        event Ok   => { pass => 0 };
        event Diag => {
            message => match qr{^\n?Failed test},
        };
        event Diag => {
            message => table(
                header => [qw/PATH GOT OP CHECK LNs/],
                rows   => [
                    ['{json}', '{"a":1}', 'JSON', "$hash", '28'],
                    ['{json} <JSON>->{a}', '1', 'eq', '2'],
                ],
            ),
        };
    };
};

subtest 'JSON cmp failure (expect Test2::Compare object)' => sub {
    is intercept {
        like {
            json => '{"a":1}',
        }, {
            json => { x => E },
        };
    }, array {
        event Ok   => { pass => 0 };
        event Diag => {
            message => match qr{^\n?Failed test},
        };
        event Diag => {
            message => table(
                header => [qw/PATH GOT CHECK/],
                rows   => [
                    ['{json}', '{"a":1}', '<HASH>'],
                ],
            ),
        };
    };
};

subtest 'JSON parse error' => sub {
    is intercept {
        is {
            json => '{ invalid json }',
        }, {
            json => {},
        };
    }, array {
        event Ok   => { pass => 0 };
        event Diag => {
            message => match qr{^\n?Failed test},
        };
        event Diag => {
            message => table(
                header => [qw/PATH GOT CHECK/],
                rows   => [
                    ['{json}', '{ invalid json }', '<HASH>'],
                ],
            ),
        };
    };
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

    like intercept {
        is {
            json => '{"foo":"X"}',
        }, {
            json => json($cus),
        };
    }, array {
        event Ok => { pass => 0 };
    };
};

done_testing;
