# -*- perl -*-

use Test::More tests => 5;
use strict;
use warnings;

use_ok("Win32::OLE::CrystalRuntime::Application::Constants", qw{crTightHorizontalConditionFormulaType crDayMonthYear});

is(crTightHorizontalConditionFormulaType(), 47, "crTightHorizontalConditionFormulaType");

is(crDayMonthYear(), 1, "crDayMonthYear");

is(Win32::OLE::CrystalRuntime::Application::Constants::crGregorianXlitFrenchCalendar(), 12, "crGregorianXlitFrenchCalendar");

eval("crJapaneseCalendar()");
ok($@, "crJapaneseCalendar not loaded");
