use utf8;
package WordPress::DBIC::Schema::Result::WpPost;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

WordPress::DBIC::Schema::Result::WpPost

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<wp_posts>

=cut

__PACKAGE__->table("wp_posts");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 post_author

  data_type: 'bigint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 post_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 post_date_gmt

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 post_content

  data_type: 'longtext'
  is_nullable: 0

=head2 post_title

  data_type: 'text'
  is_nullable: 0

=head2 post_excerpt

  data_type: 'text'
  is_nullable: 0

=head2 post_status

  data_type: 'varchar'
  default_value: 'publish'
  is_nullable: 0
  size: 20

=head2 comment_status

  data_type: 'varchar'
  default_value: 'open'
  is_nullable: 0
  size: 20

=head2 ping_status

  data_type: 'varchar'
  default_value: 'open'
  is_nullable: 0
  size: 20

=head2 post_password

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 post_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 200

=head2 to_ping

  data_type: 'text'
  is_nullable: 0

=head2 pinged

  data_type: 'text'
  is_nullable: 0

=head2 post_modified

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 post_modified_gmt

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 post_content_filtered

  data_type: 'longtext'
  is_nullable: 0

=head2 post_parent

  data_type: 'bigint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 guid

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 menu_order

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 post_type

  data_type: 'varchar'
  default_value: 'post'
  is_nullable: 0
  size: 20

=head2 post_mime_type

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 100

=head2 comment_count

  data_type: 'bigint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "bigint",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "post_author",
  {
    data_type => "bigint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "post_date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "post_date_gmt",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "post_content",
  { data_type => "longtext", is_nullable => 0 },
  "post_title",
  { data_type => "text", is_nullable => 0 },
  "post_excerpt",
  { data_type => "text", is_nullable => 0 },
  "post_status",
  {
    data_type => "varchar",
    default_value => "publish",
    is_nullable => 0,
    size => 20,
  },
  "comment_status",
  {
    data_type => "varchar",
    default_value => "open",
    is_nullable => 0,
    size => 20,
  },
  "ping_status",
  {
    data_type => "varchar",
    default_value => "open",
    is_nullable => 0,
    size => 20,
  },
  "post_password",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "post_name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 200 },
  "to_ping",
  { data_type => "text", is_nullable => 0 },
  "pinged",
  { data_type => "text", is_nullable => 0 },
  "post_modified",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "post_modified_gmt",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "post_content_filtered",
  { data_type => "longtext", is_nullable => 0 },
  "post_parent",
  {
    data_type => "bigint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "guid",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "menu_order",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "post_type",
  {
    data_type => "varchar",
    default_value => "post",
    is_nullable => 0,
    size => 20,
  },
  "post_mime_type",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 100 },
  "comment_count",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2018-07-15 12:07:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nMn+6ADXb+wDaW22xfgTWA

__PACKAGE__->load_components(qw/Tree::AdjacencyList/);

__PACKAGE__->parent_column('post_parent');

__PACKAGE__->has_many(wp_term_relationships => 'WordPress::DBIC::Schema::Result::WpTermRelationship',
                      { 'foreign.object_id' => 'self.id'});

__PACKAGE__->many_to_many(taxonomies => wp_term_relationships => 'wp_term_taxonomy');

__PACKAGE__->has_many(metas => 'WordPress::DBIC::Schema::Result::WpPostmeta',
                      { 'foreign.post_id' => 'self.id' });

use URI;

=head1 RELATIONSHIPS

=head2 wp_term_relationships: has many

=head2 taxonomies: many to many using wp_term_relationships as bridge

=head2 metas: has many to the wp_postmeta table

=head1 METHODS

They should be self-explanatory

=over 4

=item * clean_url

=item * permalink

=item * html_teaser

=item * html_body

=back

=cut

sub clean_url {
    my $self = shift;
    return '/' . join('/', reverse map { $_->post_name } ($self, $self->ancestors));    
}

sub permalink {
    my $self = shift;
    return URI->new($self->guid)->path_query;
}

sub html_teaser {
    my $self = shift;
    if ($self->html_body =~ m{(.*?)<!--\s*more\s*-->}si) {
        return $1;
    }
    else {
        return '';
    }
}

sub html_body {
    my $self = shift;
    my $body = $self->post_content;
    $body =~ s/(\r?\n)+/<p \/>\n/g;
    return $body;
}

1;
