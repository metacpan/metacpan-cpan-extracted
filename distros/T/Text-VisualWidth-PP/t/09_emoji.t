use strict;
use warnings;
use utf8;
use Test::More;

BEGIN { use_ok('Text::VisualWidth::PP') };

is( Text::VisualWidth::PP::width("\N{U+1f9d4}") => 2,
                                 '\N{BEARDED PERSON}');

is( Text::VisualWidth::PP::width("\N{U+1f9d4}\N{U+1f3fb}") => 2,
                                 '\N{BEARDED PERSON}'.
                                 '\N{EMOJI MODIFIER FITZPATRICK TYPE-1-2}');

is( Text::VisualWidth::PP::width("\N{U+1f9d4}\N{U+1f3fb}\N{U+200d}\N{U+2642}\N{U+fe0f}") => 2,
                                 '\N{BEARDED PERSON}'.
                                 '\N{EMOJI MODIFIER FITZPATRICK TYPE-1-2}'.
                                 '\N{ZERO WIDTH JOINER}'.
                                 '\N{MALE SIGN}'.
                                 '\N{VARIATION SELECTOR-16}');

is( Text::VisualWidth::PP::width("\N{U+1f468}\N{U+1f3ff}\N{U+200d}\N{U+1f9bd}\N{U+200d}\N{U+27a1}\N{U+fe0f}") => 2,
                                 '\N{MAN}'.
                                 '\N{EMOJI MODIFIER FITZPATRICK TYPE-6}'.
                                 '\N{ZERO WIDTH JOINER}'.
                                 '\N{MANUAL WHEELCHAIR}'.
                                 '\N{ZERO WIDTH JOINER}'.
                                 '\N{BLACK RIGHTWARDS ARROW}'.
                                 '\N{VARIATION SELECTOR-16}');

done_testing;
