# -*- cperl -*-

use Test::More tests => 12;
use XML::DT;

### XPath over elements

my $xml = <<"EOX";
<a><b><c>1</c></b><c>2</c><b><c>3</c></b></a>
EOX

# identity 1
is (pathdtstring($xml, (-default => sub{toxml} ))."\n", $xml);

# identity 2
is (pathdtstring($xml, ("//*" => sub{toxml} ))."\n", $xml);

is (pathdtstring($xml, ("//c"    => sub{"$c"},
			-default => sub{toxml})),
    "<a><b>1</b>2<b>3</b></a>");

is (pathdtstring($xml, ("/c" => sub{"$c"},
			"-default" => sub{toxml}))."\n", $xml);

is (pathdtstring($xml, ("/*/*/c" => sub{"$c"},
			"-default" => sub{toxml})),
    "<a><b>1</b><c>2</c><b>3</b></a>");

is (pathdtstring($xml, ("/*" => sub{"$q"})), "a");

is (pathdtstring($xml, ("a|b|c" => sub{toxml} ))."\n", $xml);

### XPath over attributes

$xml = <<"EOX";
<a v="1"><b>2</b><c><b>3</b></c><a v="2">4</a></a>
EOX

#identity 1
is (pathdtstring($xml, (-default => sub{toxml} ))."\n", $xml);

#identity 2
is (pathdtstring($xml, ("//*" => sub{toxml} ))."\n", $xml);

is (pathdtstring($xml, ("//*[@*]" => sub{toxml($q,{},$c)})),
    "<a><b>2</b><c><b>3</b></c><a>4</a></a>");

is (pathdtstring($xml, ("//a[\@v='2']" => sub{toxml($q,{},$c)},
			"//*" => sub{toxml})),
    "<a v=\"1\"><b>2</b><c><b>3</b></c><a>4</a></a>");

is (pathdtstring($xml, ("//a[\@v='1']" => sub{"zbr"})), "zbr");
