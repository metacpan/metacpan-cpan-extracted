use Test2::Plugin::Cover ();
use Test2::V0 -target => 'Test2::Plugin::Cover';
use Path::Tiny qw/path/;

$CLASS->enable;
$CLASS->reset_coverage;

my $tmp  = Path::Tiny->tempdir;
my $root = $tmp->child('root');
$root->mkpath;
$root = $root->realpath;

$root->child('lib')->mkpath;
$root->child('library')->mkpath;
$root->child('deps/nested/deep')->mkpath;

my $keep    = $root->child('lib/Keep.pm');
my $sibling = $root->child('library/Sibling.pm');
my $dep     = $root->child('deps/Dep.pm');
my $deep    = $root->child('deps/nested/deep/Deep.pm');
my $data    = $root->child('deps/data.json');
$_->spew("1;\n") for $keep, $sibling, $dep, $deep;
$data->spew("{}\n");

my $deps = $root->child('deps');

subtest no_exclusions => sub {
    is($CLASS->filter("$keep", root => $root), 'lib/Keep.pm', "file under the root is kept");
    is($CLASS->filter("$dep",  root => $root), 'deps/Dep.pm', "nothing is excluded without the option");
};

subtest excluded_tree => sub {
    is([$CLASS->filter("$dep", root => $root, exclude => "$deps")], [], "file directly under an excluded root is dropped");
    is([$CLASS->filter("$deep", root => $root, exclude => "$deps")], [], "file nested deeper under an excluded root is dropped");
    is([$CLASS->filter("$deps", root => $root, exclude => "$deps")], [], "the excluded root itself is dropped");

    is($CLASS->filter("$keep", root => $root, exclude => "$deps"), 'lib/Keep.pm', "unrelated file is still kept");
};

subtest similar_sibling => sub {
    my $lib = $root->child('lib');

    is([$CLASS->filter("$keep", root => $root, exclude => "$lib")], [], "file under the excluded directory is dropped");

    is(
        $CLASS->filter("$sibling", root => $root, exclude => "$lib"),
        'library/Sibling.pm',
        "a sibling whose name starts with the excluded name is kept"
    );
};

subtest path_forms => sub {
    is(
        [$CLASS->filter("$dep", root => $root, exclude => $deps)],
        [],
        "exclude accepts a Path::Tiny instance"
    );

    is(
        [$CLASS->filter("$dep", root => $root, exclude => ["$root/lib", "$deps"])],
        [],
        "exclude accepts an arrayref"
    );

    is(
        $CLASS->filter("$keep", root => $root, exclude => ["$deps"]),
        'lib/Keep.pm',
        "an arrayref that does not match leaves the file alone"
    );

    is(
        [$CLASS->filter("$dep", root => $root, exclude => "$root/no/such/dir")],
        ['deps/Dep.pm'],
        "an exclusion path that does not exist matches nothing"
    );

    my $orig = Path::Tiny->cwd;
    chdir("$root") or die "Could not chdir to '$root': $!";
    my $ok = eval {
        is([$CLASS->filter("$dep", root => $root, exclude => 'deps')], [], "a relative exclusion resolves against the current directory");
        1;
    };
    my $err = $@;
    chdir("$orig") or die "Could not chdir back to '$orig': $!";
    die $err unless $ok;
};

subtest symlinked_root => sub {
    skip_all "symlinks not available on this platform" unless eval { symlink("", ""); 1 };
    skip_all "could not create symlink" unless symlink("$deps", $root->child('link')->stringify);

    is(
        [$CLASS->filter("$dep", root => $root, exclude => $root->child('link')->stringify)],
        [],
        "a symlinked exclusion root resolves to the same tree"
    );
};

subtest both_record_types => sub {
    $CLASS->reset_coverage;
    $CLASS->touch_source_file("$keep");
    $CLASS->touch_source_file("$dep");
    $CLASS->touch_data_file("$data");

    is(
        $CLASS->files(root => $root),
        ['deps/Dep.pm', 'deps/data.json', 'lib/Keep.pm'],
        "all records are present without exclusions"
    );

    is(
        $CLASS->files(root => $root, exclude => "$deps"),
        ['lib/Keep.pm'],
        "exclusion drops both subroutine and data file records"
    );

    is(
        $CLASS->data(root => $root, exclude => "$deps"),
        {'lib/Keep.pm' => {'*' => ['*']}},
        "data() honors exclusions"
    );

    $CLASS->reset_coverage;
};

# The -M command line form cannot pass an arrayref, it repeats the key instead.
subtest repeated_import_key => sub {
    is(
        {$CLASS->_parse_params(root => 'r', exclude => 'a', exclude => 'b')},
        {root => 'r', exclude => ['a', 'b']},
        "repeated exclude keys accumulate instead of overwriting"
    );

    is(
        {$CLASS->_parse_params(exclude => ['a', 'b'], exclude => 'c')},
        {exclude => ['a', 'b', 'c']},
        "arrayref and repeated forms combine"
    );

    is({$CLASS->_parse_params(no_event => 1)}, {no_event => 1}, "no exclude key means no exclude param");
};

subtest odd_parameter_list => sub {
    my %params;
    my $warning = warning { %params = $CLASS->_parse_params(exclude => 'a', 'stray') };

    like($warning, qr/Odd number of parameters.*'stray' has no value/, "warned about the dangling key");
    is(\%params, {exclude => ['a']}, "kept the complete pairs");
};

done_testing;
