package WebService::LastFM::Session;

use strict;
use warnings;

use base qw(Class::Accessor);

our $VERSION = '0.07';

__PACKAGE__->mk_accessors(
    qw( session )
);

sub new {
    my ( $class, $args ) = @_;
    bless $args, $class;
}

1;

__END__

=head1 NAME

WebService::LastFM::Session - Session class of WebService::LastFM

=head1 SYNOPSIS

  use WebService::LastFM;

  my $lastfm = WebService::LastFM->new(
        username => $config{username},
        password => $config{password},
  );
  my $stream_info = $lastfm->get_session  || die "Can't get Session\n";
  my $session_key = $stream_info->session;

=head1 DESCRIPTION

WebService::LastFM::Session is the class for WebService::LastFM sessions.

=head1 CAVEAT

This is NOT A BACKWARDS COMPATIBLE update. LastFM has changed their
API enough to warrant an interface change. The stream_url() accessor
has been removed, since it is no longer accessable.

=head1 METHODS

=over 4

=item session()

  $stream_info = $lastfm->get_session;
  $session_key = $stream_info->session();

Returns the session key for the current session object.


=back

=head1 SEE ALSO

=over 4

=item * Last.FM

L<http://www.last.fm/>

=item * Last.FM Stream API documentation

L<http://www.audioscrobbler.com/development/lastfm-ws.php>

=item * L<LWP::UserAgent>

=back

=head1 AUTHOR

Christian Brink, E<lt>grep_pdx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 - 2009 by Christian Brink
Copyright (C) 2005 - 2008 by Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
