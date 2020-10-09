use Test::More 0.98 tests => 4;
use Encode qw(is_utf8 encode_utf8 decode_utf8);
use feature qw(say);

use usw;

my $com = 'cat';
qx"$com t/_12_STDIN/03_empty.txt";
$com = 'type' if $?;
qx"$com t/_12_STDIN/03_empty.txt";

SKIP: {
    skip "there is no way to do `$com`", 3 if $?;
    qx"$com t/_12_STDIN/03_empty.txt | $^X t/_12_STDIN/00_detect_auto.pl";
    ok !$!, "Successfully detected empty file";

    qx"$com t/_12_STDIN/04_empty_lines.txt | $^X t/_12_STDIN/00_detect_auto.pl";
    ok !$!, "Successfully detected file with empty lines";

    qx"$com t/_12_STDIN/01_utf8.txt | $^X t/_12_STDIN/00_detect_auto.pl";
    BAIL_OUT $! if $!;
    is $?, 0, "succeeded to parse STDIN in utf8";
}

SKIP: {
    my $enc = usw->_get_encoding();
    skip "there is no way to do `$com`",                      1 if $?;
    skip 'this test is for the environment other than UTF-8', 1 if $enc eq 'UTF-8';
    open my $in,  '<:utf8',           't/_12_STDIN/01_utf8.txt'      or fail "open failed: $!";
    open my $out, ">:encoding($enc)", 't/_12_STDIN/05_generated.txt' or fail "open failed: $!";
    my $count = 0;
    while (<$in>) {    # copying encoded lines from which was utf8;
        chomp;
        say $out $_;
        $count++;
    }
    fail "lines are too less" if $count < 30;

    qx"$com t/_12_STDIN/05_generated.txt | $^X t/_12_STDIN/00_detect_auto.pl";
    BAIL_OUT $!, if $!;
    is $?, 0, "succeeded to parse STDIN in $enc";

    unlink 't/_12_STDIN/05_generated.txt';
}

done_testing;
