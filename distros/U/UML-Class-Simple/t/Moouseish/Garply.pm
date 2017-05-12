package Moouseish::Garply;
use Moose;
extends 'Moouseish::Bar';
with 'Moouseish::Zot';
with 'Moouseish::Quux';
__PACKAGE__->meta->make_immutable;
1;
__END__
