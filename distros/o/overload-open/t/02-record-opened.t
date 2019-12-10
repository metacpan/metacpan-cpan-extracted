#!perl
use strict;
use warnings;
use feature qw/ say /;;
use Test::More;
use Carp qw/ confess /;
my %opened_files;
sub record_opened_file {
    my ($filename) = @_;
    if (exists $opened_files{$filename}) {
    }
    else {
        $opened_files{$filename} = 1;
    }
}
use overload::open 'record_opened_file';
my $fh;
my $global;
unlink 'filename.txt';
my $open_lives = 0;
eval {
	open $fh, '>', "filename.txt" || die $!;
	$open_lives = 1;
	1;
} or do {
	die $@;
};
my $print_lives = 0;
eval {
	print $fh "words" || die $!;
	$print_lives = 1;
	1;
} or do {
	confess $@;
};
is $print_lives, 1, "Print does not die";
is $open_lives, 1, "open does not die";
is `cat filename.txt`, 'words', "file has correct content";
unlink 'filename.txt';
close $fh;
sub noop {
	$global = 99;
	undef;
}
open $fh, '>', 'filename.txt' || die $!;
ok $opened_files{"filename.txt"}, 'recorded that we opened filename.txt from three argument open';
is keys %opened_files, 1, "correct number of keys after opened filename.txt twice";
%opened_files = ();
close $fh;
open $fh, 'filename2.txt';
is keys %opened_files, 1, "correct number of keys after opened filename2.txt once";
ok $opened_files{"filename2.txt"}, "stored filename2.txt from two argument open";
unlink 'filename.txt';
done_testing();
