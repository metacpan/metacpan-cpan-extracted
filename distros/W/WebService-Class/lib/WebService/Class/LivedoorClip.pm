package WebService::Class::LivedoorClip;
use strict;
use utf8;
use base qw(WebService::Class::AbstractHTTPandXMLRPCRequestClass);
__PACKAGE__->mk_classdata('endpoint'=>'http://rpc.clip.livedoor.com/');
__PACKAGE__->base_url('http://api.clip.livedoor.com/json/');

sub count{
	my $self = shift;
	my @urls = @_;
	return $self->request_api_xmlrpc()->request('clip.getCount',$self->endpoint.'count/',@urls)->parse_xml();
}

sub myclip{
	my $self = shift;
	my $livedoor_id = shift;
	my $limit = shift;
	my $offset = shift;
	return $self->request_api_http()->request('GET',$self->base_url.'clips/',{
			livedoor_id=>$livedoor_id,
			limit=>$limit,
			offset=>$offset,
	})->result;
}


sub comments{
	my $self = shift;
	my $link = shift;
	my $all = shift;
	return $self->request_api_http()->request('GET',$self->base_url.'comments/',{
			link=>$link,
			all=>$all,
	})->request;
}
1;

