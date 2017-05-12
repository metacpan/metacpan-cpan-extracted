package WWW::Webrobot::Print::Null;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG


=head1 NAME

WWW::Webrobot::Print::Null - Zero response output listener

=head1 DESCRIPTION

This module does nothing.
It is the default output listener.

=head1 METHODS

See L<WWW::Webrobot::pod::OutputListeners>.

=cut

sub new {
    my $class = shift;
    my $self = bless({}, ref($class) || $class);
    return $self;
}

sub global_start {}
sub item_pre {}
sub item_post {}
sub global_end {}

1;
