package xDash::Archivist;
# Copyright 2005 Jerzy Wachowiak

use strict;
use warnings;
use vars qw( $VERSION );
use Carp;
use Net::Jabber qw( Client );
use XML::Stream qw( Tree );
use POSIX qw( setsid );

# The developer has to provide in the main scrip the implementation for package:
# [1] ErrorLogger;
# [2] MessageLogger;
# [3] EventLogger.

$VERSION = '1.00';

my $xDash__Archivist__object_instance;

# PUBLIC METHODS (convention: capital first letter)

sub new {

    my $class = shift;
    my $self = {};
    $self->{VERSION} = $VERSION;
    $self->{ErrorLogger} = new ErrorLogger;
    $self->{ErrorLogger}->Open();
    $self->{MessageLogger} = new MessageLogger;
    $self->{MessageLogger}->Open();
    $self->{EventLogger} = new EventLogger;
    $self->{EventLogger}->Open();
    $self->{Archive} = new Archive;
    $self->{EmergencyLogger} = new EmergencyLogger;
    $self->{EmergencyLogger}->Open();

    # Bypassing Net::Jabber limit on arguments in SetCallBacks()
    $xDash__Archivist__object_instance = $self;
    bless ( $self, $class );
    return $self
}

sub SetParticipants {

#Contract: 
#	[1] Log file path in unix convention as input for XML configuration
#       [2] Method can either suceed (true) or everything dies...

    my $self = shift;
    my $configfilepath = shift;
    my $parser_tree = new XML::Stream::Parser(style => "tree");
    my $tree = $parser_tree->parsefile( $configfilepath );
    unless ( defined( $tree ) ){
	$self->{ErrorLogger}->Log( "process($$)",
	 'Can not find or open archivist configuration file.');
	exit 1
    }
    my %config = %{ &XML::Stream::XML2Config( $tree ) };
    if ( $config{account}->{role} =~ m/archivist/i ){
        $self->{archivist}->{hostname}
         = trim( $config{account}->{hostname} );
        check_hostname( $self->{archivist}->{hostname} );
        $self->{archivist}->{port}
         = trim( $config{account}->{port} );
        check_port( $self->{archivist}->{port} );
        $self->{archivist}->{username}
         = trim( $config{account}->{username} );
        check_username( $self->{archivist}->{username} );
        $self->{archivist}->{password}
         = trim( $config{account}->{password} );
        $self->{archivist}->{resource}
         = trim( $config{account}->{resource} )
    }

    # Archivist: JID and Fully Qualified JID
    $self->{archivist_JID} = lc( $self->{archivist}->{username}."@"
	            	     .$self->{archivist}->{hostname} );

    $self->{archivist_FQJID} = $self->{archivist_JID}."/"
		             .$self->{archivist}->{resource};
			     
    $self->{SetParticipants}++;
    return 1
}

sub SetConnectionParameters {

#Contract: 
#	[1] Passing through connection paramaters to the Net::Jabber 
#       [2] Method can always suceed (true) because checking parameter
#	 correctness passed to the Net::Jabber
#	[4] Calling the method is optionaly - no checking if exists
#	[5] Parameters overwrite parameters from the xml configuration file

    my $self = shift;

    $self->{connection_parameters} = { @_ };
    return 1
}

sub SetMode {

#Contract: 
#	[1] Passing hash: own session ( daemon=>1 );
#	 how much delay on start in seconds (eg delay=>10 );
#	 how much timeout in seconds between reconnection ( timeout=>10 ).
#       [2] Method can only suceed, when:
#	 (daemon=>1 or 0) and  delay>=0 and timeout >=0.
#	[3] Default debugging values ( daemon=>0, delay=>0, timeout=>100 ).

    my $self = shift;

    $self->{mode} = { @_ };

    unless ( defined( $self->{mode}->{daemon} ) ){
	croak 'xDash: Missing daemon parameter in the SetMode method'
    }
    unless ( $self->{mode}->{daemon} == 0 or $self->{mode}->{daemon} == 1 ){
	croak 'xDash: Wrong daemon parameter in the SetMode method'
    }

    unless ( defined( $self->{mode}->{delay} ) ){
	croak 'xDash: Missing delay parameter in the SetMode method'
    }
    unless ( $self->{mode}->{delay} == 0 or $self->{mode}->{delay} > 0 ){
	croak 'xDash: Delay parameter is negative in the SetMode method'
    }
    unless ( defined( $self->{mode}->{timeout} ) ){
	croak 'xDash: Missing timeout parameter in the SetMode method'
    }
    unless ( $self->{mode}->{timeout} == 0 or $self->{mode}->{timeout} > 0 ){
	croak 'xDash: Timeout parameter is negative in the SetMode method'
    }

    $self->{SetMode}++;
    return 1
}

sub SetRestartArchiveError {

#Contract: 
#	[1] An error code list as input
#       [2] Method call is optional so no usage counting
# 	[4] Method suceed always

    my $self = shift;

    foreach my $error_code ( @_) {
	$self->{critical_errors}->{$error_code} = undef 
    };
    return 1
}

sub Process {

#Contract: 
#	[1] No input 
#       [2] Method can either suceed (true) or everything dies...

    my $self = shift;
    
    defined( $self->{SetMode} ) or croak
     'xDash: Missing SetMode() call prior to the Process() call';
    defined( $self->{SetParticipants} ) or croak
     'xDash: Missing SetParticipants() call prior to the Process() call';

    $self->{Archive}->SetParameters();

    # Establishing own session if supposed to have own sesssion and
    # run as daemon...
    if ( $self->{mode}->{daemon} ){
        POSIX::setsid();
        open( STDOUT, "< /dev/null" );
        open( STDIN, "> /dev/null" );
        open( STDERR, "> &STDOUT" );
        chdir '/';
        umask( 0 )
    }

    # Start/restart delay...
    select undef, undef, undef, $self->{mode}->{delay};
    $self->{EventLogger}->Log( 
     $self->{archivist_FQJID}."($$)", 'Session start.' );

    if ( defined( my $result = $self->{Archive}->Connect() ) ){
	$self->{ErrorLogger}->Log( 
         $self->{archivist_FQJID}."($$)", 
         "Can not connect to the archiv, error "
    	 .$result->{error_code}.' ('.$result->{error}.').' );
	exit 1
    }
    else {
	$self->{EventLogger}->Log( 
	  $self->{archivist_FQJID}."($$)",
	  'Connection to the archiv established.' )
    }
    
    unless ( defined( $self->{connection_parameters} ) ){
	$self->{connection_parameters} = {}
    }
    
    $self->{connection_parameters} = {
     hostname => $self->{archivist}->{hostname},
     port => $self->{archivist}->{port},
     %{ $self->{connection_parameters} }
    };
    
    until ( defined( our $status ) ){
        $self->{connection} = new Net::Jabber::Client();
 	$status = $self->{connection}->Connect(
	 %{ $self->{connection_parameters} } );
        unless ( defined( $status ) ){
    	    $self->{ErrorLogger}->Log( 
	     $self->{archivist_FQJID}."($$)->".$self->{archivist}->{hostname}, 
	     "Jabber server is down ($!)." );
    	    select undef, undef, undef, $self->{mode}->{timeout};	    
	}
    }

    $self->{connection}->SetCallBacks( message => \&message_processing );

    my @result = $self->{connection}->AuthSend(
        username => $self->{archivist}->{username},
        password => $self->{archivist}->{password},
        resource => $self->{archivist}->{resource} );
     
    unless ( $result[0] =~ m/ok/i ){
	$self->{ErrorLogger}->Log( 
	 $self->{archivist_FQJID}."($$)->".$self->{archivist}->{hostname}, 
	 "Authorization failed $result[0] - $result[1]" );
	exit 1
    } 
    else {
	$self->{EventLogger}->Log( 
	 $self->{archivist_FQJID}."($$)->".$self->{archivist}->{hostname}, 
	 'Login ok.' )		
    }

    $self->{connection}->PresenceSend();

    while (1) {
	my $result = $self->{connection}->Process(10);
        if ( !defined( $result ) or $result eq '' ){
	    $self->{Archive}->Disconnect();
	    $self->{ErrorLogger}->Log( 
	     $self->{archivist_FQJID}."($$)->".$self->{archivist}->{hostname}, 
	     'The connection to the server has been lost.' );
	    exit 1
	}
    }
}


# PRIVATE METHODS (convention: small first letter)

sub message_processing {

    my $self = $xDash__Archivist__object_instance;
    my $sid = shift;
    my $message = shift;
    
    my $fromJID = $message->GetFrom( 'jid' );
    my $from = lc( $fromJID->GetUserID() );
    my $server = lc( $fromJID->GetServer() );
    my $resource = $fromJID->GetResource();
    my $subject = $message->GetSubject();
    my $type = lc( $message->GetType() );
    $type or $type = 'normal';
    my $body = $message->GetBody();
    my $thread = $message->GetThread();
    $thread or $thread = 'nothread';
    
    # Checking if valid message->preventing flooding the database
    my $messageJID = "$from\@$server";
    return unless $self->{Archive}->IsValidSender( $messageJID ) or
     $self->{Archive}->IsValidReceiver( $messageJID ); 
    return unless $type =~ m/job/i and $message->DefinedThread();
    $self->{MessageLogger}->Log( $$, $message->GetXML() );    
    
    my( $result, $action_result, $action_description );

    if ( $message->DefinedError() or $message->DefinedErrorCode() ){
        $action_result = $message->GetErrorCode;
        $action_description = $message->GetError()
    }
    else {
	$action_result = 0;
	$action_description = 'ok'
    }

    if ( defined( $result = $self->{Archive}->AddMessage(
     $thread, $from, $server, $resource, $type, $subject, $body,
     $action_result, $action_description ) ) ){
	$self->{ErrorLogger}->Log( 
         $self->{archivist_FQJID}."($$)", 
         'On message archiv error '.$result->{error_code}.' ('
	 .$result->{error}.').' );
	$self->{EmergencyLogger}->Log( $$, $message->GetXML() );
	if ( exists $self->{critical_errors}->{$result->{error_code}} ){
	 exit 1
	}
    }

    # Handling statistics    
    if ( $self->{Archive}->IsValidSender( $messageJID ) and
     ( $type =~ m/job/i ) ){
	if ( defined( 
	 $result =  $self->{Archive}->UpdateStatisticsWithSenders( 
	  $messageJID, $thread ) ) ){
	    $self->{ErrorLogger}->Log( 
	     $self->{archivist_FQJID}." $thread($$)", 
             'On senders statistics archiv error '.$result->{error_code}
	     .' ('.$result->{error}.') .' )
	}
	if ( defined( $message->GetID() ) ){
	    my $response = $message->Reply();
	    $self->{connection}->Send( $response );
	    $self->{MessageLogger}->Log( $$, $response->GetXML() )
	}
	return
    }
    
    if ( $self->{Archive}->IsValidReceiver( $messageJID ) and
     ( $type =~ m/job/i ) ){
	if ( defined( 
	 $result = $self->{Archive}->UpdateStatisticsWithReceivers(
	  $messageJID, $thread, $action_result ) ) ){
	    $self->{ErrorLogger}->Log( 
	     $self->{archivist_FQJID}." $thread($$)", 
             'On receivers statistics archiv error '.$result->{error_code}
	     .' ('.$result->{error}.') .' )
	}
    }
    return
}

sub trim {

    my $string = shift;

    if ( $string =~ m/^\s*\S+\s*$/ ){ 
	$string =~ s/^\s*(\S+)\s*$/$1/;
	return $string  
    }
    else {
	croak "xDash: Found <...>$string</...> where single value expected"
	.' in the XML configuration file'	
    }
}

sub check_username {

    my $username = shift;
    
    if ( $username !~ /^[0-9a-zA-Z\.\-\_]+$/ ){
	    croak "xDash: Username ", $username, " contains somewhere unallowed character:",
	     ' @, :, /, "',",",
	     " control character, ASCI under 33 (decimal)"
	     .' in the XML configuration file'
    }
    
    if ( $username =~ /^[^0-9a-zA-Z]/ ){
	    croak "xDash: Username $username must start with alpha or number"
		.' in the XML configuration file'
    }
    
    if ( length($username) > 255 ){
	    croak "xDash: Username $username"
	    .' is longer than allowed 255 characters'
	    .' in the XML configuration file'
    }
}

sub check_hostname {

    my $hostname = shift;

    if ( $hostname !~ /^[0-9a-zA-Z\.\-]+$/ ){
	    croak "xDash: Hostname ", $hostname, " contains somewhere unallowed character:",
	     ' @, :, /, "',",",
	     " control character, ASCI under 33 (decimal)"
	     .' in the XML configuration file'
    }
    
    if ( $hostname =~ /^[^0-9a-zA-Z]/ ){
	    croak "xDash: Hostname $hostname must start with alpha or number"
	    .' in the XML configuration file'
    }
} 

sub check_port {
    
    my $port = shift;    

    if ( $port !~ /^[0-9]+$/ ){ 
	    croak "xDash: Port $port is not a number in the XML configuration file"
    }
}

1;
__END__
######################## User Documentation ##################

=pod

=head1 NAME

xDash::Archivist - Module for Archivist's client script implementation

=head1 SYNOPSIS

 #!/usr/bin/perl 
 # xDash - Asynchronous Messaging and Instant Messaging reunited

 #===
 package EventLogger;
 use base xDash::Logger::File;
 # Check the correct file path for logger (absolute path if daemon!) and
 # Uncomment 1.line and comment out 2.line below after debugging.
 # sub Open { shift->SUPER::Open( 'home/xdash/archivist/event.log' ) }
 sub Open { shift->SUPER::Open( STDOUT ) }

 package ErrorLogger;
 use base xDash::Logger::File;
 # Check the correct file path for logger (absolute path if daemon!) and
 # Uncomment 1.line and comment out 2.line below after debugging.
 # sub Open { shift->SUPER::Open( 'home/xdash/archivist/error.log' ) }
 sub Open { shift->SUPER::Open( STDERR ) }

 package MessageLogger;
 # Check the correct file path for logger (absolute path if daemon!) and
 # Uncomment the 1.line and comment out 2.&3.line below after debugging.
 # use base xDash::Logger::Dumb;
 use base xDash::Logger::File;
 sub Open { shift->SUPER::Open( STDOUT ) }

 package EmergencyLogger;
 # Check the correct file path for logger (absolute path if daemon!).
 use base xDash::Logger::File;
 sub Open { shift->SUPER::Open( 'home/xdash/archivist/emergency.log' ) }

 package Archive;
 use base xDash::Archive::Pg;
 # Set up your own database access parameters 
 sub SetParameters { shift->SUPER::SetDatabaseConnection(
  name => 'xdash', user => '', password => '' ) }
 #===

 package main;
 use strict;
 use warnings;
 use xDash::Archivist;

 my $archivist = new xDash::Archivist;

 # After debugging change:
 # daemon => 1, for running as daemon (daemon => O, console usage)
 # delay => 10, for waiting 10 seconds before becomming a daemon
 # timeout => 100, for waiting 100 seconds to try to reconnect
 # Test settings:
 $archivist->SetMode( daemon=> 0, delay=> 0, timeout=> 5 );

 # Parameters from archivist.xml and default connection parameters 
 # from package Net::Jabber::Client (::Connect()) can be overriden here:
 #	hostname => string, port => integer,
 # 	connectiontype => tcpip|http, ssl => 0|1
 # Uncomment if needed, method is optional.
 # $archivist->SetConnectionParameters( ... => ... , );

 # Initiate Archivist's JID (absolute path if daemon!)
 $archivist->SetParticipants( 'home/xdash/archivist/archivist.xml' );

 # A comma separated list of archive error numbers on which Archivist's script
 # dies and is restarted by the operating system.
 $archivist->SetRestartArchiveError( -1 );

 # Go on ...
 $archivist->Process();

=head1 DESCRIPTION

=head2 USAGE

For detailed description, how xDash framework works, please refer to 
L<http://xdash.jabberstudio.org>.

A convenient way for using the module and auto generating Archivist's script 
is the utility F<xdscr> from F<deployment> directory. For script usage read the 
F<deployment/README.txt> or usage information embedded into the script.
The synopsis above is an example of the Archivist's client script generated by the F<xdscr>.
You can find an introduction to the deployment: I<Planning and deploying xDash 
in a sandbox> at L<http://xdash.jabberstudio.org/deployment/perl>.

The module is developed in the object orientated way. You have to provide 
base classes for logging tasks and archive, which have to implement a fixed 
set of methods (driver pattern).
You can use for logging C<xDash::Logger::File> and C<xDash::Logger::Dumb> 
in a way as it is proposed in the script generated by F<xdscr> 
or provide your own implementation of the base class for 
C<EventLogger>, C<ErrorLogger>, C<MessageLogger> and C<EmergencyLogger>.
You can use for archive C<xDash::Archive::Pg> 
as it is proposed in the script generated by F<xdscr>. 
If you wish something else then PostgreSQL based persistence, you have to 
provide for the class C<Archive> your own implementation of the base 
class with all other belongings.
If you have to develop your own logger or archive, see provided modules source 
code for further implementation hints. If you think, they can be reused, 
make them public over CPAN in the xDash::Spool and xDash::Archive namespace!

=head2 METHODS

=over

=item SetMode( daemon=> 0|1, delay=> $time, timeout=> $time, wait => $time )

daemon => 1, for running script as daemon; 
daemon => 0, console usage of the script; 
delay=> $time, for waiting $time seconds before becomming a daemon;
timeout => $time, for waiting $time seconds to try to reconnect.

=item SetConnectionParameters( hostname => $string, port => $integer,
connectiontype => tcpip|http, ssl => 0|1 )

Overrides parameters <hostname> and <port> from the XML configuration 
file (usually F<archivist.xml>) 
and default connection parameters from package Net::Jabber::Client (::Connect()). 
Method is optional.

=item SetParticipants( $XML_configuration_file )

Initiate Sender's and Archivist's JIDs with a absolute path to the 
XML configuration file, 
usually with the name F<archivist.xml>.

=item SetRestartArchiveError( $error_number_1, $error_number_2, ... )

Sets a comma separated list of spool error numbers, on which 
the Archivist's script dies and is restarted by the operating system.

=item Process( )

Go on...

=back

=head1 BUGS

Any suggestions for improvement are welcomed!

If a bug is detected or nonconforming behavior, 
please send an error report to <jwach@cpan.org>.
Please attache log entries, if possible.

=head1 COPYRIGHT

Copyright 2005 Jerzy Wachowiak <jwach@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the terms of the Apache 2.0 license attached to the module.


=head1 SEE ALSO

=over

=item L<xDash::Logger::File>

=item L<xDash::Logger::Dumb>

=item L<xDash::Archive::Pg>

=item L<xDash::Sender>

=item L<xDash::Receiver>

=item L<http://xdash.jabberstudio.org>

=back

=cut
