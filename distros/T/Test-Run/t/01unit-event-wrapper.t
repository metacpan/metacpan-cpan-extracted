use strict;
use warnings;

use Test::More tests => 6;

use Test::Run::Straps::EventWrapper;
use TAP::Parser;
use File::Spec;

my $simple_file = File::Spec->catfile(File::Spec->curdir(), "t", "sample-tests", "simple");
my $simple_fail_file = File::Spec->catfile(File::Spec->curdir(), "t", "sample-tests", "simple_fail");

{
    my $parser = TAP::Parser->new({source => $simple_file});

    my $event = Test::Run::Straps::EventWrapper->new({event => $parser->next()});

    # TEST
    ok (scalar($event->is_pass()),
        "is_pass returns true in scalar context for a plan event"
    );

    my @list = $event->is_pass();

    # TEST
    is_deeply(\@list, [1],
        "is_pass returns a list containing true in list context"
    );

    $event = Test::Run::Straps::EventWrapper->new({event => $parser->next()});

    # TEST
    ok (scalar($event->is_pass()),
        "is_pass returns true in scalar context for an ok event"
    );

    @list = $event->is_pass();

    # TEST
    is_deeply(\@list, [1],
        "is_pass returns a list containing true in list context"
    );
}

{
    my $parser = TAP::Parser->new({source => $simple_fail_file});

    # Skip to the third event - the "not ok".
    $parser->next();
    $parser->next();

    my $event = Test::Run::Straps::EventWrapper->new({event => $parser->next()});

    # TEST
    ok (! scalar($event->is_pass()),
        "is_pass returns true in scalar context for an ok event"
    );

    my @list = $event->is_pass();

    # TEST
    is_deeply(\@list, [0],
        "is_pass returns a list containing 0 in list context"
    );
}
