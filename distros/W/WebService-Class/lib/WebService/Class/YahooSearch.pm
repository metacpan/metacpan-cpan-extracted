package WebService::Class::YahooSearch;
use strict;
use utf8;
use base qw(WebService::Class::AbstractHTTPRequestClass);
__PACKAGE__->mk_accessors(qw(appid));
__PACKAGE__->base_url('http://api.search.yahoo.co.jp/');
sub init{
	my $self = shift;
	my %args = @_;
	$self->SUPER::init(@_);
	$self->appid($args{'appid'});
	$self->urls({
		'web_search' =>  $self->base_url.'WebSearchService/V1/webSearch',
		'image_search' =>  $self->base_url.'ImageSearchService/V1/imageSearch',
		'video_search' =>  $self->base_url.'VideoSearchService/V1/videoSearch',
		'related_search' =>  $self->base_url.'AssistSearchService/V1/webunitSearch',
	});
}


sub web_search{
	my $self    = shift;
	my $keyword = shift;
	my $args    = shift;
	unless($args){
		$args    = {
				type=>"any",
				start=>1,
				results=>10,
				format=>"any",
				language=>"ja",
		}
	}
	$args->{keyword}=$keyword;
	$args->{appid}=$self->appid;
	$self->request_api()->request('GET',$self->urls()->{'web_search'},$args,{})->parse_xml();
}



sub image_search{
	my $self = shift;
	my $keyword = shift;
	my $args    = shift;
	unless($args){
		$args    = {
			type=>"any",
			start=>1,
			results=>10,
			format=>"any",
			language=>"ja",
			coloration=>"any",
		}
	}
	$args->{keyword}=$keyword;
	$args->{appid}=$self->appid;
	$self->request_api()->request('GET',$self->urls()->{'image_search'},$args,{})->parse_xml();
}

sub video_search{
	my $self = shift;
	my $keyword = shift;
	my $args    = shift;
	unless($args){
		$args    = {
			type=>"any",
			start=>1,
			results=>10,
			format=>"any",
			language=>"ja",
			coloration=>"any",
		}
	}
	$args->{keyword}=$keyword;
	$args->{appid}=$self->appid;
	$self->request_api()->request('GET',$self->urls()->{'video_search'},$args,{})->parse_xml();
}



sub related_search{
	my $self = shift;
	my $keyword = shift;
	my $args    = shift;
	unless($args){
		$args    = {
				start=>1,
				results=>10,
		}
	}
	$args->{keyword}=$keyword;
	$args->{appid}=$self->appid;
	$self->request_api()->request('GET',$self->urls()->{'related_search'},$args,{})->parse_xml();
}



1;
