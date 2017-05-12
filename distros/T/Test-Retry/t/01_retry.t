use strict;
use warnings;
use Test::More;
use Test::Retry max => 3, delay => 0.1;

my $x = 0;

retry_test {
    is $x++, 2, '$x++ == 2';
};

my ($passing, $out, $failure_out) = do {
    my ($out, $failure_out) = ('', '');

    local $Test::Builder::Test = do {
        my $builder = Test::Builder->create;
           $builder->output(\$out);
           $builder->failure_output(\$failure_out);
        $builder;
    };

    subtest 'fails' => sub {
        retry_test {
            is 'a', 'b', 'a eq b';
        };

        my $y = 0;

        retry_test {
            is $y++, 3, '$y++ == 3';
        };
    };

    ( Test::More->builder->is_passing, $out, $failure_out );
};

ok !$passing, 'expectedly fails';
$out =~ s/^\s*#.*\n//g;
is $out, <<'TAP';
    not ok 1 - a eq b
    not ok 2 - $y++ == 3
    1..2
not ok 1 - fails
TAP

done_testing;
