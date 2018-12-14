package Pet;
use Sympatic;
with 'Flyable';

has qw( altitude is rw lvalue 1 default 0 );
has qw( name is rw );

1;

