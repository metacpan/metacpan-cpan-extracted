package #
	MyPackage;
use accessors::fast qw(field1 field2);

# constructor is private, redefine only init;
sub init {
	my $self = shift;
	my %args = @_;
	$self->field1($args{arg1});
	$self->field2($args{arg2} || 'not defined');
}

1;

