#
# WING - Web-IMAP/NNTP Gateway
#
# Wing/Util.pm
#
# Author: Malcolm Beattie, mbeattie@sable.ox.ac.uk
#
# This program may be distributed under the GNU General Public License (GPL)
#
# 25 Aug 1998  Copied from development system to main cluster.
# 23 Feb 1999  Release version 0.5
#
#
# Utility functions for Wing.pm
#
package Wing::Util;
use Apache::Constants qw(:common REDIRECT);
use Wing::Shared;
use Socket;	# for AF_INET and sockaddr_in
use Fcntl;
use HTTP::Date;	# for str2time
use strict;
use vars qw(@ISA @EXPORT);
@ISA = 'Exporter';
@EXPORT = qw(&dont_cache &redirect &wing_error &info_message_html
	     &finger &do_write_file &server_url);

#
# Prevent browser from caching: a simple $r->no_cache(1) is insufficient.
# If the second argument is specified, it's a MIME type which we send
# along with the send_http_header for convenience.
#
sub dont_cache ($;$) {
    my ($r, $type) = @_;
    $r->no_cache(1);
    $r->err_header_out(Pragma => "no-cache");
    $r->err_header_out("Cache-control" => "no-cache");
    if (defined($type)) {
	$r->content_type($type);
	$r->send_http_header;
    }
}

#
# Redirect browser to another URL
#
sub redirect ($$) {
    my ($r, $url) = @_;
    $r->header_out(Location => $url);
    $r->status(REDIRECT);
    $r->send_http_header;
    return OK;
}

#
# Generate a standard WING error message page. This is for errors
# that Should Not Happen (e.g. the user has been messing with
# explicit URLs or trying something naughty) so we don't care too
# much for user-friendliness.
#
sub wing_error ($$) {
    my ($r, $message) = @_;
    dont_cache($r, "text/html");
    $r->print(<<"EOT");
<html><head><title>WING Error</title></head>
<body><h1>WING Error</h1>
$message
</body></html>
EOT
    return OK;
}

sub info_message_html {
    my $s = shift;
    my $info = maild_get_and_reset($s, "message");
    if ($info) {
	$info = "<br><strong>$info</strong><br>\n";
    }
    return $info;
}

sub finger {
    my $username = shift;
    my $html;
    return undef unless $username =~ /^\w{1,8}$/;
    my $dbh = DBI->connect(@WING_DBI_CONNECT_ARGS);
    my ($sender, $group) = $dbh->selectrow_array(<<"EOT");
select sender, groups.name from users, groups
where username='$username' and users.gid = groups.gid
EOT
    if ($sender) {
	my $sender_html = escape_html($sender);
	$html = <<"EOT";
<h4>Canonical email address</h4>
$sender_html
<h4>Group</h4>
$group
<h4>Current login session</h4>
EOT
	my ($host, $start) = $dbh->selectrow_array(
	    "select host, start from sessions where username='$username'"
	);
	
	if ($start) {
	    $host = gethostbyaddr(inet_aton($host), AF_INET) || $host;
	    $start = localtime(str2time($start));
	    substr($start, -5) = "";	# truncate " yyyy" from end
	    $html .= "Logged in at $start from $host\n";
	} else {
	    $html .= "Not currently logged in\n";
	}
    } else {
	$html = "No such username\n";
    }
    $dbh->disconnect;
    return $html;
}

sub do_write_file {
    my ($filename, $contents) = @_;
    local(*FILE);
    if (length($contents) == 0) {
	return unlink($filename) || $! =~ /No such file/;
    }
    sysopen(FILE, $filename, O_CREAT|O_RDWR|O_TRUNC, 0664) or return undef;
    print FILE $contents;
    close(FILE);
    return 1;
}

#
# Note that we must use $r->connection->local_addr to get the port
# and not $r->get_server_port or $r->server->port.
# The former gives the actual port on which this request was
# received (and we listen on both 80 and 81) whereas the latter two
# give the canonical port of the (virtual)host which is always 80.
# Now life gets even more complicated: we also do https which
# listens on 443. There doesn't seem to be a special method to
# pick off "http" or "https" so we just check for 443 and fix up
# the server_url to start with https if so. Blech.
#

sub server_url {
    my ($r, $hostname) = @_;
    my ($port) = sockaddr_in($r->connection->local_addr);
    my $scheme = "http";
    if ($port == 443) {
	$scheme = "https";
	$port = "";
    } elsif ($port == 80) {
	$port = "";
    } else {
	$port = ":$port";
    }
    $hostname ||= $r->server->server_hostname;
    return "$scheme://$hostname$port";
}

1;

