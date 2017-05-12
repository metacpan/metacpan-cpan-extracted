package xDash::Receiver;
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

my $xDash__Receiver__object_instance;

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
    # Bypassing Net::Jabber limit on arguments in SetCallBacks()
    $xDash__Receiver__object_instance = $self;
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
	 'Can not find or open receiver configuration file.');
	exit 1
    }
    my %config = %{ &XML::Stream::XML2Config( $tree ) };
    foreach my $item ( 0..( scalar(@{$config{account}})-1 ) ){
        if ( $config{account}->[$item]->{role} =~ m/receiver/i ){
	    $self->{receiver}->{hostname}
	     = trim( $config{account}->[$item]->{hostname} );
	    check_hostname( $self->{receiver}->{hostname} );
	    $self->{receiver}->{port}
	     = trim( $config{account}->[$item]->{port} );
	    check_port( $self->{receiver}->{port} );
	    $self->{receiver}->{username}
	     = trim( $config{account}->[$item]->{username} );
	    check_username( $self->{receiver}->{username} );
	    $self->{receiver}->{password}
	     = trim( $config{account}->[$item]->{password} );
	    $self->{receiver}->{resource}
	     = trim( $config{account}->[$item]->{resource} )
	}
	if ( $config{account}->[$item]->{role} =~ m/archivist/i ){
	    $self->{archivist}->{hostname}
	     = trim( $config{account}->[$item]->{hostname} );
	    check_hostname( $self->{archivist}->{hostname} );
	    $self->{archivist}->{username}
	     = trim( $config{account}->[$item]->{username} );
	    check_username( $self->{archivist}->{username} );
	    $self->{archivist}->{resource}
	     = trim( $config{account}->[$item]->{resource} )
	}
    }

    # Receiver: JID and Fully Qualified JID
    $self->{receiver_JID} = lc( $self->{receiver}->{username}."@"
	            	     .$self->{receiver}->{hostname} );

    $self->{receiver_FQJID} = $self->{receiver_JID}."/"
		             .$self->{receiver}->{resource};
			     
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

sub SetJobCallback {

#Contract: 
#	[1] Passing the reference to the function 
#       [2] Method can either suceed (true) or everything dies...

    my $self = shift;

    $self->{jobcallback} = shift;
    unless ( defined( $self->{jobcallback} ) ){
	croak 'xDash: No function set in the SetJobCallback method'
    }
    $self->{SetJobCallback}++;
    return 1
}

sub SetJobSubject {

#Contract: 
#	[1] Passing the reference to the function 
#       [2] Method call is optional
#	[3] No usage counting due to unknown usage
# 	[4] Method suceed always

    my $self = shift;

    $self->{jobsubject} = shift;
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
    defined( $self->{SetJobCallback} ) or croak
     'xDash: Missing SetJobCallback() call prior to the Process() call';     

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
     $self->{receiver_FQJID}."($$)", 'Session start.' 
    );
    
    unless ( defined( $self->{connection_parameters} ) ){
	$self->{connection_parameters} = {}
    }
    
    $self->{connection_parameters} = {
     hostname => $self->{receiver}->{hostname},
     port => $self->{receiver}->{port},
     %{ $self->{connection_parameters} }
    };
    
    until ( defined( our $status ) ){
        $self->{connection} = new Net::Jabber::Client();
 	$status = $self->{connection}->Connect(
	 %{ $self->{connection_parameters} } );
        unless ( defined( $status ) ){
    	    $self->{ErrorLogger}->Log( 
	     $self->{receiver_FQJID}."($$)->".$self->{receiver}->{hostname}, 
	     "Jabber server is down ($!)." );
    	    select undef, undef, undef, $self->{mode}->{timeout};	    
	}
    }

    $self->{connection}->SetCallBacks( message => \&message_processing );

    my @result = $self->{connection}->AuthSend(
        username => $self->{receiver}->{username},
        password => $self->{receiver}->{password},
        resource => $self->{receiver}->{resource} );
     
    unless ( $result[0] =~ m/ok/i ){
	$self->{ErrorLogger}->Log( 
	 $self->{receiver_FQJID}."($$)->".$self->{receiver}->{hostname}, 
	 "Authorization failed $result[0] - $result[1]" );
	exit 1
    } 
    else {
	$self->{EventLogger}->Log( 
	 $self->{receiver_FQJID}."($$)->".$self->{receiver}->{hostname}, 
	 'Login ok.' )		
    }

    $self->{connection}->PresenceSend();

    while (1) {
	my $result = $self->{connection}->Process(10);
        if ( !defined( $result ) or $result eq '' ){
	    $self->{ErrorLogger}->Log( 
	     $self->{receiver_FQJID}."($$)->".$self->{receiver}->{hostname}, 
	     'The connection to the server has been lost.' );
	    exit 1
	}
    }
}

# PRIVATE METHODS (convention: small first letter)

sub message_processing {
    
    #Starting working on incomming message...
    my $self = $xDash__Receiver__object_instance;
    my $sid = shift;
    my $message = shift;
 
    # Extracting valuse from the incomming message
    my $fromJID = $message->GetFrom( 'jid' );
    my $from = lc( $fromJID->GetUserID() );
    my $server = lc( $fromJID->GetServer() );
    my $resource = $fromJID->GetResource();
    my $subject = $message->GetSubject();
    my $type = lc( $message->GetType() );
    $type or $type = 'normal';
    my $body = $message->GetBody();
    my $thread = $message->GetThread();
        
    # Is the message a valid job? 
    if ( ( $from."@".$server eq $self->{archivist_JID} )
         and ( $type =~ m/job/i ) 
	 and $message->DefinedThread() 
       ){
        $self->{MessageLogger}->Log( $$, $message->GetXML() );
	if ( $message->DefinedError() ){
	    $self->{EventLogger}->Log( 
	     $self->{archivist_FQJID}."->".$self->{receiver_FQJID}."($$)", 
	     "Message ($thread) has been discarded for errors ("
	     .$message->GetError().').' );		
	    return
	}
	else {
	    $self->{EventLogger}->Log( 
	     $self->{archivist_FQJID}."->".$self->{receiver_FQJID}."($$)", 
	     "Job ($thread) received." )
	}
    }
    else { return }  
    # The integration implementation 
    my $result = &{ $self->{jobcallback} }( $thread, $body );
    if ( defined( $result->{error_code} ) ){
        $self->{EventLogger}->Log( 
         $self->{receiver_FQJID}."($$)", 
         "Job ($thread) done, exit "
	 .$result->{error_code}.' ('.$result->{error}.').' )
    }
    else {
	$self->{EventLogger}->Log( 
	 $self->{receiver_FQJID}."($$)", "Job ($thread) done." )
    }

    #Building and sending the job report for the archivist
    my $response = new Net::Jabber::Message();
    $response->SetTo( $self->{archivist_FQJID} );
    $response->SetFrom( $self->{receiver_FQJID} );
    $response->SetType( $type );    
    $response->SetThread( $thread );
   
    defined( $self->{jobsubject} ) or $self->{jobsubject} = '';
    defined( $subject ) or $subject = '';
    $response->SetSubject( $subject.' '.$self->{jobsubject} );

    if ( defined( $result->{error_code} ) or defined( $result->{error_code} ) ){
	$response->SetErrorCode( $result->{error_code} or 1001 );
	$response->SetError( $result->{error} or 'unknown' )  
    }
    
    if ( defined( $result->{response} ) ){
	$response->SetBody( $result->{response} ) 
    }
    
    $self->{connection}->Send( $response );
    
    $self->{EventLogger}->Log( 
     $self->{receiver_FQJID}."($$)->".$self->{archivist_FQJID}, 
     "Job result ($thread) sent." );
    $self->{MessageLogger}->Log( $$, $response->GetXML() )
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
    
    if ( $username !~ /^[0-9a-zA-Z\.\-\_]+$/){
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

xDash::Receiver - Module for Receiver's client script implementation

=head1 SYNOPSIS

 #!/usr/bin/perl 
 # xDash - Asynchronus Messaging and Instant Messaging reunited

 #===
 package EventLogger;
 use base xDash::Logger::File;
 # Check the correct file path for logger (absolute path if daemon!) and
 # Uncomment 1.line and comment out 2.line below after debugging.
 # sub Open { shift->SUPER::Open( '/home/xdash/receiver/event.log' ) }
 sub Open { shift->SUPER::Open( STDOUT ) }

 package ErrorLogger;
 use base xDash::Logger::File;
 # Check the correct file path for logger (absolute path if daemon!) and
 # Uncomment 1.line and comment out 2.line below after debugging.
 # sub Open { shift->SUPER::Open( '/home/xdash/receiver/error.log' ) }
 sub Open { shift->SUPER::Open( STDERR ) }

 package MessageLogger;
 # Uncomment the 1.line and comment out 2.&3.line below after debugging.
 # use base xDash::Logger::Dumb;
 use base xDash::Logger::File;
 sub Open { shift->SUPER::Open( STDOUT ) }
 #===

 package main;
 use strict;
 use warnings;
 use xDash::Receiver;
 
 # Establish first local communication to the application receiving jobs
 # (die, if not possible) and then...

 my $receiver = new xDash::Receiver;

 # After debugging change:
 # daemon => 1, for running as daemon (daemon => 0, console usage)
 # delay => 10, for waiting 10 seconds before becomming a daemon
 # timeout => 100, for waiting 100 seconds to try to reconnect
 # Test settings:
 $receiver->SetMode( daemon=> 0, delay=> 0, timeout=> 5 );

 # Parameters from receiver.xml and default connection parameters 
 # from package Net::Jabber::Client (::Connect()) can be overriden here:
 #	hostname => string, port => integer,
 # 	connectiontype => tcpip|http, ssl => 0|1
 # Uncomment if needed, method is optional.
 # $receiver->SetConnectionParameters( ... => ... , );

 # Set Subject to everything, what helps to track better jobs
 # (below alias name from the archiv database).
 $receiver->SetJobSubject( 'receiver_1' );

 # Initiate receiver and Archivist JIDs (absolute path if daemon!)
 $receiver->SetParticipants( '/home/xdash/receiver/receiver.xml' );

 # Set job callback function for incomming jobs
 # (You habe to implement you own job handling - see some lines below...).
 $receiver->SetJobCallback( \&job_execution );

 # Go on ...
 $receiver->Process();

 #===========
 #  CUSTOM: This should be implemented as the script doing integration
 #===========
    
 sub job_execution {
    
     # Unique ID of the transported data
     my $thread = shift;  
    
     # Data transported inside of the message from Sender
     my $job = shift; 
            
     # Use for critical part of the internal script: eval{...}; if($!){...} 
     eval { 
      print "\n THIS JOB EXECUTION SCRIPT NEEDS STILL TO BE IMPLEMENTED !!!\n\n"
     };
     if ($!) { print "Ups, some error...!\n"};
    
     # If everything OK make return without any parameters or
     # only optional response of your choice:
     
     return { response => '  ~{:-)  ' };
        
     # if the were some troubles:
     return { 

 	    # Beware of jabber internal error codes: 400-409, 500-510
 	    # carried also by the coresponding jabber message tag    
 	    error_code => '1001',

 	    # Your optional error description
 	    error => 'hocus pocus',

 	    # Your optional response
 	    response => '  ~{:-(  '
 	    }
 }

=head1 DESCRIPTION

=head2 USAGE

For detailed description, how xDash framework works, please refer to 
L<http://xdash.jabberstudio.org>.

A convenient way for using the module and auto generating Receiver's script 
is the utility F<xdscr> from F<deployment> directory. For script usage read the 
F<deployment/README.txt> or usage information embedded into the script.
The synopsis above is an example of the Receiver's client script generated by the F<xdscr>.
You can find an introduction to the deployment: I<Planning and deploying xDash 
in a sandbox> at L<http://xdash.jabberstudio.org/deployment/perl>.

The module is developed in the object orientated way. You have to provide 
base classes for logging tasks, which have to implement a fixed 
set of methods (driver pattern).
You can use for logging C<xDash::Logger::File> and C<xDash::Logger::Dumb>
in a way as it is proposed in the script generated by F<xdscr> or provide your own 
implementation of the base class for C<EventLogger>, C<ErrorLogger> and C<MessageLogger>.
If you have to develop your own logger see, provided logger modules source 
code for further implementation hints. If you think, it can be reused, 
make it public over CPAN in the xDash::Logger namespace!

=head2 METHODS

=over

=item SetMode( daemon=> 0|1, delay=> $time, timeout=> $time )

daemon => 1, for running script as daemon; 
daemon => 0, console usage of the script; 
delay=> $time, for waiting $time seconds before becoming a daemon;
timeout => $time, for waiting $time seconds to try to reconnect.

=item SetConnectionParameters( hostname => $string, port => $integer,
connectiontype => tcpip|http, ssl => 0|1 )

Overrides parameters <hostname> and <port> from the XML configuration file (usually F<receiver.xml>) 
and default connection parameters from package Net::Jabber::Client (::Connect()). 
Method is optional.

=item SetJobSubject( $string )

Sets message subject to everything, what helps to track better jobs.
Method is optional.

=item SetParticipants( $XML_configuration_file )

Initiate Receiver's and Archivist's JIDs with the absolute path to the 
XML configuration file, 
usually with the name F<receiver.xml>.

=item SetJobCallback( \&job_execution )

Sets job callback function for incoming jobs
as you have to implement you own job handling in the client script.
Job thread and transported data (job) are passed as initial arguments to the registered
function during the callback. For detailed example
of the callback function see the script auto generated by the utility F<xdscr>.

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

=item L<xDash::Sender>

=item L<xDash::Archivist>

=item L<http://xdash.jabberstudio.org>

=back

=cut
