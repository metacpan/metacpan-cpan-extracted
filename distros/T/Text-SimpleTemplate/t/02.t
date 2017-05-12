# -*- mode: perl -*-
#
# $Id: 02.t,v 1.1 1999/10/24 13:30:25 tai Exp $
#

use Test;
use Text::SimpleTemplate;

BEGIN { plan tests => 3 }

package EmptyClass;

sub new { bless {}, shift; }

package main;

$tmpl = new Text::SimpleTemplate;
$tmpl->setq("TEXT", 'hello, world');

ok("hello, world", $tmpl->pack(q{<% $TEXT %>})->fill);

ok("hello, world",
   $tmpl->pack(q{<% $TEXT %>})->fill(PACKAGE => 'EmptyClass'));

ok("hello, world",
   $tmpl->pack(q{<% $TEXT %>})->fill(PACKAGE => new EmptyClass));

exit(0);
