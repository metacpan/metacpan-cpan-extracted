use strict;
use warnings;
use Test::More tests => 17;
use Test::Exception;
use XML::API;

my $x = XML::API->new( doctype => 'xhtml' );

is( $x->_lang, undef, 'current lang not defined' );
is( $x->_dir,  undef, 'current dir not defined' );

$x->html_open('');
$x->_set_lang('en');

ok( $x->_langs == 1, 'first lang recorded' );
is( $x->_lang, 'en',  'current lang en' );
is( $x->_dir,  undef, 'current dir not defined' );

is(
    "$x", '<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xml:lang="en" xmlns="http://www.w3.org/1999/xhtml"></html>', 'html ok'
);

$x->_set_lang( 'de', 'rtl' );
$x->head_open('test head');
ok( $x->_langs == 2, 'second lang accepted' );
is( $x->_lang, 'de',  'current lang de' );
is( $x->_dir,  'rtl', 'current dir is rtl' );
$x->head_close;

is( $x->_lang, 'en',  'current lang back to en' );
is( $x->_dir,  undef, 'current dir not defined' );

is(
    "$x", '<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xml:lang="en" xmlns="http://www.w3.org/1999/xhtml">
  <head dir="rtl" xml:lang="de">test head</head>
</html>', 'html ok'
);

$x->one_open;
$x->two_open;
$x->three_open;
is( $x->_lang, 'en', 'current lang still en' );

#
# Test languages on a generic XML document
#
$x = XML::API->new();
$x->one_open;
$x->_set_lang('en');
$x->two_open('a test two element');
is( $x->_lang, 'en', 'current lang en' );
$x->two_close;
is( $x->_dir, undef, 'current dir not defined' );

ok( $x->_langs == 1, 'lang accepted for generic xml' );
is(
    "$x", '<?xml version="1.0" encoding="UTF-8" ?>
<one>
  <two xml:lang="en">a test two element</two>
</one>', 'generic xml ok'
);

