#!perl -w
use strict;
use Test::More tests => 30;

BEGIN { use_ok('Text::Glob', qw( glob_to_regex ) ) }

{
	my $regex = glob_to_regex( 'foo', "::" );
	is( ref $regex, 'Regexp', "glob_to_regex hands back a regex" );
	ok( 'foo'    =~ $regex, "matched foo" );
	ok( 'foobar' !~ $regex, "didn't match foobar" );
}

########################################################################
# Test '*'
########################################################################

# single char seperator
{
	local $Text::Glob::seperator = ":";
	my $regex = glob_to_regex( 'foo*:bar' );
	is( ref $regex, 'Regexp', "glob_to_regex hands back a regex" );
	ok( 'foo:bar'         =~ $regex, "matched foo::bar" );
	ok( 'foowibble:bar'   =~ $regex, "matched foowibble::bar" );
	ok( 'foo/wibble:bar'  =~ $regex, "matched foo/wibble::bar" );
	ok( 'foo::wibble:bar' !~ $regex, "didn't match foo::wibble::bar" );
}

# multi char seperator
{
	local $Text::Glob::seperator = "::";
	my $regex = glob_to_regex( 'foo*::bar' );
	is( ref $regex, 'Regexp', "glob_to_regex hands back a regex" );
	ok( 'foo::bar'         =~ $regex, "matched foo::bar" );
	ok( 'foowibble::bar'   =~ $regex, "matched foowibble::bar" );
	ok( 'foo/wibble::bar'  =~ $regex, "matched foo/wibble::bar" );
	ok( 'foo::wibble::bar' !~ $regex, "didn't match foo::wibble::bar" );
}

# meta char seperator
{
	local $Text::Glob::seperator = "(";
	my $regex = glob_to_regex( 'foo*(bar' );
	is( ref $regex, 'Regexp', "glob_to_regex hands back a regex" );
	ok( 'foo(bar'         =~ $regex, "matched foo(bar" );
	ok( 'foowibble(bar'   =~ $regex, "matched foowibble(bar" );
	ok( 'foo/wibble(bar'  =~ $regex, "matched foo/wibble(bar" );
	ok( 'foo(wibble(bar'  !~ $regex, "didn't match foo(wibble(bar" );
}

########################################################################
# Test '?'
########################################################################

# single char seperator
{
	local $Text::Glob::seperator = ":";
	my $regex = glob_to_regex( 'fo?:bar' );
	is( ref $regex, 'Regexp', "glob_to_regex hands back a regex" );
	ok( 'foo:bar' =~ $regex, "matched foo:bar" );
	ok( 'fo::bar' !~ $regex, "didn't match fo::bar" );
}

# multi char seperator
{
	local $Text::Glob::seperator = "::";
	my $regex = glob_to_regex( 'f??::bar' );
	is( ref $regex, 'Regexp', "glob_to_regex hands back a regex" );
	ok( 'foo::bar' =~ $regex, "matched foo:bar" );
	ok( 'f::::bar' !~ $regex, "didn't match f::::bar" );
	ok( 'fo:::bar' !~ $regex, "didn't match fo:::bar" );
}

# meta char seperator
{
	local $Text::Glob::seperator = "((";
	my $regex = glob_to_regex( 'f??((bar' );
	is( ref $regex, 'Regexp', "glob_to_regex hands back a regex" );
	ok( 'foo((bar' =~ $regex, "matched foo((bar" );
	ok( 'f((((bar' !~ $regex, "didn't match f((((bar" );
	ok( 'fo(((bar' !~ $regex, "didn't match fo((((bar" );
}
