package Text::Password::Pronounceable::Harden;

use strict;
use warnings;
use Moose;
use Text::Pipe;
use Text::Pipe::Stackable;
use Text::Password::Pronounceable;

has pipe => (
    is      => 'ro',
    builder => '_create_pipe',
    lazy    => 1,
    isa     => 'Text::Pipe::Stackable',
    handles => [qw( pop push shift unshift count clear splice )]
);

has generator => (
    is      => 'rw',
    isa     => 'Text::Password::Pronounceable',
    lazy    => 1,
    builder => '_create_generator'
);

has min => ( is => 'rw', isa => 'Int', default => 8 );
has max => ( is => 'rw', isa => 'Int', default => 8 );

__PACKAGE__->meta->make_immutable;

our $VERSION = '0.01';

sub _create_pipe {
    my ($self) = @_;
    return Text::Pipe::Stackable->new();
}

sub _create_generator {
    my ($self) = @_;
    return Text::Password::Pronounceable->new( $self->min, $self->max );
}

sub add_filter {
    my ( $self, $name, @args ) = @_;
    my $pipe = Text::Pipe->new( $name, @args );
    $self->pipe->push($pipe);
}

sub generate {
    my ($self) = @_;
    my $password = $self->generator->generate( $self->min, $self->max );
    return $self->pipe->filter($password);
}

1;

__END__

=head1 NAME

Text::Password::Pronounceable::Harden - harden your pronounceable passwords

=head1 SYNOPSIS

  use Text::Password::Pronounceable::Harden;
  my $pwgen = Text::Password::Pronounceable::Harden->new(min => 8, max => 12);
  $pwgen->add_filter('RandomCase', probability => 2 );
  $pwgen->generate();

=head1 DESCRIPTION

Althouh less secure than random passwords, most people have less
problems to remember chunks of pronounceable characters rather than
individual characters themselves. L<Text::Password::Pronounceable>
produces those, but it has the one disadvantage that it only uses
lower case characters.  This module tries to solve this shortcoming
by providing a generic text filter to generate passwords that are
at the same time easy to remember and harder to crack.

It's intended to be used with filters like L<Text::Pipe::RandomCase>,
but you can actually use any of Text::Pipes filters if you want to.

=head1 CONSTRUCTION

The following paramters can be passed to I<new()>, but none of these
are actually required:

=over 4

=item min

The minimum numbers of characters a password should have. Defaults to 8.

=item max

The maximum numbers of characters a password should have. Defaults to 12.

=item pipe

A already initilized L<Text::Pipe::Stackable> object.

=item generator

A already initilized L<Text::Password::Pronounceable> object.

=back

=head1 METHODS

=head2 generate($min, $max)

Generates a new password with L<Text::Password::Pronounceable> and
filter it through every pipe added via I<add_filter> of the native
pipe methods.

=head2 add_filter($name, @arguments)

Add the pipe segment I<$name> to your stackable pipe and initialize it with I<@arguments>. The construct is syntactically identical to the following:

  my $pipe = Text::Pipe->new($name, @arguments);
  $stacked_pipe->push($pipe);

=head2 pop(), push(), shift(), unshift(), count(), clear() and splice()

These methods are delegated to the underlying L<Text::Pipe::Stackable>
pipe attribute. Please note, that unlike I<add_filter()> you will
have to construct the pipe segments by hand with these methods.

=head1 VERSION

0.01

=head1 AUTHOR

Mario Domgoergen <mdom@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-password-pronounceable-harden
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Passwort-Pronounceable-Harden>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Password::Pronounceable::Harden

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Password-Pronounceable-Harden>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Password-Pronounceable-Harden>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Password-Pronounceable-Harden>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Password-Pronounceable-Harden>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2008-2009 Mario Domgoergen.

This program is free software; you can redistribute it and/or modify
it under the terms the GNU General Public License as published by
the Free Software Foundation; either version 1, or (at your option)
any later version.

