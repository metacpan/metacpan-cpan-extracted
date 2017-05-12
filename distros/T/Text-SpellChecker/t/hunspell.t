#########################

use Test::More tests => 6;
BEGIN { use_ok('Text::SpellChecker') };

my $checker = Text::SpellChecker->new(text => "Foor score and seevn yeers ago", lang => "en_US" );
ok($checker, 'object creation' );

SKIP: {
    skip 'Text::Hunspell not installed', 4 unless $Text::SpellChecker::SpellersAvailable{Hunspell};
    skip 'English dictionary not installed', 4 
        unless (-e $Text::SpellChecker::DictionaryPath{Hunspell}.'/en_US.dic');

    ok($checker->next_word eq 'Foor', 'Catching English word');

    ok($checker->next_word eq 'seevn', 'Iterator');

    # we can call it two different ways
    my @suggestions = $checker->suggestions;
    my $suggestions = $checker->suggestions;
    ok( eq_array( \@suggestions, $suggestions), 'suggestions' );

    $checker->replace(new_word => 'seven');

    ok($checker->text =~ /score and seven/, 'replacement');
};

1;

