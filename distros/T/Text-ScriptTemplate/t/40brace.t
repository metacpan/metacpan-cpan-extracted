#!/usr/bin/perl -Iblib/lib -Iblib/arch

use Test;
use Text::ScriptTemplate;

#$Text::ScriptTemplate::DEBUG = 1;

BEGIN { plan tests => 6 };

ok($tmpl = new Text::ScriptTemplate);

## BSD-style indent - Should fail due to "\n" between "}" and "else".
$tmpl->pack(q{
<% if (1) { %>
<%= 100 %>
<% } %>
<% else { %>
<%= 200 %>
<% } %>
});
ok($tmpl->fill =~ /syntax error/ ? 1 : 0);

## BSD-style indent, part2 - This is OK
$tmpl->pack(q{
<% if (1) { %>
<%= 100 %>
<% }
   else { %>
<%= 200 %>
<% } %>
});
ok($tmpl->fill eq q{

100

});

## Is it OK to put comment at the end of the block? - Yes.
$tmpl->pack(q{
<% if (1) { # this is always true %>
<%= 100 %>
<% } else { # this part is never executed %>
<%= 200 %>
<% } %>
});
ok($tmpl->fill == 100);

## Brace inside brace is OK
$tmpl->pack(q{
function foo() {
    return retval = "<%= "hello" %>";
}
});
ok($tmpl->fill, q{
function foo() {
    return retval = "hello";
}
});

## Check for backslash handling
$tmpl->pack('this is a \ (backslash).');
ok($tmpl->fill, 'this is a \ (backslash).');

exit(0);
