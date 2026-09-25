package QdrantTest;
use strict;
use warnings;
use parent 'LWP::UserAgent';
use Exporter 'import';
use HTTP::Response;
use JSON::MaybeXS;
use WebService::Qdrant;
use WebService::Qdrant::UA;
our @EXPORT_OK = qw(client_for json_response);

sub json_response {
   my ($code, $data) = @_;
   return HTTP::Response->new($code, undef,
      ['Content-Type' => 'application/json'],
      JSON::MaybeXS->new(utf8 => 1)->encode($data));
}

sub client_for {
   my ($response) = @_;
   my $http = __PACKAGE__->new;
   $http->{test_response} = $response;
   $http->{test_requests} = [];
   my $transport = WebService::Qdrant::UA->new(
      base_url => 'http://qdrant.invalid:6333', ua => $http);
   return (WebService::Qdrant->new(
      base_url => 'http://qdrant.invalid:6333', ua => $transport), $http);
}

# Intercept at the HTTP boundary, exercising the real client and JSON layer.
# No request can reach the network, even when the implementation is broken.
sub request {
   my ($self, $request) = @_;
   push @{$self->{test_requests}}, $request->clone;
   die $self->{test_response} if !ref $self->{test_response};
   return $self->{test_response}->clone;
}

sub requests { return $_[0]->{test_requests}; }
1;
