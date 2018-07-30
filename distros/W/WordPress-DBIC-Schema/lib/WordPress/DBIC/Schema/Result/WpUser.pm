use utf8;
package WordPress::DBIC::Schema::Result::WpUser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

WordPress::DBIC::Schema::Result::WpUser

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<wp_users>

=cut

__PACKAGE__->table("wp_users");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 user_login

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 60

=head2 user_pass

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 user_nicename

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 50

=head2 user_email

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 100

=head2 user_url

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 100

=head2 user_registered

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 user_activation_key

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 user_status

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 display_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 250

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "bigint",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "user_login",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 60 },
  "user_pass",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "user_nicename",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 50 },
  "user_email",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 100 },
  "user_url",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 100 },
  "user_registered",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "user_activation_key",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "user_status",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "display_name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 250 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2018-07-15 12:07:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WmcoXPkvVmSV2hX/ktqaJg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
