my $t; use lib $t = -e 't' ? 't' : 'test';
use TestWikiText tests => 7;

#no_diff;
spec_file "$t/data/sample";

$TestWikiText::parser_module = 'WikiText::Sample::Parser';
$TestWikiText::emitter_module = 'WikiText::HTML::Emitter';

filters {
    sample => 'parse_wikitext',
};

run_is sample => 'html';
