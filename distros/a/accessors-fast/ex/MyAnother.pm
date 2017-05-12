package #
	MyAnother;
use base 'MyPackage';
use accessors::fast qw(field3);

# constructor is private, redefine only init;
sub init {
	my $self = shift;
	my %args = @_;
	$self->field3(delete $args{arg3}  || 'not defined');
	$self->next::method(%args);
}

1;

