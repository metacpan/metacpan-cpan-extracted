package WWW::DuckDuckGo;
BEGIN {
  $WWW::DuckDuckGo::AUTHORITY = 'cpan:DDG';
}
{
  $WWW::DuckDuckGo::VERSION = '0.016';
}
# ABSTRACT: Access to the DuckDuckGo APIs

use Moo;

use LWP::UserAgent;
use HTTP::Request;
use WWW::DuckDuckGo::ZeroClickInfo;
use JSON;
use URI;
use URI::QueryParam;

our $VERSION ||= '0.0development';

has _duckduckgo_api_url => (
	is => 'ro',
	lazy => 1,
	default => sub { 'http://api.duckduckgo.com/' },
);

has _duckduckgo_api_url_secure => (
	is => 'ro',
	lazy => 1,
	default => sub { 'https://api.duckduckgo.com/' },
);

has _zeroclickinfo_class => (
	is => 'ro',
	lazy => 1,
	default => sub { 'WWW::DuckDuckGo::ZeroClickInfo' },
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

has forcesecure => (
	is => 'ro',
	default => sub { 0 },
);

has safeoff => (
	is => 'ro',
	default => sub { 0 },
);

has html => (
	is => 'ro',
	default => sub { 0 },
);

# HashRef of extra params
has params => (
    is => 'ro',
    default => sub { {} },
);

sub zci { shift->zeroclickinfo(@_) }

sub _zeroclickinfo_request_base {
	my ( $self, $for_uri, @query_fields ) = @_;
	my $query = join(' ',@query_fields);
	my $uri = URI->new($for_uri);
    my %params = %{$self->params};
	$uri->query_param( q => $query );
	$uri->query_param( o => 'json' );
	$uri->query_param( kp => -1 ) if $self->safeoff;
    $uri->query_param( no_redirect => 1 );
    $self->html ? 
        $uri->query_param( no_html => 0 ) : 
        $uri->query_param( no_html => 1 );
    $uri->query_param($_ => $params{$_}) for keys %params;
	return HTTP::Request->new(GET => $uri->as_string);
}

sub zeroclickinfo_request_secure {
	my ( $self, @query_fields ) = @_;
	return if !@query_fields;
	return $self->_zeroclickinfo_request_base($self->_duckduckgo_api_url_secure,@query_fields);
}

sub zeroclickinfo_request {
	my ( $self, @query_fields ) = @_;
	return if !@query_fields;
	return $self->_zeroclickinfo_request_base($self->_duckduckgo_api_url,@query_fields);
}

sub zeroclickinfo {
	my ( $self, @query_fields ) = @_;
	return if !@query_fields;
	my $query = join(' ',@query_fields);
	my $res;
	eval {
		$res = $self->_http_agent->request($self->zeroclickinfo_request_secure(@query_fields));
	};
	if (!$self->forcesecure and ( $@ or !$res or !$res->is_success ) ) {
		warn __PACKAGE__." HTTP request failed: ".$res->status_line if ($res and !$res->is_success);
		warn __PACKAGE__." Can't access ".$self->_duckduckgo_api_url_secure." falling back to: ".$self->_duckduckgo_api_url;
		$res = $self->_http_agent->request($self->zeroclickinfo_request(@query_fields));
	}
	return $self->zeroclickinfo_by_response($res);
}

sub zeroclickinfo_by_response {
	my ( $self, $response ) = @_;
	if ($response->is_success) {
		my $result = decode_json($response->content);
		return $self->_zeroclickinfo_class->by($result);
	} else {
		die __PACKAGE__.' HTTP request failed: '.$response->status_line, "\n";
	}	
}

1;

__END__

=pod

=head1 NAME

WWW::DuckDuckGo - Access to the DuckDuckGo APIs

=head1 VERSION

version 0.016

=head1 SYNOPSIS

  use WWW::DuckDuckGo;

  my $duck = WWW::DuckDuckGo->new;
  
  # request the Zero Click Info, you can also use ..->zci('duck duck go')
  my $zeroclickinfo = $duck->zeroclickinfo('duck duck go');

  # request the Zero Click Info of "duck duck go more stuff"
  my $other_zeroclickinfo = $duck->zeroclickinfo('duck duck go','more stuff');

=head1 DESCRIPTION

This distribution gives you an easy access to the DuckDuckGo Zero Click Info API. It tries to connect via https first and falls back to http if there is a failure.

=head1 ATTRIBUTES

=head2 forcesecure

Set to true will force the client to use https, so it will not fallback to http on failure.

=head2 http_agent_name

Set the http agent name which the webserver gets. Defaults to WWW::DuckDuckGo

=head2 safeoff

Set to true to disable safesearch.

=head2 html

Allow HTML in output. This is the default in DuckDuckGo, but not default here to maintain backwards compatibility.

=head2 params

A HashRef of extra GET params to pass with the query (documented on https://api.duckduckgo.com/)

=head1 METHODS

=head2 $obj->zeroclickinfo

Arguments: @query_fields

Return value: L<WWW::DuckDuckGo::ZeroClickInfo>

Returns the L<WWW::DuckDuckGo::ZeroClickInfo> of the query specified by the parameters. If you give several parameters they will get joined with an empty space.

=encoding utf8

=head1 ATTRIBUTES

=head1 METHODS

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-www-duckduckgo
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-www-duckduckgo/issues

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=item *

Michael Smith <crazedpsyc@duckduckgo.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by L<DuckDuckGo, Inc.|https://duckduckgo.com/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
