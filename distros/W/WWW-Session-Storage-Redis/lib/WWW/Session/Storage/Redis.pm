package WWW::Session::Storage::Redis;

use 5.006;
use strict;
use warnings;

use Carp qw(croak);

my $HAS_CACHE_REDIS = eval { require Cache::Redis; 1 } ? 1 : 0;

# Cache::Redis cannot store a key without an expiration time (an undef
# TTL falls back to its default_expires_in, 30 days), so "never expire"
# is approximated with a ten-year TTL.
use constant NEVER_EXPIRES_TTL => 60 * 60 * 24 * 365 * 10;

=head1 NAME

WWW::Session::Storage::Redis - Redis storage for WWW::Session

=head1 DESCRIPTION

Redis backend for WWW::Session

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

This module is used for storing serialized WWW::Session objects in redis

Usage :

    use WWW::Session::Storage::Redis;

    my $storage = WWW::Session::Storage::Redis->new({ server => "127.0.0.1:6379" });
    ...

    $storage->save($session_id,$expires,$serialized_data);

    my $serialized_data = $storage->retrieve($session_id);

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new WWW::Session::Storage::Redis object

This method accepts only one argument, a hashref that contains all the options
that will be passed to the Cache::Redis module. The mandatory key in the hash
is "server" which must be a scalar containing the C<redis> server we want to
use.

See Cache::Redis module for more details on available options

Croaks if the Cache::Redis module is not installed or if the "server"
option is missing.

Example :

    my $storage = WWW::Session::Storage::Redis->new({ server => "127.0.0.1:6379" });

=cut
sub new {
    my $class = shift;
    my $params = shift;

    croak "You must install the Cache::Redis module from CPAN to use the redis storage engine!"
        unless $HAS_CACHE_REDIS;

    croak 'WWW::Session::Storage::Redis->new() requires a hashref of options containing a "server" key'
        unless ref($params) eq 'HASH' && defined $params->{server};

    my $self = { options => $params,
                 redis => Cache::Redis->new(%$params),
                };

    bless $self, $class;

    return $self;
}

=head2 save

Stores the session data in redis for the given number of seconds.

An expiration time of -1 means the session should never expire. Redis
(through Cache::Redis) always stores keys with a TTL, so such sessions
are stored with a ten-year TTL instead.

=cut
sub save {
    my ($self,$sid,$expires,$string) = @_;

    return $self->{redis}->set($sid,$string,$expires == -1 ? NEVER_EXPIRES_TTL : $expires );
}

=head2 retrieve

Retrieves the session data for the given session id and returns the
string containing the serialized data. Returns undef if the session
does not exist or has expired (expiration is handled by redis itself).

=cut
sub retrieve {
    my ($self,$sid) = @_;

    return $self->{redis}->get($sid);
}

=head2 delete

Completely removes the session data for the given session id and
returns the result of the removal.

=cut
sub delete {
    my ($self,$sid) = @_;

    return $self->{redis}->remove($sid);
}

=head1 AUTHORS

Jeffrey Goff, C<< <jeffrey.goff at evozon.com> >>

Horea Gligan, C<< <horea.gligan at devnest.ro> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-session-storage-redis at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Session-Storage-Redis>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Session::Storage::Redis


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Session-Storage-Redis>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Session-Storage-Redis>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Session-Storage-Redis>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Session-Storage-Redis/>

=back


=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the terms of:

  The GNU General Public License, Version 3, June 2007

See L<http://www.gnu.org/licenses/gpl-3.0.html> for the full license text.


=cut

1; # End of WWW::Session::Storage::Redis
