package Issue55::MooseAroundChildOrig;
use Moose;
extends 'Issue55::MooseAroundParent';
around foo => sub {
    my ($orig, $self, @args) = @_;
    return 'wrapped(' . $orig->($self, @args) . ')';
};
1;
