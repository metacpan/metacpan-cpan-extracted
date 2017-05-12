use strict;
use warnings;
use Test::More tests => 12;
use XML::API;

use_ok('XML::API::Cache');
can_ok(
    'XML::API::Cache', qw/
      new
      langs
      /
);

my $x = XML::API->new( doctype => 'xhtml' );

$x->_set_lang('en');
$x->html_open('');
is(
    "$x", '<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xml:lang="en" xmlns="http://www.w3.org/1999/xhtml"></html>'
);
is_deeply( $x->_langs, 'en', 'x lang' );

my $x2 = XML::API->new();
$x2->_set_lang('de');
$x2->element('content');
is(
    $x2, '<?xml version="1.0" encoding="UTF-8" ?>
<element xml:lang="de">content</element>'
);
is_deeply( $x2->_langs, 'de', 'x2 lang' );

my $c = XML::API::Cache->new($x2);
isa_ok( $c, 'XML::API::Cache' );
is( "$c",
'<?xml version="1.0" encoding="UTF-8" ?><element xml:lang="de">content</element>'
);
is_deeply( $c->langs, 'de', 'c lang' );

$x->_add($c);

ok( $x->_langs == 2, 'lang count' );
is(
    "$x", '<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xml:lang="en" xmlns="http://www.w3.org/1999/xhtml"><?xml version="1.0" encoding="UTF-8" ?><element xml:lang="de">content</element></html>'
);
is_deeply( [ sort $x->_langs ], [ 'de', 'en' ], 'lang match' );

