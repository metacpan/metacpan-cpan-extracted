# -*- coding: utf-8 -*-

# http://www.aozora.gr.jp/cards/000042/card2363.html
# 
# 図書カード: No.2363
# 
# 作品名: 茶わんの湯
# 作品名読み: ちゃわんのゆ
# 作品集名: 寺田寅彦随筆集第二巻「科学について」
# 作品集名読み: てらだとらひこずいひつしゅうだいにかん「かがくについて」
# 著者名: 寺田 寅彦
# 
# http://www.aozora.gr.jp/cards/000042/files/2363_ruby_4700.zip
# chawanno_yu.txt

use strict;
use warnings;
use utf8;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catdir catfile );

BEGIN {
    my $module = catfile(catdir(dirname(__FILE__), '..'), 'Aozora.pm');
    require $module;
}

package Aozora2363;
use parent -norequire, 'Aozora::AozoraFetcher';

our $URL    = 'http://www.aozora.gr.jp/cards/000042/files/2363_ruby_4700.zip';
our $SOURCE = 'chawanno_yu.txt';

sub run {
    my ($class) = @_;

    $class->SUPER::run({
        url => $URL, archive_name => '2363.zip', source => $SOURCE,
        output => '2363.txt',
    });
}

package main;

Aozora2363->run();
