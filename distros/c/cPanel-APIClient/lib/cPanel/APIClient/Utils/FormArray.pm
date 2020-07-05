package cPanel::APIClient::Utils::FormArray;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use URI::Escape ();

sub to_kv_equals_strings {
    my ($args_hr) = @_;

    return map {
        defined( $args_hr->{$_} ) or die "undef value ($_) is invalid!";

        if ( 'ARRAY' eq ref $args_hr->{$_} ) {
            my $key_u = URI::Escape::uri_escape($_);
            map { "$key_u=" . URI::Escape::uri_escape($_) } @{ $args_hr->{$_} };
        }
        else {
            URI::Escape::uri_escape($_) . '=' . URI::Escape::uri_escape( $args_hr->{$_} );
        }
    } keys %$args_hr;
}

1;
