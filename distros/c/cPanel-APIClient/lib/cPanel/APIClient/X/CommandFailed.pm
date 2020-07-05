package cPanel::APIClient::X::CommandFailed;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use parent qw( cPanel::APIClient::X::Base );

sub _new {
    my ( $class, $cmd_ar, $child_err ) = @_;

    my $signal = $child_err & 127;
    if ($signal) {
        require Config;
        my @signame = split m< >, $Config::Config{'sig_name'};

        my $name = $signame[$signal] || '??';

        $signal .= "/$name";
    }

    my $exit = $child_err >> 8;
    my $core = $child_err & 128;

    my $err = $signal ? "got signal $signal" : "exit $exit";
    $err .= ', dumped core' if $core;

    return $class->SUPER::_new("Command failed ($err): @$cmd_ar");
}

1;
