package Moouseish::Baz;
use Moose;
with 'Moouseish::Foo';
__PACKAGE__->meta->make_immutable;
1;
__END__
