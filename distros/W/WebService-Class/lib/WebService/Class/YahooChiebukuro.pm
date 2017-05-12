package WebService::Class::YahooChiebukuro;
use strict;
use utf8;
use base qw(WebService::Class::AbstractHTTPRequestClass);
__PACKAGE__->mk_accessors(qw(appid));
__PACKAGE__->base_url('http://chiebukuro.yahooapis.jp/Chiebukuro/V1/');

sub init{
	my $self = shift;
	my %args = @_;
	$self->SUPER::init(@_);
	$self->appid($args{'appid'});
	$self->urls({
		'question_search' => $self->base_url.'questionSearch',
		'category_tree'   => $self->base_url.'categoryTree',
	});
}


sub question_search{
	my $self    = shift;
	my $keyword = shift;
	my $args    = shift;
	$args->{keyword}=$keyword;
	$args->{appid}=$self->appid;
	$self->request_api()->request('GET',$self->urls()->{'question_search'},$args,{})->parse_xml();
}


sub category_tree{
	my $self = shift;
	my $categoryid = shift;
	my $args = {
			appid=>$self->appid,
			categoryid=>$categoryid
	};
	$self->request_api()->request('GET',$self->urls()->{'category_tree'},$args,{})->parse_xml();
}



1;
