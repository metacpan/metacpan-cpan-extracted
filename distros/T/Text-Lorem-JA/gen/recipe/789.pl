# -*- coding: utf-8 -*-

# http://www.aozora.gr.jp/cards/000148/card789.html
# 
# 図書カード: No.789
# 
# 作品名:     吾輩は猫である
# 作品名読み: わがはいはねこである
# 著者名:     夏目 漱石
# 
# http://www.aozora.gr.jp/cards/000148/files/789_ruby_5639.zip
# wagahaiwa_nekodearu.txt

use strict;
use warnings;
use utf8;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catdir catfile );

BEGIN {
    require do { catfile(catdir(dirname(__FILE__), '..'), 'Aozora.pm') };
}

package NakamidashiTrimmer;

use parent -norequire, 'Aozora::TextFilter';

sub input {
    my ($self, $line) = @_;

    if ($line !~ m{^ .*? ［＃ .*? 中見出し］ \s* $}xmso) {
        $self->puts($line);
    }
}

package AccentTrimmer;

use parent -norequire, 'Aozora::TextFilter';

sub input {
    my ($self, $line) = @_;

    $line =~ s{〔 (.*?) 〕}{ $1 }gxmso;
    $self->puts($line);
}

package Aozora789;
use parent -norequire, 'Aozora::AozoraFetcher';

our $URL    = 'http://www.aozora.gr.jp/cards/000148/files/789_ruby_5639.zip';
our $SOURCE = 'wagahaiwa_nekodearu.txt';

sub run {
    my ($class) = @_;

    $class->SUPER::run({
        url => $URL, archive_name => '789.zip', source => $SOURCE,
        output => '789.txt',
    });
}

sub create_manager {
    my ($self, $output_file) = @_;

    my $manager = Aozora::TextFilterManager->new();
    $manager->add_filter(Aozora::AozoraTrimHeader->new());
    $manager->add_filter(Aozora::AozoraTrimTrailer->new());
    $manager->add_filter(NakamidashiTrimmer->new());
    $manager->add_filter(Aozora::BlankTrimmer->new());
    $manager->add_filter(Aozora::AozoraTrimmer->new());
    $manager->add_filter(AccentTrimmer->new());
    $manager->add_filter(Aozora::FileOutput->new($output_file));
    $manager->setup();

    return $manager;
}

package main;

Aozora789->run();
