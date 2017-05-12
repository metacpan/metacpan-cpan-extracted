#!/usr/bin/perl

use strict;

package Saa;
use Tana;

use Data::Dumper;
use Sys::Hostname;
use IO::Socket;
use IO::Select;
use Fcntl;

my $LOCALADDR_PREFIX = "/var/tmp/searchrpc_localsoc_";
my $debug = 0;

sub new
{
    my ($this) = @_;
    my $class = ref($this) || $this;

    my $my_addr = gethostbyname(hostname());
    if(!defined($my_addr))
    {
	return undef;
    }

    $this = {
	'servs' => {},
	'serv_sel' => IO::Select->new(),
	'conns' => {},
	'conn_sel' => IO::Select->new(),
	'ip_clis' => {},
	'my_addr' => $my_addr,
	'err' => '',
	'queue' => [],
    };

    bless $this, $class;

    $SIG{'PIPE'} = 'IGNORE';

    return $this;
}

sub err
{
    my $this = shift;

    return $this->{'err'};
}

# 'auto_arb' => bool    # Autoread arb messages?
# 'callback' => [func, params]
sub listen
{
    my $this = shift;
    my $port = shift;

    my %par = @_;

    if(exists($this->{'servs'}->{$port}))
    {
	$this->{'err'} = "Already listening";
	return 0;
    }
    
    my $serv = 
    {
	'port' => $port,
	'auto_arb' => 0,
    };

    if(exists($par{'callback'}))
    {
	$serv->{'callback'} = $par{'callback'};
    }

    if(exists($par{'auto_arb'}))
    {
	$serv->{'auto_arb'} = $par{'auto_arb'};
    }

    my $inet_sock = IO::Socket::INET->new(LocalPort => $port,
					  Type => SOCK_STREAM,
					  Reuse => 1,
					  Listen => 10);
    if(!defined($inet_sock))
    {
	$this->{'err'} = "$@";
	return 0;
    }

#    print STDERR "Soketti on $LOCALADDR_PREFIX$port\n";
    unlink "$LOCALADDR_PREFIX$port";
    my $unix_sock = IO::Socket::UNIX->new(Local => "$LOCALADDR_PREFIX$port",
					  Type => SOCK_STREAM,
					  Listen => 10);
    if(!defined($unix_sock))
    {
	$this->{'err'} = "$@";
	close($inet_sock);
	return 0;
    }

    binmode($inet_sock, ":raw");
    binmode($unix_sock, ":raw");

    $serv->{'inet_sock'} = $inet_sock;
    $serv->{'unix_sock'} = $unix_sock;

    $this->{'servs'}->{$port} = $serv;
    $this->{'serv_sel'}->add($inet_sock);
    $this->{'serv_sel'}->add($unix_sock);

    return 1;
}

sub connected
{
    my $this = shift;
    my $host = shift;
    my $port = shift;

    return(exists($this->{'conns'}->{"${host}_$port"}));
}

sub disconnect_all
{
    my $this = shift;

    foreach (keys(%{$this->{'conns'}}))
    {
	my $conn = $this->{'conns'}->{$_}->{'conn'};
	$this->{'conn_sel'}->remove($conn);
	delete($this->{'conns'}->{"$_"});

	shutdown($conn, 2);
	close($conn);
    }

    return 1;
}

sub disconnect
{
    my $this = shift;
    my $host = shift;
    my $port = shift;

    if(!exists($this->{'conns'}->{"${host}_$port"}))
    {
	$this->{'err'} = "Not connected";
	return 0;
    }

    my $conn = $this->{'conns'}->{"${host}_$port"}->{'conn'};
    $this->{'conn_sel'}->remove($conn);
    delete($this->{'conns'}->{"${host}_$port"});

    shutdown($conn, 2);
    close($conn);

    return 1;
}


sub unlisten
{
    my $this = shift;
    my $port = shift;

    if(!exists($this->{'servs'}->{$port}))
    {
	$this->{'err'} = "Not connected";
	return 0;
    }

    my $serv = $this->{'servs'}->{$port};
    $this->{'serv_sel'}->remove($serv->{'unix_sock'});
    $this->{'serv_sel'}->remove($serv->{'inet_sock'});
    shutdown($serv->{'unix_sock'}, 2);
    shutdown($serv->{'inet_sock'}, 2);
    close($serv->{'unix_sock'});
    close($serv->{'inet_sock'});
    unlink("$LOCALADDR_PREFIX$port");
    delete($this->{'servs'}->{$port});

    return 1;
}

sub connect
{
    my $this = shift;
    my $host = shift;
    my $port = shift;

    if(exists($this->{'conns'}->{"${host}_$port"}))
    {
	$this->{'err'} = "Already connected";
	return 0;
    }

    my $cn = 
    {
	'host' => $host,
	'port' => $port,
	'auto_arb' => 1,
    };

    my $addr = gethostbyname($host);
    my $conn = undef;
# local socket handling is fundamentally broken, a saa-redesign is needed
#    if($this->{'my_addr'} eq $addr) # try domain socket first
#    {
#	$conn = IO::Socket::UNIX->new(Peer => "$LOCALADDR_PREFIX$port",
#				      Type => SOCK_STREAM,
#				      Timeout => 10);
#    }
    if(!defined($conn))
    {
#	$debug && print STDERR "Saa::connect(): domain socket $LOCALADDR_PREFIX$port failed with $!, trying inet\n";
	if(!($conn = IO::Socket::INET->new(PeerAddr => $host,
					   PeerPort => $port,
					   Proto => "tcp",
					   Type => SOCK_STREAM)))
	{
	    $debug && print STDERR "Saa::connect(): tcp connect failed with $@\n";
	    $this->{'err'} = "$@";
	    return 0;
	}
    }
    else
    {
	$debug && print STDERR "Saa::connect(): Successfully opened localsoc!\n";
    }

    binmode($conn, ":raw");

    $cn->{'conn'} = $conn;
    $this->{'conn_sel'}->add($conn);
    $this->{'conns'}->{"${host}_$port"} = $cn;

    return 1;
}

# 'auto_arb' => bool
sub conn_set
{
    my $this = shift;
    my $host = shift;
    my $port = shift;

    my %par = @_;

    my $c = "${host}_$port";
    if(!exists($this->{'conns'}->{$c}))
    {
	$this->{'err'} = "No such connection.";
	return 0;
    }

    for(keys(%par))
    {
	$this->{'conns'}->{$c}->{$_} = $par{$_};
    }
    
    return 1;
}


# 'tag' => client name for the msg
# 'arb' => scalar data or func(tag) that returs scalar or undef on end-of-data
# 'arb_name' => scalar
sub queue
{
    my $this = shift;
    my $host = shift;
    my $port = shift;
    my $msg = shift;

    my %par = @_;

    my $q_elem = {
	'host' => $host,
	'port' => $port,
	'msg'  => $msg
    };

    if(exists($par{'arb'}))
    {
	$q_elem->{'arb'} = $par{'arb'};
	$q_elem->{'arb_name'} = $par{'arb_name'};
    }

    if(exists($par{'tag'}))
    {
	$q_elem->{'tag'} = $par{'tag'};
    }

#    print STDERR "scheduled req: " . Dumper($q_elem);
    push(@{$this->{'queue'}}, $q_elem);

    return 1;
}

sub process_accept
{
    my $this = shift;
    my $timeout = shift;

    $timeout=10;

    my @servs = keys(%{$this->{'servs'}});
    my @reads = $this->{'serv_sel'}->can_read($timeout);
    
#    print "Riidit: " . Dumper(\@reads) . "\n";
    my $conn;
    foreach $conn (@reads)
    {
	my $serv;
	my $found = 0;
	for(@servs)
	{
	    if($this->{'servs'}->{$_}->{'inet_sock'} == $conn ||
	       $this->{'servs'}->{$_}->{'unix_sock'} == $conn)
	    {
		$serv = $this->{'servs'}->{$_};
		$found = 1;
		last;
	    }
	}

	my $client = $conn->accept();
#	print "Conn " . Dumper($conn);
	if(!defined($client))
	{
#	    print STDERR "PRKL: $!\n";
	    next;
	}

	my $str_ip;
	my $port;
#for some reason sockdomain returns undef
#	if(AF_INET == $client->sockdomain)
#	{
	    my $sockaddr = $client->peername();
	    my $iaddr;
	    ($port, $iaddr) = sockaddr_in($sockaddr);
	    $str_ip = inet_ntoa($iaddr);
#	    print STDERR "Saa: accept found port $port and ip $str_ip\n";
#	}
#	else # AF_UNIX
#	{
#	    my $sn = $client->sockname();
#	    $sn =~ /$LOCALADDR_PREFIX([0-9]+)/;
#	    $port = $1;
#	    $str_ip = inet_ntoa($this->{'my_addr'});
#	    $debug && print STDERR "Saa::process_accept(): AF_UNIX connection with ip $str_ip port $port\n";
#	}

	my $cn = 
	{
	    'host' => $str_ip,
	    'port' => $port,
	    'conn' => $client,
	    'lport' => $serv->{'port'},
	};

	$serv->{'auto_arb'} && ($cn->{'auto_arb'} = $serv->{'auto_arb'});
	$serv->{'callback'} && ($cn->{'callback'} = $serv->{'callback'});

	$this->{'conns'}->{"${str_ip}_$port"} = $cn;
	$this->{'conn_sel'}->add($client);
    }

    return (1, 0);
}

sub process_write
{
    my $this = shift;
    my $sent = shift;

    my $q = $this->{'queue'};
    my %banned = (); # makes sure the order of messages for the same connection is kept

    my $offset = 0;
    while($offset < scalar(@$q))
    {
	my $qe = $q->[$offset];

	# ensure connection
	if(! $this->connected($qe->{'host'}, $qe->{'port'}))
	{
#	    print STDERR "Write connects to $qe->{'host'} $qe->{'port'}\n";
	    if(!$this->connect($qe->{'host'}, $qe->{'port'}))
	    {
#		print STDERR "Write is not connected to $qe->{'host'} $qe->{'port'}: $@\n";
		$this->{'err'} = $@;
		$qe->{'status'} = "failed";
		shift(@$q);
		push(@$sent, $qe);

		return (0, scalar(@$q));
	    }
	}
	
	my $connstr = $qe->{'host'} . "_" . $qe->{'port'};
	my $conn = $this->{'conns'}->{$connstr}->{'conn'};

	#see writability if not known
	if($banned{$connstr}) 
	{
	    $offset++;
	    next; # earlier message in q already unsent to this connstr
	}
	
	if(scalar(IO::Select->new($conn)->can_write(0)))
	{
	    my $ok;
	    if(defined($qe->{'arb_name'}))
	    {
#		print STDERR "Saa: writing arb " . $qe->{'arb_name'} . " " . Dumper($qe->{'msg'});
		$ok = Tana::write($conn, $qe->{'msg'}, $qe->{'arb_name'});
	    }
	    else
	    {
#		print STDERR "Saa: writing fix " . Dumper($qe->{'msg'});
		$ok = Tana::write($conn, $qe->{'msg'}, undef);
	    }
	    if(!$ok)
	    {
		$qe->{'status'} = "failed";
		$this->{'err'} = Tana::error($conn);
		$this->disconnect($qe->{'host'}, $qe->{'port'});
		shift(@$q);
		push(@$sent, $qe);
		
		return (0, $offset < scalar(@$q));
	    }
	    
	    if(defined($qe->{'arb_name'}))
	    {
		$ok = 1;
		my $func = undef;
		my @param;
		if(!ref($qe->{'arb'})) #scalar
		{
#		    print STDERR "S: writing scalar arb " . $qe->{'arb'} . "\n";
#		    print STDERR Dumper($qe->{'arb'});
		    $ok = Tana::write_arb($conn, $qe->{'arb'}, 1);
		}
		elsif(ref($qe->{'arb'}) eq 'ARRAY')
		{
#		    print STDERR "S: arb-callback with params\n";
		    @param = @{$qe->{'arb'}};
		    $func = shift(@param);
		}
		else
		{
#		    print STDERR "S: arb-callback without params\n";
		    $func = $qe->{'arb'};
		    @param = ();
		}
		
		if(defined($func))
		{
#		    print STDERR "S: writing arb from func...\n";
		    my $end = 0;
		    my $arb;
		    while($ok && !$end)
		    {
			($arb, $end) = $func->($this, $qe->{'tag'}, $qe->{'host'}, $qe->{'port'}, @param);
			$ok = Tana::write_arb($conn, $arb, $end);
		    }
		    
		    if(!$ok)
		    {
			$qe->{'status'} = "failed";
			$this->{'err'} = Tana::error($conn);
			$this->disconnect($qe->{'host'}, $qe->{'port'});
			shift(@$q);
			push(@$sent, $qe);
			
			return (0, $offset < scalar(@$q));
		    }
		}
	    }
	    $qe->{'status'} = "ok";
	    shift(@$q);
	    push(@$sent, $qe);
	}
    }	

    return(1, $offset < scalar(@$q));
}

sub process_read
{
    my $this = shift;
    my $received = shift;
    my $timeout = shift;

    my $pending = 0;

#    if(rand(100000) < 10)
#    {
#	my $ch = $this->{'conns'};
#	print STDERR "Saa::process_read() does can_read for " . scalar(keys(%$ch)) . " sockets\n";
#    }
    my @conns = $this->{'conn_sel'}->can_read(0);
    my @cns = keys(%{$this->{'conns'}});

#    print STDERR "read conns: " . scalar(@conns) . Dumper(@conns);
    
    my $conn;
    foreach $conn (@conns)
    {
	my $cn;
	my $cnkey;
	my $found = 0;
	for (@cns)
	{
	    if($this->{'conns'}->{$_}->{'conn'} == $conn)
	    {
		$cn = $this->{'conns'}->{$_};
		$cnkey = $_;
		$found = 1;
		last;
	    }
	}

	my $arb_type = 0;
#		print STDERR "saa: reading msg from " . $conns[$i] . " / " . fileno($conns[$i]) . "\n";
	my $msg = Tana::read($conn, \$arb_type);

#	warn "Saa process_read(): Tana::read() gave msg",Dumper($msg);

	if(!defined($msg))
	{
	    $this->{'err'} = Tana::error($conn);
	    if(scalar(@conns) > scalar(@$received))
	    {
		$pending = 1;
	    }
	    
	    $this->disconnect($cnkey);
	    next;
	}
	my $entry = 
	{
	    'msg' => $msg,
	    'type' => 'fix',
	    'host' => $cn->{'host'},
	    'port' => $cn->{'port'},
	    'conn' => $conn,
	};
	if(defined($arb_type))
	{
	    $entry->{'type'} = 'arb';
	    $entry->{'arb_name'} = $arb_type;
	    if(exists($cn->{'auto_arb'}) && ($cn->{'auto_arb'}))
	    {
		my $eom = 0;
		my $arb = '';
		while(!$eom)
		{
		    my $ext = Tana::read_arb($entry->{'conn'}, 1024000, \$eom);
		    if(!defined($ext))
		    {
			$this->{'err'} = "Error auto-reading arb: " . Tana::error($entry->{'conn'});
			if(scalar(@conns) > scalar(@$received))
			{
			    $pending = 1;
			}
			return (0, $pending);
		    }
		    
		    $arb .= $ext;
		}
		
		$entry->{'arb'} = $arb;
	    }
	}
	
	if($cn->{'callback'})
	{
	    my $cb = $cn->{'callback'};
	    my $func = undef;
	    my @param = ();
	    
	    $debug && print STDERR "Callback = ", ref($cb), "\n";
	    if(ref($cb) eq 'CODE')
	    {
		$func = $cb;
	    }
	    else
	    {
		@param = @$cb;
		$func = shift(@param);
	    }
	    $debug && print STDERR "Func cb ref = ", ref($func), "\n";
	    $func->($this, $entry, @param);
	}
	else
	{
	    push(@$received, $entry);
	}
    }

    return (1, 0);
}


sub process
{
    my $this = shift;
    my $timeout = shift;

    $timeout=10;

    my $received = [];
    my $sent = [];

    #cleanup
    for (keys(%{$this->{'conns'}}))
    {
	my $c = $this->{'conns'}->{$_}->{'conn'};
	if((!$c->connected()))
	{
	    print STDERR "Reaping $_\n";
	    my($host, $port) = split("_", $_);
	    $this->disconnect($host, $port);
	}
    }

    # read from conns
#    print STDERR "*saa read\n";
    my ($ok, $pending) = $this->process_read($received, $timeout);
    if(!$ok)
    {
	print STDERR "read sanoi nok\n";
	return (0, $sent, $received, $pending);
    }

#    print STDERR "*saa write\n";
    # write queue
    if($pending)
    {
	($ok, undef) = $this->process_write($sent, $timeout);
    }
    else
    {
	($ok, $pending) = $this->process_write($sent, $timeout);
    }
    if(!$ok)
    {
#	print STDERR "write sanoi nok\n";
	return (0, $sent, $received, $pending);
    }

#    print STDERR "*saa accept\n";
    # accept
    if($pending)
    {
	($ok, undef) = $this->process_accept($timeout);
    }
    else
    {
	($ok, $pending) = $this->process_accept($timeout);
    }

    return ($ok, $sent, $received, $pending);
}

sub tana_msg_reply
{
    my ($saa, $msg, $host, $port, $wait) = @_;

    my $giveup_time = time() + $wait;
    my $done = 0;
    my $reply = undef;
    my $ok = 1;
    do
    {
	if(!$saa->queue($host, $port, $msg))
	{
	    return (0, "Saa::queue() failed: " . $saa->{'err'}); 
	}

	my $received = [];
	$ok = 1;
	while(scalar(@$received) < 1 && (time() < $giveup_time) && $ok)
	{
	    ($ok, undef, $received, undef) = $saa->process(0.1);
	    if(!$ok)
	    {
		return (0, "Saa::process() failed: " . $saa->{'err'});
	    }
	}
	if(scalar(@$received) > 0)
	{
	    $reply = $received->[0]->{'msg'};
	    $done = 1;
	}
    } while((!$done) && (time() < $giveup_time));

    if(!$done)
    {
	return (0, "Timeout.");
    }

    return ($ok, $reply);
}

sub tana_msg_send
{
    my ($saa, $msg, $host, $port, $wait) = @_;

    my $giveup_time = time() + $wait;
    my $done = 0;
    my $stat = undef;
    my $sent = [];
    my $ok = 1;
    do
    {
	if(!$saa->queue($host, $port, $msg))
	{
	    return (0, "Saa::queue() failed: " . $saa->{'err'}); 
	}
	$ok = 1;
	$sent = [];
	while(scalar(@$sent) < 1 && (time() < $giveup_time) && $ok)
	{
	    ($ok, $sent, undef, undef) = $saa->process(0.1);
	    if(!$ok)
	    {
		return (0, "Saa::process() failed: " . $saa->{'err'});
	    }
	}
	if(scalar(@$sent) > 0)
	{
	    $done = 1;
	}
    } while((!$done) && (time() < $giveup_time));

    if(!$done)
    {
	return (0, "Timeout.");
    }

    return ($ok, $sent->[0]->{'status'});
}



1;
