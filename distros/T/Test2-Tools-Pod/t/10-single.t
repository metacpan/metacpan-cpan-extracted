use v5.42;
use utf8;
use Test2::V0;
use Test2::API 'intercept';
use Path::Tiny;

use Test2::Tools::Pod;

my $pod = Path::Tiny->tempfile;

# Non-existing file
{
    my $r;
    my $e = intercept { $r = pod_ok 'AFileThatDoesNotExist' };

    is @$e, 1, 'generates event for a bad filename';
    isa_ok $e->[0], [ 'Test2::Event::Fail' ], 'fails on bad filename';
    is $r, false, 'returns false for bad filename';
}

# Good file
{
    $pod->spew('=head1 H');
    my $r;
    my $e = intercept { $r = pod_ok "$pod" };

    is @$e, 1, 'generates event for good file';
    isa_ok $e->[0], [ 'Test2::Event::Pass' ], 'passes on good file';
    is $r, true, 'returns true for good file';
}

# Broken syntax
{
    $pod->spew("=head1 H\n\n=over8");
    my $r;
    my $e = intercept { $r = pod_ok "$pod" };

    is @$e, 1, 'generates event for bad syntax';
    isa_ok $e->[0], [ 'Test2::Event::Fail' ], 'fails on bad syntax';
    is $r, false, 'returns false for bad syntax';

    my $facets = $e->[0]->facets->{info} // [];

    is @$facets, 1, 'generated diagnostic for bad syntax';
    like $facets->[0]->details,
         qr/unknown directive/i,
         'emits correct diagnostic for bad syntax';
}

# Multiple problems
{
    $pod->spew_utf8("=head1\n\n=c 𝄡\n\n=over8");
    my $e = intercept { pod_ok "$pod" };

    is @$e, 1, 'generates event for multiple problems';
    isa_ok $e->[0], [ 'Test2::Event::Fail' ], 'fails on multiple problems';

    my $facets = $e->[0]->facets->{info} // [];

    is @$facets, 3, 'captures the correct number of problems';
}

# Skips if no POD on file
{
    $pod->spew('1');
    my $r;
    my $e = intercept { $r = pod_ok "$pod" };

    is @$e, 1, 'generates event for no pod content';
    isa_ok $e->[0], [ 'Test2::Event::Skip' ], 'skips file with no pod';
    is $r, undef, 'returns undef on skipped test';

    like $e->[0]->reason, qr/no pod/i, 'addresses pod inexistence'
}

# Test names
{
    my $e;

    # Default name
    $pod->spew('=head1 H');
    $e = intercept { pod_ok "$pod" };
    like $e->[0]->name, qr/^POD syntax ok for/, 'uses default test name';

    # False name
    $e = intercept { pod_ok "$pod", '' };
    is $e->[0]->name, '', 'accepts and keeps empty name';

    # Non-existing file
    $e = intercept { pod_ok 'AFileThatDoesNotExist', 'secret_name' };
    is $e->[0]->name, 'secret_name', 'uses custom name on bad filename';

    # Good file
    $pod->spew('=head1 H');
    $e = intercept { pod_ok "$pod", 'secret_name' };
    is $e->[0]->name, 'secret_name', 'uses custom name on good file';

    # Bad syntax
    $pod->spew("=head1 H\n\n=over8");
    $e = intercept { pod_ok "$pod", 'secret_name' };
    is $e->[0]->name, 'secret_name',
        'uses custom name on file with bad syntax';

    # No POD
    $pod->spew('1');
    $e = intercept { pod_ok "$pod", 'secret_name' };
    is $e->[0]->name, 'secret_name',
        'uses custom name on file without any pod';
}

done_testing;
