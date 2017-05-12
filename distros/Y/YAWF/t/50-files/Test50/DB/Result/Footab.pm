package Test50::DB::Result::Footab;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Test50::DB::Result::Footab

=cut

__PACKAGE__->table("footab");

=head1 ACCESSORS

=head2 id

  data_type: INTEGER
  default_value: undef
  is_nullable: 0
  size: undef

=head2 bartext

  data_type: VARCHAR
  default_value: undef
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "bartext",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.05001 @ 2010-03-17 12:00:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Knl5kgwJ3WZibJwASsyKmw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
