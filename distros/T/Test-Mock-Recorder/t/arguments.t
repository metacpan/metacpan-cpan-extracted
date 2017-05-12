use strict;
use warnings;
use Test::More;

use_ok 'Test::Mock::Recorder';

{
    my $double = Test::Mock::Recorder->new;
    $double->expects('print')->with('hello world');

    $double->replay(
        sub {
            shift->print('hello world');
        }
    );

    $double->replay(
        sub {
            eval {
                shift->print('hello foobar');
            };
            like(
                "$@",
                qr/Called "print" with invalid arguments at the first invocation of the mock /
            );
        }
    );
};

{
    my $double = Test::Mock::Recorder->new;
    $double->expects('close')->without_arguments;

    $double->verify_ok(
        sub { shift->close }
    );

    my $io = $double->replay;
    eval {
        $io->close('foobar');
    };
    ok($@, 'without_arguments');
};


{
    my $double = Test::Mock::Recorder->new;
    $double->expects('print')->code(
        sub { like($_[1], qr/^hello /) }
    );

    my $io = $double->replay;
    $io->print('hello foobar');
    ok($double->verify($io));
};

done_testing;
