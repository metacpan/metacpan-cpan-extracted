use XML::DoubleEncodedEntities qw(decode);

use strict;
$^W = 1;

use Test::Simple tests => 6;

$SIG{__WARN__} = sub { die("Caught a warning, making it fatal:\n\n$_[0]\n"); };

ok(XML::DoubleEncodedEntities::decode('<chocolate>Green &amp; Blacks</chocolate>') eq '<chocolate>Green &amp; Blacks</chocolate>',
   "Kosher XML is left alone");

ok(decode('   <chocolate>Green &amp; Blacks</chocolate>') eq '   <chocolate>Green &amp; Blacks</chocolate>',
   "Kosher XML with leading whitespace is left alone");
   
ok(XML::DoubleEncodedEntities::decode('<chocolate>Green &amp;amp; Blacks</chocolate>') eq '<chocolate>Green &amp; Blacks</chocolate>',
   "Broken XML (detected by leading &amp;amp;) is fixed");

ok(decode('&lt;chocolate>Green &amp; Blacks</chocolate>') eq '<chocolate>Green & Blacks</chocolate>',
   "Broken XML (detected by leading &lt;) is fixed");

ok(decode(' &lt;chocolate>Green &amp; Blacks</chocolate>') eq ' <chocolate>Green & Blacks</chocolate>',
   "Broken XML (detected by leading &lt; with whitespace) is fixed");

eval { decode(' &lt;chocolate>Green &amp; Blacks</chocolate&bogus;') };
ok($@, "Unrecognised entities are an error");
