package Test::Smoke::ObjectBase;
use warnings;
use strict;
use Carp qw/ confess /;

our $VERSION = '0.001';

=head1 NAME

Test::Smoke:ObjectBase - Base class for objects (AUTOLOADed accessors)

=head1 DESCRIPTION

This base class provides accessors via AUTOLOAD for hashkeys that start with
an underscore.

    $self->{_name} gives $self->name()

The accessors are 'getters' as well as 'setters'.

=cut

sub AUTOLOAD {
    my $self = shift;

    (my $attrib = our $AUTOLOAD) =~ s/.*:://;
    if (exists $self->{"_$attrib"}) {
        $self->{"_$attrib"} = shift if @_;
        return $self->{"_$attrib"};
    }
    confess(
        sprintf(
            "Invalid attribute '%s' for class '%s'",
            $attrib,
            ref($self)
        )
    );
}

sub DESTROY { 1 } # the 1 is for coverage

1;
