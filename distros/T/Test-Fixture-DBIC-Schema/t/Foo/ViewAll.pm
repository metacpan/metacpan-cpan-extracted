package t::Foo::ViewAll;
use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table('view_all');
__PACKAGE__->add_columns(qw/ cdid artist_id artist_name title year /);
__PACKAGE__->set_primary_key('cdid');
__PACKAGE__->result_source_instance->is_virtual(0);
__PACKAGE__->result_source_instance->view_definition
    (
     "select cd.cdid, cd.title, cd.year, a.artistid as artist_id, a.name as artist_name from cd, artist a where cd.artist=a.artistid"
    );

1;

