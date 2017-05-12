package TestClassAccessorPBP;

use base 'Class::Accessor';
__PACKAGE__->follow_best_practice();
__PACKAGE__->mk_accessors(qw(name role salary));

sub blah {
}

1;
