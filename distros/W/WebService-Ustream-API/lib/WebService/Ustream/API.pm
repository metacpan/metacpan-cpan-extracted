package WebService::Ustream::API;

use strict;
use warnings;
use version; our $VERSION = '0.03';

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(key ua));

use Carp;
use WebService::Ustream::API::User;
use WebService::Ustream::API::Stream;

sub user {
	my $self = shift;

	$self->{_user} ||= WebService::Ustream::API::User->new($self);
	return $self->{_user};
}

sub stream {
	my $self = shift;
	
	$self->{_stream} ||= WebService::Ustream::API::Stream->new($self);
	return $self->{_stream};
}

1;

__END__

=head1 NAME

WebService::Ustream::API - Perl interface to Ustream API Service

=head1 SYNOPSIS

  use WebService::Ustream::API;
  
  my $ust = WebService::Ustream::API->new( { key => YOUR_KEY } );

  # Get user information via Ustream API
  my $ret = $ust->user->info('koba206');
 
  # Get all the channels belonging to a user
  my $ret = $ust->user->list_channels('koba206');

  # Get all the videos belonging to a user
  my $ret = $ust->user->list_videos('spacevidcast');

  # Get all the comments for the user profile belonging to a user
  my $ret = $ust->user->comments('koba206'); 

  # Get information about most recent show that started broadcasting
  my $ret = $ust->stream->recent();

  # Get information about currently running show having the most viewers
  my $ret = $ust->stream->most_viewers();

  # Get information about currently on-air show that is picked randomly from all on-air broadcasts
  my $ret = $ust->stream->random();

  # Get all live shows that were created less than 1 hour old
  my $ret = $ust->stream->all_new();

=head1 DESCRIPTION

This is a Perl interface to Ustream API.
See Developer Page L<http://developer.ustream.tv/> for details.

=head1 SEE ALSO

L<URI::Fetch>
http://developer.ustream.tv/apps/register

L<URL::Fetch>
http://developer.ustream.tv/docs

=head1 AUTHOR

Takeshi Kobayashi, E<lt>tkobayashi@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Takeshi Kobayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
