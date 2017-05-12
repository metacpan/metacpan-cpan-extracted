# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-VCardFast.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('Text::VCardFast') };

my $hash = {
 objects => [
  {
    type => 'test',
    properties => {
     name => [
      {
        name => 'name',
        value => "averyveryveryveryveryveryveryveryveryveryveryveryveryverylongisstring
withasplitatalogicalplace",
      },
     ],
    },
    objects => [],
  },
 ],
};

my $card = Text::VCardFast::hash2vcard($hash);
is($card, <<EOF);
BEGIN:TEST
NAME:averyveryveryveryveryveryveryveryveryveryveryveryveryverylongisstring\\n
 withasplitatalogicalplace
END:TEST
EOF

my $hash2 = {
 objects => [
  {
    type => 'test',
    properties => {
     name => [
      {
        name => 'name',
        value => "averyveryveryveryveryveryveryveryveryveryveryveryveryveryverylongisstring
withasplitatalogicalplace",
      },
     ],
    },
    objects => [],
  },
 ],
};

my $card2 = Text::VCardFast::hash2vcard($hash2);
is($card2, <<EOF);
BEGIN:TEST
NAME:averyveryveryveryveryveryveryveryveryveryveryveryveryveryverylongisstr
 ing\\n
 withasplitatalogicalplace
END:TEST
EOF

my $hash3 = {
 objects => [
  {
    type => 'test',
    properties => {
     name => [
      {
        name => 'name',
        value => "lots
of
short
lines
of
text
",
      },
     ],
    },
    objects => [],
  },
 ],
};


my $card3 = Text::VCardFast::hash2vcard($hash3);
is($card3, <<EOF);
BEGIN:TEST
NAME:lots\\n
 of\\n
 short\\n
 lines\\n
 of\\n
 text\\n
END:TEST
EOF
