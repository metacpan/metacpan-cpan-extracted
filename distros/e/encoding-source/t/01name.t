#!perl

use strict;
use warnings;
use Test::More;
plan tests => 8;

ok( !defined encoding::source->name );
use encoding::source 'latin1';
is( encoding::source->name, 'iso-8859-1' );
use encoding::source 'utf8';
is( encoding::source->name, 'utf8' );
no encoding::source;
ok( !defined encoding::source->name );
{
    use encoding::source 'latin1';
    is( encoding::source->name, 'iso-8859-1' );
    {
	use encoding::source 'utf8';
	is( encoding::source->name, 'utf8' );
    }
    is( encoding::source->name, 'iso-8859-1' );
}
ok( !defined encoding::source->name );
