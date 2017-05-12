package WWW::UsePerl::Server::Schema::Result::Story;

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

WWW::UsePerl::Server::Schema::Result::Story

=cut

__PACKAGE__->table("stories");

=head1 ACCESSORS

=head2 stoid

  data_type: 'mediumint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 sid

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 16

=head2 uid

  data_type: 'mediumint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 time

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 submitter

  data_type: 'mediumint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 title

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 100

=head2 introtext

  data_type: 'text'
  is_nullable: 1

=head2 bodytext

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "stoid",
  {
    data_type => "mediumint",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "sid",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 16 },
  "uid",
  {
    data_type => "mediumint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "time",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "submitter",
  {
    data_type => "mediumint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "title",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 100 },
  "introtext",
  { data_type => "text", is_nullable => 1 },
  "bodytext",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("stoid");
__PACKAGE__->add_unique_constraint("sid", ["sid"]);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-04-29 14:56:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UVoSCsgnI8oTXIwX7y7jqA

__PACKAGE__->belongs_to('user', 'WWW::UsePerl::Server::Schema::Result::User', 'uid');

sub introtext_html {
    my $self = shift;
    my $article = $self->introtext;
    $article =~ s{\r?\n\r?\n}{<br/><br/>}g unless $article =~ /<p>/;
    $article =~ s{<ecode>}{<pre>}g;
    $article =~ s{</ecode>}{</pre>}g;
    return $article;
}

sub bodytext_html {
    my $self = shift;
    my $article = $self->bodytext;
    $article =~ s{\r?\n\r?\n}{<br/><br/>}g unless $article =~ /<p>/;
    $article =~ s{<ecode>}{<pre>}g;
    $article =~ s{</ecode>}{</pre>}g;
    return $article;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
