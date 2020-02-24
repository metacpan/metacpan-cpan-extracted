package ojo::ServeDir;

use strict;
use warnings FATAL => 'all';
use ojo::ServeDir::App;

our $VERSION = '0.11';

sub import {
    ojo::ServeDir::App->new->start('daemon');
}

1;

__END__

=head1 NAME

ojo::ServeDir - Helper module to serve local files

=head1 VERSION

Version 0.1

=head1 SYNOPSIS

Module import interface:

    $ perl -Mojo::ServeDir

Command interface:

    $ serve_dir DIRECTORY_NAME OPTIONS

The directory name is optional (default is the current working directory), options go directly to Mojo's C<daemon> command.

=head1 CONTRIBUTORS

=over 4

=item Mohammad S Anwar

=back

=head1 AUTHOR

Mirko Westermeier, C<< <mirko at westermeier.de> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) by Mirko Westermeier.

Released under the MIT (X11) license. See LICENSE for details.
