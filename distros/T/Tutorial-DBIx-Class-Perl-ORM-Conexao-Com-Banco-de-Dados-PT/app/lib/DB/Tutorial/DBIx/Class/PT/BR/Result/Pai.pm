use utf8;
package DB::Tutorial::DBIx::Class::PT::BR::Result::Pai;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

DB::Tutorial::DBIx::Class::PT::BR::Result::Pai

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<pai>

=cut

__PACKAGE__->table("pai");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'pai_id_seq'

=head2 nome

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "pai_id_seq",
  },
  "nome",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 filhoes

Type: has_many

Related object: L<DB::Tutorial::DBIx::Class::PT::BR::Result::Filho>

=cut

__PACKAGE__->has_many(
  "filhoes",
  "DB::Tutorial::DBIx::Class::PT::BR::Result::Filho",
  { "foreign.pai_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-07-08 15:13:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:B4I5N4/abdMhSMNWiYJFJQ

__PACKAGE__->has_many(
  "filhos",
  "DB::Tutorial::DBIx::Class::PT::BR::Result::Filho",
  { "foreign.pai_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
