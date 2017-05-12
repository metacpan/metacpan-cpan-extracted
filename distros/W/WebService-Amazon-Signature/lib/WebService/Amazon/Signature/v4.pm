package WebService::Amazon::Signature::v4;
$WebService::Amazon::Signature::v4::VERSION = '0.002';
use strict;
use warnings;

use parent qw(WebService::Amazon::Signature);

=head1 NAME

WebService::Amazon::Signature::v4 - support for v4 of the Amazon signing method

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 my $req = 'GET / HTTP/1.1 ...';
 my $amz = WebService::Amazon::Signature::v4->new(
  scope      => '20110909/us-east-1/host/aws4_request',
  access_key => 'AKIDEXAMPLE',
  secret_key => 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
 );
 $amz->parse_request($req)
 my $signed_req = $amz->signed_request($req);

=head1 DESCRIPTION

=cut

use Time::Moment;
use POSIX qw(strftime);
use Digest::SHA qw(sha256 sha256_hex);
use Digest::HMAC qw(hmac hmac_hex);
use List::UtilsBy qw(sort_by);
use HTTP::StreamParser::Request;
use URI;
use URI::QueryParam;
use URI::Escape qw(uri_escape_utf8 uri_unescape);

use constant DEBUG => 0;

use Log::Any qw($log);

=head1 METHODS - Constructor

=cut

=head2 new

Instantiate a signing object. Expects the following named parameters:

=over 4

=item * scope - the scope used for requests, typically something like C<20130112/us-west-2/dynamodb/aws4_request>

=item * secret_key - your secret key

=item * access_key - your access key

=back

=cut

sub new {
	my $class = shift;
	bless {
		algorithm  => 'AWS4-HMAC-SHA256',
		@_
	}, $class
}

=head1 METHODS - Accessors

=head2 algorithm

Read-only accessor for the algorithm (default is C<AWS4-HMAC-SHA256>)

=cut

sub algorithm { shift->{algorithm} }

=head2 date

Read-only accessor for the date field.

=cut

sub date { shift->{date} }

=head2 scope

Read-only accessor for scope information - typically something like
C<20110909/us-east-1/host/aws4_request>.

=cut

sub scope { shift->{scope} }

=head2 access_key

Readonly accessor for the access key used when signing requests.

=cut

sub access_key { shift->{access_key} }

=head2 secret_key

Readonly accessor for the secret key used when signing requests.

=cut

sub secret_key { shift->{secret_key} }

=head2 signed_headers

Read-only accessor for the headers used for signing purposes
(a string consisting of the lowercase headers separated by ;
in lexical order)

=cut

sub signed_headers { shift->{signed_headers} }

=head1 METHODS

=head2 parse_request

Parses a given request. Takes a single parameter - the HTTP request as a string.

=cut

sub parse_request {
	my $self = shift;
	my $txt = shift;
	my $parser = HTTP::StreamParser::Request->new;
	my $method;
	my $uri;
	my %header;
	my @headers;
	my $payload = '';
	$parser->subscribe_to_event(
		http_method => sub { $method = $_[1] },
		http_uri    => sub { $uri = $_[1]; },
		http_header => sub {
			if(exists $header{lc $_[1]}) {
				$header{lc $_[1]} = [
					$header{lc $_[1]}
				] unless ref $header{lc $_[1]};
				push @{$header{lc $_[1]}}, $_[2]
			} else {
				$header{lc $_[1]} = $_[2]
			}
		},
		http_body_chunk => sub {
			$payload .= $_[1]
		}
	);
	$parser->parse($txt);
	$self->{headers} = \@headers;
	$self->{header} = \%header;
	$self->{method} = $method;
	$self->{uri} = $uri;
	$self->{payload} = $payload;
	$self
}

=head2 from_http_request

Parses information from an L<HTTP::Request> instance.

=cut

sub from_http_request {
	my $self = shift;
	my $req = shift;
	$self->{method} = $req->method;
	$self->{uri} = '' . $req->uri;
	$self->{payload} = $req->content;
	my %header;
	$req->scan(sub {
		my ($k, $v) = @_;
		if(exists $header{lc $k}) {
			$header{lc $k} = [
				$header{lc $k}
			] unless ref $header{lc $k};
			push @{$header{lc $k}}, $v
		} else {
			$header{lc $k} = $v
		}
	});
	$self->{header} = \%header;
	$self
}

=head2 canonical_request

Returns the string form of the canonical request, used
as an intermediate point in generating the signature.

=cut

sub canonical_request {
	my $self = shift;

	my %header = %{$self->{header}};
	my $method = $self->{method};
	my $payload = $self->{payload};
	my $uri = $self->{uri};

	# Strip all leading/trailing whitespace from headers,
	# convert to canonical comma-separated format
	s/^\s+//, s/\s+$// for map @$_, grep ref($_), values %header;
	$_ = join ',', sort @$_ for grep ref($_), values %header;
	s/^\s+//, s/\s+$// for values %header;

	$uri =~ s{ .*$}{}g;
	$uri =~ s{#}{%23}g;

	# We're not actually connecting to this so a default
	# value should be safe here. Only used to ensure URI
	# detects this as an HTTP URI.
	$uri = 'http://localhost' . $uri if !length($uri) or $uri !~ /^https?:/;

	my $u = (ref $uri ? $uri : URI->new($uri))->clone->canonical;
	$uri = $u->path;
	my $path = '';
	while(length $uri) {
		if(substr($uri, 0, 3) eq '../') {
			substr $uri, 0, 3, '';
		} elsif(substr($uri, 0, 2) eq './') {
			substr $uri, 0, 2, '';
		} elsif(substr($uri, 0, 3) eq '/./') {
			substr $uri, 0, 3, '/';
		} elsif(substr($uri, 0, 4) eq '/../') {
			substr $uri, 0, 4, '/';
			$path =~ s{/?[^/]*$}{};
		} elsif(substr($uri, 0, 3) eq '/..') {
			substr $uri, 0, 3, '/';
			$path =~ s{/?[^/]*$}{};
		} elsif(substr($uri, 0, 2) eq '/.') {
			substr $uri, 0, 3, '/';
		} elsif($uri eq '.' or $uri eq '..') {
			$uri = '';
		} else {
			$path .= $1 if $uri =~ s{^(/?[^/]*)}{};
		}
	}
	$path =~ s{/+}{/}g;
	$u->path($path);
	my @query;
	if(length $u->query) {
		for my $qp (split /&/, $u->query) {
			my ($k, $v) = map uri_unescape($_), split /=/, $qp, 2;
			for ($k, $v) {
				$_ //= '';
				s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
				$_ = Encode::decode('UTF-8' => $_);
				s{\+}{ }g;
				$_ = uri_escape_utf8($_);
			}
			push @query, "$k=$_" for $v
		}
	}
	my $query = join '&', sort @query;

	# Now apply the date. This can come from various sources:
	# * X-Amz-Date:
	# * Date:
	# * Current date/time
	if(exists $header{'x-amz-date'}) {
		$self->{date} = $header{'x-amz-date'};
	} elsif(exists $header{'date'}) {
		eval {
			require Time::Piece;
			$self->{date} = Time::Piece->strptime($header{date}, '%a, %d %b %Y %H:%M:%S GMT')->strftime('%Y%m%dT%H%M%SZ');
		};
		# ignore $@, we'll fall through to default value on failure
	}
	# Worst-case scenario: apply a default value.
	$self->{date} ||= strftime '%Y%m%dT%H%M%SZ', gmtime;

	my $can_req = join "\n",
			$method,
			$path,
			$query;
	my @can_header = map { lc($_) . ':' . $header{$_} } sort_by { lc } keys %header;
	$can_req .= "\n" . join "\n", @can_header;
	$can_req .= "\n\n" . join ';', sort map lc, keys %header;
	$self->{signed_headers} = join ';', sort map lc, keys %header;
	$can_req .= "\n" . sha256_hex($payload);
	return $can_req;
}

=head2 string_to_sign

Returns the \n-separated string as the last step before
generating the signature itself.

=cut

sub string_to_sign {
	my $self = shift;
	my $can_req = $self->canonical_request;
	$log->debugf("Canonical request:\n%s", $can_req) if DEBUG;
	my $hashed = sha256_hex($can_req);
	$log->debugf("Hashed [%s]", $hashed) if DEBUG;
	my $to_sign = join "\n",
			$self->algorithm,
			$self->date,
			$self->scope,
			$hashed;
	$log->debugf("To sign:\n%s", $to_sign) if DEBUG;
	$to_sign
}

=head2 calculate_signature

Calculates the signature for the current request and returns it
as a string suitable for the C<Authorization> header.

=cut

sub calculate_signature {
	my $self = shift;
	die "No secret key" unless defined($self->secret_key);
	die "No scope" unless defined($self->scope);
	my $hmac = 'AWS4' . $self->secret_key;
	$hmac = hmac($_, $hmac, \&sha256) for split qr{/}, $self->scope;
	my $signature = hmac_hex($self->string_to_sign, $hmac, \&sha256);
	my $headers = $self->signed_headers;
	return $self->algorithm . ' Credential=' . $self->access_key . '/' . $self->scope . ', SignedHeaders=' . $headers . ', Signature=' . $signature;
}

=head2 signed_request

Returns a signed version of the request.

=cut

sub signed_request {
	my $self = shift;
	my $req = shift;
	my $signature = $self->calculate_signature;
	$req =~ s{\x0D\x0A\x0D\x0A}{\x0D\x0AAuthorization: $signature\x0D\x0A\x0D\x0A};
	$req
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2012-2013. Licensed under the same terms as Perl itself.
