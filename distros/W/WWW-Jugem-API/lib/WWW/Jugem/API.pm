package WWW::Jugem::API;
use 5.008005;
use strict;
use warnings;
use utf8;
use Mouse;
use Furl;
use JSON;

our $VERSION = "0.01";

use constant BASE_URL => 'http://api.jugemkey.jp/api/horoscope/free/';

has 'date' => (is => 'rw',isa => 'Str');

has furl => (
  is => 'rw',
 isa => 'Furl',
 lazy_build => 1
);

sub _build_furl{
 my $self = shift;
 return Furl->new(
    agent => 'WWW::Jugem::API(Perl)',
    timeout => 20,
 );
}

my %star_chart = (
   '牡羊座' => 0,
   '牡牛座' => 1,
   '双子座' => 2,
   '蟹座'   => 3,
   '獅子座' => 4,
   '乙女座' => 5,
   '天秤座' => 6,
   '蠍座'   => 7,
   '射手座' => 8,
   '山羊座' => 9,
   '水瓶座' => 10,
   '魚座'   => 11
);

sub fetch{
 my ($self,$star) = @_;
 my $date = $self->date;
 my $url = BASE_URL.$date;
 my $response = $self->furl->get($url);
 my $content = JSON::decode_json($response->content);
 return $content->{horoscope}->{$date}->[$star_chart{$star}];
}

1;


__END__

=encoding utf-8

=head1 NAME

WWW::Jugem::API - It's jugem uranai API

=head1 SYNOPSIS

    use WWW::Jugem::API;

    my $jugem = WWW::Jugem::API->new(date => '2014/09/09');
    my $response = $jugem->fetch('双子座');
    print $response->{content} #=> '不利な状況でも、強気な姿勢を崩さないことがポイント。今日の仕事では、あなたらしく素晴らしい結果が出せそうです。'
    print $response->{color} #=> 'ホワイト'
    print $response->{sign}  #=> '双子座'
    pritn $response->{jog} # 3  <1~5> #仕事運

=head1 DESCRIPTION

 WWW::Jugem::API is API by given URL <http://jugemkey.jp/api/waf/api.ph>

=head1 LICENSE

Copyright (C) sue7ga.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sue7ga E<lt>sue77ga@gmail.comE<gt>

=cut

