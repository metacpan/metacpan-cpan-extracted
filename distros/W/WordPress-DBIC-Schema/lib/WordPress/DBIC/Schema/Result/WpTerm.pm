use utf8;
package WordPress::DBIC::Schema::Result::WpTerm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

WordPress::DBIC::Schema::Result::WpTerm

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

=head1 TABLE: C<wp_terms>

=cut

__PACKAGE__->table("wp_terms");

=head1 ACCESSORS

=head2 term_id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 200

=head2 slug

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 200

=head2 term_group

  data_type: 'bigint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "term_id",
  {
    data_type => "bigint",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 200 },
  "slug",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 200 },
  "term_group",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</term_id>

=back

=cut

__PACKAGE__->set_primary_key("term_id");


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2018-07-15 12:07:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:meW85vK2T7qLX6M+czocGQ

__PACKAGE__->has_many(wp_term_taxonomies => 'WordPress::DBIC::Schema::Result::WpTermTaxonomy', 'term_id');

1;
