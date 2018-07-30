use utf8;
package WordPress::DBIC::Schema::Result::WpTermRelationship;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

WordPress::DBIC::Schema::Result::WpTermRelationship

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

=head1 TABLE: C<wp_term_relationships>

=cut

__PACKAGE__->table("wp_term_relationships");

=head1 ACCESSORS

=head2 object_id

  data_type: 'bigint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 term_taxonomy_id

  data_type: 'bigint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 term_order

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "object_id",
  {
    data_type => "bigint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "term_taxonomy_id",
  {
    data_type => "bigint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "term_order",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</object_id>

=item * L</term_taxonomy_id>

=back

=cut

__PACKAGE__->set_primary_key("object_id", "term_taxonomy_id");


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2018-07-15 12:07:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:q7eDuejLxkqqkDkfFMlaWA

__PACKAGE__->belongs_to(wp_post => 'WordPress::DBIC::Schema::Result::WpPost::WpPost',
                        { 'foreign.id' => 'self.object_id' });

__PACKAGE__->belongs_to(wp_term_taxonomy => 'WordPress::DBIC::Schema::Result::WpTermTaxonomy',
                        'term_taxonomy_id');


1;
