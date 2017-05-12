use warnings;
use strict;
use Test::More;

plan tests => 3;

use Text::MiniTmpl qw( render tmpl2code );

my $res;

use utf8;
my $name_unicode = 'Юзер';
my $name_utf8 = $name_unicode;
utf8::encode($name_utf8);
my $wait_unicode = "Привет, Юзер! ☺\n";
my $wait_utf8 = $wait_unicode;
utf8::encode($wait_utf8);

$res = render('t/tmpl/unicode.txt', name => $name_unicode);
is $res, $wait_utf8,    'unicode';

Text::MiniTmpl::raw(1);

$res = render('t/tmpl/unicode.txt', name => $name_utf8);
isnt $res, $wait_utf8,  'raw failed because of cache';

$res = ${ tmpl2code('t/tmpl/unicode.txt')->( name => $name_utf8 ) };
is $res, $wait_utf8,    'raw';

