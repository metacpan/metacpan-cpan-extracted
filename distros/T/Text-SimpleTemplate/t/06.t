# -*- mode: perl -*-
#
# $Id: 06.t,v 1.1 1999/10/24 13:30:25 tai Exp $
#

use Test;
use Text::SimpleTemplate;

BEGIN { plan tests => 2 }

eval {
    package SandBox;
    use Safe;
    @ISA = qw(Safe);

    package main;

    use Safe;

    $tmpl = new Text::SimpleTemplate;
    $tmpl->setq(TEXT => 'hello, world');

    ok("hello, world",
       $tmpl->pack(q{<% $TEXT %>})->fill(PACKAGE => new Safe));
    ok("hello, world",
       $tmpl->pack(q{<% $TEXT %>})->fill(PACKAGE => new SandBox));
};

# report all as skipped if there's no Safe.pm
if ($@) { skip(1, 1) for (1..2); }

exit(0);
