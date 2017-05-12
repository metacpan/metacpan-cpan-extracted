use utf8;
package Dbc::Schema::Result::Langue;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Dbc::Schema::Result::Langue

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<langues>

=cut

__PACKAGE__->table("langues");

=head1 ACCESSORS

=head2 langid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 langue

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "langid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "langue",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</langid>

=back

=cut

__PACKAGE__->set_primary_key("langid");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-09-02 16:20:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8pO0r+Fl/xKtsDdleh12bg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
