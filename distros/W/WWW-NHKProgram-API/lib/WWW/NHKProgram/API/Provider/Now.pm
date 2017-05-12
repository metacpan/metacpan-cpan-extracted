package WWW::NHKProgram::API::Provider::Now;
use strict;
use warnings;
use utf8;
use JSON ();
use WWW::NHKProgram::API::Area    qw/fetch_area_id/;
use WWW::NHKProgram::API::Service qw/fetch_service_id/;
use WWW::NHKProgram::API::Provider::Common;

sub call {
    my ($class, $context, $arg, $raw) = @_;

    my $area    = fetch_area_id($arg->{area});
    my $service = fetch_service_id($arg->{service});

    my $content = WWW::NHKProgram::API::Provider::Common::call(
        $context,
        "now/%(area)s/%(service)s.json",
        {
            area    => $area,
            service => $service,
        },
        $raw,
    );
    return $content if $raw;
    return JSON::decode_json($content)->{nowonair_list}->{$service};
}

1;
