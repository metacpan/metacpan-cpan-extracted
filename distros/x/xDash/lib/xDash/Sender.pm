package xDash::Sender;
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

my $xDash__Sender__object_instance;

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
    $self->{Spool} = new Spool;
    $xDash__Sender__object_instance = $self;
    bless ( $self, $class );
    return $self
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
    $self->{SetConnectionParameters}++;
    return 1
}

sub SetMode {

#Contract: 
#	[1] Passing hash: own session ( daemon=>1 );
#	 how much delay on start in seconds (eg delay=>10 );
#	 how much timeout in seconds between reconnection ( timeout=>10 ).
#	 how much time Sender should wait for confirmation ( wait => 10)
#       [2] Method can only suceed, when:
#	 (daemon=>1 or 0) and  delay>=0 and timeout >=0.
#	[3] Default debugging values ( daemon=>0, delay=>0, timeout=>100,
#	 wait => 10 ).

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
    unless ( $self->{mode}->{delay} >= 0 ){
	croak 'xDash: Delay parameter is negative in the SetMode method'
    }
    unless ( defined( $self->{mode}->{timeout} ) ){
	croak 'xDash: Missing timeout parameter in the SetMode method'
    }
    unless ( $self->{mode}->{timeout} >= 0 ){
	croak 'xDash: Timeout parameter is negative in the SetMode method'
    }
    unless ( defined( $self->{mode}->{wait} ) ){
	croak 'xDash: Missing time parameter for waiting confirmation'
	 .' in the SetMode method'
    }
    unless ( $self->{mode}->{wait} >= 0 ){
	croak 'xDash: Time parameter for waiting confirmation is'
	.' negative in the SetMode method'
    }

    $self->{SetMode}++;
    return 1
}

sub SetSpoolCheckInterval {

#Contract: 
#	[1] If nothing in Spool time interval in seconds to wait 
#	 for the next check
#       [2] Method can only suceed, if time interval >= 1 s.

    my $self = shift;

    $self->{spool_check_interval} = shift;
    
    unless ( $self->{spool_check_interval} ){
	croak 'xDash: Missing time parameter in the SetSpoolCheckInterval method'
    }
    
    unless ( $self->{spool_check_interval} >= 1 ){
	croak 'xDash: Wrong daemon parameter in the SetMode method'
    }
    $self->{SetSpoolCheckInterval}++;
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
	 'Can not find or open sender configuration file.');
	exit 1
    }
    my %config = %{ &XML::Stream::XML2Config( $tree ) };
    foreach my $item ( 0..( scalar(@{$config{account}})-1 ) ){
        if ( $config{account}->[$item]->{role} =~ m/sender/i ){
	    $self->{sender}->{hostname}
	     = trim( $config{account}->[$item]->{hostname} );
	    check_hostname( $self->{sender}->{hostname} );
	    $self->{sender}->{port}
	     = trim( $config{account}->[$item]->{port} );
	    check_port( $self->{sender}->{port} );
	    $self->{sender}->{username}
	     = trim( $config{account}->[$item]->{username} );
	    check_username( $self->{sender}->{username} );
	    $self->{sender}->{password}
	     = trim( $config{account}->[$item]->{password} );
	    $self->{sender}->{resource}
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

    # sender: JID and Fully Qualified JID
    $self->{sender_JID} = lc( $self->{sender}->{username}."@"
	            	     .$self->{sender}->{hostname} );

    $self->{sender_FQJID} = $self->{sender_JID}."/"
		             .$self->{sender}->{resource};
			     
    # Archivist: JID and Fully Qualified JID
    $self->{archivist_JID} = lc( $self->{archivist}->{username}."@"
	                      .$self->{archivist}->{hostname} );
    $self->{archivist_FQJID} = $self->{archivist_JID}."/"
		              .$self->{archivist}->{resource};

    $self->{SetParticipants}++;
    return 1
}

sub SetRestartSpoolError {

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
    defined( $self->{SetSpoolCheckInterval} ) or croak
     'xDash: Missing SetSpoolCheckInterval() call prior to the Process() call';
    
    $self->{Spool}->SetParameters();
    
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
     $self->{sender_FQJID}."($$)", 'Session start.' );
    
    my $result = $self->{Spool}->Connect();
    if ( defined( $result->{error_code} ) ){
        $self->{ErrorLogger}->Log( 
          $self->{sender_FQJID}."($$)", 
          "Can not connect to the spool, error "
    	  .$result->{error_code}.' ('.$result->{error}.').' );
	exit 1
    }
    else {
	$self->{EventLogger}->Log( 
	  $self->{sender_FQJID}."($$)",
	  'Connection to the spool established.' )
    }

    unless ( defined( $self->{connection_parameters} ) ){
	$self->{connection_parameters} = {}
    }
    
    $self->{connection_parameters} = {
        hostname => $self->{sender}->{hostname},
        port => $self->{sender}->{port},
        %{ $self->{connection_parameters} } 
        };
    
    until ( defined( our $status ) ){
        $self->{connection} = new Net::Jabber::Client();
 	$status = $self->{connection}->Connect(
	 %{ $self->{connection_parameters} } );
        unless ( defined( $status ) ){
    	    $self->{ErrorLogger}->Log( 
	     $self->{sender_FQJID}."($$)->".$self->{sender}->{hostname}, 
	     "Jabber server is down ($!)." );
    	    select undef, undef, undef, $self->{mode}->{timeout};	    
	}
    }

    $self->{connection}->SetCallBacks( message => \&archivist_confirmation );

    my @result = $self->{connection}->AuthSend(
     username => $self->{sender}->{username},
     password => $self->{sender}->{password},
     resource => $self->{sender}->{resource}
    );
    unless ( $result[0] =~ m/ok/i ){
	$self->{ErrorLogger}->Log( 
	 $self->{sender_FQJID}."($$)->".$self->{sender}->{hostname}, 
	 "Authorization failed $result[0] - $result[1]" );
	exit 1
    } 
    else {
	$self->{EventLogger}->Log( 
	 $self->{sender_FQJID}."($$)->".$self->{sender}->{hostname}, 
	 'Login ok.' )		
    }
    

    $self->{connection}->PresenceSend();

    while (1) {  
	my @threads;
	my $result = $self->{Spool}->Check();
	if ( defined( $result->{error_code} ) ){
	    $self->{ErrorLogger}->Log( 
	     $self->{sender_FQJID}."($$)",'On spool check, error '
	     .$result->{error_code}.' ('.$result->{error}.').' );
	    if (
	     exists $self->{critical_errors}->{$result->{error_code}} ){
		exit 1
	    }
	}
	else {
	    @threads = @{ $result->{threads} };
	    foreach my $thread ( @threads ){
		# For passing working thread to the CallBack function
		$self->{thread} = $thread;
	        $result = $self->{Spool}->Fetch( $thread );
		
		my $message = new Net::Jabber::Message();
		$message->SetTo( $self->{archivist_FQJID} );
		$message->SetFrom( $self->{sender_FQJID} );
		$message->SetType( 'job' );    
		$message->SetThread( $thread );
		$message->SetSubject( $self->{jobsubject} );
    		$message->SetBody( $result->{body} );
	
		my $messageID = $self->{connection}->SendWithID ( $message );
		$self->{MessageLogger}->Log( $$, $message->GetXML() );
		# Internal function -> hardly any hint in the documentation !
		$self->{connection}->DeregisterID( 'message', $messageID );
		my $echo 
		 = $self->{connection}->Process( $self->{mode}->{wait} );
		if ( !defined( $echo ) or  $echo eq '' ) {
		    $self->{ErrorLogger}->Log( 
		     $self->{sender_FQJID}."($$)->".$self->{sender}->{hostname}, 
		     'The connection to the server has been lost.' );
		    $self->{Spool}->Disconnect();
		    exit 1
		}
		elsif (  $echo == 0 ) {
		    $self->{EventLogger}->Log( 
		     $self->{archivist_FQJID}.'->'.$self->{sender_FQJID}."($$)", 
		     "Job ($thread) not confirmed." )	
		}
	    }	    
	}
	# Pausing, if nothing in spool
	select undef, undef, undef, $self->{spool_check_interval}
	 unless threads_in_spool( @threads );
    }
}

# PRIVATE METHODS (convention: small first letter)

sub threads_in_spool {

    scalar( shift ) or return 0;
    return 1
}

sub archivist_confirmation {

    #Starting working on incomming message...
    my $self = $xDash__Sender__object_instance;
    my $sid = shift;
    my $message = shift;

    # Extracting valuse from the incomming message
    my $fromJID = $message->GetFrom( 'jid' );
    my $from = lc( $fromJID->GetUserID() );
    my $server = lc( $fromJID->GetServer() );
    my $resource = $fromJID->GetResource();
    my $subject = $message->GetSubject();
    my $type = $message->GetType();
    $type or $type = 'normal';
    my $body = $message->GetBody();
    my $thread = $message->GetThread();
    
    # Is the message a valid job? 
    if ( ( $from."@".$server eq $self->{archivist_JID} )
      and ( $type =~ m/job/i )  
      and $message->DefinedThread()  
      and ( $self->{thread} eq $thread )
      ){
        $self->{MessageLogger}->Log( $$, $message->GetXML() );
        if ( $message->DefinedError() ){
	    $self->{EventLogger}->Log( 
	     $self->{archivist_FQJID}.'->'.$self->{sender_FQJID}."($$)", 
	     "Message ($thread) has been discarded for errors ("
	     .$message->GetError().').' )
	}
	else {
	    $self->{EventLogger}->Log( 
	     $self->{archivist_FQJID}.'->'.$self->{sender_FQJID}."($$)", 
	     "Job ($thread) confirmed." );
	    $self->{Spool}->Remove( $thread )
	}
    }
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
	    croak "xDash: Port $port is not a number"
	    .' in the XML configuration file'
    }
}

1;
__END__
######################## User Documentation ##################

=pod

=head1 NAME

xDash::Sender - Module for Sender's client script implementation

=head1 SYNOPSIS

 #!/usr/bin/perl 
 # xDash - Asynchronous Messaging and Instant Messaging reunited

 #===
 package EventLogger;
 use base xDash::Logger::File;
 # Check the correct file path for logger (absolute path if daemon!) and
 # Uncomment 1.line and comment out 2.line below after debugging,
 # sub Open { shift->SUPER::Open( '/home/xdash/sender/event.log' ) }
 sub Open { shift->SUPER::Open( STDOUT ) }


 package ErrorLogger;
 use base xDash::Logger::File;
 # Check the correct file path for logger (absolute path if daemon!)  and
 # Uncomment 1.line and comment out 2.line below after debugging.
 # sub Open { shift->SUPER::Open( '/home/xdash/sender/error.log' ) }
 sub Open { shift->SUPER::Open( STDERR ) }

 package MessageLogger;
 # Uncomment the 1.line and comment out 2.&3. line below after debugging.
 # use base xDash::Logger::Dumb;
 use base xDash::Logger::File;
 sub Open { shift->SUPER::Open( STDOUT ) }

 package Spool;
 # Test settings:
 use base xDash::Spool::Dummy;
 sub SetParameters { shift->SUPER::SetParameters( 
  event_limit => 10, mean_interoccurence_time => 1 )

 # Change if you have your own implemantation or 
 # Comment out the test settings above and uncomment the 1.&3.line below.
 #use base xDash::Spool::Dir;
 # Do not forget to create spool directory (absolute path if daemon!).
 #sub SetParameters { shift->SUPER::SetDirPath( '/home/xdash/sender/spool' ) }
 #===

 package main;
 use strict;
 use warnings;
 use xDash::Sender;

 my $sender = new xDash::Sender;

 # After debugging change:
 # daemon => 1, for running as daemon (daemon => O, console usage)
 # delay => 10, for waiting 10 seconds before becomming a daemon
 # timeout => 100, for waiting 100 seconds to try to reconnect
 # wait => 10, for waiting 10 seconds on the job confirmation from Archivist
 # Test settings:
 $sender->SetMode( daemon=> 0, delay=> 0, timeout=> 5, wait => 10 );

 # Parameters from sender.xml and default connection parameters 
 # from package Net::Jabber::Client (::Connect()) can be overriden here:
 #	hostname => string, port => integer,
 # 	connectiontype => tcpip|http, ssl => 0|1
 # Uncomment if needed, method is optional.
 # $sender->SetConnectionParameters( ... => ... , );

 # Set Subject to everything, what helps to track jobs better 
 # (below alias name from the archiv database).
 $sender->SetJobSubject( 'sender_1' );

 # Initiate Sender's and Archivist's JIDs (absolute path if daemon!)
 $sender->SetParticipants( '/home/xdash/sender/sender.xml' );

 # Spool check interval all 10 seconds, change if needed.
 $sender->SetSpoolCheckInterval( 10 ); 

 # A comma separated list of spool error numbers, on which Sender's script dies 
 # and is restarted by the operating system.
 $sender->SetRestartSpoolError( 1 );

 # Go on ...
 $sender->Process();

=head1 DESCRIPTION

=head2 USAGE

For detailed description, how xDash framework works, please refer to 
L<http://xdash.jabberstudio.org>.

A convenient way for using the module and auto generating Sender's script 
is the utility F<xdscr> from F<deployment> directory. For script usage read the 
F<deployment/README.txt> or usage information embedded into the script.
The synopsis above is an example of the Sender's client script generated by the F<xdscr>.
You can find an introduction to the deployment: I<Planning and deploying xDash 
in a sandbox> at L<http://xdash.jabberstudio.org/deployment/perl>.

The module is developed in the object orientated way. You have to provide 
base classes for logging tasks and spool, which have to implement a fixed 
set of methods (driver pattern).
You can use for logging C<xDash::Logger::File> and C<xDash::Logger::Dumb> 
in a way as it is proposed in the script generated by F<xdscr> 
or provide your own implementation of the base class for 
C<EventLogger>, C<ErrorLogger> and C<MessageLogger>.
As spool you can use C<xDash::Spool::Dir> and during testing C<xDash::Spool::Dummy> 
as it is proposed in the script generated by F<xdscr>. 
If you wish something else then a file system spool, you have to 
provide for the class C<Spool> your own implementation of the base class.
If you have to develop your own logger or spool, see provided modules source 
code for further implementation hints. If you think, they can be reused, 
make them public over CPAN in the xDash::Spool and xDash::Logger namespace!

=head2 METHODS

=over

=item SetMode( daemon=> 0|1, delay=> $time, timeout=> $time, wait => $time )

daemon => 1, for running script as daemon; 
daemon => 0, console usage of the script; 
delay=> $time, for waiting $time seconds before becoming a daemon;
timeout => $time, for waiting $time seconds to try to reconnect;
wait => $time, for waiting $time seconds on the job confirmation from Archivist.

=item SetConnectionParameters( hostname => $string, port => $integer,
connectiontype => tcpip|http, ssl => 0|1 )

Overrides parameters <hostname> and <port> from the XML configuration file (usually F<sender.xml>) 
and default connection parameters from package Net::Jabber::Client (::Connect()). 
Method is optional.

=item SetJobSubject( $string )

Sets message subject to everything, what helps to track better jobs.
Method is optional.

=item SetParticipants( $XML_configuration_file )

Initiate Sender's and Archivist's JIDs with a absolut path to 
the XML configuration file, 
usually with the name F<sender.xml>.

=item SetSpoolCheckInterval( $time )

Sets spool check interval all $time seconds. 
Should be set in an individual manner according to the needs.

=item SetRestartSpoolError( $error_number_1, $error_number_2, ... )

Sets a comma separated list of spool error numbers on which 
the Sender's script dies and is restarted by the operating system.

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

=item L<xDash::Spool::Dir>

=item L<xDash::Spool::Dummy>

=item L<xDash::Receiver>

=item L<xDash::Archivist>

=item L<http://xdash.jabberstudio.org>

=back

=cut
