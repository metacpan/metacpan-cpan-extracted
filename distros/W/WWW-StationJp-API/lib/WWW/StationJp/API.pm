package WWW::StationJp::API;
use 5.008005;
use strict;
use warnings;
use URI;
use LWP::UserAgent;
use JSON;

our $VERSION = "0.01";

use constant BASE_URL => 'http://www.ekidata.jp/api';

use Mouse;

sub response{
 my($self,$url) = @_;
 my $ua = LWP::UserAgent->new;
 my $res = $ua->get($url);
}

sub pref{
 my($self,$pref) = @_;
 my $url = URI->new(BASE_URL."/p/".$pref->{prefcode}.".json");
 my $res = $self->response($url);
 $res = xml_parse($res->content);
 return JSON::decode_json($res); 
}

sub line{
 my($self,$line) = @_;
 my $url = URI->new(BASE_URL."/l/".$line->{linecode}.".json");
 my $res = $self->response($url);
 $res = xml_parse($res->content);
 return JSON::decode_json($res); 
}

sub station{
 my($self,$station) = @_;
 my $url = URI->new(BASE_URL."/s/".$station->{stationcode}.".json");
 my $res = $self->response($url);
 $res = xml_parse($res->content);
 return JSON::decode_json($res); 
}

sub group{
 my($self,$group) = @_;
 my $url = URI->new(BASE_URL."/g/".$group->{stationcode}.".json");
 my $res = $self->response($url);
 $res = xml_parse($res->content);
 return JSON::decode_json($res); 
}

sub near{
 my($self,$near) = @_;
 my $url = URI->new(BASE_URL."/n/".$near->{linecode}.".json");
 my $res = $self->response($url);
 $res = xml_parse($res->content);
 return JSON::decode_json($res); 
}

sub xml_parse{
 my ($content) = @_;
 $content =~ s/if\(typeof\(xml\)==\'undefined\'\) xml = {};//;
 $content =~ s/xml.data = //; 
 $content =~ s/if\(typeof\(xml.onload\)==\'function\'\) xml.onload\(xml.data\);//;
 return $content;
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::StationJp::API - It's a StationJP Module.

=head1 SYNOPSIS

    use WWW::StationJp::API;

  my $station = new WWW::StationJp::API();

  my $line = $station->line({linecode => 11302});
 
  print $line->{line_name};

=head1 DESCRIPTION

WWW::StationJp::API is a StationJP Module.

=head1 LICENSE

Copyright (C) sue7ga.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sue7ga E<lt>sue77ga@gmail.comE<gt>

=cut

