use strict;
use warnings;
use Test::More tests => 7;
use Unicode::EastAsianWidth::Detect qw(is_cjk_lang);

is(is_cjk_lang('ja_JP.UTF-8'), 1);
is(is_cjk_lang('ja_JP.eucJP'), 1);
is(is_cjk_lang('ja_JP.CP932'), 1);
is(is_cjk_lang('ja.CP932'), 1);
is(is_cjk_lang('POSIX'), 0);
is(is_cjk_lang('C'), 0);
is(is_cjk_lang('en_US.UTF-8'), 0);
