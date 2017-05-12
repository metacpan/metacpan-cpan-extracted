# -*- perl -*-
# -*- coding: utf-8 -*-

use strict;
use Test::More;
use Unicode::LineBreak qw(:all);

BEGIN { plan tests => 1 }

diag sprintf "sombok %s with Unicode %s\n",
	     Unicode::LineBreak::SOMBOK_VERSION,
	     Unicode::LineBreak::UNICODE_VERSION;
ok(1);

