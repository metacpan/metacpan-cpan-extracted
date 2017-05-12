# -*- mode: perl -*-
#
# $Id: 03.t,v 1.1 1999/10/24 13:30:25 tai Exp $
#

package EmptyClass;

sub new { bless {}, shift; }

package main;

use Test;
use Text::SimpleTemplate;

BEGIN { plan tests => 3 }

$tmpl = new Text::SimpleTemplate;

$EmptyClass::TEXT = "hello, world";

ok("hello, world",
   $tmpl->pack(q{<% $TEXT %>})->fill(PACKAGE => 'EmptyClass'));

ok("hello, world",
   $tmpl->pack(q{<% $TEXT %>})->fill(PACKAGE => new EmptyClass));

## This dummy test is to shut up "used only once" warning
ok($EmptyClass::TEXT, $EmptyClass::TEXT);

exit(0);
