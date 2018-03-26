# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::HTTP;

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

my $LF = "\r\n";

sub post {
    my $self = shift;
    $self->make_request(POST => @_);
}

sub put {
    my $self = shift;
    $self->make_request(PUT => @_);
}

sub get {
    my $self = shift;
    $self->make_request(GET => @_);
}

sub delete {
    my $self = shift;
    $self->make_request(DELETE => @_);
}

sub make_request {
    my ($self, $verb, $path, $params, $file) = @_;
    my $request = HTTP::Request->new($verb => $self->config->base_merchant_url . $path);
    $request->headers->authorization_basic($self->config->public_key, $self->config->private_key);

    if ($file) {
        my $boundary = DateTime->now->strftime('%Q');
        $request->content_type("multipart/form-data; boundary=${boundary}");

        my @form_params = map {
            $self->add_form_field($_, $params->{$_})
        } keys %{$params // {}};
        push @form_params, $self->add_file_part(file => $file);

        $request->content(
            join("", (
                map { "--${boundary}${LF}${_}" } @form_params
            )) . "--${boundary}--"
        );
    }
    elsif ($params) {
        $request->content_type("text/xml; charset=utf-8");
        $request->content(hash_to_xml($params));
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
    confess "ClientError"         if $code eq '400';
    confess "AuthenticationError" if $code eq '401';
    confess "AuthorizationError"  if $code eq '403';
    confess "NotFoundError"       if $code eq '404';
    confess "ServerError"         if $code eq '500';
    confess "DownForMaintenance"  if $code eq '503';
}

sub add_form_field {
    my ($self, $key, $value) = @_;
    return "Content-Disposition: form-data; name=\"${key}\"${LF}${LF}${value}${LF}";
}

sub add_file_part {
    my ($self, $key, $file) = @_;

    my $mime_type = $self->mime_type_for_file_name($file);

    my $contents = do {
        local $/;
        open(my $fh, '<', $file) or die "Cannot open $file for reading: $!\n";
        <$fh>;
    };

    return "Content-Disposition: form-data; name=\"${key}\"; filename=\"${file}\"${LF}"
        . "Content-Type: ${mime_type}${LF}${LF}${contents}${LF}";
}

sub mime_type_for_file_name {
    my ($self, $filename) = @_;
    my ($ext) = $filename =~ /\.([^.]+)$/;
    $ext = lc($ext // '');

    if ($ext eq 'jpeg' || $ext eq 'jpg') {
        return 'image/jpeg';
    }
    elsif ($ext eq 'png') {
        return 'image/png';
    }
    elsif ($ext eq 'pdf') {
        return 'application/pdf';
    }
    else {
        return 'application/octet-stream';
    }
}

__PACKAGE__->meta->make_immutable;

1;
__END__
