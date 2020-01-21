#!perl
use strict;
use warnings;
use Test::More;
sub noop { undef };
use File::Temp;;
use Fcntl;
my $temp_file = File::Temp->new->filename;
use overload::open \&noop;
my $fh;
my $global;
unlink $temp_file;
my $open_lives = 0;
eval {
    open $fh, '>', $temp_file || die $!;
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
    die $@;
};
is $print_lives, 1, "Print does not die";
is $open_lives, 1, "open does not die";

close $fh;
my $sysopen_fh;
die if ! -f $temp_file;
sysopen($sysopen_fh, $temp_file, O_RDONLY);
my $a;
($a = <$sysopen_fh>) or warn $!;
is $a, 'words', "file has correct content";

unlink $temp_file;
close $fh;
no warnings 'redefine';
sub noop {
    use warnings;
    $global = 99;
    undef;
}
done_testing();
exit;
use warnings;
open $fh, '>', $temp_file || die $!;
is $global, 99, "sets global variable using overloaded sub";
unlink $temp_file;
done_testing();
