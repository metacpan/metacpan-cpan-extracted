#!/usr/local/bin/perl
#
#   pRPC - Perl RPC, package for writing simple, RPC like clients and
#       servers
#
#   lib.pl is the base for the test suite.
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
#   $Id: lib.pl,v 0.1001 1997/09/14 22:53:31 joe Exp $
#


############################################################################
#
#   Modules we use; both pragmatic and true modules
#
############################################################################

use 5.004;
use strict;

use RPC::pServer;
use RPC::pClient;
use IO::Socket();
use Sys::Syslog();


############################################################################
#
#   Constant values
#
############################################################################

use vars qw{$TEST_APPLICATION $TEST_VERSION $TEST_USER $TEST_PASSWORD};
$TEST_APPLICATION = "Test Application";
$TEST_VERSION = 1.0;
$TEST_USER = "foo";
$TEST_PASSWORD = "bar";


############################################################################
#
#   Global variables
#
############################################################################

use vars qw{$childPid $childGone $verbose};
$childPid = 0;
$childGone = 0;

my ($tblob, $blob) = ('', '');
{
    my $i;
    for ($i = 0;  $i < 256;  $i++) {
	$tblob .= chr($i);
    }
    for ($i = 0;  $i < 256;  $i++) {
	$blob .= $tblob;
    }
}


############################################################################
#
#   Name:    Server
#
#   Purpose: Performs the server tasks: Wait for a connection and
#            perform clients requests.
#
#   Inputs:  $sock - Socket created for the server.
#            $cipher - cipher object being used for encryption
#            $configFile - path of config file
#
#   Result:  Nothing; dies in case of serious errors
#
############################################################################

sub multiply ($$@) {
    my($con, $ref, @args) = @_;
    my($mul) = shift @args;
    my($m);
    while (defined($m = shift @args)) {
	$mul *= $m;
    }
    (1, $mul);
}

sub ListFunc($) {
    my($dir) = shift;
    my ($file, @result);
    if (opendir(DIR, $dir)) {
	while (defined($file = readdir(DIR))) {
	    push(@result, $file);
	}
	closedir(DIR);
    }
    @result;
}

sub listdir ($$@) {
    my ($con, $ref, @args) = @_;
    my ($dir) = shift @args;
    if (-d $dir) {
	(1, ListFunc($dir));
    } else {
	(0, "No such directory: $dir");
    }
}

sub reverseblob ($$$) {
    my ($con, $ref, $gblob) = @_;

    if ($gblob eq $blob) {
	(1, reverse $blob);
    } else {
	(0, "mismatch");
    }
}

sub quitProgram ($$) {
    my ($con, $ref) = @_;
    my ($runRef) = $ref->{'running'};
    $$runRef = 0;
    (1, "Bye!");
}

sub Server ($@) {
    my($sock, $cipher, $configFile) = @_;
    my($con, $running, %handles);

    my ($funcTable) = {
	'quit'     => { 'code' => \&quitProgram, 'running' => \$running },
        'list'     => { 'code' => \&listdir },
        'multiply' => { 'code' => \&multiply },
	'reverseblob' => { 'code' => \&reverseblob },
	'new'      => { 'code' => \&RPC::pServer::NewHandle,
			'handles' => \%handles,
		        'classes' => ['List'] },
	'call'     => { 'code' => \&RPC::pServer::CallMethod,
			'handles' => \%handles }
    };

    $SIG{'ALRM'} = sub { exit 10; };
    alarm 20;

    $con = RPC::pServer->new('sock' => $sock,
			     'cipher' => $cipher,
			     'funcTable' => $funcTable,
			     'configFile' => $configFile,
			     'debug' => 1);

    if (!ref($con)) {
	exit 0;
    }

    $con->Accept();

    $running = 1;
    while ($running) {
	if ($con->{'sock'}->eof()  ||  $con->{'sock'}->error) {
	    exit 0;
	}
        $con->Loop();
    }
    exit 0;
}


############################################################################
#
#   Name:    Client
#
#   Purpose: Performs the client tasks: Connects to the server, calls
#            remote procedures and disconnects.
#
#   Inputs:  $ip - servers ip number
#            $port - servers port number
#            $cipher - cipher object being used for encryption
#
#   Result:  Nothing; dies in case of serious errors
#
############################################################################

sub childGone () {
    my $pid = wait;
    if ($childPid == $pid) {
	$childGone = 1;
    }
    $SIG{CHLD} = \&childGone;
}

sub Client ($$;$) {
    my($ip, $port, $cipher) = @_;
    my($sock, $con);

    $SIG{CHLD} = \&childGone;

    if ($verbose) {
	print "Connecting to $ip, port $port.\n";
    }
    $sock = IO::Socket::INET->new('Proto' => 'tcp',
				  'PeerAddr' => $ip,
				  'PeerPort' => $port);
    if (!defined($sock)) {
	print STDERR "Cannot connect to server: $!\n";
	exit 10;
    }

    $con = RPC::pClient->new('sock' => $sock,
			     'application' => $TEST_APPLICATION,
			     'version' => $TEST_VERSION,
			     'user' => $TEST_USER,
			     'password' => $TEST_PASSWORD,
			     'debug' => 1,
			     'cipher' => $cipher);

    if (!ref($con)) {
	printf STDERR "Failed to connect, error $con.\n";
	exit 10;
    }
    printf("ok 1 Storable OO : %d\n", $RPC::pClient::haveOoStorable);

    #   Call the 'multiply' function.
    my ($mult) = $con->Call('multiply', 3, 4);
    if ($con->error) {
	print "not ok 2 error ", $con->error, "\n";
    } elsif ($mult != 12) {
	print "not ok 2 result $mult\n";
    } else {
	print "ok 2\n";
    }

    #   Call the 'list' function
    my @list = ListFunc(".");
    my (@res, $elem);
    @res = $con->Call('list', ".");
    if ($con->error) {
	print "not ok 3 error ", $con->error, "\n";
    } else {
	my $ok = (@res == @list);
	foreach $elem (@res) {
	    if ($elem ne shift @list) {
		$ok = 0
		}
	}
	if ($ok) {
	    print "ok 3\n";
	} else {
	    print "not ok 3 result @res\n";
	}
    }

    #   Call an illegal function
    my (@ill) = $con->Call('illegal');
    if ($con->error) {
	if (!@ill) {
	    print "ok 4\n";
	} else {
	    print "not ok 4 result @ill\n";
	}
    } else {
	print "not ok 4 expected error\n";
    }

    #   Create a list object
    @list = (1, 2, "a", 4, 5, "c");
    my ($handle) = $con->Call('new', 'List', @list);
    if ($con->error) {
	print "not ok 5 error ", $con->error, "\n";
    } elsif ($handle !~ /^\d+$/) {
	print "not ok 5 handle $handle\n";
    } else {
	print "ok 5\n";
    }

    #   Access the third item
    my ($item) = $con->Call('call', $handle, 'item', 2);
    if ($con->error) {
	print "not ok 6 error ", $con->error, "\n";
    } elsif ($item ne "a") {
	print "not ok 6 item $item\n";
    } else {
	print "ok 6\n";
    }

    #   Access an invalid item
    ($item) = $con->Call('call', $handle, 'item', 7);
    if ($con->error) {
	print "not ok 7 error ", $con->error, "\n";
    } elsif (defined($item)) {
	printf ("not ok 7 item $item, length %s\n", length($item));
    } else {
	print "ok 7\n";
    }

    #   Get the number of items
    my ($items) = $con->Call('call', $handle, 'items');
    if ($con->error) {
	print "not ok 8 error ", $con->error, "\n";
    } elsif ($items ne 6) {
	print "not ok 8 items $items\n";
    } else {
	print "ok 8\n";
    }

    #   Retreive the complete list
    my(@l) = $con->Call('call', $handle, 'list');
    if ($con->error) {
	print "not ok 9 error ", $con->error, "\n";
    } elsif (@l ne @list) {
	print "not ok 9 items ", scalar(@l), "\n";
    } else {
	my $ok = 1;
	my $i;
	for ($i = 0;  $i < @l;  $i++) {
	    if ($l[$i] ne $list[$i]) {
		$ok = 0;
		print "not ok 9 item $i $l[$i]\n";
		last;
	    }
	}
	if ($ok) {
	    print "ok 9\n";
	}
    }

    #   Access an invalid handle
    ($item) = $con->Call('call', $handle+1, 'item', 7);
    if ($con->error) {
	print "ok 10\n";
    } else {
	print "not ok 10 expected error\n";
    }

    #   Destroy the handle
    $con->Call('call', $handle, 'DESTROY');
    if ($con->error) {
	print "not ok 11 error ", $con->error, "\n";
    } else {
	print "ok 11\n";
    }

    #   Try blobs
    my ($gblob) = $con->Call('reverseblob', $blob);
    if ($con->error) {
	print "not ok 12 error ", $con->error, "\n";
    } elsif ($gblob ne $blob) {
	sub ShowBlob($) {
	    my ($blob) = @_;
	    my $i;
	    for($i = 0;  $i < 8;  $i++) {
		if (defined($blob)  &&  length($blob) > $i) {
		    $b = substr($blob, $i*32);
		} else {
		    $b = "";
		}
		printf("%08lx %s\n", $i*32, unpack("H64", $b));
	    }
	}

	print "not ok 12 mismatch\n";
        #ShowBlob($blob);
        #print " vs.\n";
        #ShowBlob(reverse $gblob);
    } else {
	print "ok 12\n";
    }


    if ($childGone) {
	print "not ok 13 child gone previously\n";
	print "not ok 14\n";
	exit 0;
    }

    #   Call the quit function
    $con->Call('quit');
    if ($con->error) {
	print "not ok 13 error ", $con->error, "\n";
    } else {
	print "ok 13\n";
    }

    sleep 10;
    if ($childGone) {
	print "ok 14\n";
        exit 0;
    } else {
	print "not ok 14 child not gone\n";
    }
}


############################################################################
#
#   Create a simple package for testing the handle functions
#
############################################################################

package List;

sub new ($@) {
    my ($proto, @args) = @_;
    my ($class) = ref($proto) || $proto;
    my ($self) = [@args];
    bless($self, $class);
    $self;
}

sub item ($$) {
    my ($self) = shift;
    my ($i) = shift;
    my ($result);

    if ($i < 0  ||  $i >= @$self) {
	$result = undef;
    } else {
	$result = $$self[$i];
    }
    $result;
}

sub items ($) {
    my ($self) = shift;
    scalar(@$self);
}

sub list ($) {
    my ($self) = shift;
    (@$self);
}

1;
