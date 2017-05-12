# -*- coding: utf-8 -*-

# http://www.aozora.gr.jp/cards/001475/card52960.html
# 
# 図書カード: No.52960
# 
# 作品名: 赤い船のお客
# 作品名読み: あかいふねのおきゃく
# 著者名: 小川 未明
# 
# http://www.aozora.gr.jp/cards/001475/files/52960_ruby_46826.zip
# akai_funeno_okyaku.txt

use strict;
use warnings;
use utf8;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catdir catfile );

BEGIN {
    require do { catfile(catdir(dirname(__FILE__), '..'), 'Aozora.pm') };
}

package Aozora52960;
use parent -norequire, 'Aozora::AozoraFetcher';

our $URL    = 'http://www.aozora.gr.jp/cards/001475/files/52960_ruby_46826.zip';
our $SOURCE = 'akai_funeno_okyaku.txt';

sub run {
    my ($class) = @_;

    $class->SUPER::run({
        url => $URL, archive_name => '52960.zip', source => $SOURCE,
        output => '52960.txt',
    });
}

package main;

Aozora52960->run();
