#!perl -wT
# Win32::GUI::Constants test suite
# $Id: 10_inherit.t,v 1.1 2006/05/13 15:39:30 robertemay Exp $
#
# - test that we can inherit from Win32::GUI::Constants

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 8;

package Win32::ABC;

# We're not allowed to inherit AUTOLOAD for non-methods,
# or we get this warning:
# "Use of inherited AUTOLOAD for non-method Win32::ABC::CW_USEDEFAULT() is deprecated ... "
# so we explicitly import it.
use Win32::GUI::Constants(-autoload);
our @ISA = qw(Win32::GUI::Constants);

package main;

#use Win32::ABC qw(CW_USEDEFAULT);
Win32::ABC->import('CW_USEDEFAULT');  # Equililent to use() when package doesn't come from seperate file

# Test exporting of default constant
can_ok("main", "CW_USEDEFAULT");

ok(!defined(&CW_USEDEFAULT), "default constant not defined");
is(&CW_USEDEFAULT, 2147483648, "correct value");
ok(defined(&CW_USEDEFAULT), "default constant defined after calling it");

# Test other symbol not exported
ok(!main->can("ES_WANTRETURN"), "main->can('ES_WANTRETURTN') failed");

# Test exporting of default constant
ok(!defined(&Win32::ABC::ES_WANTRETURN), "constant not defined");
ok(Win32::ABC::ES_WANTRETURN() == 4096, "correct value");
ok(defined(&Win32::ABC::ES_WANTRETURN),"constant defined after calling it");

