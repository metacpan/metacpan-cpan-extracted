#   -*- perl -*-
#
#
#   pRPC - Perl RPC, package for writing simple, RPC like clients and
#       servers
#
#   RPC::pServer.pm is the module for writing the pRPC server.
#
#
#   Copyright (c) 1997  Jochen Wiedmann
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   Author: Jochen Wiedmann
#           Am Eisteich 9
#           72555 Metzingen
#           Germany
# 
#           Email: wiedmann@neckar-alb.de
#           Phone: +49 7123 14881
#
#
#   $Id: pServer.pm,v 0.1001 1997/09/14 22:53:27 joe Exp $
#
package RPC::pServer;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use RPC::pClient;

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader RPC::pClient);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.1005';



# Preloaded methods go here.

use POSIX();
use Sys::Syslog();
use IO::Socket();
use Socket();
use Storable();


############################################################################
#
#   Name:    _ReadConfigFile
#
#   Purpose: Reads a server configuration file
#
#   Inputs:  file name
#
#   Returns: a reference to a list of clients, if successfull; the
#            reference will additionally be stored in the variable
#            $RPC::pServer::configFile for later use. 'undef'
#            will be returned in case of errors.
#
############################################################################

sub Log($$$@) {
    my($self, $level, $msg, @args) = @_;
    if (!$self->{'stderr'}) {
	Sys::Syslog::syslog($level, $msg, @args);
    } else {
	print STDERR "$msg\n";
    }
}
my $logClass = "RPC::pServer";


sub _ReadConfigFile ($) {
    my($file) = @_;
    my($line, $configFile, $client, $mask, $lineNum);

    if(defined($RPC::pServer::configFile)) {
	return $RPC::pServer::configFile;
    }

    $configFile = [];
    if (!open(FILE, "<$file")) {
	return "Cannot read config file $file: $!";
    }

    $lineNum = 0;
    while (defined($line = <FILE>)) {
	++$lineNum;
	$line =~ s/\#.*//;   # Comments are allowed
	if ($line =~ /^\s*accept\s+(\S+)\s*$/i) {
	    $mask = $1;
	    $client = { 'mask' => $mask, 'accept' => 1 };
	    push(@$configFile, $client);
	} elsif ($line =~ /^\s*deny\s+(\S+)\s*$/i) {
	    $mask = $1;
	    $client = { 'mask' => $mask, 'accept' => 0 };
	    push(@$configFile, $client);
	} elsif ($line =~ /^\s*(\S+)\s+(.*\S)\s*$/) {
	    if (defined($client)) {
		$client->{$1} = $2;
	    } else {
		close(FILE);
		return "Cannot parse line $lineNum of config file $file.";
	    }
	} elsif ($line !~ /^\s*$/) {
	    close(FILE);
	    return "Cannot parse line $lineNum of config file $file.";
	}
    }

    close(FILE);

    $RPC::pServer::configFile = $configFile;
}


############################################################################
#
#   Name:    new
#
#   Purpose: Constructor of the RPC::pServer module
#
#   Inputs:  Hash list of attributes; see RPC::pServer(3)
#
#   Returns: connection object or 'undef' in case of errors
#
############################################################################

sub new ($@) {
    my ($proto) = shift;
    my ($class) = ref($proto) || $proto;
    my ($self) = {@_};
    my ($sock);

    bless($self, $class);

    # Read the configuration file, if not already done.
    if (defined($self->{'configFile'})) {
	my ($result) = _ReadConfigFile($self->{'configFile'});
	if (!ref($result)) {
	    $self->Log('err', $result);
	    return $result;
	}
	$self->{'authorizedClients'} = $result;
    }

    if (!defined($self->{'inetd'})) {
	#   Non-Inetd-Server
	$sock = $self->{'sock'}->accept();
	if (!defined($sock)) {
	    my $msg = "Cannot accept: $?";
	    $self->Log('err', $msg);
	    return $msg;
	}
    } else {
	#   Inetd based server; need to work out how to create a
	#   IO::socket object for that
	$sock = $self->{'sock'};
    }

    #
    #   Check whether the client is authorized to connect
    #
    my ($name, $aliases, $addrtype, $length, @addrs)
	= gethostbyaddr($sock->peeraddr, &Socket::AF_INET);
    my $client;
    foreach $client (@{$self->{'authorizedClients'}}) {
	my($alias, $found, $mask);
	my (@cfl) = (%$client);
	$mask = $client->{'mask'};
	$found = 0;
	if ($sock->peerhost =~ /$mask/  ||
	    $name =~ /$mask/) {
	    $found = 1;
	}
	if (!$found) {
	    foreach $alias (split(/ /, $aliases)) {
		if ($alias =~ /$mask/) {
		    $found = 1;
		    last;
		}
	    }
	}
	if (!$found) {
	    my $addr;
	    foreach $addr (@addrs) {
		if (Socket::inet_ntoa($addr) =~ /$mask/) {
		    $found = 1;
		    last;
		}
	    }
	}
	if ($found) {
	    my ($class, $key);
	    if (!$client->{'accept'}) {
		my $msg = sprintf("Access not permitted from %s, %s",
				  $sock->sockhost, $sock->sockport);
		$self->Log('err', $msg);
		return $msg;
	    }
	    $self->{'client'} = $client;
	    if (defined($key = $client->{'key'})  &&
		defined($class = $client->{'encryption'})) {
		my ($module);
		if (!defined($module = $client->{'encryptModule'})) {
		    $module = $class;
		}
		($self->{'cipher'}) = eval qq{
		    use $module;
		    new $class(pack("H*", \$key));
		};
		$self->Log('debug', "Using encryption: " . $self->{'cipher'});

		if ($@) {
		    my $msg = "Cannot create cipher object: $@";
		    $self->Log('err', $msg);
		    return $msg;
		}
	    }
	    last;
	}
    }
    if ($self->{'configFile'}  &&  !$self->{'client'}) {
	my $msg = sprintf("Access not permitted from %s, %s",
			  $sock->sockhost, $sock->sockport);
	$self->Log('err', $msg);
	return $msg;
    }

    $self->Log('notice', sprintf("Accepting connect from %s, port %s",
				 $sock->sockhost, $sock->sockport));

    #
    #   Ok, the client is allowed to connect. Create Storable
    #   objects and wait for the login message.
    #
    if ($self->_HaveOoStorable) {
	$self->{'io'} = Storable->new('file' => *{$sock}{IO},
				      'crypt' => $self->{'cipher'},
				      'netorder' => 1,
				      'forgive_me' => 1);
	if (!defined($self->{'io'})) {
	    my $msg = "Cannot create Storable object for read: $!";
	    $self->Log('err', $msg);
	    return $msg;
	}
    } else {
	$self->{'file'} = $sock;
    }

    if ($self->{'debug'}) {
	$self->Log('debug', "$logClass: Waiting for client to log in.");
    }

    my $loginMsg;
    $loginMsg = $self->_Retrieve();
    if (!defined($loginMsg)) {
	my $msg = "Error while logging in: " . $self->error;
	$self->Log('err', $msg);
	return $msg;
    }
    if (ref($loginMsg) ne 'ARRAY') {
	my $msg = "Error while logging in: Expected array.";
	$self->Log('err', $msg);
	return $msg;
    }

    ($self->{'application'}, $self->{'version'}, $self->{'user'},
     $self->{'password'}) = @$loginMsg;
    if ($self->{'debug'}) {
	$self->Log('debug', "$logClass: Client logs in: "
		            . $self->{'application'}
		            . " " . $self->{'version'} . " "
		            . ($self->{'user'} || ''));
    }
    if (!defined($self->{'application'})  ||
	!defined($self->{'version'})) {
	my $msg = "Protocol error while logging in";
	$self->Log('err', $msg);
	return $msg;
    }

    $self->{'sock'} = $sock;
    $self;
}


############################################################################
#
#   Name:    Accept, Deny
#
#   Purpose: Methods for accepting or denying a connection
#
#   Inputs:  $con - connection object
#            $msg - Message being sent to the client
#
#   Returns: TRUE for succcess, FALSE otherwise; you might consult
#            the method $con->error in that case.
#
############################################################################

sub Accept($$) {
    my ($self, $msg) = @_;
    $self->Log('debug', "Accepting client.\n");
    $self->_Store([1, $msg]);
}

sub Deny($$) {
    my ($self, $msg) = @_;
    $self->Log('debug', "Denying client.\n");
    $self->_Store([0, $msg]);
}

sub error ($) { my $self = shift; $self->{'error'}; }


############################################################################
#
#   Name:    Loop
#
#   Purpose: Process client requests
#
#   Inputs:  $con - connection object
#
#   Returns: TRUE, if a client request was successfully processed,
#            FALSE otherwise in which case $con->error is set
#
############################################################################

sub Loop ($) {
    my($self) = shift;
    my($command, $commandRef);
    my(@result);

    if ($self->{'sock'}->eof()) {
	$self->{'error'} = "Cannot talk to Client: EOF";
	$self->Log('err', $self->error);
	return 0;
    }

    my $msg;
    $msg = $self->_Retrieve();
    if (!defined($msg)) {
	$self->{'error'} = "Error while reading client request: "
	    . $self->{'error'};
	$self->Log('err', $self->error);
	return 0;
    }
    my $ok = 0;
    if (ref($msg) ne 'ARRAY') {
	$self->{'error'} = "Error in request data: Expected array.";
    } elsif (!defined($command = shift @$msg)) {
	$self->{'error'} = "Error in request data: Missing command";
    } elsif (!defined($commandRef = $self->{'funcTable'}->{$command})) {
	$self->{'error'} = "Unknown command ($command)";
    } else {
	my($code);
	$code = $commandRef->{'code'};
	($ok, @result) = eval '&$code($self, $commandRef, @$msg)';
	if ($@ ne '') {
	    $ok = 0;
	    $self->{'error'} = "Function evaluation failed: $@";
	} else {
	    if (!defined($ok)) {
		$ok = 0;
	    }
	    if (!$ok) {
		if (@result) {
		    $self->{'error'} = shift @result;
		} else {
		    $self->{'error'} = "Unknown error";
		}
	    } else {
		$self->{'error'} = '';
	    }
	}	
    }

    if ($self->error) {
	$self->Log('err', "Client Request -> error " . $self->error);
	$ok = 0;
	@result = ($self->error);
    } elsif ($self->{'debug'}) {
	$self->Log('debug', "$logClass: Client requested $command -> ok");
    }

    if (scalar(@result) == 1  &&  !defined($result[0])) {
	# If we'd simply use @result now, this would give a warning
	# "Use of uninitialized value"; even worse, the returned
	# result would differ from the expected.
	if (!$self->_Store([$ok, undef])) {
	    my $error = $self->error;
	    $self->Log('err', "Error while replying client: $error");
	    $ok = 0;
	}
    } else {
	if (!$self->_Store([$ok, @result])) {
	    my $error = $self->error;
	    $self->Log('err', "Error while replying client: $error");
	    $ok = 0;
	}
    }

    return $ok;
}


############################################################################
#
#   Name:    Encrypt
#
#   Purpose: Get or set the current encryption mode
#
#   Inputs:  $self - client object
#            $crypt - encryption object
#
#   Returns: current encryption object; 'undef' for no encryption
#
############################################################################

sub Encrypt ($;$) {
    my ($self, $crypt) = @_;
    if (@_ == 2) {
	if ($self->_HaveOoStorable) {
	    $self->{'io'}->{'crypt'} = $crypt;
	} else {
	    $self->{'cipher'} = $crypt;
	}
    }
    $self->_HaveOoStorable ? $self->{'io'}->{'crypt'} : $self->{'cipher'};
}


############################################################################
#
#   Name:    NewHandle, UseHandle, StoreHandle, CallMethod,
#            DestroyHandle
#
#   Purpose: Support functions for working with objects
#
#   Inputs:  $con - server object
#            $ref - hash reference to the entry in $con's function
#                 table being currently executed; this *must* have
#                 an attribute 'handles' which should be a reference
#                 to a hash array which is part of the server
#                 functions local variables; so you are safe in
#                 a multithreaded environment.
#            other input, depending on the method
#
#   Returns: All functions guarantee that $con->error is empty in
#            case of success and nonempty otherwise. StoreHandle
#            guarantees to return 'undef' for error and a
#            defined() value for success; so does UseHandle, at
#            least as long as you don't feed 'undef' objects
#            into 'StoreHandle'. This is guaranteed by 'NewHandle',
#            which satisfies the same behaviour. The results of
#            CallMethod() are unpredictable.
#
############################################################################

sub UseHandle ($$$) {
    my ($con, $ref, $objectHandle) = @_;
    my ($hRef);
    if (!defined($hRef = $ref->{'handles'})  ||  ref($hRef) ne 'HASH') {
	$con->{'error'} = "Mising 'handles' attribute on server";
	return;
    }
    if (!defined($objectHandle)  ||  !exists($hRef->{$objectHandle})) {
	$con->{'error'} = "Unknown object handle";
	return;
    }
    $con->{'error'} = '';
    $hRef->{$objectHandle};
}

sub DestroyHandle ($$$) {
    my ($con, $ref, $objectHandle) = @_;
    my ($hRef);
    if (!defined($hRef = $ref->{'handles'})  ||  ref($hRef) ne 'HASH') {
	$con->{'error'} = "Mising 'handles' attribute on server";
	return 0;
    }
    if (!exists($hRef->{$objectHandle})) {
	$con->{'error'} = "Unknown object handle";
	return 0;
    }
    delete $hRef->{$objectHandle};
    1;
}

sub CallMethod ($$@) {
    my ($con, $ref, $objectHandle, $method, @arg) = @_;
    my ($objectRef) = UseHandle($con, $ref, $objectHandle);
    my (@result);

    if (!defined($objectRef)) {
	$con->{'error'} = "Illegal object handle";
	return(0, $con->error);
    }
    if ($method eq 'DESTROY') {
	if (!DestroyHandle($con, $ref, $objectHandle)) {
	    return (0, $con->error);
	}
    } else {
	if (!$objectRef->can($method)) {
	    $con->{'error'} = "Unknown method: $method";
	    return (0, $con->error);
	}
	(@result) = eval '$objectRef->' . $method . '(@arg)';
	if ($@) {
	    $con->{'error'} = "Error while executing method: $@";
	    return (0, $con->error);
	}
    }
    $con->{'error'} = '';
    (1, @result);
}

sub StoreHandle ($$$) {
    my ($con, $ref, $objectRef) = @_;
    my ($hRef);
    if (!defined($hRef = $ref->{'handles'})  ||  ref($hRef) ne 'HASH') {
	$con->{'error'} = "Mising 'handles' attribute on server";
	return;
    }
    my ($num) = exists($hRef->{'num'}) ? $hRef->{'num'} : 0;
    $hRef->{'num'}  = ++$num;
    $hRef->{$num} = $objectRef;
    $con->{'error'} = '';
    $num;
}

sub NewHandle ($$$@) {
    my ($con, $ref, $classWanted, @arg) = @_;
    my ($lRef) = $ref->{'classes'};

    #  Check, if access to this class is permitted
    my $class;
    foreach $class (@$lRef) {
	if ($class eq $classWanted) {
	    # It is, create the method
	    my $command = $class . '->new(@arg)';
	    my ($object) = eval $command;
	    if ($@) {
		$con->{'error'} = $@;
		return (0, $@);
	    }
	    if (!defined($object)) {
		$con->{'error'} = ' Failed to create object, unknown error';
		return (0, $con->error);
	    }
	    my $handle = StoreHandle($con, $ref, $object);
	    if ($con->error  ||  !defined($handle)) {
		return(0, $con->error);
	    }
	    return (1, $handle);
	}
    }
    $con->{'error'} = "Not permitted to create objects of class $classWanted";
    (0, $con->{'error'});
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

RPC::pServer - Perl extension for writing pRPC servers

=head1 SYNOPSIS

  use RPC::pServer;
 
  $sock = IO::Socket::INET->new('LocalPort' => 9000,
				'Proto' => 'tcp',
				'Listen' = 5,
				'Reuse' => 1);

  $connection = new RPC::pServer('sock' => $sock,
				      'configFile' => $file,
				      'funcTable' => $funcTableRef,
				      # other attributes #
				     );

  while ($running) {
      $connection->Loop();
      if ($connection->error) {
	  # Do something
      }
  }

=head1 DESCRIPTION

pRPC (Perl RPC) is a package that simplifies the writing of Perl based
client/server applications. RPC::pServer is the package used on the
server side, and you guess what Net::pRPC::Client is for. See
L<Net::pRPC::Client(3)> for this part.

pRPC works by defining a set of of functions that may be executed by
the client. For example, the server might offer a function "multiply"
to the client. Now a function call

    @result = $con->Call('multiply', $a, $b);

on the client will be mapped to a corresponding call

    multiply($con, $data, $a, $b);

on the server. (See the I<funcTable> description below for
$data.) The function call's result will be returned to the
client and stored in the array @result. Simple, eh? :-)

=head2 Server methods

=over 4

=item new

The server constructor. Unlike the usual constructors, this one
will in general not return immediately, at least not for a
server running as a daemon. Instead it will return if a
connection is established with a connection object as result.
The result will be an error string or the connection object,
thus you will typically do a

    $con = RPC::pServer->new ( ...);
    if (!ref($con)) {
        print "Error $con.\n";
    } else {
        # Accept connection
        ...
    }

=item Accept

=item Deny

After a connection is established, the server should call either of
these methods. If he calls Accept(), he should continue with calling
the Loop() method for processing the clients requests.

=item Loop

When a connection is established, the Loop method must be called. It
will process the client's requests. If Loop() returns FALSE, an error
occurred. It is the main programs task to decide what to do in that
case.

=item Encrypt

This method can be used to get or set the I<cipher> attribute, thus
the encryption mode. If the method is passed an argument, the argument
will be used as the new encryption mode. ('undef' for no encryption.)
In either case the current encryption mode will be returned. Example:

    # Get the current encryption mode
    $mode = $server->Encrypt();

    # Currently disable encryption
    $server->Encrypt(undef);

    # Switch back to the old mode
    $server->Encrypt($mode);

=back

=head2 Server attributes

Server attributes will typically be supplied with the C<new>
constructor.

=over 4

=item configFile

RPC::pServer has a builtin authorization mechanism based on
a configuration file. If you want to use this mechanism,
just supply the name of a configuration file with the attribute
configFile and the server will accept or deny connections
based on the configuration file.

The authorization scheme is host based, but you may add
user based functionality with the user and password
attributes. See L</CONFIGURATION FILE> below.

=item client

This attribute is useful in conjunction with the I<configFile>.
If the server has authorized a client by using the config file,
he will create a hash ref with all the client attributes
and store a reference to this hash under the key I<client>.
Thus you can easily extend the configuration file for your
own purposes, at least as long as host based configuration is
sufficient for you.

=item sock

An object of type IO::Socket, if this program is running
as a daemon. An accept() call will be executed on this
socket in order to wait for connections. See L<IO::Socket(3)>.

An inetd based server should leave this attribute empty:
The method will use STDIN and STDOUT instead.

B<Note:> The latter is not yet functionable, I first need
to work out how to create an object of type IO::socket for
an inetd based server's STDIN and STDOUT. It seems this
is currently not supported by IO::Socket.

=item cipher

This attribute can be used to add encryption quite easily. pRPC is not
bound to a certain encryption method, but to a block encryption API. The
attribute is an object supporting the methods I<blocksize>, I<encrypt>
and I<decrypt>. For example, the modules Crypt::DES and Crypt::IDEA
support such an interface.

Do B<not> modify this attribute directly, use the I<encrypt> method
instead!  However, it is legal to pass the attribute to the constructor.

Example:

    use Crypt::DES;
    $crypt = DES->new(pack("H*", "0123456789abcdef"));
    $client->Encrypt($crypt);

    # or, to stop encryption
    $client->Encrypt(undef);

You might prefer encryption being client dependent, so there is the
additional possibility to setup encryption in the server configuration
file. See L</CONFIGURATION FILE>. Client encryption definitions take
precedence over the I<cipher> attribute.

However, you can set or remove encryption on the fly (putting C<undef>
as attribute value will stop encryption), but you have to be sure,
that both sides change the encryption mode.

=item funcTable

This attribute is a hash reference. The hash keys are the
names of methods, that the client may execute on the server.
The hash values are hash references (again). The RPC::pServer
module will use the key 'code' only: It contains a code reference
to the function performing the clients function call. The first
argument of the function call will be the connection object
itself, the second will be the 'funcTable' value. You are free
to use this hash reference in any way you want, the exception
being the 'code' key. The function must return a list: In case
of errors the results will be the values 0, followed by a
textual error message. In case of success, it ought to return
nonzero, followed by the result list being sent to the client.

=item stderr

a value of TRUE will enable logging messages to STDERR, the
default is using syslog(); if the stderr attribute is FALSE,
you might call openlog() to configure the application name
and facility. See L<Sys::Syslog(3)>.

=item debug

this will cause the server to log debugging information
about client requests using the I<Log> method. A value
of 0 disables debugging.

=item application

=item version

=item user

=item password

it is part of the pRPC authorization process, that the client
must obeye a login procedure where he will pass an application
name, a protocol version and optionally a user name and password.
These are not used by pRPC, but when the new method returns with
a connection object, the main program may use these for additional
authorization.

These attributes are read-only.

=item io

this attribute is a Storable object created for communication
with the client. You may use this, for example, when you want to
change the encryption mode with Storable::Encrypt(). See
L<Storable(3)>.

=back

=head1 CONFIGURATION FILE

The server configuration file is currently not much more than a
collection of client names or ip numbers that should be permitted
or denied to connect to the server. Any client is represented by
a definition like the following:

        accept .*\.neckar-alb\.de
            encryption    DES
            key           063fde7982defabc
            encryptModule Crypt::DES

        deny .*

In other words a client definition begins with either C<accept pattern>
or C<deny pattern>, followed by some client attributes, each of the
attributes being on a separate line, followed by the attribute value.
The C<pattern> is a perl regular expression matching either the
clients host name or IP number. In particular this means that you
have to escape dots, for example a client with IP number
194.77.118.1 is represented by the pattern C<194\.77\.118\.1>.

Currently known attributes are:

=over 4

=item encryption

=item key

=item encryptionModule

These will be used for creating an encryption object which is used
for communication with the client, see L<Storable(3)> for
details. The object is created with a sequence like

        use $encryptionModule;
        $cipher = $encryption->new(pack("H*", $key));

I<encryptionModule> defaults to I<encryption>, the reason why we need
both is the brain damaged design of the L<Crypt::IDEA> and L<Crypt::DES>
modules, which use different module and package names without any
obvious reason.

=back

You may add any other attribute you want, thus extending your authorization
file. The RPC::pServer module will simply ignore them, but your main
program will find them in the I<client> attribute of the RPC::pServer
object. This can be used for additional client dependent configuration.

=head1 PREDEFINED FUNCTIONS

RPC::pServer offers some predefined methods which are designed
for ease in work with objects. In short they allow creation of
objects on the server, passing handles to the client and working
with these handles in a fashion similar to the use of the true
objects.

The handle functions need to share some common data, namely a hash
array of object handles (keys) and objects (values). The problem
is, how to allocate these variables. By keeping a multithreaded
environment in mind, we suggest to store the hash on the stack
of the server's main loop.

The handle functions get access to this loop, by looking into
the 'handles' attribute of the respective entry in the
'funcTables' hash. See above for a description of the
'funcTables' hash.

See below for an example of using the handle functions.

=over 4

=item NewHandle

This method can be inserted into the servers function table. The
client may call this function to create objects and receive handles
to the objects. The corresponding entry in the function table 
must have a key I<classes>: This is a list reference with
class names. The client is restricted to create objects of these
classes only.

The I<NewHandle> function expects, that the constructor returns
an object in case of success or 'undef' otherwise. Note, that
this isn't true in all cases, for example the RPC::pServer
and Net::pRPC::Client classes behave different. In that cases
you have to write your own constructor with a special error
handling. The I<StoreHandle> method below will help you.
Constructors with a different name than I<new> are another
example when you need I<StoreHandle> directly.

=item StoreHandle

After you have created an object on behave of the clients request,
you'd like to store it for later use. This is what I<StoreHandle>
does for you. It returns an object handle which may be passed back
to the client. The client can pass the objects back to the server
for use in I<CallMethod> or I<UseHandle>.

=item NewHandle

The I<NewHandle> is mainly a wrapper for I<StoreHandle>. It creates
an object of the given class, passes it to I<StoreHandle> and returns
the result. The I<NewHandle> method is designed for direct use
within the servers function table.

=item UseHandle

This is the counterpart of I<StoreHandle>: It gets an object handle,
passed by the client, as argument and returns the corresponding
object, if any. An 'undef' value will be returned for an invalid
handle.

=item CallMethod

This function receives an object handle as argument and the name
of a method being executed. The method will be invoked on the
corresponding object and the result will be returned.

A special method is 'DESTROY', valid for any object handle. It
disposes the object, the handle becomes invalid.

=back

All handle functions are demonstrated in the following example.

=head1 EXAMPLE

Enough wasted time, spread the example, not the word. :-) Let's write
a simple server, say a spreadsheet server. Of course we are not
interested in the details of the spreadsheet part (which could well
be implemented in a separate program), the spreadsheet example
is choosen, because it is obvious, that such a server is dealing
with complex data structures. For example, a "sum" method should
be able to add over complete rows, columns or even rectangular
regions of the spreadsheet. And another thing, obviously a spread-
sheet could easily be represented by perl data structures:
The spreadsheet itself could be a list of lists, the elements
of the latter lists being hash references, each describing one
column. You see, such a spreadsheet is an ideal object for
the L<Storable(3)> class. But now, for something completely
different:

    #!/usr/local/bin/perl -wT # Note the -T switch! I mean it!
    use 5.0004;               # Yes, this really *is* required.
    use strict;               # Always a good choice.

    use IO::Socket();
    use RPC::pServer;

    # Constants
    $MY_APPLICATION = "Test Application";
    $MY_VERSION = 1.0;

    # Functions that the clients may execute; for simplicity
    # these aren't designed in an object oriented manner.

    # Function returning a simple scalar
    sub sum ($$$$$) {
	my($con, $data, $spreadsheet, $from, $to) = @_;
        # Example: $from = A3, $to = B5
	my($sum) = SpreadSheet::Sum($spreadsheet, $from, $to);
	return (1, $sum);
    }

    # Function returning another spreadsheet, thus a complex object
    sub double ($$$$$) {
        my($con, $data, $spreadsheet, $from, $to);
        # Doubles the region given by $from and $to, returns
        # a spreadsheet
	my($newSheet) = SpreadSheet::Double($spreadsheet, $from, $to);
	(1, $newSheet);
    }

    # Quit function; showing the use of $data
    sub quit ($$) {
	my($con, $data) = @_;
	$$data = 0;   # Tell the server's Loop() method, that we
                      # are done.
        (1, "Bye!");
    }

    # Now we give the handle functions a try. First of all, a
    # spreadsheet constructor:
    sub spreadsheet ($$$$) {
	my ($con, $data, $rows, $cols) = @_;
	my ($sheet, $handle);
	if (!defined($sheet = SpreadSheet::Empty($rows, $cols))) {
	    $con->error = "Cannot create spreadsheet";
	    return (0, $con->error);
	}
	if (!defined($handle = StoreHandle($con, $data, $sheet))) {
	    return (0, $con->error); # StoreHandle stored error message
	}
	(1, $handle);
    }

    # Now a similar function to "double", except that a spreadsheet
    # is doubled, which is stored locally on the server and not
    # remotely on the client
    sub rdouble ($$$$$) {
        my($con, $data, $sHandle, $from, $to);
	my($spreadsheet) = UseHandle($con, $data, $sHandle);
	if (!defined($spreadsheet)) {
	    return (0, $con->error); # UseHandle stored an error message
	}
        # Doubles the region given by $from and $to, returns
        # a spreadsheet
	my($newSheet) = SpreadSheet::Double($spreadsheet, $from, $to);
	my($handle);
	if (!defined($handle = StoreHandle($con, $data, $newSheet))) {
	    return (0, $con->error); # StoreHandle stored error message
	}
	(1, $newSheet);
    }

    # This function is called for any valid connection to a client
    # In a loop it processes the clients requests.
    #
    # Note, that we are using local data only, thus we should be
    # safe in a multithreaded environment. (Of course, noone knows
    # about the spreadsheet functions ... ;-)
    sub Server ($) {
        my($con) = shift;
        my($con, $configFile, %funcTable);
        my($running) = 1;
	my(%handles) = (); # Note: handle hash is on the local stack

	# First, create the servers function table. Note the
	# references to the handle hash in entries that access
	# the handle functions.
        %funcTable = {
	    'sum'         => { 'code' => &sum },
	    'double'      => { 'code' => &list },
	    'quit'        => { 'code' => &quit,
			       'data' = \$running }
	    'spreadsheet' => { 'code' => \&spreadsheet,
			       'handles' => \%handles },
	    'rdouble'     => { 'code' => \&rdouble,
			       'handles' = \%handles },

            # An alternative to the 'spreadsheet' entry above;
            'NewHandle'   => { 'code' => \&RPC::pServer::NewHandle,
			       'handles' => \%handles,
			       'classes' => [ 'Spreadsheet' ] },

	    # Give client access to *all* (!) spreadsheet methods
	    'CallMethod'  => { 'code' => \&RPC::pServer::CallMethod,
			       'handles' => \%handles }
	};

	$con->{'funcTable'} = \%funcTable;

        while($running) {
	    if (!$con->Loop()) {
		$con->Log('err', "Exiting.\n"); # Error already logged
		exit 10;
	    }
        }
	$con->Log('notice', "Client quits.\n");
	exit 0;
    }

    # Avoid Zombie ball ...
    sub childGone { my $pid = wait; $SIG{CHLD} = \&childGone; }

    # Now for main
    {
        my ($iAmDaemon, $sock);

	# Process command line arguments ...
        ...

        # If running as daemon: Create a socket object.
	if ($iAmDaemon) {
	    $sock = IO::Socket->new('Proto' => 'tcp',
				    'Listen' => SOMAXCONN,
				    'LocalPort' => 'wellKnownPort(42)',
				    'LocalAddr' => Socket::INADDR_ANY
				   );
	} else {
	    $sock = undef; # Let RPC::pServer create a sock object
	}

        while (1) {
	    # Wait for a client establishing a connection
	    my $con = RPC::pServer('sock' => $sock,
				   'configFile' => 'testapp.conf');
            if (!ref($con)) {
		print STDERR "Cannot create server: $con\n";
	    } else {
		if ($con->{'application'} ne $MY_APPLICATION) {
		    # Whatever this client wants to connect to:
		    # It's not us :-)
		    $con->Deny("This is a $MY_APPLICATION server. Go away");
		} elsif ($con->{'version'} > $MY_VERSION) {
		    # We are running an old version of the protocol :-(
		    $con->Deny("Sorry, but this is version $MY_VERSION");
		} elsif (!IsAuthorizedUser($con->{'user'},
					   $con->{'password'})) {
		    $con->Deny("Access denied");
		} else {
		    # Ok, we accept the client. Spawn a child and let
		    # the child do anything else.
		    my $pid = fork();
		    if (!defined($pid)) {
			$con->Deny("Cannot fork: $!");
		    } elsif ($pid == 0) {
			# I am the child
			$con->Accept("Welcome to the pleasure dome ...");
			Server();
		    }
		}
	    }
	}			
    }

=head1 SECURITY

It has to be said: pRPC based servers are a potential security problem!
I did my best to avoid security problems, but it is more than likely,
that I missed something. Security was a design goal, but not *the*
design goal. (A well known problem ...)

I highly recommend the following design principles:

=head2 Protection against "trusted" users

=over 4

=item perlsec

Read the perl security FAQ (C<perldoc perlsec>) and use the C<-T> switch.

=item taintperl

B<Use> the C<-T> switch. I mean it!

=item Verify data

Never untaint strings withouth verification, better verify twice.
For example the I<CallMethod> function first checks, whether an
object handle is in a a proper format (currently integer numbers,
but don't rely on that, it could change). If it is, then it will
still be verified, that an object with the given handle exists.

=item Be restrictive

Think twice, before you give a client access to a function. In
particular, think twice, before you give a client access to
objects via the handle methods: If a client can coerce
CallMethod() on an object, he has access to *all* methods of
that object!

=item perlsec

And just in case I forgot it: Read the C<perlsec> man page. :-)

=back

=head2 Protection against untrusted users

=over 4

=item Host based authorization

pRPC has a builtin host based authorization scheme; use it!
See L</CONFIGURATION FILE>.

=item User based authorization

pRPC has no builtin user based authorization scheme; that doesn't
mean, that you should not implement one.

=item Encryption

Using encryption with pRPC is extremely easy. There is absolutely
no reason for communicating unencrypted with the clients. Even
more: I recommend two phase encryption: The first phase is the
login phase, where to use a host based key. As soon as the user
has authorized, you should switch to a user based key. See the
DBD::pNET agent for an example.

=back

=head1 AUTHOR

Jochen Wiedmann, wiedmann@neckar-alb.de

=head1 SEE ALSO

L<Net::pRPC::Client(3)>, L<Storable(3)>, L<Sys::Syslog(3)>

See L<DBD::pNET(3)> for an example application.

=cut
