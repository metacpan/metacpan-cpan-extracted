use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Exception;
use Test::Win32::Unicode::Util;

use Win32::Unicode::File;

my $dir;
setup: {
    $dir = tempdir;
    my $fh = Win32::Unicode::File->new(w => "$dir/\x{26c4}.txt");
    print $fh join "\n", qw/ほげ ふが ぴよ/; # auto replacing \n -> \015\012
}

sub rfh {
    my $fh = Win32::Unicode::File->new(r => "$dir/\x{26c4}.txt");
};

subtest 'no args' => sub {
    eval { Win32::Unicode::File::slurp() };
    ok $@;
};

subtest default => sub {
    my $text = rfh->slurp();
    is $text, join "\n", qw/ほげ ふが ぴよ/;
};

subtest binmode => sub {
    my $text = rfh->slurp(binmode => 1);
    is $text, join "\015\012", qw/ほげ ふが ぴよ/;
};

subtest 'binmode :utf8' => sub {
    my $text = rfh->slurp(binmode => ':utf8');
    is $text, Encode::decode_utf8(join "\n", qw/ほげ ふが ぴよ/);
};

subtest wantarray => sub {
    my @lines = rfh->slurp();
    is_deeply \@lines, [ "ほげ\n", "ふが\n", "ぴよ" ];
};

subtest 'wantarray with chomp' => sub {
    my @lines = rfh->slurp(chomp => 1);
    is_deeply \@lines, [ qw/ほげ ふが ぴよ/ ];
};

subtest array_ref => sub {
    my $lines = rfh->slurp(array_ref => 1);
    is_deeply $lines, [ "ほげ\n", "ふが\n", "ぴよ" ];
};

subtest 'array_ref with chomp' => sub {
    my $lines = rfh->slurp(array_ref => 1, chomp => 1);
    is_deeply $lines, [ qw/ほげ ふが ぴよ/ ];
};

subtest scalar_ref => sub {
    my $text_ref = rfh->slurp(scalar_ref => 1);
    is $$text_ref, join "\n", qw/ほげ ふが ぴよ/;
};

subtest buf_ref => sub {
    my $text = rfh->slurp(buf_ref => \my $buff);
    is $text, $buff;
};

subtest 'buf_ref with scalar_ref' => sub {
    my $text_ref = rfh->slurp(buf_ref => \my $buff, scalar_ref => 1);
    is $$text_ref, $buff;
};

subtest 'buf_ref with wantarray' => sub {
    my @lines = rfh->slurp(buf_ref => \my $buff);
    is $buff, join q{}, @lines;
};

subtest 'buf_ref with array_ref' => sub {
    my $lines = rfh->slurp(buf_ref => \my $buff, array_ref => 1);
    is $buff, join q{}, @$lines;
};

subtest 'buf_ref with void context' => sub {
    rfh->slurp(buf_ref => \my $buff);
    is $buff, join "\n", qw/ほげ ふが ぴよ/;
};

subtest blk_size => sub {
    my $text = rfh->slurp(blk_size => 1);
    is $text, join "\n", qw/ほげ ふが ぴよ/;
};

subtest 'restore file position' => sub {
    my $fh = rfh;
    $fh->seek(10, Win32::Unicode::File::SEEK_CUR);
    my $text = $fh->slurp();
    is $text, join "\n", qw/ほげ ふが ぴよ/;
    is $fh->tell, 10;
};

subtest 'restore binmode' => sub {
    my $fh = rfh;
    my $text = $fh->slurp(binmode => ':utf8:raw');
    is $text, Encode::decode_utf8(join "\015\012", qw/ほげ ふが ぴよ/);
    ok !*$fh->{_binmode};
    ok !*$fh->{_encode};
};

subtest hashref => sub {
    my $lines = rfh->slurp({
        array_ref => 1,
        chomp     => 1,
        blk_size  => 3,
    });
    is_deeply $lines, [ qw/ほげ ふが ぴよ/ ];
};

subtest function => sub {
    my @lines = Win32::Unicode::File::slurp(rfh->file_path, binmode => 1);
    is_deeply \@lines, [ "ほげ\015\012", "ふが\015\012", "ぴよ" ];
};

done_testing;
