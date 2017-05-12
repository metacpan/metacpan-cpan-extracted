use strict;
use warnings;
use Test::More;
use Test::Mock::Recorder;

sub assert_mock {
    my ($double) = @_;

    my $obj1 = $double->replay;
    is($obj1->print('hello'), 1, 'replay');
    is($obj1->close, 2, 'replay');
    ok($double->verify($obj1), 'verified');

    eval {
        $double->verify_ok(
            sub {
                shift->close;
            }
        );
    };
    like(
        "$@",
        qr/^The first invocation of the mock should be "print" but called method was "close" /
    );

    eval {
        $double->verify_ok(
            sub {
                my $obj = shift;
                $obj->print('hello');
                $obj->close;
                $obj->print;
            }
        );
    };
    like(
        "$@",
        qr/^The third invocation of the mock is "print" but not expected /
    );
}

my $d1 = Test::Mock::Recorder->new;
$d1->expects('print')->returns(1);
$d1->expects('close')->returns(2);
assert_mock($d1);

# short-form
my $d2 = Test::Mock::Recorder->new;
$d2->expects(
    print => 1,
    close => 2,
);
assert_mock($d2);

done_testing;
