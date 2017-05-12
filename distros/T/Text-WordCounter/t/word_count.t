use strict;
use warnings;
use utf8;

use Test::More;

use Text::WordCounter;

my $counter = Text::WordCounter->new();
my $features = {};
$counter->word_count( 'trala lala lala alalal la TRala', $features );
is_deeply( $features, { 'trala' => 2, 'lala' => 2, alalal => 1 } );

my $text = 
    'lบ้าน大狗'
    .'Интересная книга'
    .'a2b3c '
    .'a-cyclic semi-unification '
    .'zażółć gęślą jaźń'
;

$features = $counter->word_count( $text );
is_deeply( $features, { 
        'интересная' => 1, 
        'книга' => 1,
        'a2b3c' => 1,
        'a-cyclic' => 1,
        'semi-unification' => 1,
        'บ้าน' => 1,
        '大' => 1,
        '狗' => 1,
        'zażółć' => 1,
        'gęślą' => 1,
        'jaźń' => 1
    } 
);

$counter = Text::WordCounter->new(stemming => 1);
$features = $counter->word_count("The lazy red dogs quickly run over the gurgling brook");
is_deeply($features, {
    lazi => 1,
    dog => 1,
    quickli => 1,
    over => 1,
    gurgl => 1,
    brook => 1,
});

$counter = Text::WordCounter->new(stemming => 1);
$features = $counter->word_count("ąąąą 狗");
is_deeply($features, { 'ąąąą' => 1, '狗' => 1 });

$counter = Text::WordCounter->new(stopwords => { these => 1 });
$features = $counter->word_count('These cheese');
is_deeply($features, {
    cheese => 1,
});


done_testing;

