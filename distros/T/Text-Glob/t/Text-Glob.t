#!perl -w
use strict;
use Test::More tests => 44;

BEGIN { use_ok('Text::Glob', qw( glob_to_regex match_glob ) ) }

my $regex = glob_to_regex( 'foo' );
is( ref $regex, 'Regexp', "glob_to_regex hands back a regex" );
ok( 'foo'    =~ $regex, "matched foo" );
ok( 'foobar' !~ $regex, "didn't match foobar" );

ok(  match_glob( 'foo', 'foo'      ), "absolute string" );
ok( !match_glob( 'foo', 'foobar'   ) );

ok(  match_glob( 'foo.*', 'foo.'     ), "* wildcard" );
ok(  match_glob( 'foo.*', 'foo.bar'  ) );
ok( !match_glob( 'foo.*', 'gfoo.bar' ) );

ok(  match_glob( 'foo.?p', 'foo.cp' ), "? wildcard" );
ok( !match_glob( 'foo.?p', 'foo.cd' ) );

ok(  match_glob( 'foo.{c,h}', 'foo.h' ), ".{alternation,or,something}" );
ok(  match_glob( 'foo.{c,h}', 'foo.c' ) );
ok( !match_glob( 'foo.{c,h}', 'foo.o' ) );

ok(  match_glob( 'foo.\\{c,h}\\*', 'foo.{c,h}*' ), '\escaping' );
ok( !match_glob( 'foo.\\{c,h}\\*', 'foo.\\c' ) );

ok(  match_glob( 'foo.(bar)', 'foo.(bar)'), "escape ()" );

ok( !match_glob( '*.foo',  '.file.foo' ), "strict . rule fail" );
ok(  match_glob( '.*.foo', '.file.foo' ), "strict . rule match" );
{
local $Text::Glob::strict_leading_dot;
ok(  match_glob( '*.foo', '.file.foo' ), "relaxed . rule" );
}

ok( !match_glob( '*.fo?',   'foo/file.fob' ), "strict wildcard / fail" );
ok(  match_glob( '*/*.fo?', 'foo/file.fob' ), "strict wildcard / match" );
{
local $Text::Glob::strict_wildcard_slash;
ok(  match_glob( '*.fo?', 'foo/file.fob' ), "relaxed wildcard /" );
}


ok( !match_glob( 'foo/*.foo', 'foo/.foo' ), "more strict wildcard / fail" );
ok(  match_glob( 'foo/.f*',   'foo/.foo' ), "more strict wildcard / match" );
{
local $Text::Glob::strict_wildcard_slash;
ok(  match_glob( '*.foo', 'foo/.foo' ), "relaxed wildcard /" );
}

ok(  match_glob( 'f+.foo', 'f+.foo' ), "properly escape +" );
ok( !match_glob( 'f+.foo', 'ffff.foo' ) );

ok(  match_glob( "foo\nbar", "foo\nbar" ), "handle embedded \\n" );
ok( !match_glob( "foo\nbar", "foobar" ) );

ok(  match_glob( 'test[abc]', 'testa' ), "[abc]" );
ok(  match_glob( 'test[abc]', 'testb' ) );
ok(  match_glob( 'test[abc]', 'testc' ) );
ok( !match_glob( 'test[abc]', 'testd' ) );

ok(  match_glob( 'foo$bar.*', 'foo$bar.c'), "escaping \$" );

ok(  match_glob( 'foo^bar.*', 'foo^bar.c'), "escaping ^" );

ok(  match_glob( 'foo|bar.*', 'foo|bar.c'), "escaping |" );


ok(  match_glob( '{foo,{bar,baz}}', 'foo'), "{foo,{bar,baz}}" );
ok(  match_glob( '{foo,{bar,baz}}', 'bar') );
ok(  match_glob( '{foo,{bar,baz}}', 'baz') );
ok( !match_glob( '{foo,{bar,baz}}', 'foz') );

ok(  match_glob( 'foo@bar', 'foo@bar'), '@ character');
ok(  match_glob( 'foo$bar', 'foo$bar'), '$ character');
ok(  match_glob( 'foo%bar', 'foo%bar'), '% character');
