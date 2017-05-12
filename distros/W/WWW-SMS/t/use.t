#!/usr/bin/env perl -w
use strict;
use Test::More tests => 2;

use WWW::SMS;
use WWW::SMS::Omnitel;
use WWW::SMS::Libero;
use WWW::SMS::Everyday;
use WWW::SMS::Gomobile;
use WWW::SMS::SFR;
use WWW::SMS::MTS;
use WWW::SMS::LoopDE;
use WWW::SMS::GsmboxIT;
use WWW::SMS::Beeline;
use WWW::SMS::Enel;
use WWW::SMS::GsmboxDE;
use WWW::SMS::GsmboxUK;
use WWW::SMS::MTS;
use WWW::SMS::Vizzavi;
use WWW::SMS::Clarence;
use WWW::SMS::GoldenTelecom;
use WWW::SMS::GsmboxIT;
use WWW::SMS::LoopDE;

ok(1);

eval('use WWW::SMS::SFR');
ok(!$@, 'You need the module Date::Manip to use the SFR gateway');

exit;
