use strict;
use warnings;
use inc::Module::Install;

name('Tk-Wizard');
version("2.158");
abstract('GUI for step-by-step interactive logical process');
author('lee-goddard-cpan-at-lgoddard-dot-net');
license('perl');

requires("Carp");
requires("Cwd");
requires("File::Copy");
requires("File::Path");
requires("File::Spec");
requires("IO::Handle");

build_requires("ExtUtils::testlib");
build_requires("File::Path");
build_requires("FileHandle");

build_recommends('IO::Capture::Stderr::Extended');

# There are features "missing" in earlier versions
recommends 'Log::Log4perl' => '1.12';

# This is used by Tk::Wizard::Installer::addDownloadPage:
recommends('LWP::UserAgent');
build_requires('LWP::UserAgent');
recommends('HTTP::Request');
requires("Scalar::Util");

build_requires("Test::More");
requires('Tk');
requires("Tk::After");
requires("Tk::DialogBox");
requires("Tk::DirTree");
requires("Tk::ErrorDialog");
requires("Tk::Frame");
requires("Tk::LabFrame");
requires("Tk::MainWindow");
requires("Tk::ProgressBar");
requires("Tk::ROText");

if ( $^O =~ m/(MSWin32)/i ) {
    requires('Win32::Shortcut');
    requires('Win32::TieRegistry');

    eval 'require Win32;';
    if ( !$@ ) {
        eval '$_ = $Win32::VERSION;';
        if ( !$@ && ( $_ < 0.2 ) ) {
            requires('Win32::OLE');
            warn "Win32.pm version is $_ (less than 0.2), therefore we will use Win32::OLE.  (This requires Windows Scripting Host which is present on Win98 and higher.)\n";
        }
        else {
            warn "Using Win32.pm for special folders...\n";
            requires( 'Win32' => 0.2 );
        }
    }
    else {
        warn "You are on a Windows platform without the core Win32 module. You can still use this module, but will experience errors if you try to create shortcuts to the Windows special folders.";
    }
}

WriteAll;

sub MY::postamble {
    return <<'PART0';
fix:
	$(PERLRUN) inc/fix.pl $(DISTVNAME).tar.gz

coverage :
	- cover -delete
	$(MAKE) HARNESS_PERL_SWITCHES=-MDevel::Cover test
	cover
PART0
}

