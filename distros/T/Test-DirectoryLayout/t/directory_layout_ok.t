use Test::Tester;
use Test::More;

use Test::DirectoryLayout;

use Path::Tiny qw(tempdir);

subtest 'default dirs are allowed' => sub {
    my $dir     = _setup_dir_with_default_dirs();
    my $dirname = $dir->stringify;

    my $results = _test_layout_of_dir($dirname);

    is $results->[0]->{diag}, '';
};

subtest 'additional dirs are not allowed' => sub {
    my $dir     = _setup_dir_with_default_dirs();
    my $dirname = $dir->stringify;

    my $not_allowed = 'foo';
    $dir->child($not_allowed)->mkpath;

    my $results = _test_layout_of_dir($dirname);

    like( $results->[0]->{diag}, qr/$not_allowed/ );
};

subtest 'test for different than default layout' => sub {

    # save current settings
    my $old_allowed_dirs = get_allowed_dirs();

    # set new ones
    my $new_allowed_dirs = ['foo'];
    set_allowed_dirs($new_allowed_dirs);
    my $dir     = _setup_dir_with_dirs($new_allowed_dirs);
    my $dirname = $dir->stringify;

    my $results = _test_layout_of_dir($dirname);

    is $results->[0]->{diag}, '';

    # restore
    set_allowed_dirs($old_allowed_dirs);
};

done_testing;

sub _setup_dir_with_dirs {
    my ($dirs) = @_;
    my $dir = tempdir;
    $dir->child($_)->mkpath for @$dirs;

    # Return $dir and not it's name because it doesn't have to go
    # out of scope. See docs of Path::Tiny::tempdir.
    return $dir;
}

sub _setup_dir_with_default_dirs {
    return _setup_dir_with_dirs(get_allowed_dirs);
}

sub _test_layout_of_dir {
    my ($dirname) = @_;
    my ( $premature, @results ) = run_tests(
        sub {
            directory_layout_ok($dirname);
        }
    );

    return \@results;
}
