package WWW::BetterServers::API;

use 5.010001;
use strict;
use warnings;
use POSIX 'strftime';
use Digest::SHA 'hmac_sha256_hex';
use Mojo::JSON;
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::Util 'encode';
use Mojo::Base -base;

our $VERSION = '0.09';

has [qw(api_id api_secret auth_type api_host
        api_port api_scheme agent)];

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    my %args = @_;
    for my $key (qw(api_id api_secret auth_type api_host api_port api_scheme agent)) {
        $self->{$key} = $args{$key} if exists $args{$key};
    }

    $self->{api_host} ||= 'api.betterservers.com';
    $self->{agent}    ||= "WWW-BetterServers-API/$VERSION";

    $self->{_ua} = Mojo::UserAgent->new;
    $self->{_ua}->transactor->name($self->{agent});

    return $self;
}

sub ua {
    $_[0]->{_ua};
}

sub request {
    my $self = shift;
    my %args = @_;

    $args{host}      //= $self->{api_host};
    $args{api_id}    //= $self->{api_id};
    $args{secret}    //= $self->{api_secret};
    $args{auth_type} //= $self->{auth_type};
    $args{scheme}    //= $self->{api_scheme} // 'https';
    $args{port}      //= $self->{api_port};
    $args{date}      //= strftime("%a, %d %b %Y %T GMT", gmtime);
    $args{body}      //= ($args{payload} ? Mojo::JSON->new->encode($args{payload}) : '');

    $args{url} = Mojo::URL->new($args{uri});
    $args{url}->scheme($args{scheme});
    $args{url}->host($args{host});
    $args{url}->port($args{port}) if $args{port};

    my $req_str = join("\x0d\x0a",
                       encode('UTF-8', $args{method}),
                       encode('UTF-8', $args{host}),
                       encode('UTF-8', $args{date}),
                       encode('UTF-8', $args{url}->path),
                       $args{body});

    if ($ENV{BSAPI_AUTH_DEBUG}) {
        print STDERR "url:         " . $args{url}->path . "\n";
        print STDERR "signed url:  " . hmac_sha256_hex($args{url}->path, $args{secret}) . "\n";
        print STDERR "body:        " . $args{body} . "\n";
        print STDERR "signed body: " . hmac_sha256_hex($args{body}, $args{secret}) . "\n";
        print STDERR "url + body:  " . hmac_sha256_hex($args{url}->path . $args{body}, $args{secret}) . "\n";
        print STDERR "string:      " . $req_str . "\n";
        print STDERR "signature:   " . hmac_sha256_hex($req_str, $args{secret}) . "\n";
    }

    my $signature = sub { hmac_sha256_hex( $req_str,
                                           $args{secret} ) }->();

    my $headers = { Date => $args{date},
                    "Content-Type" => "application/json",
                    Authorization => "$args{auth_type} $args{api_id}:$signature" };

    my $sub = lc($args{method});

    ref($args{pre_hook}) eq 'CODE' && $args{pre_hook}->($self, \%args, $headers);

    my $tx = $self->ua->$sub($args{url}->to_string,
                             $headers,
                             $args{body},
                             (ref($args{callback}) eq 'CODE' ? $args{callback} : ()));

    return (ref($args{callback}) eq 'CODE' ? undef : $tx->res);
}

1;
__END__

=head1 NAME

WWW::BetterServers::API - Perl interface for the BetterServers REST API

=head1 SYNOPSIS

  use WWW::BetterServers::API;
  use v5.10;

  my $api_id    = '(your API id)';
  my $secret    = '(your API secret)';
  my $auth_type = '(your auth type)';

  my $api = new WWW::BetterServers::API(api_id     => $api_id,
                                        api_secret => $secret,
                                        auth_type  => $auth_type);

  my $resp = $api->request(method  => "POST",
                           uri     => "/v1/accounts/$api_id/instances",
                           payload => {display_name => "new server 4",
                                       plan_id => (plan UUID)});

  if( $resp->code == 201 ) {
      say "New instance created!\n";
  }

  $api->api_id($api_id);
  $api->api_secret($secret);

  $resp = $api->request(method => "GET",
                        uri    => "/v1/accounts/$api_id/instances");

  if( $resp->code == 200 ) {
      say "Your instances:";
      for my $inst ( @{ $resp->json('/instances') } ) {
          print <<_INSTANCE_;
ID: $inst->{id}
Name: $inst->{displayname}

_INSTANCE_
      }
  }

=head1 DESCRIPTION

B<WWW::BetterServers::API> is an easy-to-use wrapper for the
BetterServers REST API. All you need is your BetterServers API id and
API secret (available in the BetterServers portal after signup).

=head2 new

Creates a new B<BetterServers API> object.

=head3 Parameters

=over 4

=item B<api_id>

Required. Your BetterServers API id. This is in the portal area after
you've signed up for BetterServers.

=item B<api_secret>

Required. Your BetterServers API secret. This is in the portal area
after you've signed up for BetterServers.

=item B<auth_type>

Required. Your BetterServers auth type. This uniquely identifies your
organization.

=item B<api_host>

Optional. If you're a white label reseller, specify your API hostname
here. Defaults to I<api.betterservers.com>.

=back

=head3 Example

    $api = new WWW::BetterServers::API(api_id => "123456-1234-1234-12345678",
                                       api_secret => "wefoidfjl324asdf982asdflkj234",
                                       auth_type => "FOKA83TI");

=head2 ua

A handle to the B<Mojo::UserAgent> object. Normally not needed unless
you want to set special proxy or other parameters. See L<Mojo::UserAgent>.

    $api->ua->https_proxy('http://localhost:8443');

=head2 request

Makes a request to the BetterServers API server (or B<api_host> if
you've specified it). Returns a B<Mojolicious> response object. The
response object has the following methods:

=over 4

=item B<code>

The HTTP response status code (e.g., 200, 404, etc.)

    if ($resp->code !~ /^[23]/) {
        warn "Error: " . $resp->json('/error') . "\n";
    }

=item B<message>

The HTTP response message (e.g., "OK", "Not Found", etc.)

=item B<headers>

A list of response headers.

=item B<json>

A B<Mojo::JSON> object. You may specify a JSON pointer to retrieve a
particular value:

    my $resp = $api->request(method => "GET",
                             uri => "/v1/instances");

    print $resp->json('/instances/0/id');

=item B<body>

The raw body of the response.

=back

=head3 Parameters

All of these parameters reference the API directly; see the API
documentation for details:

  https://www.betterservers.com/docs/api

For example, if you want to create a new VM instance, find "Create
account instance" in the API documentation here:

  https://www.betterservers.com/docs/api#createaccountinstance

The B<Method/URI> section will tell you what HTTP method and URI path
to use. Parameters, if any, are also listed.

To create new API resources (e.g., instances, plans), you will often
need to know the UUID of other offerings (e.g., disk offerings,
hypervisors, service offerings, etc.). You will look up these UUIDs
using the offerings available:

  https://www.betterservers.com/docs/api#resources

Once you've looked up the available offerings, you can use them to
create your new resource.

=over 4

=item B<method>

One of I<GET>, I<POST>, I<PATCH>, I<PUT>, I<DELETE>, or I<OPTIONS>.

=item B<uri>

The URI reference of the resource you're using.

=item B<payload>

Optional. A way to send JSON data to the API resource. The value of
this parameter should be a reference to a native Perl data type (e.g.,
array, hash) which will be JSON-encoded before it's sent. Mutually
exclusive with B<body>.

=item B<body>

Optional. Some requests require a JSON document or url-encoded strings
in the body; you may specify that here, or use the B<payload>
parameter to let this API helper encode it for you. If you already
have JSON data, use this parameter. Mutually exclusive with
B<payload>.

=item B<callback>

Optional. If you want to do non-blocking requests, specify a callback
subroutine here. The callback will be invoked with a useragent object
and the transaction object; no response will be given from the
request, instead the results will be given to the callback. This
allows you to make multiple, concurrent requests:

    my $delay = Mojo::IOLoop->delay;

    my $end1 = $delay->begin(0);
    $api->request(method   => "GET",
                  uri      => "/v1/instances",
                  callback => sub {
                      my ($ua, $tx) = @_;
                      say "Here are the VMs: " . $tx->res->body;
                      $end1->();
                  });

    my $end2 = $delay->begin(0);
    $api->request(method   => "GET",
                  uri      => "/v1/vpcs",
                  callback => sub {
                      my ($ua, $tx) = @_;
                      say "Here are the VPCs: " . $tx->res->body;
                      $end2->();
                  });

    $delay->wait;

=back

=head3 Example

  ## make a new plan
  $resp = $api->request(method  => 'POST',
                        uri     => "/v1/plans/$plan_id",
                        payload => {name => "Plan C",
                                    service_offering_id => "12345",
                                    disk_offering_id => "23456"});

  ## same thing, but we encode it ourselves
  $resp = $api->request(method => 'POST',
                        uri    => "/v1/plans",
                        body   => JSON::encode_json({name => "Plan B",
                                                     service_offering_id => "12345",
                                                     disk_offering_id => "23456"}));

  unless( $resp->code == 201 ) {
      say STDERR $resp->message;
      die Dumper($resp->json);
  }

=head1 EXAMPLES

Some additional examples may be found in the test suite for this
module. Also see the BetterServers API documentation.

=head1 TESTING

You may run the tests against your own API credentials (no resources
will be altered--only read-only queries are made). The easiest way is
to create a file called F<test-credentials> in the root of this module
when you retrieve it from CPAN:

    API_ID=4C662460-E5E0-11E2-F8DE-1F1F9B08DD17
    API_SECRET=GVSm2m+cvH1Laiphsu8hdOj3uOAVS+o6RoHh5dyoQ08
    AUTH_TYPE=BAFU33FA

Then run the tests from a Bourne-compatible shell:

    $ perl Makefile.PL
    $ make
    $ env `cat test-credentials` make test

=head1 SEE ALSO

L<Mojo::UserAgent>, L<Mojo::JSON>, L<Mojo::IOLoop>

The API helpers:

  https://www.betterservers.com/docs/api-helpers

The API documentation:

  https://www.betterservers.com/docs/api

URI relative references:

  https://tools.ietf.org/html/rfc3986

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@betterservers.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by BetterServers, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
