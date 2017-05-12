package TestWDAO;
use WebDAO::Element;
use base 'WebDAO::Element';
__PACKAGE__->mk_attr( _prop1=>1, _prop2=>3, _prop3=>undef, _prop4=>'undef', __test1=>undef, _test2=>undef);


sub init {
    my $self = shift;
}
sub Echo {
    my $self = shift;
    return shift||111
}

1;
