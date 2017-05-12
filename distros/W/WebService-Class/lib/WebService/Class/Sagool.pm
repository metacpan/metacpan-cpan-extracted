package WebService::Class::Sagool;
use strict;
use utf8;
use base qw(WebService::Class::AbstractHTTPRequestClass);

__PACKAGE__->base_url('http://sagool.jp/');
__PACKAGE__->mk_accessors(qw(myurl));

sub init{
	my $self = shift;
	$self->SUPER::init(@_);
	my $myurl = shift;
	$self->myurl($myurl);
}


sub related{
	my $self = shift;
	my $keyword = shift;
	$self->request_api()->request('GET',$self->base_url.'/openapi',{
			query=>$keyword,
			lang=>"ja",
			start=>10,
			engine=>"web",
			criendUrl=>$self->myurl,	
			PerPage=>24,
	},{},{})->parse_xml();
}

sub wacaal{
	my $self = shift;
	my $keyword = shift;
	$self->request_api()->request('GET',$self->base_url.'/wacaalapi',{
			type=>"xml",
			engine=>"web",
			clientUrl=>$self->myurl,	
			PerPage=>24,
	},{},{})->parse_xml();
}


1;
