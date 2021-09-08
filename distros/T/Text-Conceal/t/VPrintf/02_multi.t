use strict;
use warnings;
use utf8;
use open IO => ':utf8', ':std';
use lib 't/lib'; use Text::VPrintf;

use Test::More tests => 4;

# single half-width kana is special
is( Text::VPrintf::sprintf( "%s-%2s-%3s", qw"ｱ ｲ ｳ"),  "ｱ- ｲ-  ｳ", 'multiple half' );

is( Text::VPrintf::sprintf( "%s-%s", qw"ｱ 壱"),  "ｱ-壱", 'half-wide mix' );

is( Text::VPrintf::sprintf( "%s-%s", qw"壱 ｱ"),  "壱-ｱ", 'half-wide mix' );

# work fine even on buggy code.
is( Text::VPrintf::sprintf(
	join(' ', ('%s') x 27),
	qw(一 二 三 四 五 六 七 八 九 十 一 二 三 四 五 六 七 八 九 十 一 二 三 四 五 六 ｱ)),
    '' . q(一 二 三 四 五 六 七 八 九 十 一 二 三 四 五 六 七 八 九 十 一 二 三 四 五 六 ｱ),
    'max-number exceptional');

done_testing;
