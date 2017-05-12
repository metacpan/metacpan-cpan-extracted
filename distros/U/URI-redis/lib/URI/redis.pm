package URI::redis;
 
use strict;
use warnings;

our $VERSION = '0.02';

use base qw( URI::_login );

sub host {
    my $self = shift;

    return $self->SUPER::host(@_) || 'localhost';
}

sub default_port { 6379 }

sub socket_path { undef }

sub database {
    my $self = shift;

    return $self->database_from_path || $self->database_from_query || 0;
}

sub database_from_path {
    my $self = shift;

    my ($database) = $self->path =~ m{ ^ / (\d+) $ }x;

    return $database;
}
 
sub database_from_query {
    my $self = shift;

    return { $self->query_form }->{db};
}
 
sub password {
    my $self = shift;

    return $self->password_from_userinfo || $self->password_from_query;
}
 
sub password_from_userinfo {
    my $self = shift;

    my $userinfo = $self->userinfo
        or return;

    my ($password) = $userinfo =~ m{ ^ .* : ([^@]+) }x;

    return $password;
}
 
sub password_from_query {
    my $self = shift;

    return { $self->query_form }->{password};
}

1;

__END__

=head1 NAME

URI::redis - URI for Redis connection info

=head1 SYNOPSIS

 use URI::redis;
 
 $url = URI->new('redis://redis.example.com?password=correcthorsebatterystaple');

 $url = URI->new('redis://redis.example.com?db=5&password=correcthorsebatterystaple');

 $url = URI->new('redis+unix:///tmp/redis.sock?db=5&password=correcthorsebatterystaple');
 
=head1 DESCRIPTION

The C<URI::redis> class supports C<URI> objects belonging to the I<redis> and
I<redis+unix> URI scheme.

Such URLs are used to encode connection info (C<redis>: host, port, password,
database, C<redis+unix>: socket path, password, database) to Redis servers.


Supported URLs are in any of these formats:

=over

=item C<< redis://HOST[:PORT][?db=DATABASE[&password=PASSWORD]] >>

=item C<< redis://HOST[:PORT][?password=PASSWORD[&db=DATABASE]] >>

=item C<< redis://[:PASSWORD@]HOST[:PORT][/DATABASE] >>

=item C<< redis://[:PASSWORD@]HOST[:PORT][?db=DATABASE] >>

=item C<< redis://HOST[:PORT]/DATABASE[?password=PASSWORD] >>

A TCP connection, see
L<http://www.iana.org/assignments/uri-schemes/prov/redis>.

The port defaults to 6379 and the host defaults to "localhost".

=item C<< redis+unix://[:PASSWORD@]SOCKET_PATH[?db=DATABASE] >>

=item C<< redis+unix://SOCKET_PATH[?db=DATABASE[&password=PASSWORD]] >>

=item C<< redis+unix://SOCKET_PATH[?password=PASSWORD[&db=DATABASE]] >>

A Unix domain socket connection.

=back

=head1 METHODS

In addition to the methods inherited from L<URI>, it provides the following
methods:

=head2 database

Returns the database number from the path or the C<db> query param.

Returns 0 if no database is specified.

=head2 database_from_path

Returns the database number encoded in the path part of the URI. Only works if
the path is in the format C<< ^ / \d+ >>.

Returns undef if no database can be parsed from the path.

=head2 database_from_query

Returns the database number from the C<db> query param.

Returns undef if no C<db> query param, or it has no value set.

=head2 password

Returns the password from the userinfo or the C<password> query param.

=head2 password_from_userinfo

Returns the password part of the L<URI/userinfo>.

=head2 password_from_query

Returns the password from the C<password> query param.

=head2 socket_path

Returns the Unix domain socket path.

Returns undef if the URI is not of the 'redis+unix' scheme.

=begin internal

Added these paragraphs just to make Pod::Coverage happy.

=head2 host

=head2 default_port

=end internal

=head1 SEE ALSO

L<URI>

=head1 COPYRIGHT

Copyright 2016 Norbert Buchmueller.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
