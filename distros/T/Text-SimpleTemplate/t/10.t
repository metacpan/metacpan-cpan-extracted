# -*- mode: perl -*-
#
# $Id$
#

use Test;
use Text::SimpleTemplate;

BEGIN { plan tests => 3 }

$tmpl = new Text::SimpleTemplate;
$tmpl->setq("TEXT", 'hello, world');

ok("hello, world", $tmpl->pack(q{(* $TEXT *)}, DELIM => [qw((* *))])->fill);

## configuration persistence
ok("hello, world", $tmpl->pack(q{(* $TEXT *)})->fill);

## configuration inheritance
$tmpl = $tmpl->new;
ok("hello, world", $tmpl->pack(q{(* $TEXT *)})->fill);

exit(0);
