package Win32::Unicode::Native;

use strict;
use warnings;
use 5.008003;
use Exporter 'import';

our $VERSION = '0.38';

use Win32::Unicode::Console ':all';
use Win32::Unicode::File    ':all';
use Win32::Unicode::Dir     ':all';
use Win32::Unicode::Process ':all';
use Win32::Unicode::Error ();
use Win32::Unicode::Constant qw/CYGWIN/;
use Win32::Unicode::Util;
use Win32::Unicode::XS;
use Encode ();

BEGIN {
    @ARGV = ();
    my $enc = Encode::find_encoding(CYGWIN ? 'utf8' : 'cp932');
    my $script = $enc->decode($0);
    my @args = @{parse_argv()};
    my $flag = 0;
    while (@args) {
        my $argv = utf16_to_utf8 shift @args;
        unless ($flag) {
            if ($script eq '-e') {
                use bytes;
                next if $argv =~ /^-[ImMCD]/;
                next if $argv =~ /^-d:/;
                if ($argv =~ /^-.*[eE]$/) {
                    $flag++;
                    shift @args; # next argument is program
                }
            }
            elsif ($script eq '-' && $argv eq '-') {
                $flag++;
            }
            elsif (rel2abs($script) eq rel2abs($argv)) {
                $0 = $script;
                $flag++;
            }
            next;
        }
        push @ARGV, $argv;
    }

    sub __FILE__ () { $script }
};

our @EXPORT = qw{
    error
    file_size
    file_type
    dir_size
    open
    close
    opendir
    closedir
    readdir
    flock
    file_list
    dir_list
    __FILE__
    filename_normalize
    slurp
};

my $sub_export = sub {
    for my $method (@_) {
        my ($func) = $method =~ /^(.*)W$/;
        no strict 'refs';
        *{"$func"} = \&{"$method"};
        push @EXPORT, $func;
    }
};

# Win32::Unicode::Console
$sub_export->(qw{
    printfW
    warnW
    dieW
    sayW
});

for my $stdh (*STDOUT, *STDERR) {
    binmode $stdh => ':encoding(utf-8)';
    tie $stdh, 'Win32::Unicode::Console::Tie';
}

# Win32::Unicode::File
$sub_export->(qw{
    unlinkW
    renameW
    copyW
    moveW
    touchW
    statW
    utimeW
});

*flock = \&Win32::Unicode::File::flock;

sub open {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    my $fh = Win32::Unicode::File->new;
    $fh->open($_[1], $_[2]) or return;
    return $_[0] = $fh;
}

sub close {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    my $fh = $_[0];
    $fh->close or return;
    $_[0] = undef;
    return 1;
}

# Win32::Unicode::Dir
$sub_export->(qw{
    mkdirW
    rmdirW
    chdirW
    findW
    finddepthW
    mkpathW
    rmtreeW
    mvtreeW
    cptreeW
    getcwdW
});

sub opendir {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    my $dh = Win32::Unicode::Dir->new;
    return unless $dh->open($_[1]);
    return $_[0] = $dh;
}

sub closedir {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    my $dh = $_[0];
    $dh->close or return;
    $_[0] = undef;
    return 1;
}

sub readdir {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    my $dh = shift;
    return $dh->fetch;
};

# Win32::Unicode::Error
*error = \&Win32::Unicode::Error::errorW;

# Win32::Unicode::Process
$sub_export->(qw{
    systemW
    execW
});

1;
__END__
=head1 NAME

Win32::Unicode::Native - override some default method

=head1 SYNOPSIS

  use Win32::Unicode::Native;

  print $flagged_utf8;

  open my $fh, '<', $unicode_file_name or die error;

  opendir my $dh, $unicode_dir_name or die error;

=head1 DESCRIPTION

Wn32::Unicode is a perl unicode-friendly wrapper for win32api.
This module standard functions override.
But it's limited to just using Win32.

Many features easy to use Perl because I think it looks identical to the standard function.

=head1 AUTHOR

Yuji Shimada E<lt>xaicron@cpan.orgE<gt>

=head1 SEE ALSO

L<Win32::Unicode>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
