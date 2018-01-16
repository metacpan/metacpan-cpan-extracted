# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::HTTP;
$WebService::Braintree::HTTP::VERSION = '1.0';
use 5.010_001;
use strictures 1;

use Data::Dumper;
use HTTP::Request;
use LWP::UserAgent;

use WebService::Braintree::Xml qw(hash_to_xml xml_to_hash);

use Moose;
use Carp qw(confess);
use constant CLIENT_VERSION => $WebService::Braintree::VERSION || 'development';

has 'config' => (is => 'ro', default => sub { WebService::Braintree->configuration });

sub post {
    my ($self, $path, $params) = @_;
    $self->make_request($path, $params, 'POST');
}

sub put {
    my ($self, $path, $params) = @_;
    $self->make_request($path, $params, 'PUT');
}

sub get {
    my ($self, $path, $params) = @_;
    $self->make_request($path, $params, 'GET');
}

sub delete {
    my ($self, $path, $params) = @_;
    $self->make_request($path, undef, 'DELETE');
}

sub make_request {
    my ($self, $path, $params, $verb) = @_;
    my $request = HTTP::Request->new($verb => $self->config->base_merchant_url . $path);
    $request->headers->authorization_basic($self->config->public_key, $self->config->private_key);

    if ($params) {
        $request->content(hash_to_xml($params));
        $request->content_type("text/xml; charset=utf-8");
    }

    $request->header("X-ApiVersion" => $self->config->api_version);
    $request->header("environment" => $self->config->environment);
    $request->header("User-Agent" => "Braintree Perl Module " . CLIENT_VERSION );

    my $agent = LWP::UserAgent->new;

    warn Dumper $request if $ENV{WEBSERVICE_BRAINTREE_DEBUG};
    my $response;
    my $tries = 1;
    while ($tries < 5) {
        $response = $agent->request($request);
        if ($response->code eq '500' && $response->message =~ /Connection timed out/i) {
            warn "Retrying timed-out connection after try $tries\n";
            $tries++;
            next;
        }
        last;
    }
    warn Dumper $response->content if $ENV{WEBSERVICE_BRAINTREE_DEBUG};

    $self->check_response_code($response->code);

    if ($response->header('Content-Length') > 1) {
        return xml_to_hash($response->content);
    } else {
        return {http_status => $response->code};
    }
}

sub check_response_code {
    my ($self, $code) = @_;
    confess "NotFoundError"       if $code eq '404';
    confess "AuthenticationError" if $code eq '401';
    confess "AuthorizationError"  if $code eq '403';
    confess "ServerError"         if $code eq '500';
    confess "DownForMaintenance"  if $code eq '503';
}

__PACKAGE__->meta->make_immutable;

1;
__END__
