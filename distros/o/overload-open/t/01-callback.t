#!perl
use strict;
use warnings;
use Test::More;
use Carp qw/ confess /;
sub noop { undef };
use overload::open 'noop';
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
is $global, 99, "sets global variable using overloaded sub";
unlink 'filename.txt';
done_testing();
