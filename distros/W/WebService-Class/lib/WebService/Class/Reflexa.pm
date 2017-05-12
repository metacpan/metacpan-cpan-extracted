package WebService::Class::Reflexa;
use strict;
use utf8;
use base qw(WebService::Class::AbstractHTTPRequestClass);
__PACKAGE__->base_url('http://labs.preferred.jp/reflexa/api.php');


sub related{
	my $self = shift;
	my $keyword = shift;
	$self->request_api()->request('GET',$self->base_url,{q=>$keyword,'formal'=>'xml'},{},{})->parse_xml();
}


1;
