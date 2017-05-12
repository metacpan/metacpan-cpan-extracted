#!/usr/bin/perl

# $Id: tables.cgi,v 1.3 2004-03-13 23:25:07 kiesling Exp $

use UnixODBC (':all');
use UnixODBC::BridgeServer;
use RPC::PlClient;

my $loginfile = '/usr/local/etc/odbclogins'; # File that contains login data.
my %peers; # Peer host login data from /usr/local/etc/odbclogins
readlogins ();

my $dsnquery;
$dsnquery = $ENV{'REQUEST_URI'};

my $peerport = 9999;

my ($host, $dsn, $table, $user, $password, $querytext, @globalfields, @globalparams);

@globalparams = param ($dsnquery);

my $styleheader = <<END_OF_HEADER;
Content-Type: text/html

<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head><title>Untitled Document</title>
<style type="text/css">
A {color: blue}
TEXTAREA {background-color: transparent}
DIV.dsnlist {margin-left: 2}
DIV.tablelist {margin-left: 4}
DIV.loginmsg {margin-left: 10}
</style>
</head>
<body bgcolor="white" text="black">
END_OF_HEADER

starthtml();

# Here's the state determination thing.
if ($dsnquery =~ /hostdsntable/) { # From the dsn frame.
    ($host, $dsn, $table, $user, $password) = 
	($dsnquery =~ 
	 /hostdsntable=(.*?)--(.*?)--(.*?)&username=(.*?)&password=(.*?)$/);
    $dsn =~ s/\+/ /g;
    @globalfields = get_fields ($user, $password, $host, $dsn, $table);
} else { # When redrawing the query form
    ($dsn, $table, $host, $user, $password) =
	($dsnquery =~
	 /dsn=(.*?)&table=(.*?)&host=(.*?)&username=(.*?)&password=(.*?)&/);
    $dsn =~ s/\+/ /g;
    @globalfields = get_fields ($user, $password, $host, $dsn, $table);

    # translate original query from CGI param.
    ($querytext) = 
	($dsnquery =~ /querytext=(.*?)&/);
    $querytext =~ s/\+/ /g;
    local ($sp, $j, $hexcode, $c);
    $sp = '';
    for ($j = 0; $j < length ($querytext); $j++) {
	if (substr ($querytext, $j, 1) eq '%') {
	    $hexcode = substr ($querytext, $j+1, 2);
	    $c = hex_to_char ($hexcode);
	    # if $c translates to actual '%', skip over it.
	    $j += 2;
	    $sp .= $c;
	} else {
	    $sp .= substr ($querytext, $j, 1);
	}
    }
    $querytext = $sp;
}

my $loginform = <<ENDOFLOGINFORM;
 <table align="center" cellpadding="0">
  <colgroup cols="5">
     <tr>
       <td><label>Data Source:</label></td>
       <td><label>Table:</label></td>
       <td><label>Host Name:</label></td>
       <td><label>User Name:</label></td>
       <td><label>Password:</label></td>
     </tr>
     <tr>
       <td><input type="text" name="dsn" value="$dsn"></td>
       <td><input type="text" name="table" value="$table"></td>
       <td><input type="text" name="host" value="$host"></td>
       <td><input type="text" name="username" value="$user"></td>
       <td><input type="password" name="password" value="$password"></td>
     </tr>
  </colgroup>
</table>
<p>
ENDOFLOGINFORM

my $sqltextform = <<ENDOFSQLTEXTFORM;
 <form action="/cgi-bin/tables.cgi">
 <table align="center" cellpadding="0">
  <colgroup cols="5">
     <tr>
       <td><label>Data Source:</label></td>
       <td><label>Table:</label></td>
       <td><label>Host Name:</label></td>
       <td><label>User Name:</label></td>
       <td><label>Password:</label></td>
     </tr>
     <tr>
       <td><input type="text" name="dsn" value="$dsn"></td>
       <td><input type="text" name="table" value="$table"></td>
       <td><input type="text" name="host" value="$host"></td>
       <td><input type="text" name="username" value="$user"></td>
       <td><input type="password" name="password" value="$password"></td>
     </tr>
     <tr>
       <td colspan="5">
         <label>SQL Query Text:</label><br>
         <textarea cols="80" rows="5" name="querytext">$querytext</textarea>
       </td>
     </tr>
     <tr>
       <td colspan="5">
         <input type="submit" name="gettextbox" value="Text Query">
         <input type="submit" name="submitquery" value="SELECT Query">
       </td>
     </tr>
  </colgroup>
</table>
</form>
<hr>
ENDOFSQLTEXTFORM

my $end_html = <<END_HTML;
</body>
</html>
END_HTML

# Here's the state determination thing again,
# because the forms needed to be parsed.
if ($dsnquery =~ /gettextbox=Text\+Query/) {
    print $sqltextform;
    foreach my $p (@globalparams) {
        if ($p =~ /querytext/) {
           ($querytext) = ($p =~ /.*?=(.*?)$/);
        }
    }
    doclientquery () if (defined $querytext and length ($querytext));
} elsif ($dsnquery =~ /submitquery=Submit\+Query/) { # From select form
    fieldform (@globalfields);
    $querytext = buildquery();
    doclientquery ();
} elsif ($dsnparam =~ /submitquery=SELECT\+Query/) { #Return to SELECT form
    fieldform (@globalfields);
} else { # From anywhere else
    fieldform (@globalfields);
}

&endhtml;

### 
### Subroutines 
###

sub buildquery {
    my ($paramname, $paramarg, $querystring, @selectedfields, %predicates);
    my ($tmppred, $npreds);
    $npreds = 0;
   foreach my $p (@globalparams) {
	($paramname, $paramarg) = split /\=/, $p;
	if ($paramname =~ /check_/) {
	    push @selectedfields, ($paramarg) if length $paramarg;
	} elsif ($paramname =~ /input_/) {
	    if (length ($paramarg)) {
		$npreds++;
		$paramname =~ s/input_//;
		$predicates{$paramname} = $paramarg;
	    }
	}
    }
    $querystring = 'select ';
    for (my $i = 0; $i <= $#selectedfields; $i++) {
	$querystring .= $selectedfields[$i] . ', ' if $i < $#selectedfields;
	$querystring .= $selectedfields[$i] . ' ' if $i == $#selectedfields;
    }

    # No fields selected by user, so select all of them in query.
    if ($#selectedfields == -1) {
	$querystring .= ' * ';
    }

    $querystring .= "from $table";
    $querystring .= ' where (' if $npreds;
    foreach my $k (keys %predicates) {
	$querystring .= "$k " . $predicates{$k} . ' and ';
    }
    # remove the final 'and'
    $querystring =~ s/ and $// if $npreds;
    $querystring .= ')' if $npreds;
    $querystring .= ';';
    return $querystring;
}

sub starthtml {
    print $styleheader;
}

sub endhtml {
    print $end_html;
}

sub param {  # Return array of params.
    my $s = $_[0];
    my ($i, $j, $k, $c, $sp, @p1, @p);
    for ($i = length ($s) ; $i >= 0; $i--) {
	if (substr($s, $i, 1) =~ /[&?]/) {
	    push @p1, (substr ( $s, $i + 1 ));
	    $s = substr ($s, 0, $i );
	}
    }
    for ($i = $#p1; $i >= 0; $i--) {
	$p1[$i] =~ s/\+/ /g;
	if ($p1[$i] =~ /\%/) {
	    $sp = '';
	    for ($j = 0; $j < length ($p1[$i]); $j++) {
		if (substr ($p1[$i], $j, 1) eq '%') {
		    $c = substr ($p1[$i], $j+1, 2);
		    $sp .= hex_to_char ($c);
		    $j += 2;
		} else {
		    $sp .= substr ($p1[$i], $j, 1);
		}
	    }
	} else {
	    $sp = $p1[$i];
	}
	push @p, ($sp);
    }
    return @p;
}

sub get_fields {
    my ($userparam, $passwordparam, $hostparam, $dsnparam, $tableparam) =
	@_;
    my ($r, $evh, $cnh, $sth, $text, $ncols, $nrows, $textlen);
    my ($serverlogin, $serverpassword) = 
	split /\:\:/, $peers{$hostparam};
    my @lfields;
    my $client = 
	eval { RPC::PlClient->new('peeraddr' => $host,
				  'peerport' => $peerport,
				  'application' => 'RPC::PlServer',
				  'version' => $UnixODBC::VERSION,
				  'user' => $serverlogin,
				  'password' => $serverpassword) }
    or print "Failed to make first connection: $@\n";
    my $c = $client -> ClientObject ('BridgeAPI', 'new');

    if (ref $c ne 'RPC::PlClient::Object::BridgeAPI') {
	print "Error: Could not create network client.";
	print "Refer to the system log for the server error message.";
    }
    $evh =  $c -> sql_alloc_handle ($SQL_HANDLE_ENV, $SQL_NULL_HANDLE);
    if (defined $evh) { 
	$r = $c -> 
	    sql_set_env_attr ($evh, $SQL_ATTR_ODBC_VERSION, $SQL_OV_ODBC2, 0);
    } else {
	$text = odbc_diag_message ($c, $SQL_HANDLE_ENV, $evh, 'get_fields',
				   'sql_alloc_handle (evh)');
	client_error (0, $text);
	return 1;
    }
    $cnh = $c -> sql_alloc_handle ($SQL_HANDLE_DBC, $evh);
    if (! defined $cnh) {
	$text = odbc_diag_message ($c, $SQL_HANDLE_ENV, $evh, 'get_fields', 
				   'sql_alloc_handle (cnh)');
	client_error (0, $text);
	return 1;
    }
    $r = $c -> sql_connect ($cnh, $dsn, length($dsnparam),
			    $user, length($userparam), 
			    $password, length($passwordparam));
    if ($r != 0) {
	$text = odbc_diag_message ($c, $SQL_HANDLE_DBC, $cnh, 'get_fields',
				   'sql_connect');
	client_error ($r, $text);
    }

    $sth = $c -> sql_alloc_handle ($SQL_HANDLE_STMT, $cnh);
    if (! defined $sth) {
	$text = odbc_diag_message ($c, $SQL_HANDLE_DBC, $cnh, 'get_fields',
				   'sql_alloc_handle (sth)');
	client_error (0, $text);
    }

    $r = $c -> sql_columns ($sth, '', 0, '', 0,
			    $tableparam, length($tableparam), 
			    '', 0);
    if ($r != $SQL_SUCCESS) {
	$text = odbc_diag_message ($c, $SQL_HANDLE_STMT, $sth, 'get_fields',
				   'sql_columns');
	client_error (0, $text);
	return 1;
    }

    while (1) {
	$r = $c -> sql_fetch ($sth);
	last if $r == $SQL_NO_DATA;
	($r, $text, $textlen) = 
	    $c -> sql_get_data ($sth, 4, $SQL_C_CHAR, 255);
	if ($r != $SQL_SUCCESS) {
	    $text = odbc_diag_message ($c, $SQL_HANDLE_STMT, $sth,
				       'get_fields', 'sql_get_data');
	    client_error (0, $text);
	    return 1;
	} 
	push @lfields, ($text);
    }

    $r = $c -> sql_free_handle ($SQL_HANDLE_STMT, $sth);
    if ($r != 0) {
	$text = odbc_diag_message ($c, $SQL_HANDLE_STMT, $sth,
				   'get_fields', 'sql_free_handle (sth)');
	client_error ($r, $text);
    }

    $r = $c -> sql_disconnect ($cnh);
    if ($r != 0) {
	$text = odbc_diag_message ($c, $SQL_HANDLE_DBC, $cnh,
				   'get_fields', 'sql_disconnect');
	client_error ($r, $text);
    }

    $r = $c -> sql_free_connect ($cnh);
    if ($r != 0) {
	$text = odbc_diag_message ($c, $SQL_HANDLE_DBC, $cnh,
				   'get_fields', 'sql_free_connect (cnh)');
	client_error ($r, $text);
    }

    $r = $c -> sql_free_handle ($SQL_HANDLE_ENV, $evh);
    if ($r != 0) {
	$text = odbc_diag_message ($c, $SQL_HANDLE_ENV, $evh,
				   'get_fields', 'sql_free_handle (evh)');
	client_error ($r, $text);
    }
    return @lfields;
}

sub doclientquery {
    my ($r, $evh, $cnh, $sth, $text, $ncols, $nrows);
    my ($name, $namelength, $type, $size, $decimal_digits, $nullable);
    my ($serverlogin, $serverpassword) = split /\:\:/, $peers{$host};
    my $client = 
	eval { RPC::PlClient->new('peeraddr' => $host,
				  'peerport' => $peerport,
				  'application' => 'RPC::PlServer',
				  'version' => $UnixODBC::VERSION,
				  'user' => $serverlogin,
				  'password' => $serverpassword) }
    or print "Failed to make first connection: $@\n";

    my $c = $client -> ClientObject ('BridgeAPI', 'new');

    if (ref $c ne 'RPC::PlClient::Object::BridgeAPI') {
	print "Error: Could not create network client.";
	print "Refer to the system log for the server error message.";
    }

    $evh =  $c -> sql_alloc_handle ($SQL_HANDLE_ENV, $SQL_NULL_HANDLE);
    if (defined $evh) { 
	$r = $c -> 
	    sql_set_env_attr ($evh, $SQL_ATTR_ODBC_VERSION, $SQL_OV_ODBC2, 0);
    } else {
	$text = odbc_diag_message ($c, $SQL_HANDLE_ENV, $evh,
				    'doclientquery', 'sql_alloc_handle (evh)');
	client_error (0, $text);
	return 1;
    }

    $cnh = $c -> sql_alloc_handle ($SQL_HANDLE_DBC, $evh);
    if (! defined $cnh) {
	$text = odbc_diag_message ($c, $SQL_HANDLE_ENV, $evh,
				    'doclientquery', 'sql_alloc_handle (cnh)');
	client_error (0, $text);
	return 1;
    }

    $r = $c -> sql_connect ($cnh, $dsn, length($dsn),
			    $user, length($user), 
			    $password, length($password));
    if ($r != 0) {
	$text = odbc_diag_message ($c, $SQL_HANDLE_ENV, $evh,
				    'doclientquery', 'sql_connect');
	client_error ($r, $text);
    }

    $sth = $c -> sql_alloc_handle ($SQL_HANDLE_STMT, $cnh);
    if (! defined $sth) {
	$text = odbc_diag_message ($c, $SQL_HANDLE_DBC, $cnh,
				    'doclientquery', 'sql_alloc_handle (sth)');
	client_error (0, $text);
    }

    # ODBC is particular about trailing whitespace, so remove it.
    $querytext =~ s/\;.*$/\;/msi;
    $r = $c -> sql_exec_direct ($sth, $querytext, length($querytext));
    if ($r != 0) {
	$text = odbc_diag_message ($c, $SQL_HANDLE_STMT, $sth,
				    'doclientquery', 'sql_exec_direct');
	client_error ($r, $text);
    } else {
	($r, $ncols) = $c -> sql_num_result_columns ($sth);
	if ($r != 0) {
	    $text = odbc_diag_message ($c, $SQL_HANDLE_STMT, $sth,
				    'doclientquery', 'sql_num_result_columns');
	    client_error ($r, $text);
	}

	# Get number of rows and columns in result set.

	($r, $nrows) = $c -> sql_row_count ($sth);
	if ($r != 0) {
	    $text = odbc_diag_message ($c, $SQL_HANDLE_STMT, $sth,
				    'doclientquery', 'sql_row_count');
	    client_error ($r, $text);
	}
	print qq|<i>$nrows rows, $ncols columns in result set.</i><p>|;

	if (($nrows != 0) && ($ncols != 0)) {
	    # Get column descriptions
	    my $row = '<tr>';
	    table_start();
	    foreach my $col (1..$ncols) {
		($r, $name, $namelength, $type, $size, $decimal_digits,
		 $nullable) = $c -> sql_describe_col ($sth, $col, 255);
		if ($r != 0) {
		    $text = odbc_diag_message ($c, $SQL_HANDLE_STMT, $sth,
					       'doclientquery', 
					       'sql_describe_col');
		    client_error ($r, $text);
		    last;
		}
		$row = "$row<td><b>$name</b></td>";
	    }
	    $row = "$row</tr>";
	    print $row;

	    while (1) {
		$r = $c -> sql_fetch ($sth);
		last if $r == $SQL_NO_DATA ;
		$row = '<tr>';
		foreach my $col (1..$ncols) {
		    ($r, $text, $textlen) = 
			$c -> sql_get_data ($sth, $col, 
					    $SQL_CHAR, 65536);
		    if ($r != 0) {
			$text = odbc_diag_message ($c, $SQL_HANDLE_STMT, $sth,
						   'doclientquery', 
						   'sql_get_data');
			client_error ($r, $text);
		    }
		    # This lets blank cells render correctly.
		    $text = '&nbsp;' if (!defined $text or 
					 (length ($text) == 0));
		    $row = "$row<td>$text</td>";
		}
		$row = "$row</tr>";
		print $row;
	    }
	    table_end();
	}
    
	$r = $c -> sql_free_handle ($SQL_HANDLE_STMT, $sth);
	if ($r != 0) {
	    $text = odbc_diag_message ($c, $SQL_HANDLE_STMT, $sth,
				       'doclientquery', 
				       'sql_free_handle (sth)');
	    client_error ($r, $text);
	}

	$r = $c -> sql_disconnect ($cnh);
	if ($r != 0) {
	    $text = odbc_diag_message ($c, $SQL_HANDLE_DBC, $cnh,
				       'doclientquery', 'sql_disconnect');
	    client_error ($r, $text);
	}

	$r = $c -> sql_free_connect ($cnh);
	if ($r != 0) {
	    $text = odbc_diag_message ($c, $SQL_HANDLE_DBC, $cnh,
				       'doclientquery', 
				       'sql_free_connect (cnh)');
	    client_error ($r, $text);
	}

	$r = $c -> sql_free_handle ($SQL_HANDLE_ENV, $evh);
	if ($r != 0) {
	    $text = odbc_diag_message ($c, $SQL_HANDLE_ENV, $evh,
				       'doclientquery', 
				       'sql_free_handle (evh)');
	    client_error ($r, $text);
	}
	return 0;
    }
}

sub fieldform {
    my $columns = $#globalfields + 1;
    my (@check_field, @input_field, $input_val);
    print qq|<form action="/cgi-bin/tables.cgi">|;
    print $loginform;
    &table_start;
    print qq|<colgroup cols="$columns">\n|;
    print qq|<tr>\n|;
    foreach my $f (@globalfields) {
	@check_field = grep /check_$f/, @globalparams;
	if (length ($check_field[0]) ) {
	    print qq|<td><input type="checkbox" name="check_$f" value="$f" checked="1">$f</td>\n|;
	} else {
	    print qq|<td><input type="checkbox" name="check_$f" value="$f">$f</td>\n|;
	}
    }
    print qq|</tr>\n|;
    print qq|<tr>\n|;
    foreach my $f (@globalfields) {
	@input_field = grep /input_$f/, @globalparams;
	if ( length ($input_field[0]) ) {
	    ($input_val) = ($input_field[0] =~ /.*?\=(.*)/);
	    print qq|<td><input type="text" name="input_$f" value="$input_val"></td>\n|;
	} else {
	    print qq|<td><input type="text" name="input_$f" ></td>\n|;
	}
    }
    print qq|</tr>\n|;
    print qq|<tr>\n|;
    print qq|<td colspan="$columns">\n|;
    print qq|<input type="submit" name="submitquery" value="Submit Query">\n|;
    print qq|<input type="submit" name="gettextbox" value="Text Query">\n|;
    print qq|</td>\n|;
    print qq|</tr>\n|;
    print qq|</colgroup>\n|;
    table_end ();
    print qq|</form>|;
}

sub table_start {
    print qq|<table border="1">|;
}

sub table_end {
    print qq|</table>|;
}

sub client_error {
    my ($errno, $text) = @_;
    print qq|<font size="5">Error</font><p>\n|;
    print qq|<pre>ODBC Error Code: $errno</pre><p>\n|;
    print qq|<pre>$text</pre>\n|;
}

sub readlogins {
    open LOGIN, $loginfile or die "Cannot open $loginfile: $!";
    my ($line, $host, $userpwd);
    while (defined ($line = <LOGIN>)) {
	next if $line =~ /^\#/;
	next if $line !~ /.*?::.*?::/;
	($host, $userpwd) = split /::/, $line, 2;
	$peers{$host} = $userpwd;
    }
    close LOGIN;
}

sub odbc_diag_message {
    my ($c, $handletype, $handle, $func, $unixodbcfunc) = @_;
    my ($rerror, $sqlstate, $native, $etext, $elength) = 
	$c -> sql_get_diag_rec ($handletype, $handle, 1, 255);
    return "[$func][$unixodbcfunc]$etext";
}

# Interpreting line endings as spaces is a kludgy way to 
# prevent the SQL Parser from carping over \r and \n in 
# the query.
sub hex_to_char {
    my $hexdigit = $_[0];
    my $hexchars = {  '0A' => ' ', '0D' => ' ', 
	          '20' => ' ', '21' => '!', '22' => '"', '23' => '#', 
		  '24' => '$', '25' => '%', '26' => '&', '27' => '\'',
                  '28' => '(', '29' => ')', '2A' => '*', '2B' => '+', 
                  '2C' => ',', '2D' => '-', '2E' => '.', '2F' => '/', 
                  '30' => '0', '31' => '1', '32' => '2', '33' => '3', 
                  '34' => '4', '35' => '5', '36' => '6', '37' => '7', 
                  '38' => '8', '39' => '9', '3A' => ':', '3B' => ';', 
                  '3C' => '<', '3D' => '=', '3E' => '>', '3F' => '?', 
                  '40' => '@', '41' => 'A', '42' => 'B', '43' => 'C', 
                  '44' => 'D', '45' => 'E', '46' => 'F', '47' => 'G', 
                  '48' => 'H', '49' => 'I', '4A' => 'J', '4B' => 'K', 
                  '4C' => 'L', '4D' => 'M', '4E' => 'N', '4F' => 'O', 
                  '50' => 'P', '51' => 'Q', '52' => 'R', '53' => 'S', 
                  '54' => 'T', '55' => 'U', '56' => 'V', '57' => 'W', 
                  '58' => 'X', '59' => 'Y', '5A' => 'Z', '5B' => '[', 
                  '5C' => '\\','5D' => ']', '5E' => '^', '5F' => '_', 
                  '60' => '`', '61' => 'a', '62' => 'b', '63' => 'c', 
                  '64' => 'd', '65' => 'e', '66' => 'f', '67' => 'g', 
                  '68' => 'h', '69' => 'i', '6A' => 'j', '6B' => 'k', 
                  '6C' => 'l', '6D' => 'm', '6E' => 'n', '6F' => 'o', 
                  '70' => 'p', '71' => 'q', '72' => 'r', '73' => 's', 
                  '74' => 't', '75' => 'u', '76' => 'v', '77' => 'w', 
                  '78' => 'x', '79' => 'y', '7A' => 'z', '7B' => '{', 
                  '7C' => '|', '7D' => '}', '7E' => '~' };

   return $hexchars -> {$hexdigit};
}

