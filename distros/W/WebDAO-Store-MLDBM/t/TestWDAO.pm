package TestWDAO;
use WebDAO::Element;
use base 'WebDAO::Element';
__PACKAGE__->attributes(qw/ __test1 _test2/);
__PACKAGE__->sess_attributes(qw/ _sess1 _sess2/);

sub init {
    my $self = shift;
    _sess2 $self (3)
}
sub echo {
    my $self = shift;
    return shift
}

1;
