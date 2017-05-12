#!perl -wT
# Win32::GUI test suite.
# $Id: 02_constants.t,v 1.1 2006/05/16 19:16:20 robertemay Exp $
#
# test coverage of constants.  Most of the coverage is provided by the
# Win32::GUI::Constants module, here we just want to check that
# delegation happens, and warnigs are raised appropriately

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 11;

use Win32::GUI();

# Check warnings from import statements
{
    my $warning;
    local $SIG{__WARN__} = sub {
        $warning = $_[0];
    };

    $warning = '';
    eval "use Win32::GUI()";
    is($warning, '', "No warning from 'use Win32::GUI()'");

    $warning = '';
    eval "use Win32::GUI";
    is($warning, '', "No warning from 'use Win32::GUI'");

    $warning = '';
    eval "use Win32::GUI 1.03";
    is($warning, '', "No warning from 'use Win32::GUI 1.03'");

    $warning = '';
    eval "use Win32::GUI 1.03,''";
    is($warning, '', "No warning from 'use Win32::GUI 1.03,'''");
}

# Check basic export mechanism
ok(!defined &main::CW_USEDEFAULT, "CW_USEDEFAULT not defined in main package");
eval "use Win32::GUI qw(CW_USEDEFAULT)";
ok(!defined &main::CW_USEDEFAULT, "CW_USEDEFAULT still not defined in main package");
is(CW_USEDEFAULT(), 0x80000000, "CW_USEDEFAULT autoloaded");
ok(defined &main::CW_USEDEFAULT, "CW_USEDEFAULT defined in main package after calling it");
ok(defined &Win32::GUI::Constants::CW_USEDEFAULT, "CW_USEDEFAULT defined in Win32::GUI::Constants package after calling it");

# deprecated Win32::GUI::constant was removed in 1.08
ok(!defined &Win32::GUI::constant, "Win32::GUI::constant() was removed");
ok(defined &Win32::GUI::_constant, "Win32::GUI::_constant() exists");
