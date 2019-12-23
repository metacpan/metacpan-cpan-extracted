package Util;
use utf8;
use strict;
use warnings;
eval { require Encode } && Encode->import();
use parent qw(Exporter);

our @EXPORT = qw(
    entries_cp932 entries_utf8
    asciis nox5cs_utf8 x5cs_utf8
    x5cs_cp932 x5cs_utf8
    to_cp932 to_utf8
    cleanup_dir
    ls pwd pwd_win touch
    );

my @asciis = ( "foo",       "foo bar", );
my @nox5cs = ( "あいう", "あい う", );
my @x5cs   = (
    "構わない",     "構.わない",
    "構 わない",    "芸能界",
    "芸能.界",       "芸能 界",
    "芸 能界",       "ソフト構造",
    "ソ.フト構造", "ソ.フト構.造",
    "ソフト 構造", "ソ フ ト 構 造",
);

sub array_cp932 {
    return map { to_cp932($_) } @_;
}

sub entries_utf8 {
    my %e;
    my @a = ( @asciis, @nox5cs, @x5cs );
    @e{@a} = () x scalar(@a);
    return keys(%e);
}

sub entries_cp932 {
    my %e;
    my @a = ( @asciis, @nox5cs, @x5cs );
    @e{@a} = () x scalar(@a);
    return array_cp932( keys(%e) );
}

sub asciis { return @asciis; }

sub nox5cs_utf8 { return @nox5cs; }

sub x5cs_utf8 { return @x5cs; }

sub nox5cs_cp932 {
    return array_cp932(@nox5cs);
}

sub x5cs_cp932 {
    return array_cp932(@x5cs);
}

sub to_utf8 {
    return decode( "cp932", $_[0] );
}

sub to_cp932 {
    return encode( "cp932", $_[0] );
}

sub cleanup_dir {
    if ( -d $_[0] ) {
        my $path = to_utf8($_[0]);
        $path =~ s:/:\\:g;
        $path = to_cp932($path);
        return !system(qw{cmd.exe /C rmdir /S /Q}, $path);
    }
    return 1;
}

sub ls {
    my $dir = shift;
    $dir = "." unless defined $dir;
    split /\x0D?\x0A/, decode( 'cp932', qx{$ENV{COMSPEC} /C dir /B $dir} );
}

sub pwd {
    ( my $cwd = qx/cd/ ) =~ s/\x0D?\x0A//;
    ( $cwd = to_utf8( $cwd ) ) =~ s:\\:/:g;
    return to_cp932( $cwd );
}

sub pwd_win {
    ( my $cwd = qx/cd/ ) =~ s/\x0D?\x0A//;
    $cwd;
}

sub touch {
    my $path = to_utf8(shift);
    $path =~ s:/:\\:g;
    $path = to_cp932($path);
    system(qq{$ENV{COMSPEC} /C type NUL >> "$path"});
}
