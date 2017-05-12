# -*- perl -*-

use Test::More tests => 5;
use strict;
use warnings;

use_ok("Win32::OLE::CrystalRuntime::Application::Constants", qw{:CRDateOrder :CRBorderConditionFormulaType});

is(crTightHorizontalConditionFormulaType(), 47, "crTightHorizontalConditionFormulaType loaded");

is(crDayMonthYear(), 1, "crDayMonthYear loaded");

is(Win32::OLE::CrystalRuntime::Application::Constants::crGregorianXlitFrenchCalendar(), 12, "crGregorianXlitFrenchCalendar available");

eval("crJapaneseCalendar()");
ok($@, "crJapaneseCalendar not loaded");
