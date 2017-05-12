package WebService::Class::Kizasi;
use strict;
use utf8;
use base qw(WebService::Class::AbstractHTTPRequestClass);
__PACKAGE__->base_url('http://kizasi.jp/kizapi.py');

sub rank{
	my $self = shift;
	$self->request_api()->request('GET',$self->base_url,{type=>"rank"},{},{})->parse_xml();
}

sub coll{
	my $self = shift;
	my $keyword = shift;
	$self->request_api()->request('GET',$self->base_url,{type=>"coll",'span'=>24,'kw_expr'=>$keyword},{},{})->parse_xml();
}

sub channel{
	my $self = shift;
	my $keyword = shift;
	$self->request_api()->request('GET',$self->base_url,{type=>"channel",'span'=>24,'kw_expr'=>$keyword},{},{})->parse_xml();
}

sub kwic{
	my $self = shift;
	my $keyword = shift;
	$self->request_api()->request('GET',$self->base_url,{type=>"kwic",'span'=>24,'kw_expr'=>$keyword},{},{})->parse_xml();
}


1;
