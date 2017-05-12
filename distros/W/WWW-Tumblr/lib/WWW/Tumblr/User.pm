package WWW::Tumblr::User;

use Moose;
use strict;
use warnings;

use WWW::Tumblr::API;

extends 'WWW::Tumblr';

tumblr_api_method $_, [ 'GET',  'oauth' ] for qw( info dashboard likes following );
tumblr_api_method $_, [ 'POST', 'oauth' ] for qw( follow unfollow like unlike );

sub user { Carp::croak "Unimplemented" }


1;

=pod

=head1 NAME

WWW::Tumblr::User

=head1 SYNOPSIS

  my $user = $tumblr->user;
  
  # as per http://www.tumblr.com/docs/en/api/v2#user-methods
  my $dashboard = $user->dashboard;
  my $likes = $user->likes(
      limit => 1,
  );

  die "booyah!" unless $dashboard or $likes;

=head1 BUGS

Please refer to L<WWW::Tumblr>.

=head1 AUTHOR(S)

The same folks as L<WWW::Tumblr>.

=head1 SEE ALSO

L<WWW::Tumblr>, L<WWW::Tumblr::ResponseError>.

=head1 COPYRIGHT and LICENSE

Same as L<WWW::Tumblr>.

=cut

