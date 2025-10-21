package TestHelper;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw(match_executed match_skipped run_test_file);

use Capture::Tiny qw(capture);
use Encode qw(decode_utf8 encode_utf8);
use File::Spec ();

sub match_executed {
    my ($name) = @_;
    # Extract the last component after the last '>'
    my $leaf_name = $name =~ / > ([^>]+)$/ ? $1 : $name;
    return qr/ok \d+ - \Q$leaf_name\E \{/;
}

sub match_skipped {
    my ($name) = @_;
    # Extract the last component after the last '>'
    my $leaf_name = $name =~ / > ([^>]+)$/ ? $1 : $name;
    return qr/\Q$leaf_name\E # skip/;
}

sub run_test_file {
    my ($test_file, $filter, $debug) = @_;

    local $ENV{SUBTEST_FILTER} = defined $filter ? encode_utf8($filter) : undef;
    local $ENV{SUBTEST_FILTER_DEBUG} = $debug // 1; # Default to enabled

    my $file = File::Spec->catfile(split m!/!, $test_file);

    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Ilib', $file);
    };
    $stdout = decode_utf8($stdout);

    my $err = $exit >> 8;
    if ($err != 0) {
        die "Test file '$test_file' exited with code $err. STDERR:\n$stderr\nSTDOUT:\n$stdout\n";
    }

    return $stdout;
}

1;
