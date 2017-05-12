use utf8;
package Schema::TPath::Result::File;

=head1 NAME

Schema::TPath::Result::File

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';


__PACKAGE__->load_components;

=head1 TABLE: C<files>

=cut

__PACKAGE__->table("files");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 file

  data_type: 'varchar'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "file",
  { data_type => "varchar", is_nullable => 1, size => undef },
  "page_id",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);


=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<file_unique>

=cut

__PACKAGE__->add_unique_constraint("file_unique", ["file"]);


=head1 UNIQUE CONSTRAINTS

=head2 C<name_parent_unique>

=cut

__PACKAGE__->meta->make_immutable;

1;
