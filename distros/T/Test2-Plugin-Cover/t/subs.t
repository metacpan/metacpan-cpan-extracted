use Test2::Plugin::Cover;
use Test2::V0 -target => 'Test2::Plugin::Cover';
use Path::Tiny qw/path/;
use File::Spec();

BEGIN { unshift @INC => 't/lib' }

use Fake1;
use Fake2;

subtest simple_coverage => sub {
    # Start fresh
    $CLASS->reset_coverage;

    Fake1->fake;
    Fake2->fake;

    $CLASS->set_from('simple_coverage');
    Fake1->fake;
    Fake1->fake;
    Fake2->fake;
    Fake2->fake;

    $CLASS->set_from('simple_coverage_x');
    Fake1->fake;
    Fake1->fake;
    Fake2->fake;
    Fake2->fake;
    $CLASS->clear_from;

    Fake1->fake;
    Fake2->fake;

    # This is just to add another sub call we want filtered
    path('.');

    is(
        $CLASS->files(root => path('t/lib')),
        [
            'Fake1.pm',
            'Fake2.pm',
        ],
        "Got just the 2 files under the specified dir"
    );

    is(
        $CLASS->submap(root => path('t/lib')),
        {
            'Fake1.pm' => {
                'fake' => ['*', 'simple_coverage', 'simple_coverage_x'],
            },
            'Fake2.pm' => {
                'fake' => ['*', 'simple_coverage', 'simple_coverage_x'],
            },
        },
        "Got expected submap"
    );

    $CLASS->reset_coverage;

    is(
        $CLASS->files(root => path('t/lib')),
        [],
        "Cleared files"
    );

    is(
        $CLASS->submap(root => path('t/lib')),
        {},
        "Cleared submap",
    );
};

subtest goto_and_lvalue => sub {
    $CLASS->reset_coverage;
    Fake1->gfake;
    is($CLASS->files(root => path('t/lib')), ['Fake1.pm'], "Found with a goto");

    $CLASS->reset_coverage;
    Fake1->lfake = 'xxx';
    is($CLASS->files(root => path('t/lib')), ['Fake1.pm'], "Found with an lvalue");
};

$CLASS->reset_coverage;

done_testing;
