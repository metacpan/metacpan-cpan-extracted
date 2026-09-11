package eBay::Client::OpenAPI3;

use strict;
use warnings;

use JSON;
use URI ();
use HTTP::Tiny;
use HTTP::Status;
use MIME::Base64;
use Util::H2O::More qw/baptise d2o ddd HTTPTiny2h2o h2o ini2h2o o2h/;

our $VERSION = '0.01';
our $EBAY_ENDPOINT_BASE = q{https://api.ebay.com};

sub new {
    my $pkg  = shift;
    my %opts = @_;
    my $self = baptise \%opts, $pkg, qw/config next token total/;
    die qq{configuration file not found\n} if not -e $self->config;
    my $config_file = $self->config;        # initially, ->config is just a string file name
    $self->config(ini2h2o $config_file);    # then it becomes an actual Config::Tiny object with accessors
    return $self;
}

# Construction seam used by tests/subclasses; default behavior remains HTTP::Tiny.
sub _new_ua {
    my ($self, %opts) = @_;
    return HTTP::Tiny->new(%opts);
}

sub oauth2 {
    my ($self)        = @_;
    my $ua            = $self->_new_ua();
    my $URL           = sprintf qq{%s/%s},    $EBAY_ENDPOINT_BASE, q{identity/v1/oauth2/token};
    my $authorization = sprintf qq{%s:%s},    $self->config->eBay->client_id, $self->config->eBay->client_secret;
    my $auth_token    = sprintf qq{Basic %s}, encode_base64( $authorization, q{} );
    my $options       = {
        headers => {
            'Content-Type'  => q{application/x-www-form-urlencoded},
            'Authorization' => $auth_token,
        },

        # define API scopes enabled by this token
        content => q{grant_type=client_credentials&scope=https://api.ebay.com/oauth/api_scope},
    };

    my $resp = h2o $ua->post($URL, $options);

    my $full = h2o JSON::from_json $resp->content;

    # set token member
    $self->token($full);

    # return $self, for chaining
    return $self;
}

sub warn_if_exists {
  my ($self, $headers, $header) = @_;
  if (exists $headers->{$header}) {
    warn sprintf("WARNING: '%s' detected: %s\n\n", $header, $headers->{$header})
  }
}

sub _defined_params {
    my (%params) = @_;
    return map { defined $params{$_} ? ( $_ => $params{$_} ) : () } keys %params;
}

sub _error_message_from_json {
    my ($json) = @_;
    return eval { $json->errors->get(0)->longMessage }
        // eval { $json->{errors}->[0]{longMessage} }
        // q{Unknown error};
}

# Call limit for all Browse APIs is 5,000 / day
#   https://developer.ebay.com/develop/apis/api-call-limits

sub get_ua {
    my ($self)          = @_;
    my $auth_token      = sprintf qq{Bearer %s}, $self->token->access_token;
    my $options         = {
        default_headers    => {
            'Accept'                  => q{*/*},
            'Authorization'           => $auth_token,
            'X-EBAY-C-MARKETPLACE-ID' => 'EBAY_US',
            'X-EBAY-C-ENDUSERCTX'     => sprintf('affiliateCampaignId=%s', $self->config->eBay->affiliateCampaignId),
        },
        # define API scopes enabled by this token
        content => undef,
    };
    my $ua              = $self->_new_ua(%$options);
    return $ua;
}

# https://api.ebay.com/developer/analytics/v1_beta/rate_limit?api_name=browse
sub rate_limit {
    my ($self, %params) = @_;
    my $ua              = $self->get_ua; 
    my $uri             = URI->new('', 'http');
    $uri->query_form(_defined_params(%params));
    my $URL             = sprintf qq{%s/%s?%s}, $EBAY_ENDPOINT_BASE, q{developer/analytics/v1_beta/rate_limit}, $uri->query;

    my $resp = h2o $ua->get($URL);

    my $raw = $resp->content;
    my $json        = d2o from_json $raw;

    if (not is_success($resp->status)) {
      $self->warn_if_exists($resp->headers, "x-ebay-api-call-limit");
      $self->warn_if_exists($resp->headers, "x-ebay-api-throttle-limit");
      $self->warn_if_exists($resp->headers, "x-ebay-api-throttle-remaining");
      my $status = $resp->status;
      my $msg = _error_message_from_json($json);
      die "$msg (HTTP Status: $status)\n";
    }

    return $json;
}

# getItem (part of the 'Browse' API); only gets one item at a time
sub getItem {
    my ($self, %params) = @_;
    my $params = h2o \%params, qw/itemid/;
    my $URL             = sprintf qq{%s/%s/v1|%s|0}, $EBAY_ENDPOINT_BASE, q{buy/browse/v1/item}, $params->itemid;

    my $ua   = $self->get_ua;
    my $resp = HTTPTiny2h2o $ua->get($URL);

    # error handling
    if (not is_success($resp->status)) {
      $self->warn_if_exists($resp->headers, "x-ebay-api-call-limit");
      $self->warn_if_exists($resp->headers, "x-ebay-api-throttle-limit");
      $self->warn_if_exists($resp->headers, "x-ebay-api-throttle-remaining");
      my $status = $resp->status;
      my $msg = eval { $resp->content->errors->get(0)->longMessage } // "Unknown error";
      die "$msg (HTTP Status: $status)\n";
    }

    return $resp->content;;
}

# Perl-style alias; retain getItem() for compatibility with existing callers.
sub get_item {
    my ($self, @args) = @_;
    return $self->getItem(@args);
}

# https://developer.ebay.com/api-docs/buy/browse/resources/item_summary/methods/search
sub browse {
    my ($self, %params) = @_;
    my $ua              = $self->get_ua; 
    my $uri             = URI->new('', 'http');
    $uri->query_form(_defined_params(%params));
    my $URL             = sprintf qq{%s/%s?%s}, $EBAY_ENDPOINT_BASE, q{buy/browse/v1/item_summary/search}, $uri->query;
    my $resp = h2o $ua->get($URL);

    my $raw = $resp->content;
    my $json         = from_json $raw;
    $json->{next}    = $json->{next}      // undef;  # d2o should probably allow some top level
    $json->{total}   = $json->{total}     // undef;  # default accessors to be defined
    $json->{warnings} = $json->{warnings} // [];     # default accessors to be defined
    $json->{errors}   = $json->{errors}   // [ { longMessage => undef } ];
    $json = d2o $json;

    if (not is_success($resp->status)) {
      $self->warn_if_exists($resp->headers, "x-ebay-api-call-limit");
      $self->warn_if_exists($resp->headers, "x-ebay-api-throttle-limit");
      $self->warn_if_exists($resp->headers, "x-ebay-api-throttle-remaining");
      my $status = $resp->status;
      my $msg = _error_message_from_json($json);
      die "$msg (HTTP Status: $status)\n";
    }

    # capture the next URL as member, "next"
    $self->next($json->next);
    $self->total($json->total);

    return $json;
}

1;

__END__

=head1 NAME

eBay::Client::OpenAPI3 - lightweight client for selected eBay REST APIs

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  use eBay::Client::OpenAPI3;

  my $ebay = eBay::Client::OpenAPI3->new(
      config => "$ENV{HOME}/.ebayapi3.conf",
  );

  my $results = $ebay->oauth2->browse(
      category_ids => 13956,
      q            => 'patch insignia SSI',
      filter       => 'buyingOptions:{AUCTION}',
      limit        => 50,
      offset       => 0,
      sort         => 'newlyListed',
  );

=head1 DESCRIPTION

C<eBay::Client::OpenAPI3> is a small client for the parts of eBay's REST API
currently needed by its applications.  Version 0.01 supports application OAuth2,
Browse API search, retrieving a Browse item from a legacy numeric item ID, and
Developer Analytics rate-limit information.

The client intentionally remains close to the API.  It does not attempt to be a
complete generated OpenAPI client, and Browse query parameters are passed
through with minimal transformation.

=head1 CONFIGURATION

The constructor takes the filename of an INI configuration file.  It does not
take a token hashref.

  [eBay]
  client_id            = your-client-id
  client_secret        = your-client-secret
  affiliateCampaignId  = your-epn-campaign-id
  affiliateReferenceId = optional-reference-id

C<client_id> and C<client_secret> are used to obtain an application OAuth token.
The existing client behavior uses C<affiliateCampaignId> when building the
C<X-EBAY-C-ENDUSERCTX> request header.  C<affiliateReferenceId> is retained in
the configuration format for compatibility with existing deployments but is
not currently added to that header by this module.

The production endpoint and C<EBAY_US> marketplace are currently fixed in the
implementation.

=head1 METHODS

=head2 new

  my $ebay = eBay::Client::OpenAPI3->new(
      config => '/path/to/.ebayapi3.conf',
  );

Constructs a client and reads the INI configuration file.  The file must exist.
No network request is made by the constructor.

=head2 oauth2

  $ebay->oauth2;

Obtains an application OAuth token using the client-credentials flow, stores the
decoded token response in C<< $ebay->token >>, and returns the client object so
calls can be chained.

=head2 browse

  my $results = $ebay->browse(%params);

Calls the Browse API C<item_summary/search> endpoint:

  /buy/browse/v1/item_summary/search

Undefined values are omitted from the query string.  Common parameters include
C<category_ids>, C<q>, C<filter>, C<limit>, C<offset>, and C<sort>.  Other
supplied parameters are passed through rather than checked against a local copy
of the eBay schema.

The decoded response is returned as nested accessor objects.  The response's
C<next> URL and C<total> value are also stored in C<< $ebay->next >> and
C<< $ebay->total >>.

=head2 getItem

  my $item = $ebay->getItem(itemid => 123456789012);

Retrieves one Browse item.  The supplied numeric legacy item ID is converted to
the REST Browse item-ID form C<v1|ITEMID|0>.

This camel-case spelling is the original public interface and is retained for
compatibility.

=head2 get_item

  my $item = $ebay->get_item(itemid => 123456789012);

A Perl-style alias for C<getItem>.  It does not change the behavior of the
original method.

=head2 rate_limit

  my $info = $ebay->rate_limit(api_name => 'browse');

Calls the Developer Analytics rate-limit endpoint:

  /developer/analytics/v1_beta/rate_limit

Query parameters are passed through to the endpoint.

=head2 get_ua

Builds the authenticated L<HTTP::Tiny> client used for API requests.  Normal
callers generally use C<oauth2> first and then call one of the API methods.

=head1 ERROR HANDLING

For Browse, item, and rate-limit requests, HTTP error responses cause the method
to die.  The client attempts to use C<errors[0].longMessage> where available and
includes the HTTP status.  eBay rate/throttle headers are warned when present on
those failures.

Version 0.01 deliberately preserves the pre-CPAN OAuth behavior rather than
changing failure semantics during packaging cleanup.

=head1 COMPATIBILITY

The initial CPAN release is intended to preserve the behavior of the pre-CPAN
client and the C<ebayapi3> utility used by existing applications.  New method
names and test seams in 0.01 are additive.

=head1 LIMITATIONS

This release implements only a small subset of eBay's REST API surface.  It does
not validate OpenAPI schemas, normalize responses into separate domain classes,
or expose every Browse resource.

=head1 BUGS AND SUPPORT

Please report bugs and feature requests at:

L<https://github.com/oodler577/p5-eBay-Client-OpenAPI3/issues>

Source repository:

L<https://github.com/oodler577/p5-eBay-Client-OpenAPI3>

=head1 AUTHOR

Oodler 577 L<< <oodler@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Brett Estrade.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
