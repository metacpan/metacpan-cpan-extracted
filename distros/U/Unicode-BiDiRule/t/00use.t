#-*- perl -*-
#-*- coding: utf-8 -*-

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Unicode::BiDiRule') }
use Unicode::UCD;

diag sprintf 'Unicode version %s', Unicode::BiDiRule::UnicodeVersion();
is(Unicode::BiDiRule::UnicodeVersion(), Unicode::UCD::UnicodeVersion());
