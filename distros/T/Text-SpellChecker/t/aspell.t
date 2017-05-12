#########################

use utf8;
use Test::More tests => 10;
use strict;
BEGIN { use_ok('Text::SpellChecker') };

my $checker = Text::SpellChecker->new(text => "Foor score and seevn yeers ago", lang => "en_US" );
ok($checker, 'object creation' );

SKIP: {
    skip 'Text::Aspell not installed', 6 unless $Text::SpellChecker::SpellersAvailable{Aspell};
    skip 'English dictionary not installed', 6 
        unless (grep /^en/, Text::Aspell->new()->list_dictionaries) &&
                Text::Aspell->new()->get_option('lang') =~ /^en/;

    ok($checker->next_word eq 'Foor', 'Catching English word');

    ok($checker->next_word eq 'seevn', 'Iterator');

    # we can call it two different ways
    my @suggestions = $checker->suggestions;
    my $suggestions = $checker->suggestions;
    ok( eq_array( \@suggestions, $suggestions), 'suggestions' );

    $checker->replace(new_word => 'seven');

    ok($checker->text =~ /score and seven/, 'replacement');

    my $text = "The coördinator coöror will be leading the coöditer session";
    my $unichecker = Text::SpellChecker->new(text => $text );
    my @words = split / /, $text;
    my %words = map { $_ => 1 } @words;
    my @found;
    while (my $word = $unichecker->next_word) {
        push @found, $word;
    }
    ok ((!grep !$words{$_}, @found), "split utf8 text into words");

    my $fast_checker = Text::SpellChecker->new(text => "The qick brown fox");
    $fast_checker->set_options(aspell => { "sug-mode" => "fast" } );
    is $fast_checker->next_word, 'qick', 'fast checker worked';
};

my $original = Text::SpellChecker->new(from_frozen => $checker->serialize);
my $nother = Text::SpellChecker->new_from_frozen($checker->serialize);

delete $checker->{aspell};
delete $checker->{hunspell};
ok(eq_hash($original,$checker),'freezing, thawing');
ok(eq_hash($nother,$checker),'freezing, thawing');

