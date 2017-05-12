#!/usr/bin/perl -Iblib/lib -Iblib/arch

use Test;
use Text::ScriptTemplate;

#$Text::ScriptTemplate::DEBUG = 1;

BEGIN { plan tests => 7 };

ok($tmpl = new Text::ScriptTemplate);

$tmpl->setq(TEXT => "hello");
$tmpl->setq(HASH => { foo => 123, bar => 234 });
$tmpl->setq(LIST => [0..9]);

$tmpl->pack(q{<%= $TEXT %>});
ok($tmpl->fill, "hello");

$tmpl->pack(q{<%= $TEXT %><%= $TEXT %>});
ok($tmpl->fill, "hellohello");

$tmpl->pack(q{foo<%= $TEXT %>bar<%= $TEXT %>baz});
ok($tmpl->fill, "foohellobarhellobaz");

$tmpl->pack(q{<%= $TEXT %>});
ok($tmpl->fill(PACKAGE => 'NOWHERE'), "hello");

$tmpl->pack(q{<%= $TEXT %><%= $TEXT %>});
ok($tmpl->fill(PACKAGE => 'NOWHERE'), "hellohello");

$tmpl->pack(q{foo<%= $TEXT %>bar<%= $TEXT %>baz});
ok($tmpl->fill(PACKAGE => 'NOWHERE'), "foohellobarhellobaz");

exit(0);
