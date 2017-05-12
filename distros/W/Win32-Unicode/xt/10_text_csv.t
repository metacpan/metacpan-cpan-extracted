use strict;
use warnings;
use Test::More;
use Test::Requires 'Text::CSV_XS';
use File::Temp qw/tempdir tempfile/;

use Win32::Unicode;

subtest getline => sub {
    my ($fh, $filename) = tempfile("tempXXXX", DIR => tempdir(CLEANUP => 1)) or die "$!";
    print $fh <<'CSV';
one,two,three
one,"two",three
one,"tw
o",three
CSV
    close $fh;

    my $file = Win32::Unicode::File->new(r => $filename) or die $!;
    my $csv  = Text::CSV_XS->new({ binary => 1 });
    my @rows;
    while (my $row = $csv->getline($file)) {
        push @rows, $row;
    }
    ok $csv->eof or $csv->error_diag();
    is @rows, 3;
    is_deeply \@rows, [
        [ "one", "two", "three" ],
        [ "one", "two", "three" ],
        [ "one", "tw\no", "three" ],
    ];
};

done_testing;
