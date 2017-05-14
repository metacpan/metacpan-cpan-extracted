#
# $Id: Device.pm,v 1.29 2003/03/02 11:12:09 dsw Exp $
#
# COPYRIGHT AND LICENSE
# Copyright (c) 2001-2003, Juniper Networks, Inc.  
# All rights reserved.  
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 	1.	Redistributions of source code must retain the above
# copyright notice, this list of conditions and the following
# disclaimer. 
# 	2.	Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution. 
# 	3.	The name of the copyright owner may not be used to 
# endorse or promote products derived from this software without specific 
# prior written permission. 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

#
# JUNOS::Device: This package implements an interface to the JUNOScript (tm)
# XML-based API supported by Juniper Networks. Objects of this class represent
# the local side of connection to a Juniper Networks device running JUNOS,
# over which the JUNOScript protocol will be spoken. JUNOScript is
# described on http://xml.juniper.net.
#

package JUNOS::Device;

use strict;
use vars qw(@ISA $VERSION);
use JUNOS::Access;
use JUNOS::DOM::Parser;
use JUNOS::Response;
use JUNOS::Trace;
use JUNOS::Methods;
use XML::Parser;

@ISA = qw(JUNOS::Methods);
$| = 1;

use JUNOS::version;

#
# Create a new JUNOS::Device.
#
sub new
{
    my($class, %args) = @_;

    my $self = { %args };
    my $version = $self->{version} || $VERSION;

    # Initialize Methods
    JUNOS::Methods::init($version);

    # Register the default callbacks
    $self->{JUNOS_CallbackHandler} ||= \&callbackHandler;
    $self->{JUNOS_ReplyHandler} ||= \&replyHandler;
    $self->{JUNOS_CharHandler} ||= \&charHandler;

    # Mark ourselves with the proper class
    $class = ref($class) || $class;
    bless $self, $class;

    # Bring up the connection
    unless ($self->{Do_Not_Connect})  {
        return $self->connect();
    }

    $self;
}

#
# Open the connection to the JUNOScript server. This is done by the 'new'
# operator, but can be performed explicitly by hand.
#
sub connect
{
    my($self) = @_;

    $self->clear_errors() if caller() ne __PACKAGE__;

    # Have we already connected? Silently succeed
    return $self if $self->{JUNOS_Conn};

    # The access field/class/key/type is the handle we
    # use to talk to the Juniper box.

    my $conn = new JUNOS::Access($self);

    # Need better error handling here....
    unless (ref($conn)){
	$self->report_error("Could not open connection");
	return;
    }
    eval "use " . ref($conn);

    # Record the connection; connect it, mark it
    $self->{JUNOS_Conn} = $conn;
    unless ($conn->connect()) {
	$self->report_error("Could not connect");
	return;
    }
    $self->{JUNOS_Connected} = 1;

    # Kick off the XML parser
    $self->parse_start();

    trace("Trace", "starting connect::\n");

    # We need to receive the server side of the initial handshake first
    # (at least the <?xml?> part), so that we can avoid sending our
    # handshake to the ssh processes initial prompts (password/etc).
    # So we wait til we see the start of the real XML data flow....
    until ($self->{JUNOS_Active}) {
	my $in = $conn->recv();

	my $waiting = 'waiting for xml';
	if( $conn->{seen_xml} ) { $waiting = 'found xml'; }
	trace("IO", "during connect - ($waiting) input:\n\t$in\n" );

	if ($conn->{seen_xml}) {
	    # After we've seen xml, parse anything
	} elsif ($in =~ /<\s*\?/) {
	    $in =~ s/^[\d\D]*(<\s*\?)/$1/;
	    $conn->{seen_xml} = 1;
	} else {
	    if (not $conn->incoming($in) or $conn->eof) {
	        $self->report_error("initial handshake with JUNOScript server failed");
		$self->disconnect;
		return;
	    }
	    next;
	}

	if ($conn->eof) {
	    $self->parse_done($in);
	    last;
	} else {
	    $self->parse_more($in);
	}
    }

    # Send our half of the initial handshake
    my $xml_decl = '<?xml version="1.0" encoding="us-ascii"?>';
    my $junoscript = '<junoscript version="1.0" os="perl-api">';

    $conn->send($xml_decl . "\n" . $junoscript . "\n");

    if (!$conn->authenticate) {
        $self->report_error("Authentication error");
        exit(1);
    }

    return $self;
}

#
# Disconnect from the JUNOScript server. Destroy the parser and
# disconnect (and close) the connection.
#   User program should first call 'request_end_session'
#
sub disconnect
{
    my($self) = @_;

    $self->clear_errors() if caller() ne __PACKAGE__;

    my $conn = $self->{JUNOS_Conn};

    $conn->disconnect if ($conn and $self->{JUNOS_Connected});

    $self->parse_destroy();

    $self->{JUNOS_Conn} = $self->{JUNOS_Connected} = undef;
    1;
}

#
# Automatic form of destory
#
sub DESTROY
{
    my($self) = @_;

    $self->disconnect() if $self->{JUNOS_Connected};
}

#
# Send a request to the JUNOScript server and return the result.
# Since the normal DOM top level will always contain only the
# node for the rpc-reply, we assume the caller really just wants
# that node. If called in an scalar context, we only return this
# node. In an array context, we return the document and the node
# as an array.
#
sub request
{
    my $rpc;
    my($self, $request) = @_;

    $self->clear_errors() if caller() ne __PACKAGE__;

    tracept("Request");

    $self->connect() || return unless $self->{JUNOS_Connected};

    my $conn = $self->{JUNOS_Conn};

    # Catches calling 'request_end_session' twice amongst other calamities
    if ($conn->{seen_eof}) {
	$self->report_error("connection ended unexpectedly");
	return;
    }
    
    # If the caller gives us an object, turn it into a string.
    if (ref($request)) {
	$rpc = $request->toString;
    } else {
	$rpc = $request;
    }
    trace("Trace", "starting rpc; ", ref($request), "sending::\n", $rpc);

    trace("Verbose", "--- begin request---\n",
	  $rpc, ($rpc =~ /\n$/) ? "" : "\n", "--- end request ---\n");

    # Send the request to the JUNOScript server
    my $back =  $conn->send($rpc);

    # Pull data off the server until we get a complete reply (or eof).
    until ($self->{JUNOS_Reply}) {
	my $in = $conn->recv();
	trace("Trace", "during rpc; got::\n	$in");

	if ($conn->eof) {
	    # Make sure it's legit before handing it off
	    $self->parse_done($in) if (contains_end_tag($in));
	    $conn->{seen_eof} = 1;
	    last;
	} else {
	    # This is for the case when using telnet & after we're done
	    #   running 'junoscript' we get the shell char back
	    if ($self->parse_more($in))
	    {
		$conn->{seen_eof} = 1;
		last;
	    }
	}

    }

    tracept("Request");

    # Fetch the XML::DOM::Document, as saved by replyHandler()
    my $doc = $self->{JUNOS_Reply};
    trace("Trace", "reply is ", ref($doc) || "empty", "::", $doc);
    unless ($doc) {
	$self->report_error("reply is empty");
	return;
    }

    # Clear the reply
    undef $self->{JUNOS_Reply};

    # Turn the response into a JUNOS::Response, allowing us
    # to add methods on top of the DOM methods.
    my $response = JUNOS::Response->new($doc->getDocumentElement());

    trace("Verbose", "--- begin reply---\n",
	  $response->toString, ($response =~ /\n$/) ? "" : "\n",
	  "--- end reply ---\n");

    # If the caller wants an array, we give them both the document and
    # the response, which they must dispose of.
    return ($doc, $response) if wantarray;

    # Otherwise dispose of the document, which was only needed for DOM.
    if ($#$response >= 0) {
	$doc->removeChild($response);
	$response->setOwnerDocument(undef);
	$doc->dispose;
    }

    return $response;
}

#
# Perform an rpc using a raw command string. This is a mostly unsupported
# way of getting to any JUNOS command that is currently unsupported in
# JUNOScript. Caveat coder.
#
sub command
{
    tracept("Request");
    my($self, $request) = @_;
    $self->clear_errors() if caller() ne __PACKAGE__;

    my $rpc = "<rpc><command>" . $request . "</command></rpc>\n";
    $self->request($rpc);
}

# These callback handlers are called by the parser to let
# us know important things about the connection.

#
# unsupported.callback
#
sub callbackHandler
{
    my($self, $parser) = @_;

    $self->report_error("unsupported callback");
}

#
# A reply is complete; record it for the main loop above.
#
sub replyHandler
{
    tracept("Reply");

    my($self, $parser, $reply) = @_;

    $self->{JUNOS_Reply} = $reply;
}

#
# Raw character data is available that the parser does not want. This is
# normally because the connection is not yet in XML mode. Hand the data
# off to the access method so that it can deal with it.
#
sub charHandler
{
    my($self, $parser, $data) = @_;

    my $conn = $self->{JUNOS_Conn};
    $conn->incoming($data);
}

#
# These functions are wrappers for the parser
#

#
# Start the parser: create an XML::Parser with style==JUNOS, pull
# a parser instance off this expat-parser-instance, and make
# the world even more confusing by making these objects refer
# to each other.
#
sub parse_start
{
    tracept("Parse");
    my($self, %args) = @_;

    $args{Style} = "JUNOS::DOM::Parser";
    #$args{Style} = "Debug";

    my $expat = new XML::Parser(%args);
    $self->{JUNOS_Expat} = $expat;

    my $parser = $expat->parse_start();
    $parser->{JUNOS_Device} = $self;
    $self->{JUNOS_Parser} = $parser;
}

sub contains_end_tag
{
    $_[0] =~ m#</junoscript>#m;
}

#
# Parse some more input: toss the given input data to the parser.
#
sub parse_more
{
    tracept("Parse");
    my($self, $input) = @_;

    my $done = 0;

    # Get rid of any xtra stuff after closing tag if it's there
    $done = 1 if ($input =~ s#</junoscript>(.*)$#</junoscript>#ms);

    $self->{sofar} .= $input;
    my $parser = $self->{JUNOS_Parser};

    while ($input =~ /<\/xnm:error>(?:\s*<output>)/) {
      # Add any 'output' tags to the <xnm:error> mix
      $input =~ s/(.*?)(<\/xnm:error>)(?:\s*(<output>.*?<\/output>\s*))(.*)/$1$3$2$4/s;
    }

    # Catch bad XML
    eval {
	$parser->parse_more($input);
    };
    if ($@) {
        my($col) = $@ =~ /column (\d+)/;
	my($error) = $@ =~ /^(.*?)\s+at/m;
	my $mismatched = $error =~ /mismatched/;

	# Check out the previous 50 characters
	my $bad_area = substr $self->{sofar}, $col-50;

	print "Something bad has happened - XML got garbled.\n";
	print "Here's what it did not like:\n\t",$bad_area,"\n";

	print "The error was: $error\n";
	print "This tag doesn't has a start tag!\n" if $mismatched;
		      
	die "Parse failure";
    }

    $parser->parse_done if ($done);
    $done;
}

#
# Mark the end of parsing, normally caused by end-of-file
#
sub parse_done
{
    tracept("Parse");
    my($self, $input) = @_;

    my $done = $self->parse_more($input) if ($input);
    return if $done;

    my $parser = $self->{JUNOS_Parser};
    $parser->parse_done;
}

#
# Destory the parser and clean up the self-referential nature of the objects.
sub parse_destroy
{
    my ($self) = @_;
    my $parser = $self->{JUNOS_Parser};
    $parser->{JUNOS_Device} = undef;
    $self->{JUNOS_Parser} = undef;
    undef $parser;
}

#
# These functions interact with the DOM parser. In order to pull
# complete DOM objects from the DOM parser, we need to reinitialize
# it before each <rpc-reply> and terminate it after each </rpc-reply>.
#

#
# Open a reply by reinitializing the DOM parser, passing it
# the information we learned at connection startup.
#
sub openReply
{
    tracept("Reply");
    my($self, $parser) = @_;

    XML::Parser::Dom::Init($parser);
    XML::Parser::Dom::XMLDecl($parser, $self->{XMLDecl_Version},
	$self->{XMLDecl_Encoding}, $self->{XMLDecl_Standalone});
    $self->{JUNOS_expect_1st_element} = 1;
    undef $self->{tag};
}

#
# Close a reply by terminating the parser and passing back the DOM
# document that it returned to us.
sub closeReply
{
    tracept("Reply");
    my($self, $parser) = @_;

    my $reply = XML::Parser::Dom::Final($parser);

    return $reply;
}

sub clear_errors
{
    my($self) = @_;
    $self->{Errors} = [];
    return 1;
}

sub report_error
{
    my($self, $error) = @_;
    clear_errors unless $self->{Errors};
    push(@{$self->{Errors}}, $error);
    trace("Always", "ERROR[" . scalar(@{$self->{Errors}}) . "]: $error\n");
}

sub getErrors
{
    my($self) = @_;
    return $self->{Errors};
}

sub getFirstError
{
    my($self) = @_;
    return $self->{Errors}[0] if $self->{Errors};
    return;
}

1;

__END__

=head1 NAME

JUNOS::Device - Implements a remote JUNOScript device

=head1 SYNOPSIS

Here is example that makes a telnet connection to router11, then updates the router11's
configuration with the configuration from $xmlfile.  It also deals with
error conditions and gracefully shuts down the telnet session.

    use JUNOS::Device;

    sub graceful_shutdown
    {
        my ($jnx, $req, $state, $success) = @_;
    
        if ($state >= STATE_CONFIG_LOADED) {
            print "Rolling back configuration ...\n";
            $jnx->load_configuration(rollback => 0);
        }

        if ($state >= STATE_LOCKED) {
            print "Unlocking configuration database ...\n";
            $jnx->unlock_configuration();
        }
 
        if ($state >= STATE_CONNECTED) {
            print "Disconnecting from the router ...\n";
            $jnx->request_end_session();
            $jnx->disconnect();
        }

        if ($success) {
            die "REQUEST $req SUCCEEDED\n";
        } else {
            die "REQUEST $req FAILED\n";
        }
    }

    $jnx = new JUNOS::Device(hostname => "router11",
                             login => "johndoe",
                             password => "secret",
                             access => "telnet");

    unless ( ref $jnx ) {
        die "ERROR: can't connect to $deviceinfo{hostname}.\n";
    }

    print "Locking configuration database ...\n";

    my $res = $jnx->lock_configuration();

    my $err = $res->getFirstError();

    if ($err) {
        print "ERROR: $deviceinfo{hostname}: can't lock configuration.  Reason: $err->{message}.\n";
        graceful_shutdown($jnx, $xmlfile, STATE_CONNECTED, REPORT_FAILURE);
    }

    #
    # Load the configuration
    #
    print "Loading configuration from $xmlfile ...\n";
    if (! -f $xmlfile) {
        print "ERROR: Cannot load configuration in $xmlfile\n";
        graceful_shutdown($jnx, $xmlfile, STATE_LOCKED, REPORT_FAILURE);
    }

    my $parser = new XML::DOM::Parser;
    my $doc = $parser->parsefile($xmlfile);
    unless ( ref $doc ) {
        print "ERROR: Cannot parse $xmlfile, check to make sure the XML data is well-formed\n";
        graceful_shutdown($jnx, $xmlfile, STATE_LOCKED, REPORT_FAILURE);
    }
    $res = $jnx->load_configuration(configuration => $doc);
    unless ( ref $res ) {
        print "ERROR: can't load the configuration from $xmlfile\n";
        graceful_shutdown($jnx, $xmlfile, STATE_LOCKED, REPORT_FAILURE);
    }
    $err = $res->getFirstError();
    if ($err) {
        print "ERROR: can't load the configuration from $xmlfile.  Reason: $err->{message}\n";
        graceful_shutdown($jnx, $xmlfile, STATE_CONFIG_LOADED, REPORT_FAILURE);
    }

Here is another example.  It retrieves 'show chassis hardware' information and transforms the input with XSLT.

    # connect TO the JUNOScript server
    $jnx = new JUNOS::Device(hostname => "router11",
                             login => "johndoe",
                             password => "secret",
                             access => "telnet");
    unless ( ref $jnx ) {
        die "ERROR: $deviceinfo{hostname}: can't connect.\n";
    }

    # send the command and receive a XML::DOM object
    my $res = $jnx->get_chassis_inventory(detail => 1);
    unless ( ref $res ) { 
        die "ERROR: $deviceinfo{hostname}: can't execute command $query.\n";   
    }

    # Check and see if there were any errors in executing the command.
    # If all is well, output the response using XSLT.
    my $err = $res->getFirstError();
    if ($err) {
        print STDERR "ERROR: $deviceinfo{'hostname'} - ", $err->{message}, "\n";
    } else {
        # 
        # Now do the transformation using XSLT.
        #
        my $xmlfile = "$deviceinfo{hostname}.xml";
	$res->printToFile($xmlfile);
        my $nm = $res->translateXSLtoRelease('xmlns:lc', $xslfile, "$xslfile.tmp");
        if ($nm) {
            my $command = "xsltproc $nm $deviceinfo{hostname}.xml";
            system($command);
        } else {
            print STDERR "ERROR: Invalid XSL File $xslfile\n";
        }
    }
    
    # always close the connection
    $jnx->request_end_session();
    $jnx->disconnect();


=head1 DESCRIPTION

This module implements an object oriented interface to the JUNOScript (tm)
XML-based API supported by Juniper Networks. Objects of this class represent
the local side of connection to a Juniper Networks device running JUNOS,
over which the JUNOScript protocol will be spoken. JUNOScript is
described in detail in the JUNOScript API Guide and Reference.

=head1 CONSTRUCTOR

new(%ARGS)

The constructor accepts a hash table %ARGS containing the following keys:

    hostname
        Name of Juniper box to connect to.

    login
        Username to log into box as.

    password
        Password for login username.

    access
        Access method - can be 'telnet' or 'ssh' or 'ssl'.

    Do_Not_Connect
        if set to true a connection to a Juniper box
        will not be establish upon object creation.  You then
        must call the 'connect' function to explicitly create the
        connection

    namespace-action
 	if you don't want to deal with namespace, just set this
  	to either 'remove-namespace' or 'update-namespace'. This is 
	handy when you don't want to care about declaring the XML namespace
	in your XSL file(s).  'remove-namespace' means removing all 
	namespace declarations and schemaLocation from the the responses.  
	'update-namespace' means remove all namespaces and replace 
	schemaLocation with noNamespaceSchemaLocation.

Additional keys specific to the access method are processed by the access method object (e.g. JUNOS::Access::telnet).  See the perldoc of the access method class for the definition of these additional keys.

=head1 METHODS

command($COMMAND)

Send the raw command string from $COMMAND to the remote Juniper box.
This is a 'mostly unsupported' way of getting to any JUNOS
command that is currently unsupported in JUNOScript.
Caveat Coder.

connect() 

typically called by the constructor.  If you set
'Do_Not_Connect' to be true you must call this function
yourself.

disconnect()

Disconnects from a JUNOScript server & performs
other clean-up related to this conneciton.  This function
will also be called if your JUNOS::Device object goes out
of scope or is undef'ed.

getErrors()
getFirstError()

getErrors() and getFirstError() are available for the application to 
retrieve all of the errors occured within the last JUNOS::Device method 
invocation.  The application may wish to print these error messages in 
log file or display on a different error window.  getErrors() returns
a reference to all the errors and getFirstError() returns the earliest
error that triggered the failure.  These methods can be called after
a JUNOS::Device method has failed.

Note: These errors normally go to the standard output unless
the Always category is in JUNOS::Trace is disabled.  Unless you want
the errors to go someplace other than the standard output, 
you don't need to call these methods.

An example of using getFirstError:

unless($jnx->connect()) {
    my $error = $jnx->getFirstError();
    print ERRORLOG ("ERROR: $error\n");
}

An example of using getErrors:

unless($jnx->connect()) {
    my @errors = @{$jnx->getErrors()};
    for my $error (@errors) {
        print ERRORLOG ("ERROR: $error\n");
    }
}

request($REQUEST)

You should call <JUNOScript command> functions - which
eventually utilize this function - you should not call this
directly!
            
Sends a request in $REQUEST to a Juniper box and returns the result.
In a scalar context a JUNOS::Response object is returned.
In an array context an array consisting of the 
XML::DOM::Document object and the raw JUNOS::Response 
object containing the enclosing <rpc-reply> tags.
The parameter is the name of the JUNOScript function to be
called on the remote Juniper box.

<JUNOScript command>

You may call any JUNOScript command via the JUNOS::Device
Handle.  See 'request' function for return values.
    
These methods are available when connecting to a JUNOS 5.1 router.
they can take two types of arguments or zero arguments:

1. 'toggle' - argument is present or not.
    For example the 'extensive' argument to the 'get_interface_information' 
    method: 
        get_interface_information(extensive => 1);

2. 'string' - a string argument
    For example the 'slot' argument to the 'get_pic_information' method: 
        get_pic_information(slot => "2");

    method is followed by a list of accepted arguments and their types
    if it has any.

    get_accounting_profile_information
	profile => STRING

    get_accounting_record_information
	profile => STRING
	since => STRING
	utc_timestamp => TOGGLE

    get_chassis_inventory
	detail => TOGGLE
	extensive => TOGGLE

    get_environment_information

    get_feb_information

    get_firmware_information

    get_fpc_information

    get_interface_information
	brief => TOGGLE
	destination_class => STRING
	detail => TOGGLE
	extensive => TOGGLE
	interface_name => STRING
	media => TOGGLE
	queue => TOGGLE
	snmp_index => STRING
	statistics => TOGGLE
	terse => TOGGLE

    get_pic_information
	slot => STRING

    get_route_engine_information
	slot => STRING

    get_scb_information

    get_sfm_information

    get_snmp_information

    get_ssb_information
	slot => STRING

    request_halt
	at => STRING
	in => STRING
	media => STRING
	message => STRING

    request_reboot
	at => STRING
	in => STRING
	media => STRING
	message => STRING

    get_bgp_group_information
	group_name => STRING

    get_bgp_neighbor_information
	neighbor_address => STRING

    get_bgp_summary_information

    get_instance_information
	name => STRING

    get_instance_summary_information

    get_isis_adjacency_information
	brief => STRING
	detail => STRING
	instance => STRING
	system_id => STRING

    get_isis_database_information
	brief => STRING
	detail => STRING
	extensive => STRING
	instance => STRING
	system_id => STRING

    get_isis_interface_information
	brief => STRING
	detail => STRING
	instance => STRING
	interface_name => STRING

    get_isis_route_information
	instance => STRING

    get_isis_spf_information

    get_isis_statistics_information
	instance => STRING

    get_l2vpn_connection_information
	brief => STRING
	down => STRING
	extensive => STRING
	history => STRING
	instance => STRING
	local_site => STRING
	remote_site => STRING
	status => STRING
	up => STRING
	up_down => STRING

    get_mpls_admin_group_information

    get_mpls_cspf_information

    get_mpls_interface_information

    get_mpls_lsp_information
	brief => STRING
	detail => STRING
	down => STRING
	egress => STRING
	extensive => STRING
	ingress => STRING
	name => STRING
	statistics => STRING
	terse => STRING
	transit => STRING
	up => STRING

    get_mpls_path_information
	path => STRING

    get_ospf_database_information
	advertising_router => STRING
	area => STRING
	asbrsummary => STRING
	brief => STRING
	detail => STRING
	extensive => STRING
	extern => STRING
	instance => STRING
	lsa_id => STRING
	netsummary => STRING
	network => STRING
	nssa => STRING
	router => STRING
	summary => STRING

    get_ospf_interface_information
	brief => STRING
	detail => STRING
	extensive => STRING
	instance => STRING
	interface_name => STRING

    get_ospf_io_statistics_information

    get_ospf_log_information
	instance => STRING

    get_ospf_neighbor_information
	brief => STRING
	detail => STRING
	extensive => STRING
	instance => STRING
	neighbor => STRING

    get_ospf_route_information
	abr => STRING
	asbr => STRING
	detail => STRING
	extern => STRING
	instance => STRING
	inter => STRING
	intra => STRING

    get_ospf_statistics_information
	instance => STRING

    get_rsvp_interface_information
	brief => STRING
	detail => STRING

    get_rsvp_neighbor_information

    get_rsvp_session_information
	brief => STRING
	detail => STRING
	down => STRING
	egress => STRING
	ingress => STRING
	interface => STRING
	lsp => STRING
	name => STRING
	nolsp => STRING
	terse => STRING
	transit => STRING
	up => STRING

    get_rsvp_statistics_information

    get_rsvp_version_information

    get_ted_database_information
	brief => STRING
	detail => STRING
	extensive => STRING
	system_id => STRING

    get_ted_link_information
	brief => STRING
	detail => STRING

    get_ted_protocol_information
	brief => STRING
	detail => STRING

    request_end_session

    request_package_add
	delay_restart => TOGGLE
	force => TOGGLE
	no_copy => TOGGLE
	package_name => STRING
	reboot => TOGGLE

    request_package_delete
	force => TOGGLE
	package_name => STRING

=head1 SEE ALSO
        
    JUNOS::Response
    XML::DOM
    JUNOS::Trace
    JUNOScript API Guide (available at www.juniper.net)
    JUNOScript API Reference (available at www.juniper.net)

=head1 AUTHOR

Juniper Junoscript Perl Team, send bug reports, hints, tips,
and suggestions to support@juniper.net.

=head1 COPYRIGHT

Copyright (c) 2001-2002 Juniper Networks, Inc.
All rights reserved.
