package WWW::Getsy::OAuth;

use Moose;
use MooseX::NonMoose;
use URI;
use HTTP::Request::Common ();
use Net::OAuth;
require Net::OAuth::Request;
extends 'Net::OAuth::Simple';

around '_make_request' => sub {
    my $orig = shift;
    my $self = shift;

    my $class   = shift;
    my $url     = shift;
    my $method  = lc(shift);
    my %extra   = @_;

    my $uri   = URI->new($url);
    my %query = $uri->query_form;
    $uri->query_form({});

    my $request = $class->new(
        consumer_key     => $self->consumer_key,
        consumer_secret  => $self->consumer_secret,
        request_url      => $uri,
        request_method   => uc($method),
        signature_method => $self->signature_method,
        protocol_version => $self->oauth_1_0a ? Net::OAuth::PROTOCOL_VERSION_1_0A : Net::OAuth::PROTOCOL_VERSION_1_0,
        timestamp        => time,
        nonce            => $self->_nonce,
        extra_params     => \%query,
        %extra,
    );
    $request->sign;
    die "COULDN'T VERIFY! Check OAuth parameters.\n"
      unless $request->verify;

    my $params = $request->to_hash;
     my $req;
    if ($method eq 'post') {
         $req = HTTP::Request::Common::POST($uri, Content => $params);
    } elsif ($method eq 'put') {
        $req = HTTP::Request::Common::POST $uri, Content => $params;
        $req->method('PUT');
    } elsif ($method eq 'delete') {
         my $request_url = URI->new($url);
        $request_url->query_form(%$params);
        $req = HTTP::Request::Common::DELETE($request_url);
    } else {
         my $request_url = URI->new($url);
        $request_url->query_form(%$params);
        $req = HTTP::Request::Common::GET($request_url);
    }
    my $response = $self->{browser}->request($req);
    die "$method on $uri failed: ".$response->status_line ."\n". $response->content
      unless ( $response->is_success );

    return $response;
};


no Moose;
1;
