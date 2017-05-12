package WWW::NHKProgram::API::Provider::Info;
use strict;
use warnings;
use utf8;
use JSON ();
use WWW::NHKProgram::API::Area    qw/fetch_area_id/;
use WWW::NHKProgram::API::Service qw/fetch_service_id/;
use WWW::NHKProgram::API::Provider::Common;

sub call {
    my ($self, $context, $arg, $raw) = @_;

    my $area    = fetch_area_id($arg->{area});
    my $service = fetch_service_id($arg->{service});
    my $id      = $arg->{id};

    my $content = WWW::NHKProgram::API::Provider::Common::call(
        $context,
        "info/%(area)s/%(service)s/%(id)s.json",
        {
            area    => $area,
            service => $service,
            id      => $id,
        },
        $raw,
    );
    return $content if $raw;
    return JSON::decode_json($content)->{list}->{$service}->[0];
}

1;
