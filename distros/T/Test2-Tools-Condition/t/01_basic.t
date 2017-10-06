use Test2::V0;
use Test2::Tools::Condition;

use Test2::Util::Table ();

sub table { join "\n" => Test2::Util::Table::table(@_) }

is 1, condition { $_ > 0 }, '1 > 0';
isnt 0, condition { $_ > 0 }, '!(0 > 0)';
is 0, !condition { $_ > 0 }, 'negatable';
is 3, condition { 2 < $_ && $_ < 4 }, '2 < x < 4';

is undef, condition { not defined }, 'is not undef';
is undef, !condition { defined }, '!(is undef)';

is [1,2,3], condition { scalar @$_ == 3 && $_->[0] == 1 }, 'check arrayref';
like {a => 1, b => 1}, {
    a => condition { $_ > 0 },
}, 'condition in data structure';

my $check = check_set(match qr/^a/, condition { length == 3 });
is 'abc', $check, '/^a/ and length == 3';
isnt 'cba', $check, 'unsatisfy /^a/';
isnt 'abcabc', $check, 'unsatisfy length == 3';

is intercept {
    is 0, condition { $_ > 0 };
}, array {
    event Ok => { pass => 0 };
    event Diag => {
        message => match qr{^\n?Failed test},
    };
    event Diag => {
        message => table(
            header => [qw/GOT OP CHECK LNs/],
            rows   => [
                ['<FALSE (0)>', '==', '<CONDITION>', '27'],
            ],
        ),
    };
};

is intercept {
    is 1, !condition { $_ > 0 };
}, array {
    event Ok => { pass => 0 };
    event Diag => {
        message => match qr{^\n?Failed test},
    };
    event Diag => {
        message => table(
            header => [qw/GOT OP CHECK LNs/],
            rows   => [
                ['<TRUE (1)>', '!=', '<CONDITION>', '44'],
            ],
        ),
    };
};

done_testing;
