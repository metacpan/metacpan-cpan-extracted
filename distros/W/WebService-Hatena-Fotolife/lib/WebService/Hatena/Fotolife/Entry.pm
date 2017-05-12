package WebService::Hatena::Fotolife::Entry;
use strict;
use warnings;
use base qw(XML::Atom::Entry);

__PACKAGE__->mk_elem_accessors(qw(generator));

1;
