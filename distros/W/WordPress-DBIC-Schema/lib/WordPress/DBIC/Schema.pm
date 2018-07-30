use utf8;
package WordPress::DBIC::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2018-07-15 12:06:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DRt2wnm6VB6Nj529Ii7t8g

=head1 NAME

WordPress::DBIC::Schema - Database schema for WordPress

=head1 DESCRIPTION

This is a basic schema (and mostly a work in progress) for the
WordPress database, which can be used for migrations, data fetching
etc.

It comes with some relationships even if the DB doesn't implement them
with foreign keys.

=head1 SYNOPSIS

  my $schema = WordPress::DBIC::Schema->connect('wordpress');
  foreach my $id (@ARGV) {
      if (my $post = $schema->resultset('WpPost')->published
          ->find($id, {
                       prefetch => ['metas', { wp_term_relationships => { wp_term_taxonomy => 'wp_term' } }],
                      })) {
          foreach my $taxonomy ($post->taxonomies) {
              print $post->post_title . ' ' . $taxonomy->wp_term->name . "\n";
          }
          print $post->clean_url . "\n";
          print $post->permalink . "\n";
          foreach my $meta ($post->metas) {
              if ($meta->meta_key eq 'subtitle') {
                  print $meta->meta_value . "\n";
              }
          }
          print $post->html_body . "\n";
      }
  }


=cut


our $VERSION = '1.01';

__PACKAGE__->load_components(qw/Helper::Schema::QuoteNames
                                Schema::Config
                               /);

=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to the author's email or
just use the CPAN's RT.

=head1 LICENSE

This module is free software and is published under the same terms as
Perl itself.

=cut


1;
