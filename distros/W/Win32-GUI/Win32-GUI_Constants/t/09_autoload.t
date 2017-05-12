#!perl -wT
# Win32::GUI::Constants test suite
# $Id: 09_autoload.t,v 1.1 2006/05/13 15:39:30 robertemay Exp $
#
# - check exporting of AUTOLOAD

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 5;

use Win32::GUI::Constants qw(-autoload);

ok(!main->can('ES_WANTRETURN'), "not autoloaded yet");
ok(!defined(&ES_WANTRETURN), "not defined");
is(ES_WANTRETURN(), 4096, "correct value autoloaded");
ok(defined(&ES_WANTRETURN),"constant defined after calling it");
can_ok('main', 'ES_WANTRETURN');
