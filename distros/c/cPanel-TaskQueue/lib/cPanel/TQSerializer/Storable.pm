package cPanel::TQSerializer::Storable;
$cPanel::TQSerializer::Storable::VERSION = '0.850';
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

__END__

Copyright (c) 2014, cPanel, Inc. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
