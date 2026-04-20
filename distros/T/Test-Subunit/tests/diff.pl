#!/usr/bin/perl
# Tests for Test::Subunit::Diff module
use strict;
use warnings;
use Test::More tests => 19;
use File::Temp qw(tempfile);

BEGIN { use_ok('Test::Subunit::Diff'); }

# Test 1: Create new Diff object
{
    my $diff = Test::Subunit::Diff->new();
    isa_ok($diff, 'Test::Subunit::Diff', 'new() creates Diff object');
    ok(defined $diff, 'Diff object is defined');
}

# Test 2: from_file with simple successful test
{
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "test: test1\n";
    print $fh "success: test1\n";
    close $fh;

    my $diff = Test::Subunit::Diff::from_file($filename);
    isa_ok($diff, 'Test::Subunit::Diff', 'from_file() creates Diff object');
    is($diff->{test1}, 'success', 'Successful test recorded correctly');
}

# Test 3: from_file with multiple tests
{
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "test: test1\n";
    print $fh "success: test1\n";
    print $fh "test: test2\n";
    print $fh "failure: test2\n";
    print $fh "test: test3\n";
    print $fh "skip: test3\n";
    close $fh;

    my $diff = Test::Subunit::Diff::from_file($filename);
    is($diff->{test1}, 'success', 'First test recorded as success');
    is($diff->{test2}, 'failure', 'Second test recorded as failure');
    is($diff->{test3}, 'skip', 'Third test recorded as skip');
}

# Test 4: from_file with xfail
{
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "test: xfail_test\n";
    print $fh "xfail: xfail_test\n";
    close $fh;

    my $diff = Test::Subunit::Diff::from_file($filename);
    is($diff->{xfail_test}, 'xfail', 'xfail test recorded correctly');
}

# Test 5: from_file with error
{
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "test: error_test\n";
    print $fh "error: error_test\n";
    close $fh;

    my $diff = Test::Subunit::Diff::from_file($filename);
    is($diff->{error_test}, 'error', 'error test recorded correctly');
}

# Test 6: from_file with non-existent file
{
    my $diff = Test::Subunit::Diff::from_file('/nonexistent/file/path.txt');
    is($diff, undef, 'from_file returns undef for non-existent file');
}

# Test 7: diff with no changes
{
    my $old = Test::Subunit::Diff->new();
    $old->{test1} = 'success';
    $old->{test2} = 'success';

    my $new = Test::Subunit::Diff->new();
    $new->{test1} = 'success';
    $new->{test2} = 'success';

    my $diff = Test::Subunit::Diff::diff($old, $new);
    is(ref($diff), 'HASH', 'diff returns hash reference');
    is(scalar keys %$diff, 0, 'No differences detected');
}

# Test 8: diff with one change
{
    my $old = Test::Subunit::Diff->new();
    $old->{test1} = 'success';
    $old->{test2} = 'success';

    my $new = Test::Subunit::Diff->new();
    $new->{test1} = 'success';
    $new->{test2} = 'failure';

    my $diff = Test::Subunit::Diff::diff($old, $new);
    is(scalar keys %$diff, 1, 'One difference detected');
    is_deeply($diff->{test2}, ['success', 'failure'],
              'Difference shows old and new values');
}

# Test 9: diff with multiple changes
{
    my $old = Test::Subunit::Diff->new();
    $old->{test1} = 'success';
    $old->{test2} = 'success';
    $old->{test3} = 'skip';

    my $new = Test::Subunit::Diff->new();
    $new->{test1} = 'failure';
    $new->{test2} = 'success';
    $new->{test3} = 'error';

    my $diff = Test::Subunit::Diff::diff($old, $new);
    is(scalar keys %$diff, 2, 'Two differences detected');
    is_deeply($diff->{test1}, ['success', 'failure'],
              'First difference correct');
    is_deeply($diff->{test3}, ['skip', 'error'],
              'Second difference correct');
}

# Test 10: diff from success to xfail
{
    my $old = Test::Subunit::Diff->new();
    $old->{test1} = 'success';

    my $new = Test::Subunit::Diff->new();
    $new->{test1} = 'xfail';

    my $diff = Test::Subunit::Diff::diff($old, $new);
    is_deeply($diff->{test1}, ['success', 'xfail'],
              'Change from success to xfail detected');
}
