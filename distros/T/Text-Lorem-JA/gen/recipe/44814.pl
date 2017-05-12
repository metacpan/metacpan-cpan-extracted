# -*- coding: utf-8 -*-

# http://www.aozora.gr.jp/cards/001154/card44814.html
# 
# 図書カード: No.44814
# 
# 作品名:     劇の好きな子供たちへ
# 作品名読み: げきのすきなこどもたちへ
# 著者名:     岸田 国士
# 
# http://www.aozora.gr.jp/cards/001154/files/44814_txt_40147.zip
# gekino_sukina_kodomo.txt

use strict;
use warnings;
use utf8;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catdir catfile );

BEGIN {
    require do { catfile(catdir(dirname(__FILE__), '..'), 'Aozora.pm') };
}

package AccentTrimmer;

use parent -norequire, 'Aozora::TextFilter';

sub input {
    my ($self, $line) = @_;

    $line =~ s{〔 (.*?) 〕}{ $1 }gxmso;
    $self->puts($line);
}

package Aozora44814;
use parent -norequire, 'Aozora::AozoraFetcher';

our $URL    = 'http://www.aozora.gr.jp/cards/001154/files/44814_txt_40147.zip';
our $SOURCE = 'gekino_sukina_kodomo.txt';

sub run {
    my ($class) = @_;

    $class->SUPER::run({
        url => $URL, archive_name => '44814.zip', source => $SOURCE,
        output => '44814.txt',
    });
}

sub create_manager {
    my ($self, $output_file) = @_;

    my $manager = Aozora::TextFilterManager->new();
    $manager->add_filter(Aozora::AozoraTrimHeader->new());
    $manager->add_filter(Aozora::AozoraTrimTrailer->new());
    $manager->add_filter(Aozora::NakamidashiTrimmer->new());
    $manager->add_filter(Aozora::BlankTrimmer->new());
    $manager->add_filter(Aozora::AozoraTrimmer->new());
    $manager->add_filter(AccentTrimmer->new());
    $manager->add_filter(Aozora::FileOutput->new($output_file));
    $manager->setup();

    return $manager;
}

package main;

Aozora44814->run();
