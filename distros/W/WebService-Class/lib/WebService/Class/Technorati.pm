package WebService::Class::Technorati;
use strict;
use utf8;
use base qw(WebService::Class::AbstractHTTPRequestClass);

__PACKAGE__->base_url('http://api.technorati.jp/');
__PACKAGE__->mk_accessors(qw(key));
sub init{
	my $self = shift;
	my %args = @_;
	$self->SUPER::init(@_);
	$self->key($args{'key'});
}


sub related{
	my $self = shift;
	my $query = shift;
	my $args = shift;
	$args->{query}=$query;
	$args->{key}=$self->key;
	$self->request_api()->request('GET',$self->base_url.'search',$args,{})->parse_xml();
}

sub url{
	my $self = shift;
	my $url = shift;
	my $args = shift;
	$args->{url}=$url;
	$args->{key}=$self->key;
	$self->request_api()->request('GET',$self->base_url.'cosmos',$args,{})->parse_xml();
}
sub tag{
	my $self = shift;
	my $tag= shift;
	my $args = shift;
	$args->{tag}=$tag;
	$args->{key}=$self->key;
	$self->request_api()->request('GET',$self->base_url.'tag',$args,{})->parse_xml();
}

1;
