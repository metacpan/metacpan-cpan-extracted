
package WebService::Class::Gree;
use warnings;
use strict;
use CGI::Util qw(escape);
use base qw(WebService::Class::AbstractHTTPRequestClass);
__PACKAGE__->base_url("http://open.gree.jp/");

sub init{
	my $self = shift;
	$self->SUPER::init(@_);
	$self->urls({
		'list'      => $self->base_url.'api/keyword/list/',
		'hot'           => $self->base_url.'api/keyword/hot',
		'hot_periodic'  => $self->base_url.'api/keyword/hot/periodic"',
		'keyword'   => $self->base_url.'api/keyword/%s',
		'related'   => $self->base_url.'api/keyword/related/%s',
		'random'    => $self->base_url.'api/keyword/random"',
	});


}


sub list{
	my $self = shift;
	return $self->request_api()->request('get',$self->urls->{'list'})->parse_xml();
}

sub hot{
	my $self = shift;
	return $self->request_api()->request('get',$self->urls->{'hot'})->parse_xml();
}

sub hot_periodic{
	my $self = shift;
	return $self->request_api()->request('get',$self->urls->{'hot_periodic'})->parse_xml();
}


sub random{
	my $self = shift;
	return $self->request_api()->request('get',$self->urls->{'random'})->parse_xml();
}

sub related{
	my $self = shift;
	my $keyword = shift;
	return $self->request_api()->request('get',sprintf($self->urls->{'related'},escape($keyword)))->parse_xml();
}

sub keyword{
	my $self = shift;
	my $id = shift;
	return $self->request_api()->request('get',sprintf($self->urls->{'keyword'},$id))->parse_xml();
}


1;
