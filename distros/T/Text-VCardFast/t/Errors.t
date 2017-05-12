# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-VCardFast.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 11;
BEGIN { use_ok('Text::VCardFast') };

# http://en.wikipedia.org/wiki/VCard

my @cards = (
'ITEM:VALUE
END:VCARD',
'BEGIN:VCARD',
'BEGIN:VCARD
ITEM;VAL=',
'BEGIN:VCARD
ITEM:VALUE
END:VTHING
',
'BEGIN:VCARD
ITEM
END:VCARD',
);

my @expected = (
    'Closed a different card name than opened',
    'not completed',
    'End of data while parsing parameter value',
    'Closed a different card name than opened',
    'End of line while parsing entry name',
);

foreach my $n (0..$#cards) {
    my $hash = eval { Text::VCardFast::vcard2hash($cards[$n], multival => ['adr', 'n']) };
    my $error = $@;
    is(undef, $hash, "no return value");
    like($error, qr/$expected[$n]/i, $error);
}
