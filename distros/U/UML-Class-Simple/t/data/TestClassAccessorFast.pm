package TestClassAccessorFast;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(name role salary));

sub blah {
}

1;
