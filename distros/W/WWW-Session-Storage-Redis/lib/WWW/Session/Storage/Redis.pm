package WWW::Session::Storage::Redis;

use 5.006;
use strict;
use warnings;

BEGIN {
    eval "use Cache::Redis;"; ## no critic
    
    if ($@) {
        warn "You must install the Cache::Redis module from CPAN to use the redis storage engine!"
    }
}


=head1 NAME

WWW::Session::Storage::Redis - Redis storage for WWW::Session

=head1 DESCRIPTION

Redis backend for WWW::Session

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

This module is used for storing serialized WWW::Session objects in redis

Usage : 

    use WWW::Session::Storage::Redis;

    my $storage = WWW::Session::Storage::Redis->new({ server => ["127.0.0.1:6379"] });
    ...
    
    $storage->save($session_id,$expires,$serialized_data);
    
    my $serialized_data = $storage->retrive($session_id);

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new WWW::Session::Storage::Redis object

This method accepts only one argument, a hashref that contains all the options
that will be passed to the Cache::Redis module. The mendatory key in the hash
is "server" which must be a scalar containing the C<redis> server we want to
use.

See Cache::Redis module for more details on available options

Example :

    my $storage = WWW::Session::Storage::Redis->new({ server => "127.0.0.1:6379" });

=cut
sub new {
    my $class = shift;
    my $params = shift;
    
    my $self = { options => $params,
                 redis => Cache::Redis->new(%$params),
                };
        
    bless $self, $class;
    
    return $self;
}

=head2 save

Stores the given information into the file

=cut
sub save {
    my ($self,$sid,$expires,$string) = @_;
    
    return $self->{redis}->set($sid,$string,$expires == -1 ? undef : $expires );
}

=head2 retrieve

Retrieves the informations for a session, verifies that it's not expired and returns
the string containing the serialized data

=cut
sub retrieve {
    my ($self,$sid) = @_;

    return $self->{redis}->get($sid);
}

=head2 delete

Completely removes the session data for the given session id

=cut
sub delete {
    my ($self,$sid) = @_;

    $self->{redis}->remove($sid);
}

=head1 AUTHOR

Jeffrey Goff, C<< <jeffrey.goff at evozon.com> >>

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


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Evozon

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WWW::Session::Storage::Redis
