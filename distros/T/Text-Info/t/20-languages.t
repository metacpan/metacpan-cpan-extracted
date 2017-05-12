use Test::More;
use utf8;

use Text::Info;

#
# Norwegian
#
my $text = Text::Info->new(
    text => 'Bygningen som skal hete Sky City, vil bli 838 meter høy, ha 220 etasjer, og hold deg fast - den skal bygges på bare 90 dager i byen Changsha, hovedstaden i Hunan-provinsen, like ved elva Xiangjiang i Kina, skriver Gizmodo.com.',
    tld  => 'no', # This specific sentence actually resolves to "da" if tld isn't mentioned.
);

is( $text->language, 'no' );
is( $text->tld,      'no' );

#
# English
#
$text = Text::Info->new(
    text => 'After the first quiet night in over a week, morning broke over Gaza and Israel on Thursday to relative calm, as hushed weapons indicated that the cease-fire brokered hours earlier is holding up.',
);

is( $text->language, 'en' );
is( $text->tld,      ''   );

$text = Text::Info->new(
    text => qq|If you're concerned about people profiting from your code, then the bottom line is that nothing but a restrictive license will give you legal security.  License your software and pepper it with threatening statements like "This is unpublished proprietary software of XYZ Corp. Your access to it does not give you permission to use it."  We are not lawyers, of course, so you should see a lawyer if you want to be sure your license's wording will stand up in court.|,
    tld  => 'no',
);

is( $text->language, 'en' );
is( $text->tld,      'no' );

#
# Swedish
#
$text = Text::Info->new(
    text => 'Magnus Lindgren, 30, spåddes en lysande framtid på den trestjärniga lyxkrogen The Fat Duck i England. Men i måndags dog den svenske stjärnkocken när taxin han satt i krockade med två bussar i Hongkong. – Det är obeskrivligt tomt just nu, säger hans pappa Carl Gustaf Lindgren, 61.',
);

is( $text->language, 'sv' );

#
# It should also be possible to manually set the language.
#
$text = Text::Info->new(
    text     => 'supercalifragilisticexpialidocious',
    language => 'en',
);

is( $text->language, 'en' );

#
# The End
#
done_testing;
