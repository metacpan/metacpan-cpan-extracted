package WWW::Shorten::ptl;
use strict;
use warnings;
our $VERSION = '0.04';

use JSON::Any;
use Carp;
use URI;

use base qw/WWW::Shorten::generic Exporter/;

our @EXPORT = qw/makeashorterlink makealongerlink/;

sub new
{
  my ($cls, @prm)= @_;
  
  if ( @prm % 2 ) {
    croak "parameters should be HASH form";
  }

  my %org_prm = @prm;
  my %prm;
  for my $key (qw/apikey/) {
    if (exists $org_prm{$key}) {
      $prm{$key} = delete $org_prm{$key};
    }
  }
  if ( %org_prm ) {
    carp "unknown parameter keys:", join(",", keys %org_prm);
  }

	my $ua = __PACKAGE__->ua;
	$ua->requests_redirectable([]);
  bless { ua => $ua, %prm }, $cls;
}

sub apikey
{
	my $self = shift;
	if ( @_ ) {
		$self->{apikey} = shift;
	}
	$self->{apikey};
}

sub shorten
{
	my $self = shift;
	my $url = shift;

	my $apikey = $self->apikey;
	if ( !$apikey ) {
		croak "no API-Key has been set";
	}

	if ( !$url ) {
		carp "no url passed";
		return;
	}

	my $uri = URI->new("http://p.tl/api/api_simple.php");
	$uri->query_form(
			key => $apikey,
			url => $url,
		);


	my $res = $self->{ua}->get($uri->as_string);

	if (!$res->is_success) {
		carp "failed to request : ", $res->status_line;
		return;
	}

	JSON::Any->jsonToObj($res->content);
}

sub extract 
{
	my $self = shift;

	my $url = shift;
	if (!$url) {
		carp "no url passed";
		return;
	}

	if ( !$self->_check_url($url) ) {
		carp "given url is not for p.tl : ", $url;
		return;
	}

	my $res = $self->{ua}->head($url);
	$res->header( "Location" );
}	

sub _check_url
{
	my $self = shift;
	my $url = shift;

	scalar $url =~ m{^http://p\.tl/.+};
}

sub makeashorterlink
{
	my $url = shift;
	my $apikey = shift;

	if ( !$url ) {
		carp "no url passed";
		return;
	}

	if ( !$apikey ) {
		carp "no apikey passed";
		return;
	}

	my $res = WWW::Shorten::ptl->new(apikey => $apikey)->shorten($url);

	return if !$res;

	if ( $res->{status} ne "ok" ) {
		carp "request failed: ", $res->{status};
		return;
	}

	return $res->{short_url};
}

sub makealongerlink
{
	my $url = shift;

	if ( !$url ) {
		carp "no url passed";
		return;
	}

	WWW::Shorten::ptl->new->extract($url);
}

1;
__END__

=head1 NAME

WWW::Shorten::ptl - interface to shorten URLs with http://p.tl/

=head1 SYNOPSIS

  use WWW::Shorten::ptl ();

  my $ptl = WWW::Shorten::ptl->new(apikey => $apikey);
  my $res = $ptl->shorten($url);
  my $shorturl = $res->{short_url} || die "failed to shorten $url";

  my $longurl = $ptl->extract($shorturl);

or

  use WWW::Shorten::ptl;

  my $shorturl = makeashorterlink($url, 'API-Key');
  my $url = makealongerlink($shorturl);

=head1 DESCRIPTION

WWW::Shorten::ptl provides interface to shorten URLs using http://p.tl/.

=head1 API KEY

As p.tl requires I<API-Key> for each access using its APIs,
you should apply your I<API-Key> for p.tl to shorten URLs with this module.

you can get I<API-Key> for p.tl at L<http://p.tl/key_create.php>.

I<API-Key> is required only for shortening URLs.
URL extraction service doesn't need I<API-Key>

=head1 OO INTERFACE

=head2 new([apikey => I<API-Key>])

creates an instance of WWW::Shorten::ptl with given I<API-Key>.

=head2 $obj->apikey([I<API-Key>])

set or get I<API-Key> for this instance.

=head2 $obj->shorten($url)

shorten $url, and returns HASHREF with following keys.

  status    -- see 'RESULT STATUS' section
  long_url  -- given (original) url
  short_url -- shortened url
  counter   -- # of requests in a period. (currently, api request is limited to 1000 calls/day)

dies if no I<API-Key> is set.

=head3 RESULT STATUS

the 'status' should be one of below.

  'ok'							-- url is successfully shortened 
  'empty long url'	-- input url is empty (should not occur when using this module)
  'empty API key'		-- API key is not specified (ditto.)
  'API limit'				-- request limit exceeded.
  'invalid API key' -- given API key is invalid
  'invalid long url'-- given url cannot be shortened (that url may be already shortened)

=head2 $obj->extract($url)

returns extracted $url. or undef when $url is not a form of p.tl.


=head1 FUNCTION INTERFACE

As mentioned above, additional parameter I<API-Key> is required for each shorten/expand functions.

=head2 makeashorterlink($url, I<API-Key>)

returns shortened url. or undef when failed to shorten url.

=head2 makealongerlink($url)

returns expanded url for $url or undef when $url is not a form of p.tl

=head1 AUTHOR

turugina E<lt>turugina {at} cpan.orgE<gt>

=head1 SEE ALSO

L<WWW::Shorten> L<http://p.tl/> L<http://dev.pixiv.net/archives/1156026.html> 

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
