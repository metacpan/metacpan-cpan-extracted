package xDash::Archive::Pg;
# Copyright 2004 Jerzy Wachowiak

use strict;
use warnings;
use vars qw( $VERSION );
use Carp;
use DBI;

$VERSION = '1.00';

# PUBLIC METHODS (convention: capital first letter)

sub new {

    my $class = shift;
    my $self = {};
    $self->{VERSION} = $VERSION;
    bless ( $self, $class );
    return $self
}

sub Connect { 

#Contract: 
#	[1] No input parameters
#	[2] Method establishes connection and prepares statments
#	[3] If OK, undef returned
#	[4] if something wrong, a hash with keys error and error_code returned

    my $self = shift;
    
    # Connecting to the database...
    $self->{database}->{handle} = DBI->connect(
    	    'dbi:Pg:dbname='.$self->{database}->{name},
    	    $self->{database}->{user},
    	    $self->{database}->{password}, 
    	    { PrintError=>0, RaiseError=>0 } ) or
      return { error_code => $DBI::err, error => $DBI::errstr };

    # Preparation for message handling...
    $self->{database}->{message} = $self->{database}->{handle}->prepare(
    "insert into messages ( thread, entrytime, fromuser, server, resource,
     type, subject, body, errorcode, errordescription ) 
     values ( ?, now(), ?, ?, ?, ?, ?, ?, ?, ? );" );

    # Handling SQL statments for senders and recievers.
    my ( @row, $DBsenderJID, $DBreceiverJID, $DBcallname );
    
    # Preparing receivers
    my $sth = $self->{database}->{handle}->prepare(
     "select JID, update_call from receivers;"  );
    $sth->execute();
    
    while( @row = $sth->fetchrow_array() ){
        ( $DBreceiverJID, $DBcallname ) = @row;
        
	if ( ( $DBreceiverJID eq '' ) or ($DBcallname eq '' ) ) {
	    return {
		error_code => 1,
	        error => 'Incomplete set of data in the tabele RECEIVERS' }
        }
	
        # db truncates leading and trailing spaces
        $DBreceiverJID = lc( $DBreceiverJID ); 
        $DBreceiverJID =~ s/^\s+//;
        $DBreceiverJID =~ s/\s+//;
        $self->{database}->{receivers}->{$DBreceiverJID} =
	 $self->{database}->{handle}->prepare( "select $DBcallname( ?, ? );" )
    }
    
    # Preparing sender...
    $sth = $self->{database}->{handle}->prepare(
     "select JID, update_call from senders;" );
    $sth->execute();
    
    while( @row = $sth->fetchrow_array() ){
	( $DBsenderJID, $DBcallname ) = @row;
        
	if ( ( $DBsenderJID eq '' ) or ( $DBcallname eq '' ) ){
	    return {
		error_code => 1,
	        error => 'Incomplete set of data in the tabele SENDERS' }
        }
	
	# db truncates leading and trailing spaces
        $DBsenderJID = lc( $DBsenderJID ); 
        $DBsenderJID =~ s/^\s+//;
        $DBsenderJID =~ s/\s+//;
        $self->{database}->{senders}->{$DBsenderJID} = 
	 $self->{database}->{handle}->prepare( "select $DBcallname( ? );" )
    }
    return
}

sub Disconnect { 

#Contract: 
#	[1] No input, method for gentel exit...
#	[2] No return value check in the xDash::Sender

    my $self = shift;
    
    $self->{database}->{message}->finish();

    foreach my $JID ( keys %{ $self->{database}->{senders} } ){
	$self->{database}->{senders}->{$JID}->finish()
    }
    foreach my $JID ( keys %{ $self->{database}->{receivers} } ){
	$self->{database}->{receivers}->{$JID}->finish()
    }
    
    $self->{database}->{handle}->disconnect();
    return
}

sub SetDatabaseConnection {

#Contract:
#	[1] Passing through connection paramaters  
#       [2] Method can always suceed (true) because checking parameter
#	 correctness passed further

    my $self = shift;
    $self->{database} = { @_ };

    unless ( defined( $self->{database}->{name} ) ){
	croak 'xDash: Missing database name in the SetDatabaseConnection()'
    }
    unless ( defined( $self->{database}->{user} ) ){
	croak 'xDash: Missing database user in the SetDatabaseConnection()'
    }
    unless ( defined( $self->{database}->{password} ) ){
	croak 'xDash: Missing database user password'
	.' in the SetDatabaseConnection()'
    }

    $self->{SetDatabaseConnection}++;
    return 1
}

sub IsValidSender {

#Contract: 
#	[1] lower case message JID as input
#	[2] return 1 if exists, undef if not exists

    my $self = shift; # DEV naprawde?
    my $messageJID = shift; 

    return exists( $self->{database}->{senders}->{$messageJID} )   
}

sub IsValidReceiver {

#Contract: 
#	[1] lower case message JID as input
#	[2] return 1 if exists, undef if not exists

    my $self = shift; # DEV naprawde?
    my $messageJID = shift; 

    return exists( $self->{database}->{receivers}->{$messageJID} )   
}

sub AddMessage {

#Contract: 
#	[1] Message parameters as input
#	[2] if everything ok, return undef
#	[3] if something wrong, hash with error_code and eror
     
    my $self = shift;
    
    $self->{database}->{message}->bind_param( 1, shift ); # $thread 
    $self->{database}->{message}->bind_param( 2, shift ); # $from
    $self->{database}->{message}->bind_param( 3, shift ); # $server
    $self->{database}->{message}->bind_param( 4, shift ); # $resource
    $self->{database}->{message}->bind_param( 5, shift ); # $type
    $self->{database}->{message}->bind_param( 6, shift ); # $subject
    $self->{database}->{message}->bind_param( 7, shift ); # $body
    $self->{database}->{message}->bind_param( 8, shift ); # $action_result
    $self->{database}->{message}->bind_param( 9, shift ); # $action_description

    unless ( defined( $self->{database}->{message}->execute() ) ){
	return {
	    error_code => $self->{database}->{message}->err(),
	    error => $self->{database}->{message}->errstr() }	
    }
    return
}

sub UpdateStatisticsWithSenders { 

#Contract: 
#	[1] thread parameter as input
#	[2] if everything ok, return undef
#	[3] if something wrong, hash with error_code and eror

    my $self = shift;
    my $messageJID = shift;

    # thread...
    $self->{database}->{senders}->{$messageJID}->bind_param( 1, shift ); 

    unless ( 
     defined( $self->{database}->{senders}->{$messageJID}->execute() ) ){
	    return {
	      error_code => $self->{database}->{senders}->{$messageJID}->err(),
	      error => $self->{database}->{senders}->{$messageJID}->errstr() }
    }
    return
}

sub UpdateStatisticsWithReceivers { 

#Contract: 
#	[1] thread and action result as input parameters
#	[2] if everything ok, return undef
#	[3] if something wrong, hash with error_code and eror

    my $self = shift;
    my $messageJID = shift;
    
    # $thread...
    $self->{database}->{receivers}->{$messageJID}->bind_param( 1, shift );
    # $action_result...
    $self->{database}->{receivers}->{$messageJID}->bind_param( 2, shift );
    
    unless ( 
     defined( $self->{database}->{receivers}->{$messageJID}->execute() ) ){
	    return {
	     error_code => $self->{database}->{receivers}->{$messageJID}->err(),
	     error => $self->{database}->{receivers}->{$messageJID}->errstr() }
    }
    return    
}

1;
__END__
######################## User Documentation ##################

=pod

=head1 NAME

xDash::Archive::Pg - Base class for Archive

=head1 SYNOPSIS

 package Archive;
 use base xDash::Archive::Pg;
 # Set up your own database access parameters 
 sub SetParameters { shift->SUPER::SetDatabaseConnection(
  name => 'xdash', user => '', password => '' ) }

=head1 DESCRIPTION

=head2 USAGE

The module is developed in the object orientated way. It can be used as the 
base class for archiving based on PostgreSQL as persistence. The 
base class has to implement a fixed set of methods, called by 
the derived class C<Archive>. 
C<Archive> is hardcoded in the C<xDash::Archivist> (driver pattern).
For more details, how to set up all the needed components,
see the introduction to the deployment: I<Planning and deploying xDash 
in a sandbox> at L<http://xdash.jabberstudio.org/deployment/perl>.
By deriving from the class, as the way of passing arguments, 
you have to implement explicit methods listed below .
The synopsis above is an example of the client script generated 
by the F<xdscr>.

=head2 METHODS

=over

=item SetDatabaseConnection( name => $database_name, 
user => $database_user, password => database_password )

Passes the self explanatory parameters to the  DBI 
module, required by xDash::Archivist. 

=back

=head1 BUGS

Any suggestions for improvement are welcomed!

If a bug is detected or nonconforming behavior, 
please send an error report to <jwach@cpan.org>.

=head1 COPYRIGHT

Copyright 2005 Jerzy Wachowiak <jwach@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the terms of the Apache 2.0 license attached to the module.

=head1 SEE ALSO

=over

=item L<xDash::Archivist>

=back

=cut
