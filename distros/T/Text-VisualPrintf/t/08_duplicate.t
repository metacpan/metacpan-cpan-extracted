use strict;
use warnings;
use utf8;
use open IO => ':utf8', ':std';
use Text::VisualPrintf;
$Text::VisualPrintf::REORDER = 1;

use Test::More;

is( Text::VisualPrintf::sprintf( '%s',         'あ'),        'あ',       '%s' );
is( Text::VisualPrintf::sprintf( '%s %s',      'あ', 'い'),  'あ い',    '%s %s' );
is( Text::VisualPrintf::sprintf( '%2$s %s',    'あ', 'い'),  'い あ',    '%2$s %s' );
is( Text::VisualPrintf::sprintf( '%2$s %s %s', 'あ', 'い'),  'い あ い', '%2$s %s %s' );

done_testing;
