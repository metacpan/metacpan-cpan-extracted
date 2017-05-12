use strict;
use warnings;
use Test::More;

use_ok 'Test::Mock::Recorder';

subtest 'A' => sub {
    my $double = Test::Mock::Recorder->new;
    $double->expects(
        print => 1,
    );
    is($double->default_test_name, q{called 'print'});
    done_testing;
};

subtest 'A and B' => sub {
    my $double = Test::Mock::Recorder->new;
    $double->expects(
        print => 1,
        close => 1,
    );
    is($double->default_test_name, q{called 'print' and 'close'});
    done_testing;
};

subtest 'A, B and C' => sub {
    my $double = Test::Mock::Recorder->new;
    $double->expects(
        print => 1,
        print => 1,
        close => 1,
    );
    is($double->default_test_name, q{called 'print', 'print' and 'close'});
    done_testing;
};

done_testing;
