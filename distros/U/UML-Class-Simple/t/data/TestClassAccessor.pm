package TestClassAccessor;

use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(name role salary));

sub blah {
}

1;
