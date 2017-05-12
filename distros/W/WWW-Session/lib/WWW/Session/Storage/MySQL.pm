package WWW::Session::Storage::MySQL;

use 5.006;
use strict;
use warnings;

=head1 NAME

WWW::Session::Storage::MySQL - MySQL storage for WWW::Session

=head1 DESCRIPTION

MySQL backend for WWW:Session

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

#Internal variable that controls the expired session cleanup process
#We do a cleanup not faster than every 10 minutes, when we try and retrieve
my $last_cleanup = 0;


=head1 SYNOPSIS

This module is used for storring serialized WWW::Session objects in MySQL

Usage : 

    use WWW::Session::Storage::MySQL;

    my $storage = WWW::Session::Storage::MySQL->new({ 
                                dbh => $dbh,
                                table => 'sessions',
                                fields => {
                                    sid => 'session_id',
                                    expires => 'expires',
                                    data => 'data'
                                }
                });
    ...
    
    $storage->save($session_id,$expires,$serialized_data);
    
    my $serialized_data = $storage->retrive($session_id);


The "fields" hasref contains the mapping of session internal data to the column names from MySQL. 
The keys are the session fields ("sid","expires" and "data") and must all be present. 

The MySQL types of the columns should be :

=over 4

=item * sid => varchar(32)

=item * expires => DATETIME or TIMESTAMP

=item * data => text

=back

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new WWW::Session::Storage::MySQL object

This method accepts only one argument, a hashref that must contain the fallowing data:

=over 4

=item * dbh Database handle

=item * table The name of the table where the sessions will be stored

=item * fields A hash ref containing the falowing keys 

=over 8

=item * sid The same of the database field which will store the session id

=item * expires  The same of the database field which will store the expiration time

=item * data The name of the field where the session data will be stored

=back

=back

=cut

sub new {
    my ($class,$params) = @_;
    
    my $self = {
                dbh => $params->{dbh},
                table => $params->{table},
                fields => $params->{fields},
    };
    
    bless $self,$class;
    
    $self->_check_table_structure();
    
    return $self;
}

=head2 save

Stores the given information into the database

=cut
sub save {
    my ($self,$sid,$expires,$string) = @_;

	$expires = 60*60*24*365*20 if $expires == -1;

    my $query = sprintf('INSERT INTO %s SET %s=?, %s=?,%s=FROM_UNIXTIME(?) ON DUPLICATE KEY UPDATE %s=?, %s=FROM_UNIXTIME(?)',
                        $self->{table},
                        @{$self->{fields}}{qw(sid data expires)},
						@{$self->{fields}}{qw(data expires)}
                        );

    my $sth = $self->{dbh}->prepare($query);

    my $rv = $sth->execute($sid,$string,time() + $expires, $string,time() + $expires);
    
    return $rv;
}

=head2 retrieve

Retrieves the informations for a session, verifies that it's not expired and returns
the string containing the serialized data

=cut
sub retrieve {
    my ($self,$sid) = @_;

    if ( $last_cleanup + 600 < time() ) {
        $last_cleanup = time();
        my $del_sth = $self->{dbh}->prepare(sprintf("DELETE FROM %s WHERE %s < NOW()",$self->{table},$self->{fields}{expires}));
        $del_sth->execute()
    }
    
    my $query = sprintf('SELECT %s as sid,%s as data,UNIX_TIMESTAMP(%s) as expires FROM %s WHERE %s=?',
                        @{$self->{fields}}{qw(sid data expires)},
                        $self->{table},
                        $self->{fields}->{sid}
                        );

    my $sth = $self->{dbh}->prepare($query);
    $sth->execute($sid);
    
    my $info = $sth->fetchrow_hashref();
    
    return undef unless defined $info;
    
    if ( $info->{expires} < time() ) {
        $self->delete($sid);
        return undef;
    }
    
    return $info->{data};

}

=head2 delete

Completely removes the session data for the given session id

=cut
sub delete {
    my ($self,$sid) = @_;

    my $query = sprintf('DELETE FROM %s WHERE %s=?',
                        $self->{table},
                        $self->{fields}->{sid}
                        );

    my $sth = $self->{dbh}->prepare($query);
    my $rv = $sth->execute($sid);

    return $rv;
}

=head1 Private methods

=head2 _determine_expires_type

Tries to determine if the expires field is UnixTimestamp or DateTime

=cut
sub _check_table_structure {
    my $self = shift;
    
    my $sth = $self->{dbh}->prepare("DESCRIBE ".$self->{table});
    $sth->execute();
    
    my $table_fields = $sth->fetchall_hashref('Field');
    
    die "The table structure doesn't match the field names you specified!" 
                unless  exists $table_fields->{$self->{fields}->{sid}} &&
                        exists $table_fields->{$self->{fields}->{expires}} &&
                        exists $table_fields->{$self->{fields}->{data}};
}

=head2 _reset_last_cleanup

Resets the last DB cleanup timer, forcing all expired sessions to be removed when the next session is retrieved

=cut
sub _reset_last_cleanup {
    $last_cleanup = 0;
}

=head1 AUTHOR

Gligan Calin Horea, C<< <gliganh at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-session at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Session>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Session::Storage::MySQL


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

1; # End of WWW::Session::Storage::MySQL
