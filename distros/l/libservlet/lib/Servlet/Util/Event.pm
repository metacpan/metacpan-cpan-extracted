# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Util::Event;

use fields qw(source);
use strict;
use warnings;

sub new {
    my $self = shift;
    my $source = shift;

    $self = fields::new($self) unless ref $self;

    $self->{source} = $source;

    return $self;
}

sub getSource {
    my $self = shift;

    return $self->{source};
}

1;
__END__

=pod

=head1 NAME

Servlet::Util::Event - event base class

=head1 SYNOPSIS

  my $event = Servlet::Util::Event->new($source);

  my $source = $event->getSource();

=head1 DESCRIPTION

This is a base class for the notification of a generic event.

=head1 CONSTRUCTOR

=over

=item new($source)

Construct an instance for the given event source.

B<Parameters:>

=over

=item I<$source>

the source of the event

=back

=back

=head1 METHODS

=over

=item getSource()

Returns the object that is the source of the event

=back

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
