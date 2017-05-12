#
# WING - Web-IMAP/NNTP Gateway
#
# Wing/Admin.pm
#
# Author: Malcolm Beattie, mbeattie@sable.ox.ac.uk
#
# This program may be distributed under the GNU General Public License (GPL)
#
# 23 Feb 1999  Release version 0.5
#
package Wing::Admin;
use Apache::Constants qw(:common REDIRECT);
use Socket;
use DBI;
use HTTP::Date;

use Wing::Shared;
use Wing::Util;
use strict;

sub handler {
    my $r = shift;
    my %q = $r->args;
    my $refresh = $q{refresh} || 0;
    
    my ($junk, $handler, $cmd, @args) = split(m(/), $r->path_info);

    #
    # Sanity-check command. Note in particular that only methods
    # beginning with lower-case a-z are passed on and the actual
    # method name called is prefixed with "cmd_".
    #
    if (length($cmd) > 64 || $cmd !~ /^[a-z]\w*$/) {
        return wing_error($r, "Bad command: $cmd");
    }
    $cmd = "cmd_$cmd";

    my $conn = bless { request => $r, refresh => $refresh };
    #
    # Now handle the requested command
    #
    eval { $conn->$cmd(@args) };
    if ($@ =~ /^Can't locate object method/) {
        return wing_error($r, qq(Unknown command "$cmd" sent to Wing: $@));
    }
    elsif ($@) {
        return wing_error($r, "Command error: message is\n<pre>\n$@\n</pre>");
    }
    return OK;
}

sub cmd_who {
    my ($conn, $opt) = @_;
    my $r = $conn->{request};
    my $refresh = $conn->{refresh};
    my $dbh = DBI->connect(@WING_DBI_CONNECT_ARGS);
    my $sth = $dbh->prepare(<<"EOT");
select s.username, u.sender, host, server, start
from sessions s, users u
where s.username = u.username
order by start
EOT
    return wing_error($r, "DBI prepare failed: $DBI::errstr") unless $sth;
    my $timestamp = localtime(time);
    substr($timestamp, -5) = "";	# remove trailing " yyyy"
    $sth->execute or return wing_error($r, "SQL select failed: $DBI::errstr");
    my $rows = $sth->rows;
    $r->content_type("text/html");
    $r->header_out(Refresh => $refresh) if $refresh;
    $r->send_http_header;
    $r->print(<<"EOT");
<html><head><title>Current WING sessions</title></head>
<body>
<h2 align="center">$rows WING sessions as of $timestamp</h2>
<table width="100%">
<tr>
<th align="left">Username</th>
<th align="left">Full name</th>
<th align="left">Client host</th>
<th align="left">Server</th>
<th align="left" colspan=4>Login time</th>
</tr>
EOT
    while (defined(my $row = $sth->fetchrow_arrayref)) {
	my ($username, $sender, $host, $server, $start) = @$row;
	$server =~ s/\..*//;	# remove trailing domain name
	$sender =~ s/\s*<.*//;	# remove trailing email address
	$host = gethostbyaddr(inet_aton($host), AF_INET) || $host
	    unless $opt eq "-n";
	$start = join("</td><td>",
		     split(' ', scalar(localtime(str2time($start)))));
	substr($start, -5) = "";	# truncate " yyyy" from end
	$r->print(<<"EOT");
<tr>
<td>$username</td>
<td>$sender</td>
<td>$host</td>
<td>$server</td>
<td>$start</td>
</tr>
EOT
    }
    $r->print(<<"EOT");
</table>
</body>
</html>
EOT
    $sth->finish;
    $dbh->disconnect;
}

sub get_stats {
    my $hostname = shift;
    local(*S);
    socket(S, AF_INET, SOCK_STREAM, 0) or return undef;
    my $addr = gethostbyname($hostname) or return undef;
    my $port = getservbyname("gstat", "tcp") or return undef;
    connect(S, sockaddr_in($port, $addr)) or return undef;
    my %stats;
    while (<S>) {
	chomp;
	my ($key, $value) = split(/\s*:\s*/);
	$stats{$key} = $value;
    }
    close(S);
    return \%stats;
}

sub stat_table {
    my ($hosts, $keys, $stats) = @_;
    my $html = <<"EOT";
<table border cellpadding=7>
<tr>
  <th>Hostname</th>
  <th align="right">Mem</th>
  <th colspan=3>Load average</th>
  <th align="right">Mailq</th>
EOT
    $html .= join("\n", map { qq(<th align="right">$_</th>) } @$keys)
	. "\n</tr>\n";
    my @main_keys = qw(freemem load1 load5 load15 mailq);
    foreach my $h (@$hosts) {
	my $st = $stats->{$h};
	my ($freemem, $load1, $load5, $load15, $mailq) = @{$st}{@main_keys};
	$freemem = ($freemem == -1) ? "?" : int($freemem / 1024 + 0.5);
	$load1 = sprintf("%.2f", $load1 / 100);
	$load5 = sprintf("%.2f", $load5 / 100);
	$load15 = sprintf("%.2f", $load15 / 100);
	$html .= <<"EOT";
<tr>
  <td>$h</td>
  <td align="right">$freemem</td>
  <td align="right">$load1</td>
  <td align="right">$load5</td>
  <td align="right">$load15</td>
  <td align="right">$mailq</td>
EOT
	foreach my $k (@$keys) {
	    $html .= qq(<td align="right">$st->{$k}</td>\n);
	}
	$html .= "</tr>\n";
    }
    $html .= "</table>\n";
    return $html;
}

sub cmd_stat {
    my ($conn, $opt) = @_;
    my $r = $conn->{request};
    my $refresh = $conn->{refresh};
    chomp(my @imap_hosts = `/usr/local/sbin/clist imap`);
    chomp(my @wing_hosts = `/usr/local/sbin/clist wing`);
    my @hosts = ("frontend1", "frontend2", @imap_hosts, @wing_hosts);
    my %stats;
    my $timestamp = localtime(time);
    substr($timestamp, -5) = "";	# remove trailing " yyyy"
    foreach my $h (@hosts) {
	$stats{$h} = get_stats($h);
    }
    my @frontend_keys = qw(httpd postgres);
    my @imap_keys = qw(imapd ipopd);
    my @wing_keys = qw(httpd maild);
    $r->content_type("text/html");
    $r->header_out(Refresh => $refresh) if $refresh;
    $r->send_http_header;
    $r->print(<<"EOT");
<html><head><title>Current $WING_SERVICE_NAME status</title></head>
<body>
<h2 align="center">Current $WING_SERVICE_NAME status as of $timestamp</h2>
<h3>Frontends</h3>
EOT
    $r->print(stat_table(["frontend1", "frontend2"], \@frontend_keys, \%stats));
    $r->print("<h3>WING servers</h3>\n");
    $r->print(stat_table(\@wing_hosts, \@wing_keys, \%stats));
    $r->print("<h3>IMAP servers</h3>\n");
    $r->print(stat_table(\@imap_hosts, \@imap_keys, \%stats));
    $r->print("</body></html>\n");
}

sub cmd_du {
    my ($conn, $username) = @_;
    my $r = $conn->{request};
    my $refresh = $conn->{refresh};
    my %q = $r->args;
    $username ||= $q{username};

    if (!$username) {
	$r->content_type("text/html");
	$r->send_http_header;
	$r->print(<<"EOT");
<html><head><title>Disk Usage</title></head>
<body>
<h2 align="center">Disk Usage</h2>
<form>
Username <input name="username" size=8>
<input type="submit" value="Disk Usage">
</form>
</body>
</html>
EOT
	return;
    }

    if ($username !~ /^\w{1,8}$/) {
	$r->content_type("text/plain");
	$r->send_http_header;
	$r->print("Bad username: $username\n");
	return;
    }

    my $dbh = DBI->connect(@WING_DBI_CONNECT_ARGS);
    my ($uid, $gid) = $dbh->selectrow_array(
        "select uid, gid from users where username = '$username'"
    ) or return wing_error($r, "Can't find user/group id: $DBI::errstr");

    my ($group) = $dbh->selectrow_array(
        "select name from groups where gid = $gid"
    ) or return wing_error($r, "Can't map group id to name: $DBI::errstr");
    $dbh->disconnect;

    my @usage;
    {
	local($/) = "\0";       # null terminated records
	chomp(@usage = `$IMAPDU_COMMAND $group $gid $username $uid`);
    }
    if ($? >> 8) {
	return wing_error($r, "Failed to get disk usage information");
    }
    @usage = sort { $b->[0] <=> $a->[0] } map {
	my ($size, $name) = split(' ', $_, 2);
	$name =~ s(^./)();
	$size = int($size / 1024 + 0.5);
	[$size, $name];
    } @usage;
    $r->content_type("text/html");
    $r->header_out(Refresh => $refresh) if $refresh;
    $r->send_http_header;
    $r->print(<<"EOT");
<html><head><title>Disk Usage for $username</title></head>
<body>
<form>
Username <input name="username" value="$username" size=8>
<input type="submit" value="Disk Usage">
</form>
<h2 align="center">Disk Usage for $username</h2>
<table>
<tr><th align="right">Size/KB</th><th align="left">Mailbox</th></tr>
EOT

    my $total = 0;
    while (defined(my $u = shift @usage)) {
	$total += $u->[0];
	my $name_html = escape_html($u->[1]);
	$r->print(
	    qq(<tr><td align="right">$u->[0]</td><td>$name_html</td></tr>\n)
	);
    }
    $r->print("</table>\nTotal usage: $total KB\n</body></html>\n");
}

sub cmd_finger {
    my ($conn, $username) = @_;
    my $r = $conn->{request};
    my %q = $r->args;
    $username ||= $q{username};

    if (!$username) {
	$r->content_type("text/html");
	$r->send_http_header;
	$r->print(<<"EOT");
<html><head><title>Finger</title></head>
<body>
<h2 align="center">Finger</h2>
<form>
Username <input name="username" size=8>
<input type="submit" value="Finger">
</form>
</body>
</html>
EOT
	return;
    }

    my $html = finger($username);
    if (!defined($html)) {
	$r->content_type("text/plain");
	$r->send_http_header;
	$r->print("Bad username: $username\n");
	return;
    }

    $r->content_type("text/html");
    $r->send_http_header;
    $r->print(<<"EOT");
<html><head><title>Finger information for $username</title></head>
<body>
<form>
Username <input name="username" value="$username" size=8>
<input type="submit" value="Finger">
</form>
<h2 align="center">Finger information for $username</h2>
$html
</body>
</html>
EOT
}
1;
