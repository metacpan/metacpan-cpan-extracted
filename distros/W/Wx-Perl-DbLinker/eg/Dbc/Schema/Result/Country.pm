use utf8;
package Dbc::Schema::Result::Country;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Dbc::Schema::Result::Country

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<countries>

=cut

__PACKAGE__->table("countries");

=head1 ACCESSORS

=head2 countryid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 country

  data_type: 'text'
  is_nullable: 1

=head2 mainlangid

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "countryid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "country",
  { data_type => "text", is_nullable => 1 },
  "mainlangid",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</countryid>

=back

=cut

__PACKAGE__->set_primary_key("countryid");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-09-02 16:20:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mkbT8dfOnBHW8KRL+XRYSg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
