#   -*- perl -*-
#
#
#   pRPC - Perl RPC, package for writing simple, RPC like clients and
#       servers
#
#   RPC::pClient.pm is the module for writing the pRPC client.
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
#   $Id: pClient.pm,v 0.1001 1997/09/14 22:53:27 joe Exp $
#
package RPC::pClient;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.1002';

use POSIX();
use Sys::Syslog();
use IO::Socket();
use Storable();
use Socket();


sub error ($) { my $self = shift; $self->{'error'}; }


############################################################################
#
#   Name:    new
#
#   Purpose: Constructor of the pRPC::Client module
#
#   Inputs:  Hash list of attributes; see pRPC::Client(3)
#
#   Returns: connection object or error message
#
############################################################################

sub new ($@) {
    my ($proto) = shift;
    my ($class) = ref($proto) || $proto;
    my ($self) = {@_};

    bless($self, $class);

    if (!defined($self->{'application'})  ||  !defined($self->{'version'})) {
	return "Required attributes 'application' or 'version' missing.";
    }

    #
    #   Create Storable objects and send the login message.
    #
    if ($self->_HaveOoStorable) {
	$self->{'io'} = Storable->new('file' => *{$self->{'sock'}}{IO},
				      'crypt' => $self->{'cipher'},
				      'netorder' => 1,
				      'forgive_me' => 1);
	if (!defined($self->{'io'})) {
	    return "Cannot create Storable object: $!";
	}
    } else {
	$self->{'file'} = $self->{'sock'};
    }

    if ($self->{'debug'}) {
        Sys::Syslog::syslog('debug', "Sending login message: %s %s %s",
			    $self->{'application'}, $self->{'version'},
			    $self->{'user'});
    }
    if (!$self->_Store([$self->{'application'},
			$self->{'version'},
			$self->{'user'},
			$self->{'password'}])) {
	return "Cannot send login message: " . $self->{'error'};
    }
    
    if ($self->{'debug'}) {
        Sys::Syslog::syslog('debug', "Waiting for server's response ...");
    }
    my ($msg) = $self->_Retrieve();
    if (!$msg) {
	$msg = "Error while reading server reply: " . $self->{'error'};
        Sys::Syslog::syslog('debug', $msg);
	return $msg;
    }
    if (ref($msg) ne 'ARRAY') {
	$msg = "Error while reading server reply: Expected array";
        Sys::Syslog::syslog('debug', $msg);
	return $msg;
    }

    if (!$$msg[0]) {
	$msg = "Refused by server: "
	    . (defined($$msg[1]) ? $$msg[1] : "No cause");
        Sys::Syslog::syslog('debug', $msg);
	return $msg;
    }

    Sys::Syslog::syslog('debug', "Logged in, server replies %s",
			defined($$msg[1]) ? $$msg[1] : "undef");
    $self->{'error'} = '';
    $self;
}


############################################################################
#
#   Name:    Call, CallInt
#
#   Purpose: coerce method located on the server
#
#   Inputs:  $con - connection attributes
#            $method - method name
#            @args - method attributes
#
#   Returns: method results; you *must* check $con->error for potential
#            error conditions
#
############################################################################

sub CallInt ($@) {
    my($self) = shift;
    my($error, $msg, @result);

    if (!$self->_Store([@_])) {
	$error = $self->{'error'};
    } else {
	$msg = $self->_Retrieve();
	if (!$msg) {
	    $error = $self->{'error'};
	} elsif (ref($msg) ne 'ARRAY') {
	    $error = "Error while reading server reply: Expected array";
	} elsif (!defined($$msg[0])  ||  !$$msg[0]) {
	    if (defined($$msg[1])  &&  $$msg[1] ne '') {
		$error = $$msg[1];
	    } else {
		$error = "No error message";
	    }
	} else {
	    $error = '';
	    @result = @$msg;
	}
    }

    if ($self->{'error'} = $error) {
	@result = (0, $error);
    }

    if ($self->{'debug'}) {
	if ($self->error) {
	    Sys::Syslog::syslog('err', "Calling method %s -> error %s",
				$_[0], $self->error);
	} else {
	    Sys::Syslog::syslog('debug', "Calling method %s -> ok",
				$_[0]);
	}
    }

    @result;
}

sub Call ($@) {
    my($self) = shift;
    my(@result) = $self->CallInt(@_);

    if (!shift @result) {
	@result = ();
    }

    @result;
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
#   Name:    _Store, _Retrieve
#
#   Purpose: Preliminary replacements for Storable->Store and
#            Storable->Retrieve as long as Raphael hasn't integrated
#            my suggestion for an OO API.
#
#   Inputs:  $self - server object
#            $msg - message being sent (_Store only)
#
#   Returns: _Retrieve returns a message in case of success. Both
#            methods return FALSE in case of error, $self->{'error'}
#            will be set in that case.
#
############################################################################

$RPC::pClient::haveOoStorable = undef;
sub _HaveOoStorable () {
    if (!defined($RPC::pClient::haveOoStorable)) {
	$@ = '';
	eval "Storable->new()";
	$RPC::pClient::haveOoStorable = $@ ? 0 : 1;
    }
    $RPC::pClient::haveOoStorable;
}

sub _Retrieve($) {
    my($self) = @_;
    my($result);

    if ($self->_HaveOoStorable) {
	if (!($result = $self->{'io'}->Retrieve())) {
	    $self->{'error'} = $self->{'io'}->errstr;
	}
	return $result;
    }

    my($encodedSize, $readSize, $blockSize);
    $readSize = 4;
    $encodedSize = '';
    while ($readSize > 0) {
	my $result = $self->{'file'}->read($encodedSize, $readSize,
					   length($encodedSize));
	if ($result < 0) {
	    $self->{'error'} = "Error while reading: $!";
	    return undef;
	}
	$readSize -= $result;
    }
    $encodedSize = unpack("N", $encodedSize);
    $readSize = $encodedSize;
    if ($self->{'cipher'}) {
	$blockSize = $self->{'cipher'}->blocksize;
	if (my $addSize = ($encodedSize % $blockSize)) {
	    $readSize += ($blockSize - $addSize);
	}
    }
    my $msg = '';
    my $rs = $readSize;
    while ($rs > 0) {
	my $result = read($self->{'file'}, $msg, $rs, length($msg));
	if ($result < 0) {
	    $self->{'error'} = "Error while reading: $!";
	    return undef;
	}
	$rs -= $result;
    }
    if ($self->{'cipher'}) {
	my $cipher = $self->{'cipher'};
	my $encodedMsg = $msg;
	$msg = '';
	for (my $i = 0;  $i < $readSize;  $i += $blockSize) {
	    $msg .= $cipher->decrypt(substr($encodedMsg, $i, $blockSize));
	}
	$msg = substr($msg, 0, $encodedSize);
    }
    my $ref = Storable::thaw($msg);
    $ref;
}
sub _Store($$) {
    my($self, $msg) = @_;

    if ($self->_HaveOoStorable) {
	if (!$self->{'io'}->Store($msg)) {
	    $self->{'error'} = $self->{'io'}->errstr;
	    return undef;
	}
	return 1;
    }

    my($encodedMsg) = Storable::nfreeze($msg);
    my($encodedSize) = length($encodedMsg);
    if ($self->{'cipher'}) {
	my $cipher = $self->{'cipher'};
	my $size = $cipher->blocksize;
	if (my $addSize = length($encodedMsg) % $size) {
	    $encodedMsg .= chr(0) x ($size - $addSize);
	}
	$msg = $encodedMsg;
	$encodedMsg = '';
	for (my $i = 0;  $i < length($msg);  $i += $size) {
	    $encodedMsg .= $cipher->encrypt(substr($msg, $i, $size));
	}
    }
    $self->{'file'}->print(pack("N", $encodedSize) . $encodedMsg);
    $self->{'file'}->flush();
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=pod

=head1 NAME

RPC::pClient - Perl extension for writing pRPC clients

=head1 SYNOPSIS

  use RPC::pClient;

  $sock = IO::Socket::INET->new('PeerAddr' => 'joes.host.de',
				'PeerPort' => 2570,
				'Proto' => 'tcp');

  $connection = new RPC::pClient('sock' => $sock,
                                 'application' => 'My App',
				 'version' => '1.0',
				 'user' => 'joe',
				 'password' => 'hello!');

=head1 DESCRIPTION

pRPC (Perl RPC) is a package that simplifies the writing of
Perl based client/server applications. RPC::pServer is the
package used on the server side, and you guess what RPC::pClient
is for. See L<RPC::pClient(3)> for this part.

pRPC works by defining a set of of functions that may be
executed by the client. For example, the server might offer
a function "multiply" to the client. Now a function call

    @result = $con->Call('multiply', $a, $b);

on the client will be mapped to a corresponding call

    multiply($con, $data, $a, $b);

on the server. (See the I<funcTable> description below for
$data.) The function calls result will be returned to the
client and stored in the array @result. Simple, eh? :-)

=head2 Client methods

=over 4

=item new

The client constructor. Returns a client object or an error string,
thus you typically use it like this:

    $client = RPC::pClient->new ( ... );
    if (!ref($client)) {
        print STDERR "Error while creating client object: $client\n";
    } else {
        # Do real stuff
        ...
    }

=item Call

calls a function on the server; the arguments are a function name,
followed by function arguments. It returns the function results,
if successfull. After executing Call() you should always check
the I<error> attribute: An empty string indicates success. Thus
the equivalent to

    $c = Add($a, $b)
    # Use $c
    ...

is

    $c = $client->Call("Add", $a, $b);
    if ($client->error) {
        # Do something in case of error
        ...
    } else {
        # Use $c
        ...
    }

=item CallInt

Similar to and internally used by I<Call>. Receives the same
arguments, but the result is prepended by a status value: If this
status value is TRUE, then all went fine and the following result
array is valid. Otherwise an error occurred and the error message
follows immediately after the status code. Example:

    my($status, @result) = $client->CallInt("Add", $a, $b);
    if (!$status) {
        #  Do something in case of error
        my $errmsg = shift @result  ||  "Unknown error";
        ...
    } else {
        ...
    }

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

=head2 Client attributes

Client attributes will typically be supplied with the C<new>
constructor.

=over 4

=item sock

An object of type IO::Socket, which should be connected to the
server.

=item cipher

This attribute can be used to add encryption quite easily. pRPC is not
bound to a certain encryption method, but to a block encryption API. The
attribute is an object supporting the methods I<blocksize>, I<encrypt>
and I<decrypt>. For example, the modules Crypt::DES and Crypt::IDEA
support such an interface.

Note that you can set or remove encryption on the fly (putting C<undef>
as attribute value will stop encryption), but you have to be sure,
that both sides change the encryption mode.

Do B<not> modify this attribute directly, use the I<encrypt> method
instead! However, it is legal to pass the attribute to the constructor.

Example:

    use Crypt::DES;
    $crypt = DES->new(pack("H*", "0123456789abcdef"));
    $client->Encrypt($crypt);

    # or, to stop encryption
    $client->Encrypt(undef);

=item application

=item version

=item user

=item password

it is part of the pRPC authorization process, that the client
must obeye a login procedure where he will pass an application
name, a protocol version and optionally a user name and password.
You do not care for that (except passing the right values, of
course :-), this is done within the client constructor.

=item io

this attribute is the Storable object created for communication
with the server. You may use this, for example, when you want to
change the encryption mode with Storable::Encrypt(). See
L<Storable(3)>.

=back

=head1 EXAMPLE

    #!/usr/local/bin/perl -T
    use 5.0004;               # Yes, this really *is* required.
    use strict;               # Always a good choice.

    use IO::Socket();
    use RPC::pClient;

    # Constants
    my $MY_APPLICATION = "Test Application";
    my $MY_VERSION = 1.0;
    my $MY_USER = "foo";
    my $MY_PASSWORD = "bar";

    # Connect to the server
    my $sock = IO::Socket::INET->new('PeerAddr' => 'joes.host.de',
                                     'PeerPort' => 5000,
                                     'Proto' => 'tcp');
    if (!defined($sock)) {
        die "Cannot connect: $!\n";
    }

    # Login procedure
    my $client = RPC::pClient->new('sock' => $sock,
                                   'application' => $MY_APPLICATION,
                                   'version' => $MY_VERSION,
                                   'user' => $MY_USER,
                                   'password' => $MY_PASSWORD);
    if (!ref($client)) {
        die "Cannot create client: $client\n";
    }

    # Call multiply function
    my $a = $client->Call("multiply", 3, 4);
    if ($client->error) {
        die "An error occurred while multiplying: $a\n";
    }

=head1 AUTHOR

Jochen Wiedmann, wiedmann@neckar-alb.de

=head1 SEE ALSO

L<pRPC::Server(3)>, L<Storable(3)>, L<Sys::Syslog(3)>

For an example application, see L<DBD::pNET(3)>.

=cut

