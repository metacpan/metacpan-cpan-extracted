#!perl -T
use Test::More tests => 2;

BEGIN {
	use_ok( 'XML::OPML::SimpleGen' );
}

my $foo = new XML::OPML::SimpleGen;

$foo->head(dateCreated => '', dateModified => '');

my $data = $foo->as_string();

local $/ = undef;

my $old = <DATA>;

ok($old eq $data, "Basic function");

__DATA__
<?xml version="1.0" encoding="utf-8" ?>
<opml version="1.1">
  <body>
  </body>
  <head>
    <dateCreated></dateCreated>
    <dateModified></dateModified>
    <title></title>
  </head>
</opml>
