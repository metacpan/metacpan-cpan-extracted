package WWW::Session::Storage::Memcached;

use 5.006;
use strict;
use warnings;

BEGIN {
    eval "use Cache::Memcached;";
    
    if ($@) {
        warn "You must install Cache::Memcached module from CPAN to use the memcached storage engine!"
    }
}


=head1 NAME

WWW::Session::Storage::Memcached - Memcached storage for WWW::Session

=head1 DESCRIPTION

Memcached backend for WWW::Session

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';


=head1 SYNOPSIS

This module is used for storring serialized WWW::Session objects in memcached

Usage : 

    use WWW::Session::Storage::Memcached;

    my $storage = WWW::Session::Storage::Memcached->new({ servers => ["127.0.0.1:11211"] });
    ...
    
    $storage->save($session_id,$expires,$serialized_data);
    
    my $serialized_data = $storage->retrive($session_id);

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new WWW::Session::Storage::File object

This method accepts only one argument, a hashref that contains all the options that will be
passed to the Cache::Memcached module. The mendatory key in the hash is "servers" wihich must
be an array ref containing all the C<memcached> servers we want to use.

See Cache::Memcached module for more details on available options

Example :

    my $storage = WWW::Session::Storage::Memcached->new({ servers => ["127.0.0.1:11211"] });

=cut
sub new {
    my $class = shift;
    my $params = shift;
    
    my $self = { options => $params,
                 memcached => Cache::Memcached->new($params),
                };
        
    bless $self, $class;
    
    return $self;
}

=head2 save

Stores the given information into the file

=cut
sub save {
    my ($self,$sid,$expires,$string) = @_;
    
    return $self->{memcached}->set($sid,$string,$expires == -1 ? undef : $expires );
}

=head2 retrieve

Retrieves the informations for a session, verifies that it's not expired and returns
the string containing the serialized data

=cut
sub retrieve {
    my ($self,$sid) = @_;

    return $self->{memcached}->get($sid);
}

=head2 delete

Completely removes the session data for the given session id

=cut
sub delete {
    my ($self,$sid) = @_;

    $self->{memcached}->delete($sid);
}

=head1 AUTHOR

Gligan Calin Horea, C<< <gliganh at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-session at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Session>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Session::Storage::Memcached


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Session>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Session>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Session>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Session/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Gligan Calin Horea.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WWW::Session::Storage::Memcached
