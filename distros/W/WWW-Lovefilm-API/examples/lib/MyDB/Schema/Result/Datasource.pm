package MyDB::Schema::Result::Datasource;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('datasource');
__PACKAGE__->add_columns(
    id                     => { data_type => 'integer', size =>   6, is_nullable => 0, is_auto_increment => 1, default_value => '' },  # 1
    name                   => { data_type => 'text',    size => 128, is_nullable => 1, is_auto_increment => 0, default_value => '' },  # Lovefilm
    href                   => { data_type => 'text',    size => 128, is_nullable => 1, is_auto_increment => 0, default_value => '' }   # http://www.lovefilm.com
);

__PACKAGE__->set_primary_key('id');

1;
