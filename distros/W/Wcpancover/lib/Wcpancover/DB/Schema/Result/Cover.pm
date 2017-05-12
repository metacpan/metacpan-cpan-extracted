package Wcpancover::DB::Schema::Result::Cover;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('covers');

__PACKAGE__->add_columns(
  'name',
  {data_type => 'varchar', default_value => '', is_nullable => 0, size => 255},
  'author',
  {data_type => 'varchar', default_value => '', is_nullable => 0, size => 255},
  'coverage',
  {data_type => 'varchar', default_value => '0', is_nullable => 0, size => 25},
  'dist',
  {data_type => 'varchar', default_value => '', is_nullable => 0, size => 255},
  'version',
  {data_type => 'varchar', default_value => '', is_nullable => 0, size => 25},
);

__PACKAGE__->set_primary_key('name');

__PACKAGE__->add_unique_constraint("name_UNIQUE", ['name']);

1;
