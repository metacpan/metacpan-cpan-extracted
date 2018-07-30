use utf8;
package WordPress::DBIC::Schema::Result::WpLink;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

WordPress::DBIC::Schema::Result::WpLink

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

=head1 TABLE: C<wp_links>

=cut

__PACKAGE__->table("wp_links");

=head1 ACCESSORS

=head2 link_id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 link_url

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 link_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 link_image

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 link_target

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 25

=head2 link_description

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 link_visible

  data_type: 'varchar'
  default_value: 'Y'
  is_nullable: 0
  size: 20

=head2 link_owner

  data_type: 'bigint'
  default_value: 1
  extra: {unsigned => 1}
  is_nullable: 0

=head2 link_rating

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 link_updated

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 link_rel

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 link_notes

  data_type: 'mediumtext'
  is_nullable: 0

=head2 link_rss

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "link_id",
  {
    data_type => "bigint",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "link_url",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "link_name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "link_image",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "link_target",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 25 },
  "link_description",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "link_visible",
  { data_type => "varchar", default_value => "Y", is_nullable => 0, size => 20 },
  "link_owner",
  {
    data_type => "bigint",
    default_value => 1,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "link_rating",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "link_updated",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "link_rel",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "link_notes",
  { data_type => "mediumtext", is_nullable => 0 },
  "link_rss",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</link_id>

=back

=cut

__PACKAGE__->set_primary_key("link_id");


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2018-07-15 12:07:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Htdp36KsjTIwaTLlvQrFQw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
