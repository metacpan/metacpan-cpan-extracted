package Test::Valgrind::Component;

use strict;
use warnings;

=head1 NAME

Test::Valgrind::Component - Base class for Test::Valgrind components.

=head1 VERSION

Version 1.19

=cut

our $VERSION = '1.19';

=head1 DESCRIPTION

This class is the base for all others that act as components that can be started and stopped.

=cut

use Scalar::Util ();

use base qw<Test::Valgrind::Carp>;

=head1 METHODS

=head2 C<new>

    my $tvc = Test::Valgrind::Component->new;

Basic constructor.

=cut

sub new {
 my $self = shift;

 my $class = $self;
 if (Scalar::Util::blessed($self)) {
  $class = ref $self;
  if ($self->isa(__PACKAGE__)) {
   $self->{started} = undef;
   return $self;
  }
 }

 bless {
  started => undef,
 }, $class;
}

=head2 C<started>

    $tvc->started($bool);

Specifies whether the component is running (C<1>), stopped (C<0>) or was never started (C<undef>).

=cut

sub started { @_ <= 1 ? $_[0]->{started} : ($_[0]->{started} = $_[1] ? 1 : 0) }

=head2 C<start>

    $tvc->start;

Marks the component as started, and throws an exception if it was already.
Returns its self object.

=cut

sub start {
 my ($self) = @_;

 $self->_croak(ref($self) . ' component already started') if $self->started;
 $self->started(1);

 $self;
}

=head2 C<finish>

    $tvc->finish;

Marks the component as stopped, and throws an exception if it wasn't started.
Returns its self object.

=cut

sub finish {
 my ($self) = @_;

 $self->_croak(ref($self) . ' component is not started') unless $self->started;
 $self->started(0);

 $self;
}

=head1 SEE ALSO

L<Test::Valgrind>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-valgrind at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Valgrind>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Valgrind::Component

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2011,2013,2015,2016 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Test::Valgrind::Component
