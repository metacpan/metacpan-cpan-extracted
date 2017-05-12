# -*- perl -*-
# test Test::MockCommand::ScalarReadline

use Test::More tests => 23;
use warnings;
use strict;
use Data::Dumper;

BEGIN { use_ok 'Test::MockCommand::ScalarReadline', 'scalar_readline'; }

my $data = "Hello there.\n\nThis is a test.\nYes, a test.\n\n\nAbsolutely.\n";

die "opening file: $!" unless open my $fh, ">testfile.dat";
die "writing file: $!" unless print $fh $data;
die "closing file: $!" unless close $fh;

$Data::Dumper::Useqq = 1;

my ($one, $three, $ten, $hun) = (1, 3, 10, 100);
for ("\n", "\n\n", 'x', 't', '', undef, 'test', \$one, \$three, \$ten, \$hun) {
    # set $/ and turn it into a piece of text as well
    $/ = $_;
    my $name = Data::Dumper->Dump([$/], ['$/']);
    $name =~ s/\n+//gs;

    # compare spliting file and splitting string into records, all at once
    die "opening file: $!" unless open my $fh2, "<testfile.dat";
    my @all_file = <$fh2>;
    die "closing file: $!" unless close $fh2;

    my @all_string = scalar_readline $data;
    is_deeply \@all_file, \@all_string, "$name array compare";

    # compare spliting file and string, one line at a time
    my $line;
    die "opening file: $!" unless open my $fh3, "<testfile.dat";
    @all_file = ();
    while (defined($line = <$fh3>)) { push @all_file, $line }
    die "closing file: $!" unless close $fh3;

    my $data2 = $data;
    my $len = undef;
    @all_string = ();
    while (defined ($line = scalar_readline($data2, $len))) {
	push @all_string, $line;
	$data2 = substr($data2, $len);
    }

    is_deeply \@all_file, \@all_string, "$name scalar compare";
}

die "deleting file: $!" unless unlink 'testfile.dat';
