use v5.42;
use Test2::V0;
use Test2::API 'intercept';
use Path::Tiny;

use Test2::Tools::Pod;

my $dir = Path::Tiny->tempdir;
chdir $dir;

# Skips if no POD is found
{
    my $e = intercept { all_pod_ok "$dir" };

    is @$e, 1, 'generates event for empty directory';
    isa_ok $e->[0], [ 'Test2::Event::Skip' ], 'skips on empty directory';

    is $e->[0]->name, 'POD syntax ok', 'names the skipped test properly';
    is $e->[0]->reason, 'no POD files found', 'explains the skipping';
}

# Doesn't skip individual files
{
    $dir->child('A.pm')->spew(1);

    my $e = intercept { all_pod_ok "$dir" };
    is @$e, 1, 'sends a single skip if no POD found';
    isa_ok $e->[0], [ 'Test2::Event::Skip' ], 'skip generated';

    $dir->child('B.pm')->spew('=head1 H');

    $e = intercept { all_pod_ok "$dir" };
    is @$e, 1, 'does not generate a skip for files with no pod';
    isa_ok $e->[0], [ 'Test2::Event::Pass' ], 'single pass generated';
}

# Operates on blib by default and over lib
{
    $dir->child('blib')->mkdir;
    $dir->child('blib/A.pm')->spew('=head1 H');
    $dir->child('blib/B.pm')->spew('=head1 H');
    $dir->child('lib')->mkdir;
    $dir->child('lib/C.pm')->spew('=head1 H');

    my $e = intercept { all_pod_ok };
    is @$e, 2, 'operates on blib by default with precedence';

    $dir->child('blib')->remove_tree;

    $e = intercept { all_pod_ok };
    is @$e, 1, 'operates on lib by default';
}

chdir;
done_testing;
