package WWW::UsePerl::Server::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

WWW::UsePerl::Server::Schema::Result::User

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 uid

  data_type: 'mediumint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 nickname

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 20

=head2 journal_last_entry_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "uid",
  {
    data_type => "mediumint",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "nickname",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 20 },
  "journal_last_entry_date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("uid");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-04-29 14:56:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WraI0ZDE9oEzYJjTMm5Tlw

__PACKAGE__->has_many('journals',
    'WWW::UsePerl::Server::Schema::Result::Journal', 'uid');

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
