package cPanel::TQSerializer::Storable;
$cPanel::TQSerializer::Storable::VERSION = '0.800';
# cpanel - cPanel/TQSerializer/Storable.pm        Copyright(c) 2014 cPanel, Inc.
#                                                           All rights Reserved.
# copyright@cpanel.net                                         http://cpanel.net
# This code is subject to the cPanel license. Unauthorized copying is prohibited

use Storable();

#use warnings;
use strict;

sub load {
    my ( $class, $fh ) = @_;
    my $ref = eval { Storable::fd_retrieve($fh) };
    return @{ $ref || [] };
}

sub save {
    my ( $class, $fh, @args ) = @_;
    return Storable::nstore_fd( \@args, $fh );
}

sub filename {
    my ( $class, $stub ) = @_;
    return "$stub.stor";
}

1;

