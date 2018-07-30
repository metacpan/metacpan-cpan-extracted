use utf8;
package WordPress::DBIC::Schema::Result::WpUsermeta;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

WordPress::DBIC::Schema::Result::WpUsermeta

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

=head1 TABLE: C<wp_usermeta>

=cut

__PACKAGE__->table("wp_usermeta");

=head1 ACCESSORS

=head2 umeta_id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 user_id

  data_type: 'bigint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 meta_key

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 meta_value

  data_type: 'longtext'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "umeta_id",
  {
    data_type => "bigint",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "user_id",
  {
    data_type => "bigint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "meta_key",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "meta_value",
  { data_type => "longtext", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</umeta_id>

=back

=cut

__PACKAGE__->set_primary_key("umeta_id");


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2018-07-15 12:07:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4n+ty8kMKwkFb0phsxuAEQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
