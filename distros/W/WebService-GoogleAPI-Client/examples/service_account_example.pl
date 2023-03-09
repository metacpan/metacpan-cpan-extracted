#!/usr/bin/env perl

use strictures;
use Data::Printer;
use Mojo::UserAgent;
use Mojo::JWT::Google;

my $config = {
  path   => $ARGV[0] // '/Users/peter/Downloads/computerproscomau-b9f59b8ee34a.json',
  scopes => $ARGV[1]
      // 'https://www.googleapis.com/auth/plus.business.manage https://www.googleapis.com/auth/compute'
};

my $jwt = Mojo::JWT::Google->new(from_json => $config->{path}, scopes => [ split / /, $config->{scopes} ]);

my $ua = Mojo::UserAgent->new();

my $response = $ua->post(
  'https://www.googleapis.com/oauth2/v4/token',
  form => {
    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    'assertion'  => $jwt->encode
  }
);

if ($response->res) {
  p $response->res->json;
} else {
  warn $response->res->status, "\n";
}

exit;

=pod

POST https://www.googleapis.com/oauth2/v4/token

grant_type	Use the following string, URL-encoded as necessary: urn:ietf:params:oauth:grant-type:jwt-bearer
assertion	The JWT, including signature.

POST /oauth2/v4/token HTTP/1.1
Host: www.googleapis.com
Content-Type: application/x-www-form-urlencoded

grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiI3NjEzMjY3OTgwNjktcjVtbGpsbG4xcmQ0bHJiaGc3NWVmZ2lncDM2bTc4ajVAZGV2ZWxvcGVyLmdzZXJ2aWNlYWNjb3VudC5jb20iLCJzY29wZSI6Imh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvcHJlZGljdGlvbiIsImF1ZCI6Imh0dHBzOi8vYWNjb3VudHMuZ29vZ2xlLmNvbS9vL29hdXRoMi90b2tlbiIsImV4cCI6MTMyODU3MzM4MSwiaWF0IjoxMzI4NTY5NzgxfQ.ixOUGehweEVX_UKXv5BbbwVEdcz6AYS-6uQV6fGorGKrHf3LIJnyREw9evE-gs2bmMaQI5_UbabvI4k-mQE4kBqtmSpTzxYBL1TCd7Kv5nTZoUC1CmwmWCFqT9RE6D7XSgPUh_jF1qskLa2w0rxMSjwruNKbysgRNctZPln7cqQ


=cut

=pod
Required claims
The required claims in the JWT claim set are shown below. They may appear in any order in the claim set.

Name	Description
iss	    The email address of the service account.
scope	A space-delimited list of the permissions that the application requests.
aud	    A descriptor of the intended target of the assertion. When making an access token request this value is always https://www.googleapis.com/oauth2/v4/token.
exp	    The expiration time of the assertion, specified as seconds since 00:00:00 UTC, January 1, 1970. This value has a maximum of 1 hour after the issued time.
iat	    The time the assertion was issued, specified as seconds since 00:00:00 UTC, January 1, 1970.

=cut

