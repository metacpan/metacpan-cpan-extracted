package Tropo::WebAPI::Ask;

# ABSTRACT: "Ask" something with Tropo

use strict;
use warnings;

use Moo;
use Types::Standard qw(Num Int Str Bool ArrayRef Dict);
use Type::Tiny;

extends 'Tropo::WebAPI::Base';

Tropo::WebAPI::Base::register();

our $VERSION = 0.01;

has text          => (is => 'ro', isa => Str, required => 1);
has attempts      => (is => 'ro', isa => Int);
has timeout       => (is => 'ro', isa => Int);
has choices       => (is => 'ro', isa => Str);
has voice         => (is => 'ro', isa => Str);
has allow_signals => (is => 'ro', isa => ArrayRef[]);

sub BUILDARGS {
   my ( $class, @args ) = @_;
 
  unshift @args, "text" if @args % 2;

  return { @args };
}

1;

__END__

=pod

=head1 NAME

Tropo::WebAPI::Ask - "Ask" something with Tropo

=head1 VERSION

version 0.16

=head1 NAME

Tropo::WebAPI::Ask - "Ask" something with Tropo

=head1 VERSION

version 0.14

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
