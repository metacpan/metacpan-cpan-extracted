#!/usr/bin/env perl

# Usage: perl -Ilib etc/generate_pod.pl

use strict;
use warnings;

use Text::Caml;

use WebService::Pinterest;

my %BASE_METHOD_FOR = (
    GET    => 'fetch',
    POST   => 'create',
    PATCH  => 'edit',
    DELETE => 'delete',
);

my @endpoint_specs = @WebService::Pinterest::Spec::ENDPOINT_SPECS;    # XXX
my @endpoints;
for my $e_spec (@endpoint_specs) {
    next unless $e_spec->{resource};

    my ( $m, $p ) = @{ $e_spec->{endpoint} };

    my $rs = do { my $r = $e_spec->{resource}; ref $r eq 'ARRAY' ? $r : [$r] };

    my $b = $BASE_METHOD_FOR{$m};    # fetch, create, ...
    my $r = $rs->[0];
    $r =~ s{/}{_}g;                  # me, my_boards, ...

    my $om = ( $b eq 'fetch' && $r =~ /^search_/ ) ? $r : "${b}_${r}";

    push @endpoints, {
        resources     => $rs,
        object_method => $om,        # fetch_me, create_pin, ...
        http_method   => $m,         # GET, POST, ...
        endpoint_path => $p,         # /v1/me/, /v1/pins/ ...
    };

}

my $template = do { local $/; <DATA> };
my $view = Text::Caml->new();
my $output =
  $view->render( $template, { endpoint => \@endpoints, script => $0, } );

print $output;

__DATA__

=head1 SUPPORTED ENDPOINTS

All supported endpoints are listed below.
For details on the parameters for each call, take a look at

    https://developers.pinterest.com/docs/api/users/
    https://developers.pinterest.com/docs/api/boards/
    https://developers.pinterest.com/docs/api/pins/

=over 4

{{#endpoint}}
=item C<{{http_method}} {{endpoint_path}}>

    Resource:{{#resources}} {{.}}{{/resources}}


    Endpoint method: {{object_method}}


{{/endpoint}}

=back


