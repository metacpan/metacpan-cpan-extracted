use strict;
use warnings;

use lib qw(t/lib);

use Test::More;
use Test::Exception;
use Test::Deep;

use Test::Mock::One;
use Test::Mock::Two qw(:all);
use Test::Mock::Testsuite;
use DateTime;


{
    note "Called-By";

    my $mock = Test::Mock::One->new(
        'X-Mock-Called' => 1,
    );

    throws_ok(
        sub {

            my $object = bless({}, "Foo::Bar");
            one_called($object);
        },
        qr/We only play well with Test::Mock::One/,
        "Test::Mock::Two requires a Test::Mock::One object"
    );

    throws_ok(
        sub {
            one_called($mock);
        },
        qr/Failed to provide a method/,
        "We need a method name for one_called"
    );

    {
        my $warn;
        local $SIG{__WARN__} = sub {
            $warn = shift;
        };
        one_called($mock, 'foo', 'List::Util');
        like($warn, qr/Using Pkg::Name instead of Pkg::Name::Function/, "Fires a warning");
    }

    my $rv = one_called($mock, 'didnotcallme');
    is($rv, undef, "didnotcallme wasn't called");

    sub baz { $mock->foo(@_) };
    baz();
    baz('bar');
    baz(foo => 'bar');

    $rv = one_called($mock, 'foo', 'main::baz');
    ok($rv, "One called by main::baz");

    one_called_ok($mock, 'foo', 'main::baz');
    $rv = one_called_times_ok($mock, 'foo', 'main::baz', 3);

    cmp_deeply($rv->[0], [], 'First time called without arguments');
    cmp_deeply($rv->[1], ['bar'], '.. second with only bar');
    cmp_deeply($rv->[2], [ foo => 'bar' ], '.. third as foo => bar');

    {
        my $mock = Test::Mock::One->new(
            'X-Mock-Called' => 1,
        );

        my $pkg = Test::Mock::Testsuite->new(
            mock => $mock,
        );

        $pkg->bar();
        $pkg->bar('bar');
        $pkg->bar(foo => 'bar');

        my $rv = one_called($mock, 'foo', 'Test::Mock::Testsuite::bar');
        ok($rv, "One called by Test::Mock::Testsuite::bar");

        one_called_ok($mock, 'foo', 'Test::Mock::Testsuite::bar');
        $rv = one_called_times_ok($mock, 'foo', 'Test::Mock::Testsuite::bar', 3);

        cmp_deeply($rv->[0], [], 'First time called without arguments');
        cmp_deeply($rv->[1], ['bar'], '.. second with only bar');
        cmp_deeply($rv->[2], [ foo => 'bar' ], '.. third as foo => bar');

        $rv = one_called_times_ok($mock, 'foo', 'Test::Mock::Testsuite::foo', 0);
    }


}

done_testing();
