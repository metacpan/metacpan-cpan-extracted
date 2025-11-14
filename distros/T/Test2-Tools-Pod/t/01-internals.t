use v5.42;
use Test2::V0;
use Path::Tiny;

use Test2::Tools::Pod;

my $dir = Path::Tiny->tempdir;

### _POD_candidates
# Returns empty list for no args
{
    $dir->child('test.t')->spew(1);

    my @r = Test2::Tools::Pod::_POD_candidates;
    is @r, 0, 'returns empty list for no args';

    $dir->remove_tree({ keep_root => 1 });
}

# Finds common extensions
{
    $dir->child("test.$_")->spew(1) for qw/ PL pm pod psgi t /;

    my @r = Test2::Tools::Pod::_POD_candidates($dir);
    is @r, 5, 'finds common extensions';

    $dir->remove_tree({ keep_root => 1 });
}

# Recurses
{
    $dir->child('lib')->mkdir;
    $dir->child('lib/test.t')->spew(1);
    $dir->child('lib/test.c')->spew(1);

    my @r = Test2::Tools::Pod::_POD_candidates($dir);
    is @r, 1, 'recurses into child directories';

    $dir->remove_tree({ keep_root => 1 });
}

# Ignores
{
    $dir->child('.git')->mkdir;
    $dir->child('.git/test.t')->spew(1);

    my @r = Test2::Tools::Pod::_POD_candidates($dir);
    is @r, 0, 'ignores .git by default';

    @Test2::Tools::Pod::Ignore = ();

    @r = Test2::Tools::Pod::_POD_candidates($dir);
    is @r, 1, 'allows custom ignore list';
}

# Handles files
{
    $dir->child('lib')->mkdir;
    $dir->child('lib/A.pm')->spew(1);
    $dir->child('docs.pod')->spew(1);

    my @r = Test2::Tools::Pod::_POD_candidates("$dir/lib", "$dir/docs.pod");
    is @r, 2, 'allows directories and files';

    $dir->remove_tree({ keep_root => 1 });
}

# Handles dir and child together
{
    $dir->child('lib')->mkdir;
    $dir->child('lib/A.pm')->spew(1);

    my @r = Test2::Tools::Pod::_POD_candidates(
        "$dir/lib", "$dir/lib/A.pm");
    is @r, 1, 'does not duplicate recursive search';

    $dir->remove_tree({ keep_root => 1 });
}

done_testing;
