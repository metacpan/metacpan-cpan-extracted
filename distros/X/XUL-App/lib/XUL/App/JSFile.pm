package XUL::App::JSFile;

use strict;
use warnings;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw{
    prereqs
});

sub new {
    my $proto = shift;
    my $self = $proto->SUPER::new(@_);
    my $list = $self->prereqs;
    if (!ref $list) { $self->prereqs([$list]) }
    return $self;
}

sub go {
    my ($self, $file) = @_;
}

1;
