use strict;
use warnings;
use utf8;
use Test::More;
use Data::Dumper;
use Text::Amuse::Functions qw/muse_format_line
                              muse_fast_scan_header/;

is muse_format_line(html => '<ruby>先|ま</ruby>'), '<ruby><rb>先</rb><rt>ま</rt></ruby>';

done_testing;

