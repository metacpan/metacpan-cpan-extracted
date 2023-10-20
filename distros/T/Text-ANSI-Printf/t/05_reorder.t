use strict;
use warnings;
use utf8;
use open IO => ':utf8', ':std';
use Text::ANSI::Printf qw(ansi_printf ansi_sprintf);

use Data::Dumper;
use Test::More;

sub test {
    my $result = pop;
    my($format, @param) = @_;
    my $comment = do { local $" = ', '; sprintf "'%s', @param", $format };
    is(ansi_sprintf($format, @param), $result, $comment);
}

test( '%2$s %1$s', "abcde", "fghij",           "fghij abcde");
test( '%2$s %1$s', "あいうえお", "かきくけこ", "かきくけこ あいうえお");
test( '%2$s %1$s', "ｱｲｳｴｵ", "ｶｷｸｹｺ",           "ｶｷｸｹｺ ｱｲｳｴｵ");

test( '%2$6s %1$6s', "abcde", "fghij",             " fghij  abcde");
test( '%2$11s %1$11s', "あいうえお", "かきくけこ", " かきくけこ  あいうえお");
test( '%2$6s %1$6s', "ｱｲｳｴｵ", "ｶｷｸｹｺ",             " ｶｷｸｹｺ  ｱｲｳｴｵ");

test( '%10$s %9$s %8$s %7$s %6$s %5$s %4$s %3$s %2$s %1$s',
      split(//, "１２３４５６７８９０"),
      "０ ９ ８ ７ ６ ５ ４ ３ ２ １");

test( '%10$s %9$s %8$s %7$s %6$s %5$s %4$s %3$s %2$s %1$s',
      split(//, "ｱｲｳｴｵｶｷｸｹｺ"),
      "ｺ ｹ ｸ ｷ ｶ ｵ ｴ ｳ ｲ ｱ");

# zero-width output

test( '%10$.0s %9$s %8$.0s %7$s %6$.0s %5$s %4$.0s %3$s %2$.0s %1$s',
      split(//, "ｱｲｳｴｵｶｷｸｹｺ"),
      " ｹ  ｷ  ｵ  ｳ  ｱ");

test( '%10$.0s %9$.0s %8$.0s %7$.0s %6$.0s %5$.0s %4$.0s %3$.0s %2$.0s %1$s',
      split(//, "ｱｲｳｴｵｶｷｸｹｺ"),
      "         ｱ");

test( '%10$s %9$.0s %8$.0s %7$.0s %6$.0s %5$.0s %4$.0s %3$.0s %2$.0s %1$.0s',
      split(//, "ｱｲｳｴｵｶｷｸｹｺ"),
      "ｺ         ");

done_testing;
