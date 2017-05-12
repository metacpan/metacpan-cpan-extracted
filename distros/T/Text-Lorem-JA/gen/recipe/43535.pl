# -*- coding: utf-8 -*-

# http://www.aozora.gr.jp/cards/000042/card43535.html
# 
# 図書カード: No.43535
# 
# 作品名:     学問の自由
# 作品名読み: がくもんのじゆう
# 著者名:     寺田 寅彦
# 
# http://www.aozora.gr.jp/cards/000042/files/43535_ruby_24441.zip
# gakumonno_jiyu.txt

use strict;
use warnings;
use utf8;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catdir catfile );

BEGIN {
    my $module = catfile(catdir(dirname(__FILE__), '..'), 'Aozora.pm');
    require $module;
}

package CustomTailTrimmer;

use parent -norequire, 'Aozora::TextFilter';

sub input {
    my ($self, $line) = @_;

    $line =~ s{^\s* ［＃地から .+? 字上げ］.*? $}{}xmso;
    $self->puts($line);
}

package Aozora43535;
use parent -norequire, 'Aozora::AozoraFetcher';

our $URL    = 'http://www.aozora.gr.jp/cards/000042/files/43535_ruby_24441.zip';
our $SOURCE = 'gakumonno_jiyu.txt';

sub run {
    my ($class) = @_;

    $class->SUPER::run({
        url => $URL, archive_name => '43535.zip', source => $SOURCE,
        output => '43535.txt',
    });
}

sub create_manager {
    my ($self, $output_file) = @_;

    my $manager = Aozora::TextFilterManager->new();
    $manager->add_filter(Aozora::AozoraTrimHeader->new());
    $manager->add_filter(Aozora::AozoraTrimTrailer->new());
    $manager->add_filter(CustomTailTrimmer->new());
    $manager->add_filter(Aozora::BlankTrimmer->new());
    $manager->add_filter(Aozora::AozoraTrimmer->new());
    $manager->add_filter(Aozora::FileOutput->new($output_file));
    $manager->setup();

    return $manager;
}

package main;

Aozora43535->run();
