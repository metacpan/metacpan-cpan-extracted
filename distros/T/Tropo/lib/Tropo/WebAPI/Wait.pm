package Tropo::WebAPI::Wait;

# ABSTRACT: "Wait" with Tropo

use strict;
use warnings;

use Moo;
use Types::Standard qw(Num Int Str Bool ArrayRef Dict);
use Type::Tiny;

extends 'Tropo::WebAPI::Base';

Tropo::WebAPI::Base::register();

our $VERSION = 0.01;

has milliseconds  => (is => 'ro', isa => Int, required => 1);
has on_signals    => (is => 'ro', isa => Str);
has allow_signals => (is => 'ro', isa => ArrayRef[]);

sub BUILDARGS {
   my ( $class, @args ) = @_;
 
  unshift @args, "milliseconds" if @args % 2 == 1;
 
  return { @args };
}

1;

__END__

=pod

=head1 NAME

Tropo::WebAPI::Wait - "Wait" with Tropo

=head1 VERSION

version 0.16

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
