# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-VCardFast.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('Text::VCardFast') };

my $Card = <<EOF;
BEGIN:VCARD
ITEM:VALUE
END:VCARD

Some trailing text,
and some more
EOF

{
  my $hash = eval { Text::VCardFast::vcard2hash_c($Card) };
  my $error = $@;
  is(undef, $hash, "no return value");
  like($error, qr/Some trailing text/i, $error);
}

{
  my $hash = eval { Text::VCardFast::vcard2hash_c($Card, only_one => 1) };
  my $error = $@;
  is('', $error, "no error");
  isnt(undef, $hash, "hash defined");
}

# XXX - _pp parser doesn't error out correctly on invalid lines
