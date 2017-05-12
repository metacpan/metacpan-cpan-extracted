use utf8;
package DB::Tutorial::DBIx::Class::PT::BR::Result::Filho;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

DB::Tutorial::DBIx::Class::PT::BR::Result::Filho

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<filho>

=cut

__PACKAGE__->table("filho");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'filho_id_seq'

=head2 nome

  data_type: 'text'
  is_nullable: 1

=head2 pai_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "filho_id_seq",
  },
  "nome",
  { data_type => "text", is_nullable => 1 },
  "pai_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 amigoes

Type: has_many

Related object: L<DB::Tutorial::DBIx::Class::PT::BR::Result::Amigo>

=cut

__PACKAGE__->has_many(
  "amigoes",
  "DB::Tutorial::DBIx::Class::PT::BR::Result::Amigo",
  { "foreign.amigo_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pai

Type: belongs_to

Related object: L<DB::Tutorial::DBIx::Class::PT::BR::Result::Pai>

=cut

__PACKAGE__->belongs_to(
  "pai",
  "DB::Tutorial::DBIx::Class::PT::BR::Result::Pai",
  { id => "pai_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-07-08 15:14:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aaQcKvggMUd5YmFttR/eYw

__PACKAGE__->has_many(
  "amigos",
  "DB::Tutorial::DBIx::Class::PT::BR::Result::Amigo",
  { "foreign.amigo_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
