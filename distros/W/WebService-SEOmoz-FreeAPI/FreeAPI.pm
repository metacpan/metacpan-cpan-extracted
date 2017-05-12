package WebService::SEOmoz::FreeAPI;

use strict;
use warnings;
use Digest::SHA qw( hmac_sha1_base64 );
use HTTP::Request::Common qw(POST);
use JSON;
use LWP::UserAgent;
use URI::Escape;
use vars qw/$module $errstr $timeout $VERSION $sendUrl $apiUrl/;

$VERSION = '0.01';

sub new {
	my $class = shift;
	my $args = scalar @_ % 2 ? shift : {@_};
	$module = 'new';
	$timeout = 'Not set yet';

	# Remove any spaces trailing/starting spaces
    $args->{accessID}  =~ s/(^\s+|\s+$)//g;
    $args->{secretKey} =~ s/(^\s+|\s+$)//g;
	
	# Initiate the main function classes and vars
	unless ( $args->{useragent} ) {
		$args->{useragent} = LWP::UserAgent->new();
	}
	unless ( $args->{json} ) {
		$args->{json} = JSON->new->allow_nonref;
	}

	# Its important to realize that if your time is not out of sync, that using a higher expiration time 30000 is better
	$args->{expires} ||= 30000;

	bless $args, $class;
}

sub errstr {
	return 	"### WebService::SEOmoz::FreeAPI ERROR\n" .
			'Error description: ' . $errstr . "\n" .
			'Functions path: ' . $module . "\n" .
			'API session Timeout (Unix timestamp): ' . $timeout . "\n" .
			'Error time (Unix timestamp): '. time() . "\n\n";
}

sub getAuthenticationQuery {
	my ($self) = @_;
	my $authenticationQuery;
	$module .= ' -> getAuthenticationQuery';

	$self->{expires} = time() + $self->{expires};
	$timeout = $self->{expires};

	my $signatureString = $self->{accessID} . "\n" . $self->{expires};

    while (length($signatureString) % 4) {
        $signatureString .= '=';
    }

	my $signature = uri_escape(Digest::SHA::hmac_sha1_base64($signatureString, $self->{secretKey})) . '%3D';
	$authenticationQuery = 	'?AccessID=' . $self->{accessID} .
				'&Expires=' . $self->{expires} .
				'&Signature=' . $signature;

	return $authenticationQuery;
}

sub postAPIRequest {
	my ($self, $apiUrl, $websiteString) = @_;
	my $json_string;
	$module .= ' -> postAPIRequest';

	my $http_header = HTTP::Request->new(POST => $apiUrl);
	$http_header->content_type("application/x-www-form-urlencoded");
	$http_header->content($websiteString);

	my $response = $self->{useragent}->request($http_header);
	eval {
		$json_string = $self->{json}->decode($response->content);
		1;
	};
	return $json_string;
}

sub getAPIRequest {
	my ($self, $apiUrl) = @_;
	my $json_string;
	$module .= ' -> getAPIRequest';

	my $response = $self->{useragent}->get($apiUrl);

	unless ( $response->is_success ) {
		$errstr = $response->status_line . ', used URL (' . $apiUrl . ')';
		return;
	}
	eval {
		$json_string = $self->{json}->decode($response->content);
		1;
	};
	return $json_string;
}

sub getAnchorText {
	my $self = shift;
	my $args = scalar @_ % 2 ? shift : {@_};
	my $appendString = '';
	$module .= ' -> getAnchorText';

	if (!defined($args->{Website})) {
		$errstr = 'The input \'Website\' is required';
		return;
	}

	foreach my $k ('Scope', 'Sort', 'Cols', 'Offset', 'Limit') {
		if (defined($args->{$k})) {
			$appendString .= '&' . $k . '=' . $args->{$k};
		}
	}

	my $sendUrl = $args->{Website};
	$sendUrl =~ s/^(http|https):\/\///i; # Remove protocol, because SEOmoz API does not return any info otherwise

	my $apiUrl = 'http://lsapi.seomoz.com/linkscape/anchor-text/' . uri_escape($sendUrl) . $self->getAuthenticationQuery() . $appendString;
	return $self->getAPIRequest($apiUrl);
}

sub getUrlMetrics {
	my $self = shift;
	my $args = scalar @_ % 2 ? shift : {@_};
	my $appendString = '';
	$module .= ' -> getUrlMetrics';

	if (!defined($args->{Websites})) {
		$errstr = 'The input \'Websites\' (one or more comma seperated urls) is required';
		return;
	}

	my $fullUrl = $args->{Websites};

	# Merge website(s) into JSON format for upcoming POST request
	my $websiteString = '[';
	my @websites = split(',', $fullUrl);
	
	foreach my $url (@websites) {
		$sendUrl = $url;
		$sendUrl =~ s/^(http|https):\/\///i; # Remove protocol, because the SEOmoz API does not return any info otherwise
		$websiteString .= '"' . $sendUrl . '/",';
	}
	$websiteString = substr($websiteString, 0, -1) . ']';
	
	foreach my $k ('Cols') {
		if (defined($args->{$k})) {
			$appendString .= '&' . $k . '=' . $args->{$k};
		}
	}

	$apiUrl = 'http://lsapi.seomoz.com/linkscape/url-metrics/' . $self->getAuthenticationQuery() . $appendString;
	return $self->postAPIRequest($apiUrl, $websiteString);
}

sub getLinks {
	my $self = shift;
	my $args = scalar @_ % 2 ? shift : {@_};
	my $appendString = '';
	$module .= ' -> getLinks';

	if (!defined($args->{Website})) {
		$errstr = 'getLinks: The input \'Website\' is required';
		return;
	}
	
	foreach my $k ('Scope', 'Filter', 'Sort', 'SourceCols', 'TargetCols', 'LinkCols', 'Offset', 'Limit') {
		if (defined($args->{$k})) {
			$appendString .= '&' . $k . '=' . $args->{$k};
		}
	}

	$sendUrl = $args->{Website};
	$sendUrl =~ s/^(http|https):\/\///i; # Remove protocol, because the SEOmoz API does not return any info otherwise

	$apiUrl = 'http://lsapi.seomoz.com/linkscape/links/' . uri_escape($sendUrl) . $self->getAuthenticationQuery() . $appendString;

	return $self->getAPIRequest($apiUrl);
}

1;

__END__

=pod

=head1 NAME

Net::SEOmoz::API - SEOmoz Linkscape API

=head1 VERSION

version 0.01

=head1 SYNOPSIS

	use WebService::SEOmoz::FreeAPI;
	
	$accessID = ''; # obtained from http://www.seomoz.org/api after logging in
	$secretKey = ''; # obtained from http://www.seomoz.org/api after logging in
	
	my $seomoz = WebService::SEOmoz::FreeAPI->new({accessID => $accessID, secretKey => $secretKey, expires => 30000});

	my $urlmetrics = $seomoz->getUrlMetrics({Websites => 'http://www.domain.com,http://www.website.com'}) or print $seomoz->errstr;

	my $anchortext = $seomoz->getAnchorText({Website => 'http://www.domain.com', Scope => 'term_to_subdomain', Sort => 'domains_linking_page', Cols => 1122, Limit => 3}) or print $seomoz->errstr;

	my $links = $seomoz->getLinks({Website => 'http://www.domain.com', Scope => 'page_to_subdomain', Filter => 'external', Sort => 'page_authority', SourceCols => 36, TargetCols => 36, Limit => 250}) or print $seomoz->errstr;
	
=head1 DESCRIPTION

This API wrapper is specifically designed for the www.seomoz.org free linkscape API. With the new API limitations it is important to note that only one request can be made per 10 seconds. With this module you can use the ability to send multiple domains in one single request for the URLMetrics API function. Unfortunately at this time it is only possible to send in multiple URLs in one request for the URLMetrics API function.
Some important notes before you can start using this free API to its fullest extent:
- Make sure that your server time is set correctly because this module uses timeout calculation to terminate sessions;
- Please make sure you have understood the branding requirements and link-back attribution that SEOmoz has put up at http://apiwiki.seomoz.org/w/page/13991130/Attribution-to-SEOmoz;
- The getAnchorText is always limited to a maximum of 3 anchor texts returned;
- You must include Scope and Sort query parameters in the Links API function or you might receive a 401 Unauthorized unauthorized api links error.

If you have any questions, improvements or thoughts related to this module feel free to send me an e-mail.

=head1 METHODS

=head2 new

	my $accessID = 'foo';
	my $secretKey = 'bar';

	my $seomoz = WebService::SEOmoz::FreeAPI->new({
		accessID => $accessID,
		secretKey => $secretKey,
		expires => 30000,
	);

The first and only thing that requires calling before normal API calls can made is the new function.

=head2 getUrlMetrics

Use the following type to submit more than one website for UrlMetrics:

	my $urlmetrics = $seomoz->getUrlMetrics({
		Websites => 'http://www.domain.com,http://www.website.com'
	}) or print $seomoz->errstr;
	
And the following type to submit one website for UrlMetrics:

	my $urlmetrics = $seomoz->getUrlMetrics({
		Websites => 'http://www.domain.com'
	}) or print $seomoz->errstr;

=head2 getAnchorText

	my $anchortext = $seomoz->getAnchorText({
		Website => 'http://www.domain.com',
		Scope => 'term_to_subdomain',
		Sort => 'domains_linking_page',
		Cols => 1122,
		Limit => 3
	}) or print $seomoz->errstr;
	
=head2 getLinks

	my $links = $seomoz->getLinks({
		Website => 'www.domain.com',
		Scope => 'page_to_subdomain',
		Filter => 'external',
		Sort => 'page_authority',
		SourceCols => 36,
		TargetCols => 36,
		Limit => 250,
	}) or print $seomoz->errstr;

=head1 AUTHOR

Rick van Bommel <info@seo-visuals.com> L<http://www.seo-visuals.com/us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Rick van Bommel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut