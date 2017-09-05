use Test2::Bundle::Extended -target => 'Test2::Formatter::Stream';
use Test2::API qw/test2_stack intercept/;

use Test2::Harness::Util::File::JSONL;

use File::Temp qw/tempfile/;

test2_stack()->top;

my ($fh, $filename) = tempfile();
close($fh);

{
    local $SIG{__WARN__} = sub {};
    $CLASS->import($filename);
}

my $leaks = intercept {
    package Fake;
    use Test2::Tools::Tiny;

    use Data::Dumper;
    my $stack = Test2::API::test2_stack();
    my $hub = $stack->new_hub(formatter => $main::CLASS->new);

    my $ok = eval {
        ok(1, "pass");
        ok(2, "fail");
        note("Hi");
        diag("Bye");
        1;
    };
    my $err = $@;

    $stack->pop($hub);

    die $err unless $ok;
};

is($leaks, [], "No leaks");

$fh = Test2::Harness::Util::File::JSONL->new(name => $filename);

is(
    [$fh->read],
    [
        {
            '__FROM__'   => T(),
            stamp        => T(),
            assert_count => 1,
            facets       => {
                trace => {
                    tid      => 0,
                    buffered => 0,
                    frame    => [
                        'Fake',
                        't/Test2/Formatter/Stream.t',
                        27,
                        'Test2::Tools::Tiny::ok',
                    ],
                    pid    => $$,
                    cid    => 'C2',
                    nested => 0,
                    hid    => T()
                },
                assert => {
                    details => 'pass',
                    pass    => 1
                },
                about => {
                    package => 'Test2::Event::Pass',
                    details => 'pass'
                },
                control => {}
            },
        },
        {
            '__FROM__'   => T(),
            stamp        => T(),
            assert_count => 2,
            facets       => {
                assert => {
                    pass    => 1,
                    details => 'fail'
                },
                control => {},
                about   => {
                    details => 'pass',
                    package => 'Test2::Event::Pass'
                },
                trace => {
                    tid      => 0,
                    buffered => 0,
                    frame    => [
                        'Fake',
                        't/Test2/Formatter/Stream.t',
                        28,
                        'Test2::Tools::Tiny::ok',
                    ],
                    pid    => $$,
                    cid    => 'C3',
                    nested => 0,
                    hid    => T(),
                }
            },
        },
        {
            '__FROM__'   => T(),
            stamp        => T(),
            assert_count => 2,
            facets       => {
                control => {},
                about   => {package => 'Test2::Event::Note'},
                info    => [
                    {
                        debug   => 0,
                        details => 'Hi',
                        tag     => 'NOTE'
                    }
                ],
                trace => {
                    hid    => T(),
                    cid    => 'C4',
                    pid    => $$,
                    nested => 0,
                    frame  => [
                        'Fake',
                        't/Test2/Formatter/Stream.t',
                        29,
                        'Test2::Tools::Tiny::note'
                    ],
                    buffered => 0,
                    tid      => 0
                }
            }
        },
        {
            '__FROM__'   => T(),
            stamp        => T(),
            assert_count => 2,
            facets       => {
                about   => {package => 'Test2::Event::Diag'},
                control => {},
                trace   => {
                    tid      => 0,
                    buffered => 0,
                    frame    => [
                        'Fake',
                        't/Test2/Formatter/Stream.t',
                        30,
                        'Test2::Tools::Tiny::diag'
                    ],
                    nested => 0,
                    cid    => 'C5',
                    pid    => $$,
                    hid    => T(),
                },
                info => [
                    {
                        debug   => 1,
                        details => 'Bye',
                        tag     => 'DIAG'
                    }
                ]
            },
        }
    ],
    "Got the events"
);

unlink($filename);

done_testing;
