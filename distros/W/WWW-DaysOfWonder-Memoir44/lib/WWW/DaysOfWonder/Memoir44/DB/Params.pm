#
# This file is part of WWW-DaysOfWonder-Memoir44
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package WWW::DaysOfWonder::Memoir44::DB::Params;
# ABSTRACT: various runtime params
$WWW::DaysOfWonder::Memoir44::DB::Params::VERSION = '3.000';
use Config::Tiny;
use MooseX::Singleton;
use MooseX::Has::Sugar;

use WWW::DaysOfWonder::Memoir44::Utils qw{ $DATADIR };


my $params_file = $DATADIR->file( "params.ini" );

has _params => ( ro, isa => "Config::Tiny", lazy_build );

sub _build__params {
    my $self = shift;
    my $params = Config::Tiny->read( $params_file );
    $params  //= Config::Tiny->new;
    return $params;
}

# -- public methods


sub get {
    my ($self, $key) = @_;
    my $section = scalar caller;
    return $self->_params->{ $section }->{ $key };
}



sub set {
    my ($self, $key, $value) = @_;
    my $section = scalar caller;
    my $params = $self->_params;
    $params->{ $section }->{ $key } = $value;
    $params->write( $params_file );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::DaysOfWonder::Memoir44::DB::Params - various runtime params

=head1 VERSION

version 3.000

=head1 SYNOPSIS

    my $params = WWW::DaysOfWonder::Memoir44::DB::Params->instance;
    my $value  = $params->get( $key );
    $params->set( $key, $value );

=head1 DESCRIPTION

This module allows to store various runtime parameters.

It implements a singleton responsible for automatic retrieving & saving
of the various information. Each module gets its own section, so keys
won't be over-written if sharing the same name accross package.

=head1 METHODS

=head2 get

    my $value = $params->get( $key );

Return the value associated to C<$key> in the wanted section.

=head2 set

    $params->set( $key, $value );

Store the C<$value> associated to C<$key> in the wanted section.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
