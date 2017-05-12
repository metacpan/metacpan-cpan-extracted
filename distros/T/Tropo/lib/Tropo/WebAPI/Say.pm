package Tropo::WebAPI::Say;

# ABSTRACT: "Say" something with Tropo

use strict;
use warnings;

use Moo;
use Types::Standard qw(Int Str Bool ArrayRef Dict);
use Type::Tiny;

extends 'Tropo::WebAPI::Base';

Tropo::WebAPI::Base::register();

our $VERSION = 0.01;

has value => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has as => (
    is  => 'ro',
    isa => Str,
);

has event => (
    is  => 'ro',
    isa => Str,
);

has voice => (
    is  => 'ro',
    isa => Int,
);

has allow_signals => (
    is  => 'ro',
    isa => ArrayRef[],
);

sub BUILDARGS {
   my ( $class, @args ) = @_;
 
  unshift @args, "value" if @args % 2 == 1;
 
  return { @args };
}

1;

__END__

=pod

=head1 NAME

Tropo::WebAPI::Say - "Say" something with Tropo

=head1 VERSION

version 0.16

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
