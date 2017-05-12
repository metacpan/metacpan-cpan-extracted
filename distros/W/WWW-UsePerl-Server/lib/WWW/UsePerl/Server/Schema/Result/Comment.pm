package WWW::UsePerl::Server::Schema::Result::Comment;

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

WWW::UsePerl::Server::Schema::Result::Comment

=cut

__PACKAGE__->table("comments");

=head1 ACCESSORS

=head2 sid

  data_type: 'mediumint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 cid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 pid

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 subject

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 50

=head2 uid

  data_type: 'mediumint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 comment

  data_type: 'text'
  is_nullable: 0

=head2 journal_id

  data_type: 'mediumint'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 stoid

  data_type: 'mediumint'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 sequence

  accessor: 'column_sequence'
  data_type: 'mediumint'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 level

  data_type: 'mediumint'
  extra: {unsigned => 1}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sid",
  {
    data_type => "mediumint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "cid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "pid",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "subject",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 50 },
  "uid",
  {
    data_type => "mediumint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "comment",
  { data_type => "text", is_nullable => 0 },
  "journal_id",
  { data_type => "mediumint", extra => { unsigned => 1 }, is_nullable => 1 },
  "stoid",
  { data_type => "mediumint", extra => { unsigned => 1 }, is_nullable => 1 },
  "sequence",
  {
    accessor    => "column_sequence",
    data_type   => "mediumint",
    extra       => { unsigned => 1 },
    is_nullable => 1,
  },
  "level",
  { data_type => "mediumint", extra => { unsigned => 1 }, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("cid");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-04-29 15:09:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:P7tuoNvK4Fns8kQCrTrZXA

__PACKAGE__->belongs_to('user', 'WWW::UsePerl::Server::Schema::Result::User', 'uid');

sub comment_html {
    my $self = shift;
    my $comment = $self->comment;
    $comment =~ s{\r?\n\r?\n}{<br/><br/>}g unless $comment =~ /<p>/;
    $comment =~ s{<ecode>}{<pre>}g;
    $comment =~ s{</ecode>}{</pre>}g;
    return $comment;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
