#!/usr/bin/perl -Iblib/lib -Iblib/arch

use Test;
use Text::ScriptTemplate;

#$Text::ScriptTemplate::DEBUG = 1;

BEGIN { plan tests => 2 };

ok($tmpl = new Text::ScriptTemplate);

$tmpl->pack(q{
top: <%= $num %>
sub: <%= $tmpl->include("t/50include.sub", { num => 123 }) %>
top: <%= $num %>
});

ok($tmpl->setq(tmpl => $tmpl, num => 100)->fill eq q{
top: 100
sub: 123
top: 100
});

exit(0);
