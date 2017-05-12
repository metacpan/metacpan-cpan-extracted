#!/usr/bin/perl

# $Id: datamanager.cgi,v 1.5 2004-04-16 23:00:46 kiesling Exp $

use UnixODBC (':all');
use UnixODBC::BridgeServer;
use RPC::PlClient;

#
# If you change the subdirectory where the data manager HTML
# files are located, change the value of $folder here.
# 
my $folder='datamanager';

my $loginfile = '/usr/local/etc/odbclogins'; # File that contains login data.
my %peers; # Peer host login data from /usr/local/etc/odbclogins

my $peerport = 9999;
my $loginmsg = 'Not connected.';

##
## Connection Status -
##
my $HOST_NOT_CONNECTED = 'Not connected';
my $HOST_CONNECTED = 'Connected';
my $DSN_OPEN = 'Open DSN';
my $CLIENT_LOGIN_ERROR = 'Client login error.';

readlogins();

my $server_addr = $ENV{SERVER_ADDR};

#
# If generating page from the login screen host and dsn at least
# will be filled in.
my ($dsnuser, $dsnpwd, $host, $dsn) = 
	($ENV{'REQUEST_URI'} =~ 
	 /username=(.*?)&password=(.*?)&host=(.*?)&dsn=(.*?)&/);
$dsn =~ s/\+/ /g;
# Temporary strings for URL parameter writing.
my ($datasource, $dsnparam);
# Error return value for connect and show tables query
my $connect_error;
# Array of table names in current DSN
my @tablenames;
# Hosts and child nodes are displayed in order of @dsns array.
my @dsns = ();

my $noconnectstr = 'noconnect';

getdsns();

if ((length($host)) and (length ($dsn))) {
    $connect_error = 
	gettablenames ($host, $dsn, $dsnuser, $dsnpwd);
    if (! defined $connect_error) {
	$loginmsg = 'Connected to data source <i>' . $dsn .
	    '</i> on host <i>' . $host . 
	    '</i> as user <i>' . $dsnuser . '.</i>';
	foreach my $d (@dsns) {
	    if ($d -> {host} =~ m"$host") {
		foreach my $d1 (@{$d -> {dsnarrayref}}) {
		    $d -> {tablearrayref} = \@tablenames if $d1 =~ m"$dsn";
		}
	    }
	}
    } else {
	$loginmsg = 'Login error on host <i>'. $host . '.</i>: '. 
	    $connect_error;
    }
}

sub getdsns {
    foreach my $peeraddr (keys %peers) {
	my ($peerusername, $peerpassword) = split /::/, $peers{$peeraddr}, 2;
	my $dsnptr = new_dsn_label();
	my ($c, $loginerror) = peer_client_login ($peeraddr,
						  $peerusename,
						  $peerpassword);
	if ($c =~ m"$CLIENT_LOGIN_ERROR") {
	    print $loginerror;
	    $dsnptr -> {host} = "$peeraddr - $noconnectstr - $loginerror";
	    push @dsns, ($dsnptr);
	    next;
	}
	$dsnptr -> {host} = $peeraddr;
	$dsnptr -> {dsnarrayref} = remotedsn ($c);
	push @dsns, ($dsnptr);
    }
}

my $header_style_title = <<END_OF_HEADER;
Content-Type: text/html

<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head><title>Data Sources</title>
<style type="text/css">
A {color: blue}
TEXTAREA {background-color: transparent}
DIV.dsnlist {margin-left: 2}
DIV.tablelist {margin-left: 4}
DIV.loginmsg {margin-left: 10}
</style>
</head>
<body bgcolor="white" text="blue">
<img src="/icons/odbc.gif" hspace="5" height = "32" width="30">
<font size="5">Data Sources</font>
<p>
<div class="loginmsg">
$loginmsg<p>
</div>
END_OF_HEADER

my $end_html = <<END_HTML;
</body>
</html>
END_HTML

print $header_style_title;

foreach my $d (@dsns) {
    if ($d -> {host} =~ m"$noconnectstr") { # Couldn't create client object
                                  # so display no-term icon, print 
	                          # error message, and go to next 
                                  # server.
	local ($servername, $loginerror) = 
	    ($d -> {host} =~ m"(.*?) - $noconnectstr - (.*)");
	print qq|   <a href="dsns.shtml">\n|;
	print qq|     <img src="/icons/term-no.gif" border="0" |;
	print qq|     align="middle" hspace="10"><font size="4">\n|;
	print qq|     $servername</font>\n|;
	print qq|   </a>|;
	print qq|   &nbsp;&nbsp;$loginerror<br>\n|;
	next;
    }
    local $dp = $d -> {host};
    print qq|   <a href="dsns.shtml">\n|;
    print qq|     <img src="/icons/terminal.gif" border="0" |;
    print qq|     align="middle" hspace="10"><font size="4">$dp</font></a>\n|;

    foreach my $d2 (@{$d -> {dsnarrayref}}) {
	$dsnparam = $d2;
	$dsnparam =~ s/ /\+/g;
	print qq|<div class="dsnlist">\n|;
	print qq|<a href="http://$server_addr/$folder/|;
        print qq|odbclogin.shtml?hostdsn=$dp--$dsnparam" |;
        print qq| target="main">\n|;
        print qq|<img src="/icons/dsn.gif" border="0" |;
        print qq| align="middle" hspace="10">$d2</a>\n|;
        print qq|</div>\n|;
	
	if ( ($#{$d -> {tablearrayref}} != -1 ) &&
	     ( $d2 =~ m"$dsn") ) {
	    print qq|<div class="tablelist">|;
	    foreach my $table (@{$d -> {tablearrayref}}) {
		local $sp = $d -> {host};
		print qq|<a href="http://$server_addr/$folder/|;
                print qq|tables.shtml?hostdsntable=$sp--$dsnparam--$table&username=$dsnuser&password=$dsnpwd" |;
		print qq| target="main">\n|;
		print qq|<img src="/icons/table.gif" border="0" |;
		print qq| align="middle" hspace="10">$table</a><br>\n|;
	    } # foreach my $table
	    print qq|</div>|;
	} # if $tablearrayref && match $dsn
    } # foreach dsnarrayref 
} # foreach @dsns

endhtml();

sub endhtml {
    print $end_html;
}

sub remotedsn {
    my ($cp) = @_;
    my ($evh, $cnh, $sth, $r);
    my ($r, $sqlstate, $native, $text, $textlen);
    my ($ldsn, $dsnlength, $driver, $driverlength);

    my @dsnnames;

    $evh =  $cp -> sql_alloc_handle ($SQL_HANDLE_ENV, $SQL_NULL_HANDLE);
    $r = $cp -> 
	sql_set_env_attr ($evh, $SQL_ATTR_ODBC_VERSION, $SQL_OV_ODBC2, 0);

    $cnh = $cp -> sql_alloc_handle ($SQL_HANDLE_DBC, $evh);

    ($r, $ldsn, $dsnlength, $driver, $driverlength) = 
	$cp -> sql_data_sources ($evh, $SQL_FETCH_FIRST, 255, 255);
    push @dsnnames, ($ldsn);
    while (1) {
	($r, $ldsn, $dsnlength, $driver, $driverlength) = 
	    $cp -> sql_data_sources ($evh, $SQL_FETCH_NEXT, 255, 255);
	last unless $r == $SQL_SUCCESS;
	push @dsnnames, ($ldsn);
    }

    $r = $cp -> sql_free_handle ($SQL_HANDLE_DBC, $cnh);
    $r = $cp -> sql_free_handle ($SQL_HANDLE_ENV, $evh);

    return \@dsnnames;
}

sub gettablenames {
    my ($lhost, $ldsn, $ldsnuser, $ldsnpwd) = @_;
    my ($r, $sqlstate, $native, $text, $textlen);
    my ($etext, $etextlen);
    my ($evh, $cnh, $sth);
    my ($peerusername, $peerpassword) = split /::/, $peers{$lhost};
    chomp $peerusername; chomp $peerpassword;
    my ($c, $loginerror) = peer_client_login ($lhost, 
					      $peerusername,
					      $peerpassword);

    print "$c\n";
    if ($c =~ m"$CLIENT_LOGIN_ERROR") {
	return $loginerror;
    }
	
    $evh =  $c -> sql_alloc_handle ($SQL_HANDLE_ENV, $SQL_NULL_HANDLE);
    if (defined $evh) { 
	$r = $c -> 
	    sql_set_env_attr ($evh, $SQL_ATTR_ODBC_VERSION, $SQL_OV_ODBC2, 0);
    } else {
	return odbc_diag_message ($c, $SQL_HANDLE_ENV, $evh, 
				  'gettablenames', 'sql_set_env_attr');
    }

    $cnh = $c -> sql_alloc_handle ($SQL_HANDLE_DBC, $evh);
    if (! defined $cnh) {
	return odbc_diag_message ($c, $SQL_HANDLE_ENV, $evh, 
				  'gettablenames', 
				  'sql_alloc_handle (cnh)');
    }

    $r = $c -> sql_connect ($cnh, $ldsn, length($ldsn),
			$ldsnuser, length($ldsnuser), 
			$ldsnpwd, length($ldsnpwd));
    if ($r != $SQL_SUCCESS) {
	return odbc_diag_message ($c, $SQL_HANDLE_DBC, $cnh, 
				  'gettablenames', 'sql_connect');
    }

    $sth = $c -> sql_alloc_handle ($SQL_HANDLE_STMT, $cnh);
    if (! defined $sth) {
	return odbc_diag_message ($c, $SQL_HANDLE_DBC, $cnh, 
				  'gettablenames', 
				  'sql_alloc_handle (sth)');
    }

    $r = $c -> sql_tables ($sth, '*', 0, '*', 0, '*', 0, '*', 0);
    if ($r != $SQL_SUCCESS) {
	return odbc_diag_message ($c, $SQL_HANDLE_STMT, $sth, 
				  'gettablenames', 'sql_tables');
    }

    while (1) {
	$r = $c -> sql_fetch ($sth);
	last if $r == $SQL_NO_DATA;
	($r, $text, $textlen) = 
	    $c -> sql_get_data ($sth, 3, $SQL_C_CHAR, 255);
	if ($r == $SQL_ERROR) {
	    return odbc_diag_message ($c, $SQL_HANDLE_STMT, $sth, 
				  'gettablenames', 'sql_get_data');
	} 
	push @tablenames, ($text);
    }

    $r = $c -> sql_free_handle ($SQL_HANDLE_STMT, $sth);
    if ($r != $SQL_SUCCESS) {
	return odbc_diag_message ($c, $SQL_HANDLE_STMT, $sth, 
				  'gettablenames', 'sql_free_handle (sth)');
    }

    $r = $c -> sql_disconnect ($cnh);
    if ($r != $SQL_SUCESS) {
	return odbc_diag_message ($c, $SQL_HANDLE_DBC, $cnh, 
				  'gettablenames', 'sql_disconnect');
    }

    $r = $c -> sql_free_connect ($cnh);
    if ($r != $SQL_SUCESS) {
	return odbc_diag_message ($c, $SQL_HANDLE_DBC, $cnh, 
				  'gettablenames', 'sql_free_connect');
    }

    $r = $c -> sql_free_handle ($SQL_HANDLE_ENV, $evh);
    if ($r != $SQL_SUCESS) {
	return odbc_diag_message ($c, $SQL_HANDLE_ENV, $evh, 
				  'gettablenames', 'sql_free_handle (evh)');
    }
    return undef;
}

sub readlogins {
    eval { open LOGIN, $loginfile or 
	do {perl_errorpage ("$! while reading $loginfile.");
	     print STDERR "Error reading $loginfile: $!\n";
	     exit 0 };
       };
    my ($line, $host, $userpwd);
    while (defined ($line = <LOGIN>)) {
	next if $line =~ /^\#/;
	next if $line !~ /.*?::.*?::/;
	($host, $userpwd) = split /::/, $line, 2;
	$peers{$host} = $userpwd;
    }
    close LOGIN;

    my $i = 0;
    $i++ foreach (keys %peers);
    if (!$i) {
	perl_errorpage ("No hosts in $loginfile.");
	print STDERR "No hosts in $loginfile: $!\n";
	exit 0;
    }
}

sub peer_client_login {
    my ($peer, $peerusername, $peerpassword) = @_;
    my @clienterror;
    my $client =
	eval { RPC::PlClient->new('peeraddr' => $peer,
                          'peerport' => $peerport,
                          'application' => 'RPC::PlServer',
                          'version' => $UnixODBC::VERSION,
                          'user' => $peerusername,
			  'password' => $peerpassword)};
	  
    if ($@) { 
	return ($CLIENT_LOGIN_ERROR, $@);
    }

    $c = $client -> ClientObject ('BridgeAPI', 'new');
    if (ref $c ne 'RPC::PlClient::Object::BridgeAPI' ) {
	return ($CLIENT_LOGIN_ERROR, "Could not start ODBC peer client: $@.");
    } else {
	return ($c, undef);
    }
}

sub new_dsn_label {
    my $dsn = 
    {
	host => '',
	dsnarrayref => undef,
	tablearrayref => undef
	};
    return $dsn;
}

sub odbc_diag_message {
    my ($c, $handletype, $handle, $func, $unixodbcfunc) = @_;
    my ($rerror, $sqlstate, $native, $etext, $elength);
    ($rerror, $sqlstate, $native, $etext, $elength) = 
	$c -> sql_get_diag_rec ($handletype, $handle, 1, 255);
    return "[$func][$unixodbcfunc]$etext";
}

sub perl_errorpage {
    my $errortext = $_[0];
    print qq{Content-Type: text/html\n\n<html>
		 <font size=4><b>Error:</b></font>
		 <p>
		 $errortext
	     };
}
