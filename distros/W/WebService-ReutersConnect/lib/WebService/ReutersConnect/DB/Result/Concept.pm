package WebService::ReutersConnect::DB::Result::Concept;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

WebService::ReutersConnect::DB::Result::Concept

=cut

__PACKAGE__->table("concept");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 name_main

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 definition

  data_type: 'text'
  is_nullable: 1

=head2 name_mnemonic

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 broader_id

  data_type: 'varchar'
  default_value: NULL
  is_foreign_key: 1
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "name_main",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "definition",
  { data_type => "text", is_nullable => 1 },
  "name_mnemonic",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "broader_id",
  {
    data_type => "varchar",
    default_value => \"NULL",
    is_foreign_key => 1,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 broader

Type: belongs_to

Related object: L<WebService::ReutersConnect::DB::Result::Concept>

=cut

__PACKAGE__->belongs_to(
  "broader",
  "WebService::ReutersConnect::DB::Result::Concept",
  { id => "broader_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 concepts

Type: has_many

Related object: L<WebService::ReutersConnect::DB::Result::Concept>

=cut

__PACKAGE__->has_many(
  "concepts",
  "WebService::ReutersConnect::DB::Result::Concept",
  { "foreign.broader_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 concept_aliases

Type: has_many

Related object: L<WebService::ReutersConnect::DB::Result::ConceptAlias>

=cut

__PACKAGE__->has_many(
  "concept_aliases",
  "WebService::ReutersConnect::DB::Result::ConceptAlias",
  { "foreign.concept_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-12-16 15:00:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dTKIjiTboCCjUZdndT32+Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head2 broader_chain

Returns the chain of broader concepts ( including this one ). Therefore it's never empty.
The most general is first, the most specific is last ( this one )

Usage:

  my @concepts = $this->broader_chain();
  print join(' > ', map{ $_->name_main() } @concepts );

=cut

sub broader_chain{
  my ($self) = @_;

  my $current = $self;
  my @ret = ( $current );
  while( my $broader = $current->broader() ){
    push @ret , $broader;
    $current = $broader;
  }
  return reverse @ret;
}

1;
