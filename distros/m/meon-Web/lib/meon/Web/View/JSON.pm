package meon::Web::View::JSON;

use strict;
use base 'Catalyst::View::JSON';

use JSON::XS;

sub encode_json ($) {
    my($self, $c, $data) = @_;
    my $encoder = JSON::XS->new->utf8;
    $encoder->pretty(1)
        if $c->debug;
    return $encoder->encode($data);
}

1;
