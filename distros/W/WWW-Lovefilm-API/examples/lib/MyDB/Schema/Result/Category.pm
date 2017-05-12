package MyDB::Schema::Result::Category;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('category');
__PACKAGE__->add_columns(qw/ term label scheme status /);
__PACKAGE__->add_columns(
    id      => { data_type => 'integer', size =>   6, is_nullable => 0, is_auto_increment => 1, default_value => '' },
    term    => { data_type => 'text',    size =>  64, is_nullable => 1, is_auto_increment => 0, default_value => '' },
    label   => { data_type => 'text',    size =>  64, is_nullable => 1, is_auto_increment => 0, default_value => '' },
    scheme  => { data_type => 'text',    size =>  64, is_nullable => 1, is_auto_increment => 0, default_value => '' },
    status  => { data_type => 'text',    size =>  64, is_nullable => 1, is_auto_increment => 0, default_value => '' },
);
__PACKAGE__->set_primary_key('id');

1;
