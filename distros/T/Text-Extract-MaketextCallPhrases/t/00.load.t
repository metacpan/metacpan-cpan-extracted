use Test::More tests => 3;

BEGIN {
    use_ok('Text::Extract::MaketextCallPhrases');
}

diag("Testing Text::Extract::MaketextCallPhrases $Text::Extract::MaketextCallPhrases::VERSION");

ok( defined &get_phrases_in_text, 'get_phrases_in_text() exported by default' );
ok( defined &get_phrases_in_file, 'get_phrases_in_file() exported by default' );
