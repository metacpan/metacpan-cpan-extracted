package WebService::ReutersConnect::DB::Result::ConceptAlias;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

WebService::ReutersConnect::DB::Result::ConceptAlias

=cut

__PACKAGE__->table("concept_alias");

=head1 ACCESSORS

=head2 alias_id

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 concept_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "alias_id",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "concept_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("alias_id");

=head1 RELATIONS

=head2 concept

Type: belongs_to

Related object: L<WebService::ReutersConnect::DB::Result::Concept>

=cut

__PACKAGE__->belongs_to(
  "concept",
  "WebService::ReutersConnect::DB::Result::Concept",
  { id => "concept_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-12-19 14:31:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ln/Pwp7rqLmpJ0oiZiM/rA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
