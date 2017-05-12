# -*- cperl -*-

use Test::More tests => 5;
use Data::Dumper;

BEGIN {
  use_ok( 'XML::DT' );
}

my $XML = <<EOX;
<?xml version="1.0"?>
<xml>foo<bar>foo</bar>foo</xml>
EOX

like(dtstring($XML,
	      -default => sub { $c },
	      -type => {bar=>'SEQ'}
	     ), qr/fooARRAY\(0x[0-9a-f]+\)foo/);




is_deeply(dtstring($XML,
		   -default => sub { $c },
		   -type => {bar=>'SEQ',
			     -default=>'SEQ'}
		  ),
	  ['foo',['foo'],'foo']);



is_deeply(dtstring($XML,
		   -default => sub { $c },
		   -type => {-default=>'SEQ'}
		  ),
	  ['foo',['foo'],'foo']);



is(toxml(dtstring($XML,
		  -default => sub { $c },
		  -type => {-default=>'SEQH'})),
   "foo\n<bar>foo</bar>\nfoo");                       # yeah, we lose the xml tag.

