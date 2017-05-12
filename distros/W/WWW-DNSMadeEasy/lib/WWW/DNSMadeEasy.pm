package WWW::DNSMadeEasy;
BEGIN {
  $WWW::DNSMadeEasy::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::DNSMadeEasy::VERSION = '0.001';
}
# ABSTRACT: Accessing DNSMadeEasy API

use Moo;
use DateTime;
use DateTime::Format::HTTP;
use Digest::HMAC_SHA1 qw(hmac_sha1 hmac_sha1_hex);
use LWP::UserAgent;
use HTTP::Request;
use JSON;

use WWW::DNSMadeEasy::Domain;

our $VERSION ||= '0.0development';

has api_key => (
	is => 'ro',
	required => 1,
);

has secret => (
	is => 'ro',
	required => 1,
);

has sandbox => (
	is => 'ro',
	default => sub { 0 },
);

has _http_agent => (
	is => 'ro',
	lazy => 1,
	default => sub {
		my $self = shift;
		my $ua = LWP::UserAgent->new;
		$ua->agent($self->http_agent_name);
		return $ua;
	},
);

has http_agent_name => (
	is => 'ro',
	lazy => 1,
	default => sub { __PACKAGE__.'/'.$VERSION },
);

sub api_endpoint {
	my ( $self ) = @_;
	if ($self->sandbox) {
		return 'http://api.sandbox.dnsmadeeasy.com/V1.2/';
	} else {
		return 'http://api.dnsmadeeasy.com/V1.2/';
	}
}

sub get_request_headers {
	my ( $self, $dt ) = @_;
	$dt = DateTime->now->set_time_zone( 'GMT' ) if !$dt;
	my $date_string = DateTime::Format::HTTP->format_datetime($dt);
	return {
		'x-dnsme-requestDate' => $date_string,
		'x-dnsme-apiKey' => $self->api_key,
		'x-dnsme-hmac' => hmac_sha1_hex($date_string, $self->secret),
	};
}

sub request {
	my ( $self, $method, $path, $data ) = @_;
	my $url = $self->api_endpoint.$path;
	my $request = HTTP::Request->new( $method => $url );
	my $headers = $self->get_request_headers;
	$request->header($_ => $headers->{$_}) for (keys %{$headers});
	$request->header('Accept' => 'application/json');
	if (defined $data) {
		$request->header('Content-Type' => 'application/json');
		$request->content(encode_json($data));
	}
	my $res = $self->_http_agent->request($request);
	if ($res->is_success) {
		return decode_json($res->content);
	} else {
		die __PACKAGE__.' HTTP request failed: '.$res->status_line, "\n";
	}
}

#
# DOMAINS
#

sub path_domains { 'domains' }

sub create_domain {
	my ( $self, $domain_name ) = @_;
	return WWW::DNSMadeEasy::Domain->create({
		name => $domain_name,
		dme => $self,
	});
}

sub domain {
	my ( $self, $domain_name ) = @_;
	return WWW::DNSMadeEasy::Domain->new({
		name => $domain_name,
		dme => $self,
	});
}

sub all_domains {
	my ( $self ) = @_;
	my $data = $self->request('GET',$self->path_domains);
	return if !$data->{list};
	my @domains;
	for (@{$data->{list}}) {
		push @domains, WWW::DNSMadeEasy::Domain->new({
			dme => $self,
			name => $_,
		});
	}
	return @domains;
}

1;



__END__
=pod

=head1 NAME

WWW::DNSMadeEasy - Accessing DNSMadeEasy API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use WWW::DNSMadeEasy; # or WWW::DME as shortname

  my $dme = WWW::DNSMadeEasy->new({
    api_key => '1c1a3c91-4770-4ce7-96f4-54c0eb0e457a',
    secret => 'c9b5625f-9834-4ff8-baba-4ed5f32cae55',
  });
  
  my $sandbox = WWW::DNSMadeEasy->new({
    api_key => '1c1a3c91-4770-4ce7-96f4-54c0eb0e457a',
    secret => 'c9b5625f-9834-4ff8-baba-4ed5f32cae55',
    sandbox => 1,
  });

  my @domains = $dme->all_domains;

  my $domain = $dme->create_domain('universe.org');
  
  my $other_domain = $dme->domain('existingdomain.com');
  
  my @records = $other_domain->all_records;
  
  my $record = $domain->create_record({
    ttl => 120,
    gtdLocation => 'DEFAULT',
    name => 'www',
    data => '1.2.3.4',
    type => 'A',
  });

  $record->delete;
  
  $domain->delete;

=head1 DESCRIPTION

This distribution gives you an easy access to the DNSMadeEasy API. You require a business or corporate account to use this. You can't use it with the free test account neither with the small business account. This module doesnt check any input values, I suggest so far that you know what you do.

=head1 ATTRIBUTES

=head2 api_key

Here you must give the API key which you can obtain from this page L<https://cp.dnsmadeeasy.com/account/info>.

=head2 secret

You get the secret from the same page where you get the API key.

=head2 sandbox

If set to true, this will activate the usage of the sandbox, instead of the live system.

=head2 http_agent_name

Here you can set a different http useragent for the requests, it defaults to the package name including the distribution version.

=head1 METHODS

=head2 $obj->create_domain

Arguments: $name

Return value: L<WWW::DNSMadeEasy::Domain>

Will be creating the domain $name on your account and returns the L<WWW::DNSMadeEasy::Domain> for this domain.

=head2 $obj->domain

Arguments: $name

Return value: L<WWW::DNSMadeEasy::Domain>

Returns the L<WWW::DNSMadeEasy::Domain> of the domain with name $name.

=head2 $obj->domain

Arguments: $name

Return value: L<WWW::DNSMadeEasy::Domain>

Returns the L<WWW::DNSMadeEasy::Domain> of the domain with name $name.

=head2 $obj->all_domains

Arguments: None

Return value: Array of L<WWW::DNSMadeEasy::Domain>

Returns an array of L<WWW::DNSMadeEasy::Domain> objects of all domains listed on this account.

=encoding utf8

=head1 ATTRIBUTES

=head1 METHODS

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net and highlight Getty or /msg me.

Repository

  http://github.com/Getty/p5-www-dnsmadeeasy
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-www-dnsmadeeasy/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by L<Raudssus Social Software|http://www.raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

