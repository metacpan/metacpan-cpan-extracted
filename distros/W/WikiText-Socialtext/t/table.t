use t::TestWikiText;

plan tests => 2;

no_diff;

$t::TestWikiText::parser_module = 'WikiText::Socialtext::Parser';
$t::TestWikiText::emitter_module = 'WikiText::WikiByte::Emitter';

filters({wikitext => 'parse_wikitext'});

run_is 'wikitext' => 'wikibyte';

__DATA__
=== Spaces at the end of a row.

--- wikitext
| foo | 
| bar |
--- wikibyte
+table
+tr
+td
 foo
-td
-tr
+tr
+td
 bar
-td
-tr
-table

=== 2nd row, not a row

--- wikitext
| foo |
| bar |x
--- wikibyte
+table
+tr
+td
 foo
-td
-tr
-table
+p
 | bar |x
-p

