package t::Foo::Artist;
use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('artist');
__PACKAGE__->add_columns(qw/ artistid name /);
__PACKAGE__->set_primary_key('artistid');
__PACKAGE__->has_many(cds => 't::Foo::CD');

1;
