#!perl -wT
use strict; use warnings;
use Test::More tests => 47;                   BEGIN { eval { require Test::NoWarnings } };
*had_no_warnings='Test::NoWarnings'->can('had_no_warnings')||sub{pass"skip: no warnings"};
use Text::Glob::DWIW ':all';
#BEGIN { use_ok('Text::Glob', qw( glob_to_regex match_glob ) ) }

my $regex = tg_re 'foo';
is( ref $regex, 'Regexp', "tg_re hands back a regex" );
ok( 'foo'    =~ $regex, "matched foo" );
ok( 'foobar' !~ $regex, "didn't match foobar" );

ok(  tg_grep( 'foo', 'foo'      ), "absolute string" );
ok( !tg_grep( 'foo', 'foobar'   ) );

ok(  tg_glob( 'foo.*', 'foo.'     ), "* wildcard" );
ok(  tg_glob( 'foo.*', 'foo.bar'  ) );
ok( !tg_glob( 'foo.*', 'gfoo.bar' ) );

ok(  tg_glob( 'foo.?p', 'foo.cp' ), "? wildcard" );
ok( !tg_glob( 'foo.?p', 'foo.cd' ) );

ok(  tg_grep( 'foo.{c,h}', 'foo.h' ), ".{alternation,or,something}" );
ok(  tg_grep( 'foo.{c,h}', 'foo.c' ) );
ok( !tg_grep( 'foo.{c,h}', 'foo.o' ) );

ok(  tg_grep( 'foo.\\{c,h}\\*', 'foo.{c,h}*' ), '\escaping' );
ok( !tg_grep( 'foo.\\{c,h}\\*', 'foo.\\c' ) );

ok(  tg_glob( 'foo.(bar)', 'foo.(bar)'), "escape ()" );

ok( !tg_glob( '*.foo',  '.file.foo',{unhead=>'.'} ), "strict . rule fail" );
ok(  tg_glob( '.*.foo', '.file.foo',{unhead=>'.'} ), "strict . rule match" );
{
#local $Text::Glob::strict_leading_dot;
ok(  tg_glob( '*.foo', '.file.foo' ), "relaxed . rule" );
}

ok( !tg_glob( '*.fo?',   'foo/file.fob',{unchar=>'/'} ), "strict wildcard / fail" );
ok(  tg_glob( '*/*.fo?', 'foo/file.fob',{unchar=>'/'} ), "strict wildcard / match" );
{
#local $Text::Glob::strict_wildcard_slash;
ok(  tg_glob( '*.fo?', 'foo/file.fob' ), "relaxed wildcard /" );
}

ok( tg_glob( 'a*.foo', 'a.foo',{unhead=>'.'} ), "more strict wildcard / fail 1" );
ok( !tg_glob( '*.foo', '.foo',{unhead=>'.'} ), "more strict wildcard / fail 2" );
ok( !tg_glob( 'foo/*.foo', 'foo/.foo',{unhead=>'.',unchar=>'/'} ), "more strict wildcard / fail" ); #XXX
ok( tg_glob( 'foo/*.foo', 'foo/.foo',{unhead=>'.'} ), "more strict wildcard / fail 4" ); #XXX
ok(  tg_glob( 'foo/.f*',   'foo/.foo',{unhead=>'.'} ), "more strict wildcard / match" );
{
#local $Text::Glob::strict_wildcard_slash;
ok(  tg_glob( '*.foo', 'foo/.foo' ), "relaxed wildcard /" );
}

ok(  tg_glob( 'f+.foo', 'f+.foo' ), "properly escape +" );
ok( !tg_grep( 'f+.foo', 'ffff.foo' ) );

ok(  tg_glob( "foo\nbar", "foo\nbar" ), "handle embedded \\n" );
ok( !tg_grep( "foo\nbar", "foobar" ) );

ok(  tg_grep( 'test[abc]', 'testa' ), "[abc]" );
ok(  tg_grep( 'test[abc]', 'testb' ) );
ok(  tg_grep( 'test[abc]', 'testc' ) );
ok( !tg_grep( 'test[abc]', 'testd' ) );

ok(  tg_glob( 'foo$bar.*', 'foo$bar.c'), "escaping \$" );

ok(  tg_glob( 'foo^bar.*', 'foo^bar.c'), "escaping ^" );

ok(  tg_glob( 'foo|bar.*', 'foo|bar.c'), "escaping |" );


ok(  tg_grep( '{foo,{bar,baz}}', 'foo'), "{foo,{bar,baz}}" );
ok(  tg_grep( '{foo,{bar,baz}}', 'bar') );
ok(  tg_grep( '{foo,{bar,baz}}', 'baz') );
ok( !tg_grep( '{foo,{bar,baz}}', 'foz') );

ok(  tg_grep( 'foo@bar', 'foo@bar'), '@ character');
ok(  tg_grep( 'foo$bar', 'foo$bar'), '$ character');
ok(  tg_grep( 'foo%bar', 'foo%bar'), '% character');

had_no_warnings();