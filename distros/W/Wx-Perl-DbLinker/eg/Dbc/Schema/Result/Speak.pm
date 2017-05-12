use utf8;
package Dbc::Schema::Result::Speak;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Dbc::Schema::Result::Speak

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<speaks>

=cut

__PACKAGE__->table("speaks");

=head1 ACCESSORS

=head2 countryid

  data_type: 'integer'
  is_nullable: 0

=head2 langid

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "countryid",
  { data_type => "integer", is_nullable => 0 },
  "langid",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</countryid>

=item * L</langid>

=back

=cut

__PACKAGE__->set_primary_key("countryid", "langid");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-09-02 16:20:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MwTfMDXrvErCInH5LiZaug


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
