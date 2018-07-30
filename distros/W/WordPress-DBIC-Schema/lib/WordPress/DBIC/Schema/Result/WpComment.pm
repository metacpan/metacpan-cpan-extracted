use utf8;
package WordPress::DBIC::Schema::Result::WpComment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

WordPress::DBIC::Schema::Result::WpComment

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

=head1 TABLE: C<wp_comments>

=cut

__PACKAGE__->table("wp_comments");

=head1 ACCESSORS

=head2 comment_id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 comment_post_id

  data_type: 'bigint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 comment_author

  data_type: 'tinytext'
  is_nullable: 0

=head2 comment_author_email

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 100

=head2 comment_author_url

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 200

=head2 comment_author_ip

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 100

=head2 comment_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 comment_date_gmt

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 comment_content

  data_type: 'text'
  is_nullable: 0

=head2 comment_karma

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 comment_approved

  data_type: 'varchar'
  default_value: 1
  is_nullable: 0
  size: 20

=head2 comment_agent

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 comment_type

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 20

=head2 comment_parent

  data_type: 'bigint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 user_id

  data_type: 'bigint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "comment_id",
  {
    data_type => "bigint",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "comment_post_id",
  {
    data_type => "bigint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "comment_author",
  { data_type => "tinytext", is_nullable => 0 },
  "comment_author_email",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 100 },
  "comment_author_url",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 200 },
  "comment_author_ip",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 100 },
  "comment_date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "comment_date_gmt",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "comment_content",
  { data_type => "text", is_nullable => 0 },
  "comment_karma",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "comment_approved",
  { data_type => "varchar", default_value => 1, is_nullable => 0, size => 20 },
  "comment_agent",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "comment_type",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 20 },
  "comment_parent",
  {
    data_type => "bigint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "user_id",
  {
    data_type => "bigint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</comment_id>

=back

=cut

__PACKAGE__->set_primary_key("comment_id");


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2018-07-15 12:07:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:J+mTZcA6prFjLEKoeVLQrg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
