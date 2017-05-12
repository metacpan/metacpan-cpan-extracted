package WWW::Yahoo::InboundLinks;

use strict;
use warnings;

use vars qw($VERSION);

use LWP::UserAgent ();
use HTTP::Headers ();

use JSON ();

$VERSION = '0.07';

sub new {
	my $class = shift;
	my $appid = shift;
	
	my %options = @_;
	
	my $self  = {};
	
	# config overrided by parameters
	$self->{ua}     = LWP::UserAgent->new;
	$self->{appid}  = $appid;
	$self->{format} = 'json';
	
	foreach (keys %options) {
		$self->{$_} = $options{$_};
	}
	
	bless($self, $class);
}

sub user_agent {
	shift->{ua};
}

sub request_uri {
	my ($self, $query, %params) = @_;
	
	my %opt_params = (
		results      => 2,
		start        => undef,
		entire_site  => undef,
		omit_inlinks => undef,
		callback     => undef,
		output       => $self->{format}
	);
	
	my %allowed_params = (map {$_ => $params{$_} || $opt_params{$_}} keys %opt_params);
	$allowed_params{appid} = $self->{appid};
	$allowed_params{query} = $query;
	
	my $params_string = join '&',
		map {"$_=$allowed_params{$_}"}
		grep {defined $allowed_params{$_}}
		keys %allowed_params;
	
	my $url = 'http://search.yahooapis.com/SiteExplorerService/V1/inlinkData?'
		. $params_string;
	
	return $url;
	
}

sub get {
	my ($self, $url, %params) = @_;

	my @result = ();
	
	my $query = $self->request_uri ($url, %params);
  
	my $resp = $self->{ua}->get ($query);
	$result[1] = $resp;
	
	if ($resp->is_success) {
		my $parser = "$self->{format}_parser";
		$self->$parser ($resp, \@result);
	}
	
	if (wantarray) {
		return @result;
	} else {
		return $result[0];
	}
}

sub json_parser {
	my $self   = shift;
	my $resp   = shift;
	my $result = shift;
	
	my $content = $resp->content;
	
	# contents example:
	#HTTP/1.1 999 Rate Limit Exceeded
	#Date: Sun, 01 Mar 2009 11:26:23 GMT
	#P3P: policyref="http://info.yahoo.com/w3c/p3p.xml", CP="CAO DSP COR CUR ADM DEV TAI PSA PSD IVAi IVDi CONi TELo OTPi OUR DELi SAMi OTRi UNRi PUBi IND PHY ONL UNI PUR FIN COM NAV INT DEM CNT STA POL HEA PRE LOC GOV"
	#Connection: close
	#Transfer-Encoding: chunked
	#Content-Type: text/javascript; charset=utf-8
	if ($content =~ /rate limit exceeded/si) {
		# JSON cannot parse xml
		return;
	}
	
	my $struct = JSON::from_json ($content, {utf8 => 1});
	
	if (defined $struct and ref $struct eq 'HASH') {
		
		$result->[2] = $struct;
		
		if (exists $struct->{ResultSet}) {
			$result->[0] = $struct->{ResultSet}->{totalResultsAvailable};
		}
	}
}

1;

__END__

=head1 NAME

WWW::Yahoo::InboundLinks - Tracking Inbound Links in Yahoo Site Explorer API

=head1 SYNOPSIS

	use WWW::Yahoo::InboundLinks;
	my $ylinks = WWW::Yahoo::InboundLinks->new ('YahooAppId');
	my %params = {
		omit_inlinks => 'domain',
	};
	print $ylinks->get ('http://yahoo.com', %params), "\n";

	# or 

=head1 DESCRIPTION

The C<WWW::Yahoo::InboundLinks> is a class implementing a interface for
Tracking Inbound Links in Yahoo Site Explorer API.

More information here: L<http://developer.yahoo.com/search/siteexplorer/V1/inlinkData.html>

To use it, you should create C<WWW::Yahoo::InboundLinks> object and use its
method get(), to query inbound links for url.

It uses C<LWP::UserAgent> for making request to Yahoo and C<JSON>
for parsing response.

=head1 METHODS

=over 4

=item  my $ylinks = WWW::Yahoo::InboundLinks->new ('YahooAppId');

This method constructs a new C<WWW::Yahoo::InboundLinks> object and returns it.
Required parameter — Yahoo Application Id (L<http://developer.yahoo.com/faq/index.html#appid>)

=item  my $ua = $ylinks->user_agent;

This method returns constructed C<LWP::UserAgent> object.
You can configure object before making requests. 

=item  my $count = $ylinks->get ('http://yahoo.com', %params);

Queries Yahoo about inbound links for a specified url. Parameters similar to
params on this L<http://developer.yahoo.com/search/siteexplorer/V1/inlinkData.html>
page. If Yahoo returns error, then returned value is undef.

In list context this function returns list from three elements where
first one is a result as in scalar context, the second one is a
C<HTTP::Response> from C<LWP::UserAgent> and third one is a perl
hash with response data from Yahoo. This can be usefull for debugging
purposes, for querying failure details and for detailed info from yahoo.

=back

=head1 BUGS

If you find any, please report ;)

=head1 AUTHOR

Ivan Baktsheev F<E<lt>dot.and.thing@gmail.comE<gt>>.

=head1 COPYRIGHT

Copyright 2008, Ivan Baktsheev

You may use, modify, and distribute this package under the
same terms as Perl itself.
