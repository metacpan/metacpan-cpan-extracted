package WebService::Amazon::DynamoDB;
# ABSTRACT: Abstract API support for Amazon DynamoDB
use strict;
use warnings;

our $VERSION = '0.005';

=head1 NAME

WebService::Amazon::DynamoDB - support for the AWS DynamoDB API

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 # Using access key
 my $ddb = WebService::Amazon::DynamoDB->new(
  version        => '20120810',
  access_key     => 'access_key',
  secret_key     => 'secret_key',
  uri            => 'http://localhost:8000',
 );
 $ddb->batch_get_item(
  sub {
   my $tbl = shift;
   my $data = shift;
   warn "Batch get: $tbl had " . join(',', %$data) . "\n";
  },
  items => {
   $table_name => {
    keys => [
     name => 'some test name here',
    ],
    fields => [qw(name age)],
   }
  },
 )->get;

 # Using the IAM role from the current EC2 instance
 my $ddb = WebService::Amazon::DynamoDB->new(
  security       => 'iam',
 );

 # Using a specific IAM role
 my $ddb = WebService::Amazon::DynamoDB->new(
  security       => 'iam',
  iam_role       => 'role_name',
 );

=head1 BEFORE YOU START

B<NOTE>: I'd recommend looking at the L<Amazon::DynamoDB> module first.
It is a fork of this one with better features, more comprehensive tests,
and overall it's maintained much more actively.

=head1 DESCRIPTION

Provides a L<Future>-based API for Amazon's DynamoDB REST API.
See L<WebService::Amazon::DynamoDB::20120810> for available methods.

Current implementations for issuing the HTTP requests:

=over 4

=item * L<WebService::Async::UserAgent::NaHTTP> - use L<Net::Async::HTTP>
for applications based on L<IO::Async> (this gives nonblocking behaviour)

=item * L<WebService::Async::UserAgent::LWP> - use L<LWP::UserAgent> (will
block, timeouts are unlikely to work)

=item * L<WebService::Async::UserAgent::MojoUA> - use L<Mojo::UserAgent>,
should be suitable for integration into a L<Mojolicious> application (could
be adapted for nonblocking, although the current version does not do this).

=back

Only the L<Net::Async::HTTP> implementation has had any significant testing or use.

=cut

use WebService::Amazon::IAM::Client;

use WebService::Amazon::DynamoDB::20120810;
use Module::Load;
use POSIX qw(strftime);

use Log::Any qw($log);

=head1 METHODS

=cut

sub new {
	my $class = shift;
	my %args = @_;
	$args{implementation} //= 'WebService::Async::UserAgent::NaHTTP';
	unless(ref $args{implementation}) {
		$log->debugf("Loading module for HTTP implementation [%s]", $args{implementation});
		Module::Load::load($args{implementation});
		$log->debugf("Instantiating [%s]", $args{implementation});
		$args{implementation} = $args{implementation}->new(
			(exists $args{loop} ? (loop => delete $args{loop}) : ())
		);
	}
	my $version = delete $args{version} || '20120810';
	my $pkg = __PACKAGE__ . '::' . $version;
	$log->debugf("Look for ->new in [%s]", $pkg);
	if(my $code = $pkg->can('new')) {
		$class = $pkg if $class eq __PACKAGE__;
		$args{security} ||= 'key';
		$args{region} ||= 'us-west-1';
		$args{iam_role} = Future->done($args{iam_role}) if exists $args{iam_role} && !ref $args{iam_role};
		if(exists $args{host} or exists $args{port}) {
			$args{uri} = URI->new('http://' . $args{host} . ':' . $args{port});
		} else {
			$args{uri} ||= 'https://dynamodb.' . $args{region} . '.amazonaws.com/';
			$args{uri} = URI->new($args{uri}) unless ref $args{uri};
		}
		return $code->($class, %args)
	}
	die "No support for version $version";
}

sub security { shift->{security} }

sub uri { shift->{uri} }

sub api_version { ... }

=head2 make_request

Generates an L<HTTP::Request>.

=cut

sub make_request {
	my $self = shift;
	my %args = @_;
	my $target = $args{target};
	my $js = JSON::MaybeXS->new;
	my $req = HTTP::Request->new(
		POST => $self->uri
	);
	$req->header( host => $self->uri->host );
	my $http_date = strftime('%a, %d %b %Y %H:%M:%S %Z', localtime);
	$req->protocol('HTTP/1.1');
	$req->header( 'Date' => $http_date );
	$req->header( 'x-amz-date' => strftime('%Y%m%dT%H%M%SZ', gmtime) );
	$req->header( 'x-amz-target', 'DynamoDB_'. $self->api_version. '.'. $target );
	$req->header( 'content-type' => 'application/x-amz-json-1.0' );
	my $payload = $js->encode($args{payload});
	$req->content($payload);
	$req->header( 'Content-Length' => length($payload));
	$self->credentials->then(sub {
		my ($creds) = @_;
		# Don't show these by default
		# $log->debugf("Using [%s] for credentials", $creds);
		my $token = delete $creds->{token};
		my $amz = WebService::Amazon::Signature->new(
			version    => 4,
			algorithm  => $self->algorithm,
			scope      => $self->scope,
			%$creds,
		);
		$amz->from_http_request($req);
		$req->header(Authorization => $amz->calculate_signature);
		$req->header('X-Amz-Security-Token' => $token) if defined $token;
		Future->done($req)
	})
}

sub credentials {
	my ($self) = @_;
	if($self->security eq 'key') {
		$log->debugf("Using key-based security");
		# We don't bother caching the hashref, since we'd need to be passing
		# a copy anyway (caller may change the values)
		return Future->done({
			access_key => $self->access_key,
			secret_key => $self->secret_key,
		})
	}

	return $self->cached_iam_credentials->else(sub {
		$log->debug("No cached credentials (or already expired)");
		$self->find_iam_role->then(sub {
			my ($role) = @_;
			$log->debugf("Found role [%s]", $role);
			$self->retrieve_iam_credentials(
				$role
			)
		})
	});
}

sub cached_iam_credentials {
	my ($self) = @_;
	return Future->fail('no cached credentials') unless exists $self->{cached_iam_credentials};

	# Assume expired if we're within 5 seconds
	return Future->fail('cached credentials expire') if $self->{cached_iam_credentials}{expire_at} <= time - 5;

	# Shallow copy, so we're not affected if the caller changes the values
	return Future->done({
		%{ $self->{cached_iam_credentials}{details} }
	})
}

sub find_iam_role {
	my ($self) = @_;
	$self->{iam_role} //= $self->iam->active_roles
}

sub retrieve_iam_credentials {
	my ($self, $role) = @_;
	$self->iam->credentials_for_role($role)->then(sub {
		my ($creds, $expiry) = @_;
		$log->debugf("New credentials received, will expire in %s seconds", strftime '%H:%M:%S', gmtime($expiry - time));
		$self->{cached_iam_credentials} = {
			expire_at => $expiry,
			details => $creds
		};
		# Shallow copy, so we're not affected if the caller changes the values
		Future->done({ %$creds })
	})
}

sub _request {
	my $self = shift;
	my $req = shift;
	# Don't show requests by default
	# $log->debugf("Issuing request [%s]", $req->as_string("\n"));
	$self->implementation->request($req)
}

sub iam {
	$_[0]->{iam} //= WebService::Amazon::IAM::Client->new(
		ua => $_[0]->implementation,
	)
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Net::Amazon::DynamoDB> - supports the older (2011) API with v2
signing, so it doesn't work with L<DynamoDB Local|http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tools.html>.

=item * L<AWS::CLIWrapper> - alternative approach using wrappers around AWS
commandline tools

=back

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2013-2015. Licensed under the same terms as Perl itself.
