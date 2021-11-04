use Test2::Plugin::Cover;
use Test2::V0 -target => 'Test2::Plugin::Cover';
use Path::Tiny qw/path/;
use File::Spec();

$CLASS->reset_coverage;
$CLASS->touch_data_file('aaa.json');
$CLASS->touch_source_file('bbb.pl');
$CLASS->touch_source_file('ccc.pl', 'foo');

$CLASS->set_from('xxx');
$CLASS->touch_data_file('ddd.yaml');
$CLASS->touch_source_file('eee.pl');
$CLASS->touch_source_file('fff.pl', 'bar');

$CLASS->set_from(['yyy']);
$CLASS->touch_data_file('ggg.yaml');
$CLASS->touch_source_file('hhh.pl');
$CLASS->touch_source_file('iii.pl', [qw/foo bar baz/]);

my $data = $CLASS->files(root => path('.'));
like(
    [ sort grep { !m/\.pm$/ } @$data ],
    array {
        item 'aaa.json';
        item 'bbb.pl';
        item 'ccc.pl';
        item 'ddd.yaml';
        item 'eee.pl';
        item 'fff.pl';
        item 'ggg.yaml';
        item 'hhh.pl';
        item 'iii.pl';
    },
    "Got touched files",
);

$data = $CLASS->data(root => path('.'));

is(
    $data,
    {
        'aaa.json' => {'<>'  => ['*']},
        'bbb.pl'   => {'*'   => ['*']},
        'ccc.pl'   => {'foo' => ['*']},

        'ddd.yaml' => {'<>'  => ['xxx']},
        'eee.pl'   => {'*'   => ['xxx']},
        'fff.pl'   => {'bar' => ['xxx']},

        'ggg.yaml' => {'<>' => [['yyy']]},
        'hhh.pl'   => {'*'  => [['yyy']]},
        'iii.pl'   => {
            'foo' => [['yyy']],
            'bar' => [['yyy']],
            'baz' => [['yyy']],
        },
    },
    "Got correct file data",
);

$CLASS->reset_coverage;

done_testing;
