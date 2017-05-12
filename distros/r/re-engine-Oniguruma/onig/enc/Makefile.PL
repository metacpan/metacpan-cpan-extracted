require 5.009005;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

my $oe = $Config{obj_ext};
my @obj = map { $_ . $oe } qw(
 ascii big5 cp1251 euc_jp euc_kr euc_tw gb18030 iso8859_1 iso8859_10
 iso8859_11 iso8859_13 iso8859_14 iso8859_15 iso8859_16 iso8859_2
 iso8859_3 iso8859_4 iso8859_5 iso8859_6 iso8859_7 iso8859_8 iso8859_9
 koi8_r sjis unicode utf16_be utf16_le utf32_be utf32_le utf8
);

WriteMakefile(
  NAME         => 'onig/enc',
  AUTHOR       => 'Andy Armstrong <andy@hexten.net>',
  VERSION_FROM => '../../lib/re/engine/Oniguruma.pm',
  DEFINE       => '-DHAVE_CONFIG_H',
  clean        => { FILES => "*.o *.lo *$oe" },
  OBJECT       => join( ' ', @obj ),
  PM           => {},
  XS           => {},
  INC          => '-I..',
  linkext      => { LINKTYPE => 'static' }
);
