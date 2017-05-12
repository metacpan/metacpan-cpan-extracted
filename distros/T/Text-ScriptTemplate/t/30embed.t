#!/usr/bin/perl -Iblib/lib -Iblib/arch

use Test;
use Text::ScriptTemplate;

#$Text::ScriptTemplate::DEBUG = 1;

BEGIN { plan tests => 6 };

ok($tmpl = new Text::ScriptTemplate);

$tmpl->setq(TEXT => "hello");
$tmpl->setq(HASH => { foo => 123, bar => 234 });
$tmpl->setq(LIST => [0..9]);

##
$tmpl->setq(BOOL => 0);
$tmpl->pack(q{<% if ($BOOL) { %>BOOL == <%= $BOOL %><% } %>});
ok(! $tmpl->fill);

##
$tmpl->setq(BOOL => 1);
$tmpl->pack(q{<% if ($BOOL) { %>BOOL == <%= $BOOL %><% } %>});
ok($tmpl->fill, "BOOL == 1");

##
$tmpl->pack(q{<% for (0..9) { %><%= $_ %><% } %>});
ok($tmpl->fill, "0123456789");

##
$tmpl->pack(q{
<% for (1..3) { %>
i == <%= $_ %>
<% } %>
});
ok($tmpl->fill, q{

i == 1

i == 2

i == 3

});

##
$tmpl->pack(q{
<% for (1..3) { %>
i == <%= $_ %>
<% if ($_ == 3) { %>i is 3<% } %>
<% } %>
});
ok($tmpl->fill, q{

i == 1


i == 2


i == 3
i is 3

});

exit(0);
