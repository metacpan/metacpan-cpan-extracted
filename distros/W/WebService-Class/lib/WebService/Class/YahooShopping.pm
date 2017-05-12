package WebService::Class::YahooShopping;
use strict;
use utf8;
use base qw(WebService::Class::AbstractHTTPRequestClass);
__PACKAGE__->mk_accessors(qw(appid));
__PACKAGE__->base_url('http://shopping.yahooapis.jp/ShoppingWebService/V1/');
sub init{
	my $self = shift;
	my %args = @_;
	$self->SUPER::init(@_);
	$self->appid($args{'appid'});
	$self->urls({
		'item_search'      =>  $self->base_url.'itemSearch',
		'category_ranking' =>  $self->base_url.'categoryRanking',
		'category_search'  =>  $self->base_url.'categorySearch',
		'item_lookup'      =>  $self->base_url.'itemLookup',
		'keyword_ranking'  =>  $self->base_url.'queryRanking',
		'contents_match_item'    =>  $self->base_url.'contentMatchItem',
		'contents_match_ranking' =>  $self->base_url.'contentMatchRanking',
	});
}



sub item_search{
	my $self = shift;
	my $args = shift;
	$args->{appid}=$self->appid;
	$self->request_api()->request('GET',$self->urls()->{'item_search'},$args,{})->parse_xml();
}

sub category_ranking{
	my $self = shift;
	my $args = shift;
	$args->{appid} = $self->appid;
	$self->request_api()->request('GET',$self->urls()->{'category_ranking'},$args,{})->parse_xml();
}

sub category_search{
	my $self = shift;
	my $args = shift;
	$args->{appid} = $self->appid;
	$self->request_api()->request('GET',$self->urls()->{'category_search'},$args,{})->parse_xml();
}

sub item_lookup{
	my $self = shift;
	my $args = shift;
	$args->{appid} = $self->appid;
	$self->request_api()->request('GET',$self->urls()->{'item_lookup'},$args,{})->parse_xml();
}

sub keyword_ranking{
	my $self = shift;
	my $args = shift;
	$args->{appid} = $self->appid;
	$self->request_api()->request('GET',$self->urls()->{'keyword_ranking'},$args,{})->parse_xml();
}

sub contents_match_item{
	my $self = shift;
	my $args = shift;
	$args->{appid} = $self->appid;
	$self->request_api()->request('GET',$self->urls()->{'contents_match_item'},$args,{})->parse_xml();
}

sub contents_match_ranking{
	my $self = shift;
	my $args = shift;
	$args->{appid} = $self->appid;
	$self->request_api()->request('GET',$self->urls()->{'contents_match_ranking'},$args,{})->parse_xml();
}
1;
