#!/usr/bin/perl -w

use Test::More 'no_plan';

BEGIN { use_ok "Text::Metaphone"; }

my %test_phones = (
           'recrudescence' => 'RKRTSNS',
           'moist' => 'MST',
           'Gutenberg' => 'KTNBRK',
           'recridessence' => 'RKRTSNS',
           'crapulance' => 'KRPLNS',
           'cough' => 'KF',
           'coffee' => 'KF',
           'tchrist' => 'TKRST',
           'Schwern' => 'XWRN',
           'Schwartz' => 'XWRTS',
           'Avulsion' => 'AFLXN',
           'Aeon' => 'EN',
           'Mushrooms' => 'MXRMS',
           'Way'       => 'W',
           'What'      => 'HT',
           'Wierd'     => 'WRT',
           ''          => '',
           'picklehead'=> 'PKLHT',

           # Caused a crash because phoned word == length of word revealing
           # an off-by-one allocation mistake.
           'nsxkgbsfdtp' => 'NSKSKKBSFTT',

           # An X on the end can make the phoned word one larger than the original.
           'jgVqiNdxNVLpVBxQBlxghDx' => 'JKFKNTKSNFLPFBKSKBLKSTKS',
           'ax1x1x'                  => 'AKSKSKS'
           );

foreach my $word (keys %test_phones) {
    is Metaphone($word), $test_phones{$word}, "$word";
}


