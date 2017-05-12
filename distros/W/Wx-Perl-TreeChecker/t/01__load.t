#!/usr/bin/perl
# $Id: 01__load.t,v 1.1.1.1 2003/08/30 15:39:31 simonflack Exp $

use strict;
use Test::More tests => 3;

require_ok('Wx::Perl::TreeChecker');

# Check class inherits from Wx::TreeCtrl
ok (Wx::Perl::TreeChecker->isa('Wx::TreeCtrl'), 'Inheritance Test');

# Check exported constants
import Wx::Perl::TreeChecker ':status';
ok (TC_SELECTED() && TC_PART_SELECTED(), "import ':status'");

