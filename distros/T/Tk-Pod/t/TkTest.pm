# Copyright (C) 2003,2006,2007 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# Parts taken from TkTest.pm from Perl/Tk

package TkTest;

use strict;
use vars qw(@EXPORT);

use base qw(Exporter);
@EXPORT    = qw(check_display_test_harness display_test);

use ExtUtils::Command::MM qw(test_harness);

sub check_display_test_harness {
    my(@test_harness_args) = @_;

    # In case of cygwin, use'ing Tk before forking (which is done by
    # Test::Harness) may lead to "remap" errors, which are normally
    # solved by the rebase or rebaseall utilities.
    #
    # Here, I just skip the DISPLAY check on cygwin to not force users
    # to run rebase.
    #
    if (!($^O eq 'cygwin' || $^O eq 'MSWin32')) {

	eval q{
           use blib;
           use Tk;
        };
	die "Strange: could not load Tk library: $@" if $@;

	# empty the argument list for the following test_harness
	@ARGV = () if !_can_MainWindow();
    }

    test_harness(@test_harness_args);
}

# Avoid this function. Tk 804.xxx may die if multiple MainWindows are
# created within one process (seen e.g. on FreeBSD systems). By using
# this function a test MainWindow will be created, so the next "real"
# $mw creation may fail.
#
# display_test() is only safe if subsequent creation of MainWindows is
# done in separate processes (i.e. if using system(...))
sub display_test {
    if (!_can_MainWindow()) {
	print "1..0 # skip Cannot create MainWindow\n";
	CORE::exit(0);
    }
}

sub _can_MainWindow {
    require Tk;
    if (defined $Tk::platform && $Tk::platform eq 'unix') {
	my $mw = eval { MainWindow->new() };
	if (!Tk::Exists($mw)) {
	    warn "Cannot create MainWindow (maybe no X11 server is running or DISPLAY is not set?)\n$@\n";
	    return 0;
	} else {
	    $mw->destroy;
	    return 1;
	}
    } else {
	return 1;
    }
}

1;

__END__
