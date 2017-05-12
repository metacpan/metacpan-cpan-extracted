#
# Win32::API::Test - Test helper package for Win32::API
#
# Cosimo Streppone <cosimo@cpan.org>
#

package Win32::API::Test;
use strict;
use warnings;

sub is_perl_64bit () {
    use Config;

    # was $Config{archname} =~ /x64/;
    return 1 if $Config{ptrsize} == 8;
    return;
}

sub can_fork () {
    use Config;

    my $native = $Config{d_fork} || $Config{d_pseudofork};
    my $win32 = ($^O eq 'MSWin32' || $^O eq 'NetWare');
    my $ithr = $Config{useithreads} and $Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/;

    return $native || ($win32 and $ithr);
}

sub compiler_name () {
    use Config;
    my $cc = $Config{ccname};
    if ($cc eq 'cl' || $cc eq 'cl.exe') {
        $cc = 'cl';
    }
    return ($cc);
}

sub compiler_version () {
    use Config;
    my $ver = $Config{ccversion} || 0;
    if ($ver =~ /^(\d+\.\d+)/) {
        $ver = 0 + $1;
    }
    return ($ver);
}

#
# Run the compiler and get version from there...
# User might be running a compiler different from
# that used to build perl.
# For example, Cosimo does. For testing, of course.
#
sub compiler_version_from_shell () {
    my $cc = compiler_name();
    my $ver;

    # MSVC
    if ($cc eq 'cl') {
        my @ver = `$cc 2>&1`;    # Interesting output in STDERR
        $ver = join('', @ver);

        #print 'VER:'.$ver.':'."\n";
        if ($ver =~ /Version (\d[\d\.]+)/ms) {
            $ver = $1;
        }
    }

    # GCC
    elsif ($cc eq 'cc' || $cc eq 'gcc' || $cc eq 'winegcc') {
        $ver = join('', `$cc --version`);
        if ($ver =~ /gcc.*(\d[\d+]+)/ms) {
            $ver = $1;
        }
    }

    # Borland C
    elsif ($cc eq 'bcc32' || $cc eq 'bcc') {
        $ver = join('', `$cc 2>&1`);
        if ($ver =~ /Borland C\+\+ (\d[\d\.]+)/ms) {
            $ver = $1;
        }
    }
    return ($ver);
}

sub find_test_dll {
    require File::Spec;
    my $dll;
    my $test_dll_name =
        is_perl_64bit()
        ? 'API_test64.dll'
        : 'API_test.dll';

    my $dll_name = $_[0] || $test_dll_name;

    my @paths = qw(.. ../t ../t/dll . ./dll ./t/dll);
    while (my $path = shift @paths) {
        $dll = File::Spec->catfile($path, $dll_name);
        if(-s $dll) { #preload the rtc dll to avoid changing PATH
            #leak the DLL, this is just unit testing
            die "can't load rtc DLL for API_test DLL"
                if ! Win32::API::LoadLibrary(
                    File::Spec->catfile($path,
                        is_perl_64bit()
                        ? 'rtc64.dll'
                        : 'rtc.dll'));
            return $dll;
        }
    }
    return (undef);
}

#const optimize
BEGIN {
    package main;
    use Config;
    eval ' sub PTR_LET () { "'
    .($Config{ptrsize} == 8 ? 'Q' : 'L').
    '" }';
    eval 'sub IV_LET () { '.($] <= 5.007002 ? 'L':'J').' }';
    eval 'sub IV_SIZE () { '.length(pack(IV_LET(),0)).' }';
    package Win32::API::Test;
}

1;

__END__


#######################################################################
# DOCUMENTATION
#

=head1 NAME

Win32::API::Test - Test helper package for Win32::API

=head1 SYNOPSIS

    my $test_dll = Win32::API::Test::find_test_dll('API_test.dll');

Check the t/*.t test scripts for more details.

=head1 DESCRIPTION

Simple package to hold Win32::API test suite helper functions.
No more, no less.

=head1 AUTHOR

Cosimo Streppone ( I<cosimo@cpan.org> )

=cut
