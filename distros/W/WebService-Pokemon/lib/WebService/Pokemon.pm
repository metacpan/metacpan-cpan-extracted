package WebService::Pokemon;

use 5.008_005;
use strict;
use warnings;

use Mouse;

with 'Web::API';

our $VERSION = '0.03';


has 'commands' => (
    is      => 'rw',
    default => sub {
        {
            pokemon => { method => 'GET', require_id => 1, path => 'pokemon/:id/' },
        };
    },
);


sub commands {
    my ($self) = @_;

    return $self->commands;
}

sub BUILD {
    my ($self) = @_;

    $self->user_agent(__PACKAGE__ . ' ' . $VERSION);
    $self->base_url('http://pokeapi.co/api/v2');
    $self->content_type('application/json');
    # $self->debug(1);

    return $self;
}


1;
__END__

=encoding utf-8

=head1 NAME

Webservice::Pokemon - A module to access the Pokémon data through RESTful API
from http://pokeapi.co.

=head1 SYNOPSIS

  use WebService::Pokemon;

=head1 DESCRIPTION

Webservice::Pokemon is a Perl client helper library for the Pokemon API (pokeapi.co).

=head1 DEVELOPMENT

Setting up the required packages.

    $ cpanm Dist::Milla
    $ milla listdeps --missing | cpanm

Check you code coverage.

    $ milla cover

Several ways to run the test.

    $ milla test
    $ milla test --author --release
    $ AUTHOR_TESTING=1 RELEASE_TESTING=1 milla test
    $ AUTHOR_TESTING=1 RELEASE_TESTING=1 milla run prove t/01_instantiation.t

Release the module.

    $ milla build
    $ milla release

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Kian Meng, Ang.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=head1 AUTHOR

Kian Meng, Ang E<lt>kianmeng@users.noreply.github.comE<gt>
