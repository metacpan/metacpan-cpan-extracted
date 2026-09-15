use Test2::Plugin::Cover ();
use Test2::V0 -target => 'Test2::Plugin::Cover';
use Test2::API qw/intercept/;
use Path::Tiny qw/path/;

$CLASS->enable;
$CLASS->full_reset;

$CLASS->touch_source_file('rrr.pl', 'some_sub');
$CLASS->touch_data_file('rrr.json');

my $events = intercept { $CLASS->report(root => path('.')->realpath) };
my ($ev) = grep { $_->facet_data->{coverage} } @$events;
ok($ev, "got a coverage event") or done_testing, exit 0;

my $fd = $ev->facet_data;

like(
    $fd,
    {
        about => {details => qr/covered \d+ source files/},

        coverage => {
            root         => path('.')->realpath->stringify,
            test_type    => 'flat',
            from_manager => undef,
            details      => qr/covered \d+ source files/,

            files => {
                'rrr.pl'   => {some_sub => ['*']},
                'rrr.json' => {'<>' => ['*']},
            },
        },

        info => [{tag => 'COVERAGE', details => qr/covered \d+ source files/}],
    },
    "flat report event has the expected structure"
);

# Now with from data and a manager, the report becomes a 'split' report.
$CLASS->full_reset;
$CLASS->set_from('block_a');
$CLASS->touch_source_file('sss.pl');
$CLASS->set_from_manager('My::Manager');

$events = intercept { $CLASS->report(root => path('.')->realpath) };
($ev) = grep { $_->facet_data->{coverage} } @$events;
ok($ev, "got a second coverage event");

like(
    $ev->facet_data->{coverage},
    {
        root         => path('.')->realpath->stringify,
        test_type    => 'split',
        from_manager => 'My::Manager',

        files => {
            'sss.pl' => {'*' => ['block_a']},
        },
    },
    "split report event includes from data and manager"
);

$CLASS->full_reset;

# The root travels with the event, resolved the same way the file list was.
{
    my $tmp  = Path::Tiny->tempdir;
    my $real = $tmp->child('real');
    $real->mkpath;
    $real->child('ttt.pl')->spew("1;\n");

    $CLASS->full_reset;
    $CLASS->touch_source_file($real->child('ttt.pl')->stringify);

    $events = intercept { $CLASS->report(root => "$real") };
    ($ev) = grep { $_->facet_data->{coverage} } @$events;

    like(
        $ev->facet_data->{coverage},
        {
            root  => $real->realpath->stringify,
            files => {'ttt.pl' => {'*' => ['*']}},
        },
        "coverage event names the root its file list is relative to"
    );
}

done_testing;
