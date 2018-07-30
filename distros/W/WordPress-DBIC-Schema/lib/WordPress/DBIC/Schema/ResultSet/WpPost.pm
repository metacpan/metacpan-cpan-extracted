package WordPress::DBIC::Schema::ResultSet::WpPost;

=head1 NAME

WordPress::DBIC::Schema::ResultSet::WpPost - Posts resultset

=cut


use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head1 METHODS

=head2 published

Only the published posts.

=cut

sub published {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.post_status" => 'publish' });
}

1;
