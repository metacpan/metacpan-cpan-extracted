use strict;
use Test::More (tests => 3);

BEGIN { use_ok("XML::RSS::LibXML") }

my $xml = XML::RSS::LibXML->new;
$xml->{output} = '1.5';
eval { $xml->as_string };
ok($@, "formatting non-supported version 1.5");

delete $xml->{output};
$xml->{version} = '1.5';
eval { $xml->as_string };
ok($@, "formatting non-supported version 1.5");