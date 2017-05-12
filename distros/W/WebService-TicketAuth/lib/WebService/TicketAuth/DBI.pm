
=head1 NAME

WebService::TicketAuth::DBI - Ticket-based authentication module for SOAP services

=head1 SYNOPSIS

    @WebService::MyService::ISA = qw(WebService::TicketAuth::DBI);

=head1 DESCRIPTION

B<WebService::TicketAuth::DBI> is an authentication system for
SOAP-based web services using a DBI mechanism.  This performs crypt()
style password comparison (compatible with the UNIX crypt() call).

=head1 FUNCTIONS

=cut

package WebService::TicketAuth::DBI;

use strict;
use WebService::TicketAuth;
use DBI;

use vars qw($VERSION %FIELDS);
our $VERSION = '1.05';
@WebService::TicketAuth::DBI::ISA = qw(WebService::TicketAuth);

use base 'WebService::TicketAuth';
use fields qw(
              _dbh
              authdb_dbi
              authdb_user
              authdb_pass
	      authdb_table
	      authdb_user_field
	      authdb_passwd_field
              _error_msg
              _debug
              );

=head2 new(%args)

Creates a new instance of TicketAuth.  Establishes several private member
functions for authentication, to calculate, make, and check the authInfo.

=cut

sub new {
    my WebService::TicketAuth::DBI $self = shift;
    my (%args) = @_;

    if (! ref $self) {
        $self = fields::new($self);
    }
    $self->SUPER::new();

    foreach my $field (keys %args) {
	if (exists $FIELDS{$field} && $field =~ /^authdb/) {
	    $self->{$field} = $args{$field};
	}
    }

    return $self;
}

=head2 _get_dbh

Overridable routine to retrieve a database handle.  This is used for
caching db handles, for example.

=cut

sub _get_dbh {
    my $self = shift;

    $self->{'_dbh'} = DBI->connect_cached($self->{'authdb_dbi'},
                                          $self->{'authdb_user'},
                                          $self->{'authdb_pass'}, 
                                          { RaiseError => 1, AutoCommit => 1 }
                                          );
    if (! defined $self->{'_dbh'}) {
        $self->_set_error("Could not connect to '"
                          .$self->{'authdb_dbi'}
                          ."' as user '"
                          .$self->{'authdb_user'}
                          ."':  ".$DBI::errstr."\n");
    }

    return $self->{'_dbh'};
}

# Internal routine for setting the error message
sub _set_error {
    my $self = shift;
    $self->{'_error_msg'} = shift;
}

=head2 get_error()

Returns the most recent error message.  If any of this module's routines
return undef, this routine can be called to retrieve a message about
what happened.  If several errors have occurred, this will only return
the most recently encountered one.

=cut

sub get_error {
    my $self = shift;
    return $self->{'_error_msg'};
}

sub login {
    my $self = shift;
    return $self->SUPER::login(@_);
}

=head2 ticket_duration

Establishes length of time that a user's ticket will remain valid.
Allowed duration is 24 hours.

=cut

sub ticket_duration {
    my $self = shift;
    return 24*60*60;
}

=head2 is_valid

Override of WebService::TicketAuth::is_valid() to determine whether a
set of credentials are valid.

=cut

sub is_valid {
    my $self = shift;
    my ($username, $password) = @_;

    my $table        = $self->{'authdb_table'};
    my $user_field   = $self->{'authdb_user_field'};
    my $passwd_field = $self->{'authdb_passwd_field'};
    my $saved_pass;

    my $dbh = $self->_get_dbh();

    if (! defined $dbh) {
	my $dberr = $self->get_error() || '';
        $self->_set_error("Failure getting database handle in "
                          .__PACKAGE__."::is_valid():  $dberr\n");
        return undef;
    }
    my $sql = qq|
        SELECT $passwd_field
        FROM   $table
        WHERE  $user_field = ?
        |;
    my $sth = $dbh->prepare($sql);
    $sth->execute($username);
    ($saved_pass) = $sth->fetchrow_array;
    $sth->finish;
    
    if (! $saved_pass) {
        return undef;
    }

    my $test_pass = crypt($password, $saved_pass);

    return ($test_pass eq $saved_pass);
}


1;
__END__

=head1 AUTHORS

Bryce Harrington, bryce at bryceharrington dot org.

=head1 COPYRIGHT

Copyright (C) 2004 Bryce Harrington.  All rights reserved.

This script is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<SOAP::Lite>, L<Apache::AuthTicket>, L<WebService::TicketAuth>

=cut
