use strict;
use warnings;
use utf8;
use open IO => ':utf8', ':std';
use lib 't/lib'; use Text::VPrintf;

use Test::More;

is( Text::VPrintf::sprintf( '%s',         'あ'),        'あ',       '%s' );
is( Text::VPrintf::sprintf( '%s %s',      'あ', 'い'),  'あ い',    '%s %s' );
is( Text::VPrintf::sprintf( '%2$s %s',    'あ', 'い'),  'い あ',    '%2$s %s' );
is( Text::VPrintf::sprintf( '%2$s %s %s', 'あ', 'い'),  'い あ い', '%2$s %s %s' );

done_testing;
