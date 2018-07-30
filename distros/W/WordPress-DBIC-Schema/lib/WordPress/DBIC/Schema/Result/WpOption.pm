use utf8;
package WordPress::DBIC::Schema::Result::WpOption;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

WordPress::DBIC::Schema::Result::WpOption

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

=head1 TABLE: C<wp_options>

=cut

__PACKAGE__->table("wp_options");

=head1 ACCESSORS

=head2 option_id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 option_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 191

=head2 option_value

  data_type: 'longtext'
  is_nullable: 0

=head2 autoload

  data_type: 'varchar'
  default_value: 'yes'
  is_nullable: 0
  size: 20

=cut

__PACKAGE__->add_columns(
  "option_id",
  {
    data_type => "bigint",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "option_name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 191 },
  "option_value",
  { data_type => "longtext", is_nullable => 0 },
  "autoload",
  {
    data_type => "varchar",
    default_value => "yes",
    is_nullable => 0,
    size => 20,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</option_id>

=back

=cut

__PACKAGE__->set_primary_key("option_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<option_name>

=over 4

=item * L</option_name>

=back

=cut

__PACKAGE__->add_unique_constraint("option_name", ["option_name"]);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2018-07-15 12:07:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:f9c2fDagiUSmtBMe/yurhA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
