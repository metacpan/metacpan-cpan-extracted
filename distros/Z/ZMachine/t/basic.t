use strict;
use warnings;
use utf8;
use charnames ':full';

use Test::More;
use Test::Differences;
use Test::BinaryData;
use ZMachine::ZSCII;

sub diag_str {
  my ($str) = @_;
  for (0 .. length($str)-1) {
    my $ord = ord substr($str, $_, 1);
    diag sprintf("%02s: Z+%03x | %3s", $_, $ord, $ord);
  }
}

sub four_zchars {
  my $chr = shift;
  my $top = ($chr & 0b1111100000) >> 5;
  my $bot = ($chr & 0b0000011111);

  return "\x05\x06" . chr($top) . chr($bot);
}

sub chrs { map chr hex, @_; }

sub bytes {
  return join q{}, map chr hex, @_;
}

my $z = ZMachine::ZSCII->new(5);

{
  my $ztext = $z->encode("Hello, world.\n");

  is_binary(
    $ztext,
    bytes(qw(11 AA 46 34 16 60 72 97 45 25 C8 A7)),
    "Hello, world.",
  );

  my @zchars = split //, $z->unpack_zchars( $ztext );
  my @want   = map chr hex,
              qw(04 0D 0A 11 11 14 05 13 00 1C 14 17 11 09 05 12 05 07);
              #      H  e  l  l  o     , __  w  o  r  l  d     .    \n

  # XXX: Make a patch to eq_or_diff to let me tell it to sprintf the results.
  # -- rjbs, 2013-01-18
  eq_or_diff(
    \@zchars,
    \@want,
    "zchars from encoded 'Hello, World.'",
  );

  my $text = $z->decode($ztext);

  is_binary($text, "Hello, world.\n", q{we round-tripped "Hello, world.\n"!});
}

subtest "default extra characters in use" => sub {
  is(
    $z->unicode_to_zscii("\N{LEFT-POINTING DOUBLE ANGLE QUOTATION MARK}"), # «
    chr(163),
    "naughty French opening quote: U+00AB, Z+0A3",
  );

  is(
    $z->unicode_to_zscii("\N{RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK}"), # »
    chr(162),
    "naughty French opening quote: U+00AB, Z+0A2",
  );

  my $orig    = "«¡Gruß Gott!»";

  my $zscii   = $z->unicode_to_zscii( $orig );
  is_binary(
    $zscii,
    (join q{}, map chr,
      qw(163 222 71 114 117 161 32 71 111 116 116 33 162)),
      #  «   ¡   G  R   u   ß   __ G  o   t   t   !  »
    "converted Unicode string of Latin-1 chars to ZSCII",
  );

  is(length($zscii), 13, "the string is 13 ZSCII characters");

  my $zchars  = $z->zscii_to_zchars( $zscii );

  my @expected_zchars = (
    four_zchars(163),      # ten-bit char 163
    four_zchars(222),      # ten-bit char 222
    chrs(qw(04 0C 17 1A)), # G r u
    four_zchars(161),      # ten-bit char 161
    chrs(qw(00 04 0C 14 19 19 05 14)), # _ G o t t !
    four_zchars(162), # ten-bit char 162
  );

  is_binary(
    $zchars,
    (join q{}, @expected_zchars),
    "...then the ZSCII to Z-characters",
  );

  is(length($zchars), 28, "...there are 28 Z-characters for the 14 ZSCII");

  my $packed  = $z->pack_zchars($zchars);
  is(length($packed), 20, "28 Z-characters pack to 10 words (20 bytes)");

  # 20 bytes could, at maximum, encode 30 zchars, which means we'll expect two
  # padding zchars at the end

  my $unpacked = $z->unpack_zchars($packed);
  is(length($unpacked), 30, "once unpacked, we've got 30; 2 are padding");

  is_binary(
    $unpacked,
    (join q{}, @expected_zchars, "\x05\x05"),
    "we use Z+005 for padding",
  );

  my $zscii_again = $z->zchars_to_zscii($unpacked);
  is(length($zscii_again), 13, "paddings ignored; as ZSCII, 13 chars again");

  my $unicode = $z->zscii_to_unicode($zscii_again);
  eq_or_diff($unicode, $orig, "...and we finish the round trip!");

  {
    my $ztext   = $z->encode( $orig );
    my $unicode = $z->decode($ztext);
    eq_or_diff($unicode, $orig, "it round trips in isolation, too");
  }
};

subtest "custom extra characters" => sub {
  {
    my $zscii;
    my $ok = eval { $zscii = $z->unicode_to_zscii("Ameri☭ans"); 1 };
    ok(! $ok, "we have no HAMMER AND SICKLE by default");
  }

  my $soviet_z = ZMachine::ZSCII->new({
    version => 5,
    extra_characters => [ qw( Ж ÿ ☭ ) ],
  });

  my $zscii;
  my $ok = eval { $zscii = $soviet_z->unicode_to_zscii("Ameri☭ans"); 1 };
  ok($ok, "we can encode HAMMER AND SICKLE if we make it an extra")
    or diag "error: $@";

  is(ord(substr($zscii, 5, 1)), 157, "the H&C is ZSCII 157");
  is(length($zscii), 9, "there are 8 ZSCII charactrs");
  is_binary($zscii, "Ameri\x9Dans", "...and they're what we expect too");

  my $zchars = $soviet_z->zscii_to_zchars($zscii);

  my @expected_zchars = (
    chrs(qw(04 06 12 0A 17 0E)),
    four_zchars(157),
    chrs(qw(06 13 18)),
  );

  is_binary(
    $zchars,
    (join q{}, @expected_zchars),
    "...then the ZSCII to Z-characters",
  );

  my $zscii_again = $soviet_z->zchars_to_zscii($zchars);

  eq_or_diff($zscii_again, $zscii, "ZSCII->zchars->ZSCII round tripped");

  is(
    $soviet_z->decode( $soviet_z->encode("Ameri☭ans") ),
    "Ameri☭ans",
    "...and we can round trip it",
  );
};

for my $test_setup (
  [ "\x9D", 'ZSCII'   ],
  [ "☭",    'Unicode' ],
) {
  my $a2_19   = $test_setup->[0];
  my $charset = $test_setup->[1];
  subtest "custom alphabet, $charset" => sub {
    my $ussr_z = ZMachine::ZSCII->new({
      version  => 5,
      extra_characters => [ qw( Ж ÿ ☭ ) ],
      alphabet => "ABCDEFGHIJLKMNOPQRSTUVWXYZ"
                . "zyxwvutsrqponmlkjihgfedcba"
                . "\0\x0D0123456789.,!?_#'${a2_19}/\\-:()",
      alphabet_is_unicode => $charset eq 'Unicode',
    });

    my $zscii;
    my $ok = eval { $zscii = $ussr_z->unicode_to_zscii("Ameri☭ans"); 1 };
    ok($ok, "we can encode HAMMER AND SICKLE if we make it an extra")
      or diag "error: $@";

    is(ord(substr($zscii, 5, 1)), 157, "the H&C is ZSCII 157");
    is(length($zscii), 9, "there are 8 ZSCII charactrs");
    is_binary($zscii, "Ameri\x9Dans", "...and they're what we expect too");

    my $zchars = $ussr_z->zscii_to_zchars($zscii);

    my @expected_zchars = (
      chrs(qw(06 04 13 04 1B 04 0E 04 17)),
      chrs(qw(05 19)), # not four_zchars because we put it at A2-19
      chrs(qw(04 1F 04 12 04 0D)),
    );

    is_binary(
      $zchars,
      (join q{}, @expected_zchars),
      "...then the ZSCII to Z-characters",
    );
  };
}

subtest "dictionary words" => sub {
  {
    my $word = "cable";
    my $zchars = $z->zscii_to_zchars( $z->unicode_to_zscii( $word ) );

    is(length $zchars, 5, "as zchars, 'cable' is 5 chars");

    my $dict_cable = $z->make_dict_length($zchars);
    is(length $dict_cable, 9, "trimmed to length, it is nine");

    is(substr($dict_cable, 0, 5), $zchars, "the first five are the word");
    is(substr($dict_cable, 6, 3), "\x05\x05\x05", "the rest are x05");
  }

  {
    my $word = "twelve-inch"; # You know, like the cable.
    my $zchars = $z->zscii_to_zchars( $z->unicode_to_zscii( $word ) );

    is(length $zchars, 12, "as zchars, 'twelve-inch' is 12 chars");

    my $dict_12i = $z->make_dict_length($zchars);
    is(length $dict_12i, 9, "trimmed to length, it is nine");
  }

  {
    my $word = "queensrÿche";
             #  12345678CDE
    my $zchars = $z->zscii_to_zchars( $z->unicode_to_zscii( $word ) );

    is(length $zchars, 14, "as zchars, band name is 14 chars");

    my $dict_ryche = $z->make_dict_length($zchars);
    is(length $dict_ryche, 9, "trimmed to length, it is nine");

    {
      my $zscii;
      my $ok    = eval { $zscii = $z->zchars_to_zscii( $dict_ryche ); 1 };
      my $error = $@;
      ok(! $ok, "we can't normally decode a word terminated mid-sequence");
      like($error, qr/terminated early/, "...and so says the error");
    }

    {
      my $zscii;
      my $ok    = eval {
        $zscii = $z->zchars_to_zscii(
          $dict_ryche,
          { allow_early_termination => 1 },
        );
        1;
      };
      my $error = $@;
      ok($ok, "...but we can if we pass allow_early_termination")
        or diag $error;;

      is($zscii, "queensr", "we get the expected 7 characters");
    }
  }
};

done_testing;
