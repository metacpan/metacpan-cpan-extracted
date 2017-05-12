package Win32::Unicode::Util;

use strict;
use warnings;
use 5.008003;
use File::Basename qw/fileparse/;
use File::Spec;
use File::Spec::Win32;
use File::Spec::Cygwin;
use Exporter 'import';

use Win32::Unicode::Constant qw/CYGWIN _32INT _S32INT/;
use Win32::Unicode::XS;

File::Basename::fileparse_set_fstype('MSWIN32');

# export subs
our @EXPORT = qw/utf16_to_utf8 utf8_to_utf16 cygpathw to64int is64int catfile splitdir rel2abs close_handle/;

my $utf16;
sub utf16_to_utf8 {
    require Encode;
    $utf16 ||= Encode::find_encoding('utf16-le');
    my $str = shift;
    return unless defined $str;
    $str = $utf16->decode($str);
    $str =~ s/\x00//g;
    return $str;
}

sub utf8_to_utf16 {
    require Encode;
    $utf16 ||= Encode::find_encoding('utf16-le');
    my $str = shift;
    return unless defined $str;
    return $utf16->encode($str);
}

sub to64int {
    my ($high, $low) = @_;

    require Math::BigInt;
    return ((Math::BigInt->new($high) << 32) + $low);
}

sub is64int {
    $_[0] >= _32INT or $_[0] <= _S32INT;
}

sub cygpathw {
    require Win32::Unicode::Dir;

    my $path = shift;
    my ($name, $dir) = fileparse $path;

    $dir =~ s/^([A-Z]:)\./$1/i; # C:.\ => C:\

    my $current = Win32::Unicode::Dir::getcwdW() or return;
    CORE::chdir $dir or return;
    $dir = Win32::Unicode::Dir::getcwdW() or return;
    CORE::chdir $current or return;

    if (defined $name) {
        return catfile($dir, $name) if defined $dir;
        return $name;
    }

    return $dir;
}

sub catfile {
    my $path = File::Spec::Win32->catfile(@_);
    $path = File::Spec::Cygwin->catfile($path) if CYGWIN;
    return $path;
}

sub splitdir {
    return File::Spec::Win32->splitdir(@_);
}

sub rel2abs {
    require Win32::Unicode::Dir;
    my $path = shift;
    my $base = shift || Win32::Unicode::Dir::getcwdW() || return;
    my $abs = File::Spec->rel2abs($path, $base);
    $abs = File::Spec::Cygwin->catfile($abs) if CYGWIN;
    return $abs;
}

1;
