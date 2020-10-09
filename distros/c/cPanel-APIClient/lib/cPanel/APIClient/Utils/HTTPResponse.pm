package cPanel::APIClient::Utils::HTTPResponse;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

# Right now these are the only pieces of HTTP::Response that we need.
# HTTP::Response is fairly large, so since we only need a small part of it,
# we implement those parts ourselves.

sub new {
    my ( $class, $code, $resp_head, $resp_body ) = @_;

    return bless [ $code, $resp_head, $resp_body ], $class;
}

sub code {
    my ($self) = @_;

    return $self->[0];
}

sub as_string {
    my ($self) = @_;

    return $self->[1] . $self->[2];
}

# needed for sessions
sub header {
    my ( $self, $name ) = @_;

    $name =~ tr<A-Z><a-z>;

    my @lines = split m<\x0d?\x0a>, $self->[1];

    for my $line (@lines) {
        my ( $thisname, $value ) = split m<\s*:\s*>, $line;
        $thisname =~ tr<A-Z><a-z>;

        if ( $name eq $thisname ) {
            return $value;
        }
    }

    return undef;
}

1;
