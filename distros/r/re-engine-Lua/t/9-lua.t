use strict;
use Test::More tests => 58;
use re::engine::Lua;

ok('aaa' =~ /a/);
ok('aaa' !~ /b/);

ok('aba' =~ /b/);
ok('aba' !~ /^b/);
ok('aaa' =~ /%w/);
ok('aaa' =~ /%U/);
ok('aaa' !~ /%u/);
ok('aaa' =~ /%g/);

ok('aaa' =~ /b?a/);
is($&, 'a');
ok('baaab' =~ /a+/);
is($&, 'aaa');
ok('baaab' =~ /a*/);
is($&, '');
ok('aaa' =~ /a+b*/);
is($&, 'aaa');

ok('aba' =~ /(.)(.)./);
is($1, 'a');
is($2, 'b');

ok('aaa' =~ /(%w)/);
is($1, 'a');
ok('aaa' !~ /(%d)/);
ok('aaa' =~ /(%w*)/);
is($1, 'aaa');

ok('aaa' =~ /a()a/);
is($1, '');
is($-[1], 1);
is($+[1], 1);

ok('book' =~ /(.)%1/);
is($1, 'o');

ok('abcd' =~ /a(b(c))(d)/);
is($&, 'abcd');
is($1, 'bc');
is($2, 'c');
is($3, 'd');

ok('abcd' =~ /(a?)../);
is($1, 'a');

ok('abcdef' =~ /[c]/);
is($&, 'c');

ok('abcdef' =~ /[b-d]/);
is($&, 'b');

ok('abcdef' =~ /[^b-d]/);
is($&, 'a');

ok('abcDef' =~ /[A-Z0-9]/);
is($&, 'D');

ok('ab-def' =~ /[%-]/);
is($&, '-');

ok('a^d' =~ /a^d/);
is($&, 'a^d');

ok("a\0f" =~ /a%zf/, "deprecated");
is($&, "a\0f");

my $nul = chr 0;
ok("a\0f" =~ /a${nul}f/);
is($&, "a\0f");

ok('a(bcde)f' =~ /a%b()f/, "balanced");
is($&, 'a(bcde)f');

ok('abacdef' =~ /%f[^ab]c/, "frontier");
is($&, 'c');

ok('abacdef' !~ /%f[^ab]d/);

