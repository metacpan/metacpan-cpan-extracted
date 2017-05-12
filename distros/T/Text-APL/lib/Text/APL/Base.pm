package Text::APL::Base;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = bless {@_}, $class;

    $self->_BUILD;

    return $self;
}

sub _BUILD {}

1;
__END__

=pod

=head1 NAME

Text::APL::Base - base class

=head1 DESCRIPTION

All L<Text::APL> classes inherit from this one. Provides default C<new>
constructor and C<_BUILD> method (used for initialization and object
validation).

=head1 METHODS

=head2 C<new>

Create new L<Text::APL::Base> instance.

=cut
