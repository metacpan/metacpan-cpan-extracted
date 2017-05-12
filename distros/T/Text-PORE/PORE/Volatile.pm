#
# Volatile.pm
#
#  Implements a volatile object class, subclass of Object, so that 
#  free-form objects can be created on the fly

package Text::PORE::Volatile;

use Text::PORE::Object;

@Text::PORE::Volatile::ISA = qw(Text::PORE::Object);

sub new {
    my $type = shift;
    my %attrs = @_;

    my $self = {};

    bless $self, $type;

    $self->LoadAttributes(%attrs);

    $self;
}

1;
