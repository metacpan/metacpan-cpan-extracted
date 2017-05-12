#!/usr/local/bin/perl -w
use strict;
use Test::More tests => 3;

require_ok('Wx::Perl::Throbber');

# Check class inherits from Wx::TreeCtrl
ok (Wx::Perl::Throbber->isa('Wx::Panel'), 'Inheritance Test');

# Check exported constants
import Wx::Perl::Throbber 'EVT_UPDATE_THROBBER';
ok (defined(&EVT_UPDATE_THROBBER), "exports EVT_UPDATE_THROBBER");


