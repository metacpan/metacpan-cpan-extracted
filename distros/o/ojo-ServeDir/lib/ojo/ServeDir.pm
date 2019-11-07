package ojo::ServeDir;

use 5.020;
use strict;
use warnings FATAL => 'all';

use ojo;

our $VERSION = '0.02';

sub import {
    push @{app->static->paths}, app->home->rel_file('.');
    app->start('daemon');
}

1;

__END__

=head1 NAME

ojo::ServeDir - Helper module to serve local files

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    $ perl -Mojo::ServeDir

=head1 CONTRIBUTORS

=over 4

=item Mohammad S Anwar

=back

=head1 AUTHOR

Mirko Westermeier, C<< <mirko at westermeier.de> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Mirko Westermeier.

Released under the MIT (X11) license. See LICENSE for details.
