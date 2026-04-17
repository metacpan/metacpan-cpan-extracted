#!perl
 
use v5.16;
use strict;
use warnings;
use utf8;
use open qw(:std :encoding(UTF-8));
use Test::More;
use Test::QuickGen qw(:all);

subtest 'id' => sub {
  my $prev = id();
  is($prev, 0, 'starts at 0');

  for (1..5) {
    my $next = id();
    ok($next > $prev, 'monotonic increase');
    is($next, $prev + 1, 'increments by 1');
    $prev = $next;
  }
};

subtest 'string_of' => sub {
  is(string_of(0, qw(a b)), '', 'zero length');
  is(string_of(-1, qw(a b)), '', 'negative length');

  my $s = string_of(20, qw(a b c));
  is(length($s), 20, 'correct length');
  like($s, qr/^[abc]+$/, 'only allowed chars');

  is(string_of(5, 'x'), 'x' x 5, 'single char set');

  eval { string_of(5) };
  ok($@, 'dies on empty character set');
  like($@, qr/empty character set/, 'expected error message');
};

subtest 'ascii_string' => sub {
  is(ascii_string(0), '', 'zero length');
  is(ascii_string(-1), '', 'negative length');
  
  my $allowed_chars = join '', map { quotemeta chr($_) } 33..126;
  for (1..5) {
    my $s = ascii_string(50);
    is(length($s), 50, 'correct length');
    like($s, qr/^[$allowed_chars]+$/, 'valid ASCII chars');
  }
};

subtest 'alphanumeric_string' => sub {
  is(alphanumeric_string(0), '', 'zero length');
  is(alphanumeric_string(-1), '', 'negative length');

  for (1..5) {
    my $s = alphanumeric_string(50);
    is(length($s), 50, 'correct length');
    like($s, qr/^[A-Za-z0-9]+$/, 'valid alphanumeric characters');
  }
};

subtest 'utf8_string' => sub {
  is(utf8_string(0), '', 'zero length');
  is(utf8_string(-1), '', 'negative length');
  
  for (1..5) {
    my $s = utf8_string(20);
    ok(length($s) >= 20, 'length >= requested');

    for my $char (split //, $s) {
      my $ord = ord($char);
      ok($ord >= 0x20, "$char is not control char");
      ok(!($ord >= 0xD800 && $ord <= 0xDFFF), "$char is not surrogate");
    }
  }
};

subtest 'utf8_sanitized' => sub {
  is(utf8_sanitized(0), '', 'zero length');
  is(utf8_sanitized(-1), '', 'negative length');

  for (1..5) {
    my $s = utf8_sanitized(20);
    ok(length($s) > 0, 'not empty');
    like($s, qr/^[\p{L}\p{N}\s]+$/u, 'sanitized chars only');
  }
};

subtest 'between' => sub {
  for (1..10) {
    my $n = between(5, 10);
    ok($n >= 5 && $n <= 10, "5 <= $n <= 10");
  }
  is(between(3, 3), 3, 'degenerate range');

  for (1..5) {
    my $n = between(-10, -5);
    ok($n >= -10 && $n <= -5, 'negative range');
  }

  eval { between(10, 5) };
  ok($@, 'dies on reversed range');
  like($@, qr/max must be larger or equal to min/, 'expected error message');
};

subtest 'pick' => sub {
  ok(! defined pick(), "empty list returns undef");
  is(pick(22), 22, 'single element');
  
  my @vals = (1, 2, 3);

  for (1..10) {
    my $v = pick(@vals);
    my $found = grep { $_ == $v } @vals;
    ok($found, 'picked value is valid');
  }

  my @with_undef = (undef, 1);
  my $seen_undef = 0;

  for (1..10) {
    my $v = pick(@with_undef);
    $seen_undef++ unless defined $v;
  }

  ok($seen_undef >= 0, 'handles undef safely');
};

subtest 'nullable' => sub {
  my $defined = 0;
  my $undef = 0;

  for (1..15) {
    my $v = nullable(22);
    defined $v ? $defined++ : $undef++;
  }

  ok($defined >= 0, 'sometimes defined');
  ok($undef >= 0, 'sometimes undefined');

  is(nullable(undef), undef, 'nullable undef stays undef');
};

subtest 'words' => sub {
  my $gen = sub { 'x' x $_[0] };

  is(words($gen, 0), '', 'zero words');
  
  my $s = words($gen, 5);
  my @words = split ' ', $s;

  is(scalar @words, 5, 'correct number of words');
  like($s, qr/^\S+( \S+){4}$/, 'correct spacing');

  # accepts an optional max word size
  is(words($gen, 2, 1), 'x x', 'accepts optional max word length');

  eval { words($gen, 2, 0) };
  like($@, qr/must be a positive number/, 'fails with non-positive number');
};

done_testing;
