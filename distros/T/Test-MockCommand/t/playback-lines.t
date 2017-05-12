# -*- perl -*-
# test recording and playback with multiple lines of output and $/ changes

use Test::More tests => 36;
use warnings;
use strict;
use Data::Dumper;

BEGIN { use_ok 'Test::MockCommand'; }

my $cat = ($^O =~ /MSWin32/) ? 'type' : 'cat';

my $data = "Hello there.\n\nThis is a test.\nYes, a test.\n\n\nAbsolutely.\n";

die "opening file: $!" unless open my $fh, ">testfile.dat";
die "writing file: $!" unless print $fh $data;
die "closing file: $!" unless close $fh;

$Data::Dumper::Useqq = 1;

# turn on recording
Test::MockCommand->recording(1);

my @normal_results;

my ($one, $three, $ten, $hun) = (1, 3, 10, 100);
for ("\n", "\n\n", 'x', 't', '', undef, 'test', \$one, \$three, \$ten, \$hun) {
    # set $/ and turn it into a piece of text as well
    $/ = $_;
    my $name = Data::Dumper->Dump([$/], ['$/']);
    $name =~ s/\n+//gs;

    # compare spliting file via open(), readpipe('cat file') and
    # open('cat file |'), to check that cat/type on this platform
    # doesn't modify the file it outputs
    die "opening file: $!" unless open my $fh, "<testfile.dat";
    my @all_file = <$fh>;
    die "closing file: $!" unless close $fh;

    my @all_readpipe = readpipe("$cat testfile.dat ");

    die "open file: $!" unless open(my $fh2, "$cat testfile.dat |");
    my @all_open = <$fh2>;
    die "close file: $!" unless close($fh2);

    is_deeply \@all_file, \@all_readpipe, "$name open vs readpipe:cat";
    is_deeply \@all_file, \@all_open, "$name open vs open:cat";
    push @normal_results, [@all_file];
}

die "deleting file: $!" unless unlink 'testfile.dat';

# turn off recording
Test::MockCommand->recording(0);

my @readpipe_results;
my @open_results;

for ("\n", "\n\n", 'x', 't', '', undef, 'test', \$one, \$three, \$ten, \$hun) {
    # set $/ and turn it into a piece of text as well
    $/ = $_;
    my $name = Data::Dumper->Dump([$/], ['$/']);
    $name =~ s/\n+//gs;

    push @readpipe_results, [readpipe("$cat testfile.dat ")];
    ok open(my $fh, "$cat testfile.dat |"), "$name open:cat open()";
    push @open_results, [<$fh>];
    die "close file: $!" unless close($fh);
}

is_deeply \@normal_results, \@readpipe_results, "simulated readpipe:cat";
is_deeply \@normal_results, \@open_results, "simulated open:cat";
