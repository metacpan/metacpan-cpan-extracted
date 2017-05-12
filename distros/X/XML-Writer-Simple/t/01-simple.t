#!/usr/bin/perl 

use Test::More tests => 15;
use XML::Writer::Simple tags => [qw/a b c d e/];

like(xml_header, qr/^<\?xml version="1\.0"\?>\n$/);

like(xml_header(encoding=>'iso-8859-1'), qr/^<\?xml version="1\.0" encoding="iso-8859-1"\?>\n$/);

is(a(b(c(d(e('f'))))), "<a><b><c><d><e>f</e></d></c></b></a>");

is(a(b('a'),c('a')), "<a><b>a</b><c>a</c></a>");

is(a(b(['a'..'h'])), "<a><b>a</b><b>b</b><b>c</b><b>d</b><b>e</b><b>f</b><b>g</b><b>h</b></a>");

is(a({-foo=>'bar'}), "<a foo=\"bar\"/>");

is(a({foo=>'bar'}), "<a foo=\"bar\"/>");

is(a({-foo=>'bar'},'x'), "<a foo=\"bar\">x</a>");

is(a({foo=>'bar'},'x'), "<a foo=\"bar\">x</a>");

is(a(), "<a/>");

is(a(0), "<a>0</a>");

is(a({foo=>'"'},"b"), "<a foo=\"&quot;\">b</a>");

is(a({foo=>'&'},"b"), "<a foo=\"&amp;\">b</a>");

is(a(quote_entities("<")) => "<a>&lt;</a>");

is(b(a(quote_entities("<&>"))) => "<b><a>&lt;&amp;&gt;</a></b>");



