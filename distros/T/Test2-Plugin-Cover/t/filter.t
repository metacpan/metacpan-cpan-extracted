use Test2::Plugin::Cover ();
use Test2::V0 -target => 'Test2::Plugin::Cover';
use Path::Tiny qw/path/;

$CLASS->enable;
$CLASS->reset_coverage;

my $abs_root = path('.')->realpath;

$CLASS->touch_source_file('str_root.pl');

is(
    [grep { $_ eq 'str_root.pl' } @{$CLASS->files(root => $abs_root->stringify)}],
    ['str_root.pl'],
    "plain string root works"
);

is(
    [grep { $_ eq 'str_root.pl' } @{$CLASS->files(root => $abs_root)}],
    ['str_root.pl'],
    "Path::Tiny root works"
);

is($CLASS->filter('str_root.pl', root => "$abs_root"), 'str_root.pl', "filter accepts a string root directly");

is(
    $CLASS->filter($abs_root->child('str_root.pl')->stringify, root => $abs_root),
    'str_root.pl',
    "absolute path under root is relativized"
);

is(
    [$CLASS->filter('/no/such/other/place.pl', root => $abs_root)],
    [],
    "file outside root is filtered out"
);

SKIP: {
    skip "symlinks not available on this platform", 1 unless eval { symlink("", ""); 1 };

    my $tmp  = Path::Tiny->tempdir;
    my $real = $tmp->child('real');
    $real->mkpath;
    $real->child('mod.pl')->spew("1;\n");

    my $link = $tmp->child('link');
    skip "could not create symlink", 1 unless symlink("$real", "$link");

    is(
        $CLASS->filter($link->child('mod.pl')->stringify, root => "$link"),
        'mod.pl',
        "file seen through a symlinked root resolves consistently"
    );
}

$CLASS->reset_coverage;

done_testing;
