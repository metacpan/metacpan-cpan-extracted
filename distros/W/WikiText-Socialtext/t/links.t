use t::TestWikiText;

plan tests => 1;

#no_diff;

$t::TestWikiText::parser_module = 'WikiText::Socialtext::Parser';
$t::TestWikiText::emitter_module = 'WikiText::WikiByte::Emitter';

filters({wikitext => 'parse_wikitext'});

run_is 'wikitext' => 'wikibyte';

__DATA__
=== Old lists

--- wikitext
http://example.com "awesomeness"<http://awesome.com>
--- wikibyte
+p
+hyperlink target="http://example.com"
 http://example.com
-hyperlink
  
+hyperlink target="http://awesome.com"
 awesomeness
-hyperlink
-p
