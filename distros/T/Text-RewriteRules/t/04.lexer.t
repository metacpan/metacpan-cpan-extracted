# -*- cperl -*-
use Test::More tests => 17;
use Text::RewriteRules;

RULES/l lexer
foo==>zbr
bar==>ugh
ENDRULES

is(lexer(),undef);

lexer_init("foobar");
is(lexer(),"zbr");
is(lexer(),"ugh");
is(lexer(),undef);

# (4 tests above)---------------

RULES/l lex
(\d+)=e=>["INT",$1]
([A-Z]+)=e=>["STR",$1]
ENDRULES

is(lex(),undef);
lex_init("ID25");
is_deeply(lex(),["STR","ID"]);
is_deeply(lex(),["INT", 25]);
is(lex(),undef);

# (8 tests above)-----------------

RULES/l yylex
IF=e=>["IF","IF"]
(\w+)=e=>["ID",$1]
\s+=ignore=>
ENDRULES

is(yylex(),undef);
yylex_init("  IF XPTO");
is_deeply(yylex(),["IF","IF"]);
is_deeply(yylex(),["ID","XPTO"]);
is(yylex(),undef);

# (12 tests above)----------------

RULES/lx foo
IF=e=>("IF","IF")

(\w+)=e=>("ID",$1)

\s+=ignore=>

=EOF=e=>('',undef)
ENDRULES

=head Fix Highlight
=cut

is(foo(),undef);
foo_init("  IF XPTO");
is_deeply([foo()],["IF","IF"]);
is_deeply([foo()],["ID","XPTO"]);
is_deeply([foo()],['',undef]);
is(foo(),undef);
