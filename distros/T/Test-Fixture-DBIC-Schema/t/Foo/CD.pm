package t::Foo::CD;
use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('cd');
__PACKAGE__->add_columns(qw/ cdid artist title year /);
__PACKAGE__->set_primary_key('cdid');
__PACKAGE__->belongs_to(artist => 't::Foo::Artist');

1;

