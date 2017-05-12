#
# WING - Web-IMAP/NNTP Gateway
#
# Wing.pm
#
# Author: Malcolm Beattie, mbeattie@sable.ox.ac.uk
#
# This program may be distributed under the GNU General Public License (GPL)
#
# 25 Aug 1998  Copied from development system to main cluster.
# 23 Feb 1999  Release version 0.5
#
package Wing;
use Apache::Constants qw(:common);
use IO::Socket;
use DBI;
use HTTP::Date;		# for time2str
use Wing::Shared;
use Wing::Util;

use strict;

use vars qw($VERSION $dbh);

$VERSION = "0.2";

sub handler {
    my $r = shift;

    if (!$r) {
	Apache->error("null request passed to Wing::handler");
	return OK;
    } elsif ($r->header_only) {
	$r->warn("header_only request for ", $r->path_info);
	return OK;
    }
#    $r->warn("path_info = ", $r->path_info); # debug
    my ($loc, $handler, $username, $url_session, $cmd, @args)
	= split(m(/), $r->path_info);
    #
    # Handle requests to kill current logged-in session
    #
    if ($handler eq "kill") {
	return kill_session($r, $username, $url_session);
    }

    #
    # Otherwise, it's an ordinary /wing/cmd/... command
    #
    my $ip = $r->connection->remote_ip;
    my $conn = bless { request => $r }, "Wing::Connection";

#    $r->warn("Cookie: ", $r->header_in("Cookie")); # debug
    my %sessions = split(/[;=]/, $r->header_in("Cookie"));
    my $session = $sessions{$username};
#    $r->warn("session for username $username is $session"); # debug
    my $server_url = server_url($r);
    $conn->{url_prefix} = "$server_url/wing/cmd/$username/";
    if (!$session) {
	$session = $url_session;
	$conn->{url_prefix} .= $session;
    }
    #
    # If we're checking whether cookies work, bounce now to the init
    # command which sets a few things up with maild and then redirects
    # to list the current folder.
    #
    if ($cmd eq "check-cookie") {
	return redirect($r, "$conn->{url_prefix}/init/$args[0]");
    }
    #
    # Sanity-check username and session identifier
    #
    if (length($username) > 8 || $username =~ /\W/
	|| length($session) != 24 || $session =~ /[^A-Za-z0-9.-]/)
    {
	return wing_error($r, "Bad session identifier or username.");
    }
    $conn->{session} = $session;

    my $sockname = make_session_socket($username, $session);
    my $s = IO::Socket->new(Domain => AF_UNIX,
			    Type => SOCK_STREAM,
			    Peer => $sockname);
    if (!defined($s)) {
	#
	# Forcibly expire bad cookie so the browser won't keep sending it
	#
	my $exp = time2str(time - 1);
	$r->header_out("Set-Cookie" =>
		       make_wing_cookie($username, $session, $exp));
	my ($host, $path_info) = login_url($username);
	my $login_url = server_url($r, $host) . $path_info;
	return wing_error($r, <<"EOT");
Session does not exist (timed out perhaps?).
Please click <a href="$login_url">here</a> to login again.
EOT
    }

    $conn->{maild} = $s;

    #
    # Sanity-check command. Note in particular that only methods
    # beginning with lower-case a-z are passed on and the actual
    # method name called is prefixed with "cmd_".
    #
    if (length($cmd) > 64 || $cmd !~ /^[a-z]\w*$/) {
	return wing_error($r, "Bad command: $cmd");
    }
    $cmd = "cmd_$cmd";

    #
    # Check whether session corresponds to this host
    #
    print $s "check_client_ip $ip\n";
    chomp(my $reply = <$s>);
    if ($reply ne "OK") {
	return wing_error($r, "Security alert: this session did not login "
			     ."from this IP address. Please login properly.");
    }
    #
    # Before handling the command, register a cleanup to close the
    # maild socket. This is because $r->print and $r->read both
    # implicitly set *hard* timeouts rather than soft ones. That means
    # that if we lose the connection to the client (e.g. the client
    # hits "Stop" on their browser) then we still want to close the
    # maild socket before Apache longjmps back to its main handler.
    # If this isn't done, the socket to maild remains open and maild
    # (which is single-threaded for each httpd connection) just hangs
    # rather than responding to new httpd connections.
    #
    $r->register_cleanup(sub { $s->close }); # closure

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
    # $s->close happens in cleanup registered above
    return OK;
}

sub kill_session {
    my ($r, $username, $session) = @_;
    my $pid = 0;
    #
    # Sanity-check username and session identifier
    #
    if (length($username) > 8 || $username =~ /\W/
	|| length($session) != 24 || $session =~ /[^A-Za-z0-9.-]/)
    {
	return wing_error($r, "Bad session identifier or username.");
    }
#    $r->warn("PID $$ kill_session connecting to database for $username");#debug
    my $dbh = DBI->connect(@WING_DBI_CONNECT_ARGS);
    $dbh->{AutoCommit} = 0;
    my $server = $r->server->server_hostname;
    my $sth = $dbh->prepare(
	"select pid from sessions where username = '$username' "
	." and id = '$session' and server = '$server'"
    );
    if ($sth) {
	$dbh->do("lock table sessions");
	if ($sth->execute) {
	    my $row = $sth->fetchrow_arrayref;
	    $pid = $row->[0] if $row;
	}
	$sth->finish;
    }
    if ($pid) {
	#
	# OK, zap the session
	#
	$dbh->do("delete from sessions where username = '$username'");
	$dbh->commit;
	$dbh->disconnect;
#	$r->warn("PID $$ kill_session disconnected from database after session zap");#debug
	unlink(make_session_socket($username, $session));
	kill("TERM", $pid);
	my ($host, $path_info) = login_url($username);
	my $login_url = server_url($r, $host) . $path_info;
	$r->content_type("text/html");
	$r->send_http_header;
	$r->print(<<"EOT");
<html><head><title>WING session killed</title></head>
<body>
Your orphaned session has been killed. Please click
<a href="$login_url">here</a> to login again.
</body></html>
EOT
    } else {
	$dbh->commit;
	$dbh->disconnect;
#	$r->warn("PID $$ kill_session disconnected from database after failed auth");#debug
	$r->content_type("text/html");
	$r->send_http_header;
	$r->print(<<"EOT");
<html><head><title>WING error</title></head>
<body>
The server failed to authenticate you or find your orphaned session.
</body></html>
EOT
    }
    return OK;
}

package Wing::Connection;
use Apache::Constants qw(:common);
use Wing::Shared;
use Wing::Util;
use Fcntl;
use DBI;
use IO::File;
use Socket;
use CrackLib;		# for FascistCheck of proposed passwords
use MIME::Base64;	# for decode_base64 in decode_body_in_place
use HTTP::Date;		# for time2str in cmd_logout
use SQL;
use IO::Handle;
use Mail::Header;

sub _CHUNK_SIZE () { 16384 }	# the chunk size in which we read upload data

sub _receive_upload {
    my ($r, $filename) = @_;
    my $fh = IO::File->new(">$filename") or return "$filename: $!";
    my $field = Mail::Field->new("Content-Type");
    $field->parse($r->header_in("Content-Type"));
    my $boundary = $field->param("boundary");
    my $size = $r->header_in("Content-Length");
    my $count = $size;
    my $buffer;
    my ($client_filename, $type);
    if ($count > $UPLOAD_SIZE_LIMIT) {
	return "upload of $count bytes exceeds limit ($UPLOAD_SIZE_LIMIT bytes)";
    }
#    $r->warn("_receive_upload: client is sending us $count bytes");#debug
    do {
	my $toread = _CHUNK_SIZE;
	if ($toread > $count) {
	    $toread = $count;
	}
#	$r->warn("_receive_upload: trying to read $toread bytes"); # debug
	$buffer = "";	# must reset $buffer or Apache::read appends to it
	my $didread = $r->read($buffer, $toread);
#	$r->warn("_receive_upload: read $didread bytes"); # debug
	if ($didread == 0) {
	    $fh->close;
	    return "unexpected end of data";
	}
	if ($count == $size) {
	    #
	    # first buffer of all: remove the MIME boundary after checking it
	    # and then parse and remove the headers.
	    #
	    if (substr($buffer, 0, length($boundary)+4) ne "--$boundary\r\n") {
		$fh->close;
		return "broken MIME boundary marker at start";
	    }
	    substr($buffer, 0, length($boundary) + 4) = "";
	    if ($buffer !~ s/^(.*?\r\n\r\n)//s) {
		$fh->close;
		return "missing headers";
	    }
	    my $headers = $1;
	    my $deb_headers = $headers;
	    $deb_headers =~ s/\r/\\r/gs;
	    $deb_headers =~ s/\n/\\n/gs;
#	    $r->warn("_receive_upload: MIME headers: $deb_headers");
	    my $head = Mail::Header->new([split(/\r\n/, $headers)]);
	    my $disp = $head->get("Content-Disposition");
	    $client_filename = Mail::Field->new("Content-Disposition",
						$disp)->filename;
	    $type = $head->get("Content-Type");
#	    $r->warn("_receive_upload: disp=$disp, client_filename=$client_filename, type=$type, size=$size");#debug
	}
#	$r->warn("_receive_upload: writing ", length($buffer), " bytes");#debug
	print $fh $buffer;
	$count -= $didread;
    } while ($count > 0);

    #
    # check the trailing MIME boundary is OK
    #
    my $endlen = length($boundary) + 8;
    if (substr($buffer, -$endlen) ne "\r\n--$boundary--\r\n") {
	return "broken MIME boundary marker at end";
    }
    $fh->flush;
    my $filesize = (stat($fh))[7];
#    $r->warn("_receive_upload: filesize $filesize, truncating $endlen bytes to make ", $filesize - $endlen, " bytes");#debug
    truncate($fh, $filesize - $endlen);
    $fh->close;
    $type =~ tr/\r\n//d;
    return ("", $type, $client_filename);
}

sub _replace_body ($$$) {
    my $r = shift;
    my $s = shift;
    print $s "tmpdir\n";
    chomp(my $body_file = <$s>);
    $body_file .= "/body";
    local(*BODY);
    if (!sysopen(BODY, $body_file, O_RDWR|O_CREAT|O_TRUNC, 0600)) {
	my $err = $!;
	$r->content_type("text/plain");
	$r->send_http_header;
	$r->print("failed to open body file: $err");
	$r->warn("failed to open body file: $err");
	return 0;
    }
    print BODY $_[0];
    close(BODY);
    return 1;
}

sub cmd_init {
    my ($conn, $sess_type) = @_;
    my $r = $conn->{request};
    my $s = $conn->{maild};

    print $s "username\n";
    chomp(my $username = <$s>);

#    $r->warn("PID $$ cmd_init connecting to database for $username");#debug
    sql_connect(@WING_DBI_CONNECT_ARGS);
    sql_select(["groups.name" => \my $group], [sender => \my $sender],
	       from => "users, groups",
	       username => $username, "and users.gid = groups.gid");
    sql_fetch
	or return wing_error($r, "Can't find group or sender: $DBI::errstr");
    maild_set($s, "group", $group);
    maild_set($s, "sender", $sender);

    sql_select([signature => \my $signature],
	       [abooklist => \my $abook_list],
	       [composeheaders => \my $compose_headers],
	       [listsize => \my $list_size],
	       [copyoutgoing => \my $copy_outgoing],
	       from => "options",
	       username => $username);
    sql_fetch;
    maild_set($s, "signature", $signature) if defined $signature;
    maild_set($s, "abook_list", $abook_list) if defined $abook_list;
    maild_set($s, "compose_headers", $compose_headers)
	if defined $compose_headers;
    maild_set($s, "list_size", $list_size) if defined $list_size;
    maild_set($s, "copy_outgoing", 1) if $copy_outgoing;

    init_abook_ids($s, $username, $group); # Needs database access
    sql_disconnect;
#    $r->warn("PID $$ cmd_init disconnecting from database");#debug

#    maild_set($s, "message", "Welcome $username");
    if ($sess_type eq "portal") {
	return cmd_portal($conn);
    }
    return redirect($r, "$conn->{url_prefix}/list/last");
}

sub cmd_list {
    my ($conn, $start, $rand) = @_;
    my $r = $conn->{request};
    dont_cache($r, "text/html");
    my $s = $conn->{maild};
    my $url_prefix = $conn->{url_prefix};
    my $session = $conn->{session};

    my $info_msg = info_message_html($s);
    maild_set($s, "abook_return", "list");
    my $portal = maild_get($s, "portal");

    print $s "list $start\n";
    chomp(my $folder = <$s>);
    chomp(my $position = <$s>);
    chomp(my $flags = <$s>);
    my ($from, $to, $nmsgs) = split(' ', $position);
    my $can_save = $flags =~ /S/;
    my $can_delete = $flags =~ /D/;
    $r->print("<html><head><title>$folder</title></head>\n<body>\n");

    my ($prev_frag, $next_frag, $top_frag, $bottom_frag);
    if ($from == 1) {
	$prev_frag = '<img src="/wing-icons/arrow-up-inactive.gif" alt="      ">';
	$top_frag = '<img src="/wing-icons/top-inactive.gif" alt="      ">';
    } else {
	$prev_frag = <<"EOT";
<a href="$url_prefix/list/prev">
  <img src="/wing-icons/arrow-up.gif" border=0 alt="Prev"></a>
EOT
	$top_frag = <<"EOT";
<a href="$url_prefix/list/first">
  <img src="/wing-icons/top.gif" border=0 alt="Top"></a>
EOT
    }
    if ($to == $nmsgs) {
	$next_frag = '<img src="/wing-icons/arrow-down-inactive.gif" alt="      ">';
	$bottom_frag='<img src="/wing-icons/bottom-inactive.gif" alt="      ">';
    } else {
	$next_frag = <<"EOT";
<a href="$url_prefix/list/next">
  <img src="/wing-icons/arrow-down.gif" border=0 alt="Next"></a>
EOT
	$bottom_frag = <<"EOT";
<a href="$url_prefix/list/last">
  <img src="/wing-icons/bottom.gif" border=0 alt="Bottom"></a>
EOT
    }

    my $links_html = $portal ? "" : <<"EOT";
<td><a href="$url_prefix/links">
  <img src="/wing-icons/links.gif" border=0 alt="Links"></a></td>
EOT

    my $header = <<"EOT";
<table width="100%">
<tr>
<td><a href="$url_prefix/help/list">
  <img src="/wing-icons/help.gif" border=0 alt="Help"></a></td>
<td>$prev_frag</td>
<td>$next_frag</td>
<td>$top_frag</td>
<td>$bottom_frag</td>
<td><a href="$url_prefix/compose">
  <img src="/wing-icons/compose.gif" border=0 alt="Compose"></a></td>
<td><a href="$url_prefix/mailboxes">
  <img src="/wing-icons/mailboxes.gif" border=0 alt="Mailboxes"></a></td>
<td><a href="$url_prefix/manage">
  <img src="/wing-icons/manage.gif" border=0 alt="Manage"></a></td>
<td><a href="$url_prefix/options">
  <img src="/wing-icons/options.gif" border=0 alt="Options"></a></td>
<td><a href="$url_prefix/expunge">
  <img src="/wing-icons/purge.gif" border=0 alt="Purge"></a></td>
<td><a href="$url_prefix/abook_list/list">
 <img src="/wing-icons/address-books.gif" border=0 alt="Address Books"></a></td>
$links_html
<td><a href="$url_prefix/logout//list">
  <img src="/wing-icons/logout.gif" border=0 alt="Logout"></a></td>
</tr>
</table>
EOT

    my $message_s = $nmsgs == 1 ? "message" : "messages";
    $r->print($header, $info_msg, <<"EOT");
<h1 align="center">Mailbox `$folder' with $nmsgs $message_s</h1>
<table width="100%">
EOT
    while (1) {
	chomp(my $msgno = <$s>);
	if (!$msgno) {
	    $r->log_error("list: maild daemon vanished unexpectedly");
	    last;
	}
#	$r->warn("list: headers for msgno $msgno");#debug
	last if $msgno eq "."; # the proper way to terminate the list
	chomp(my $uid = <$s>);
	chomp(my $date = <$s>);
	chomp(my $display_address = <$s>);
	chomp(my $size = <$s>);
	chomp(my $flags = <$s>);
	chomp(my $subject = <$s>);
	$subject ||= "(No subject)"; # (Subjects of "0" deserve to lose :-)
	#
	# Calculate status:
	#     N (new) if \Recent set but \Seen not set
	#     O (old) if neither \Recent nor \Seen set
	#     " " otherwise
	#     Append "D" if \Deleted, "A" if \Answered, "F" if \Flagged
	#
	my %flags = map { $_ => 1 } split(' ', $flags);
	#
	# Right Hand Side has Save/Reply/Forward buttons (where
	# appropriate to the protocol) and a Delete or Undelete
	# button, depending on whether the message is undeleted or
	# deleted (resp).
	#
	my ($status, $is_deleted, $rhs);
	$is_deleted = $flags{"\\Deleted"};
	$status = $is_deleted ? "D" : "&nbsp;";
	if ($can_save) {
	    $rhs = qq(<a href="$url_prefix/save/move/list/$msgno">S</a>\n);
	} else {
	    $rhs = "";
	}
	$rhs .= <<"EOT";
<a href="$url_prefix/reply/$uid/$msgno">R</a>
<a href="$url_prefix/forward/$uid/$msgno">F</a>
EOT
	if ($can_delete) {
	    if ($is_deleted) {
		$rhs .= qq(<a href="$url_prefix/undelete/$uid/$msgno/list">U</a>\n);
	    } else {
		$rhs .= qq(<a href="$url_prefix/delete/$uid/$msgno">D</a>\n);
	    }
	}
	if ($flags{"\\Seen"}) {
	    $status .= "&nbsp;";
	} elsif ($flags{"\\Recent"}) {
	    $status .= "N";
	} else {
	    $status .= "O";
	}
	$status .= $flags{"\\Answered"} ? "A" : "&nbsp;";
	$status .= $flags{"\\Flagged"} ? "F" : "&nbsp;";

	$r->print(<<"EOT");
<tr>
<td>$status</td>
<td align="right"><strong>$msgno.</strong></td>
<td nowrap>$date</td>
<td nowrap>$display_address</td>
<td align="right">$size</td>
<td nowrap><a href="$url_prefix/display/$uid/$msgno">$subject</a></td>
<td nowrap>$rhs</td>
</tr>
EOT
    }
#    $r->print("</table>\n", $header, "</body></html>\n");
#   Maybe better without the header across the bottom too
    $r->print("</table>\n", "</body></html>\n");
}

sub _input_structure {
    my ($r, $s) = @_;
    chomp(my $id = <$s>);
    if ($id eq ".") {
#	$r->warn("_input_structure returning undef");#debug
	return undef;
    }
    elsif ($id eq "+") {
#	$r->warn("_input_structure read +");#debug
	my @parts = ();
	my $part;
	do {
	    $part = _input_structure($r, $s);
	    push(@parts, $part) if defined($part);
#	    $r->warn("_input_structure pushed $part");#debug
	} while defined($part);
	return bless \@parts, "Wing::Multipart";
    }
    else {
	chomp(my $type = <$s>);
	chomp(my $description = <$s>);
	chomp(my $size = <$s>);
	chomp(my $encoding = <$s>);
	chomp(my $params = <$s>);
#	$r->warn("_input_structure read info for id $id: ",
#		 "type: $type, descr: $description, size: $size, ",
#		 "encoding: $encoding, params: $params");#debug
	return [$id, $type, $description, $size, $encoding, $params];
    }
}

sub _show_structure {
    my ($r, $uid, $msgno, $part, $url_prefix) = @_;
    if (ref($part->[0])) {
#	$r->warn("_show_structure: part is a ref");#debug
	$r->print("<ol>\n");
	foreach my $p (@$part) {
	    $r->print("<li>");
#	    $r->warn("_show_structure: recursing for part $part");#debug
	    _show_structure($r, $uid, $msgno, $p, $url_prefix);
	}
	$r->print("</ol>");
    } else {
	my ($id, $type, $description, $size, $encoding, $params) = @$part;
#	$r->warn("_show_structure writing info for id $id");#debug
	my $name = "noname";
	#
	# The way we extract the recommended name from params is a bit
	# yucky--we really ought to get maild to send it us separately.
	#
	if ($params =~ /\bname="(.*?)"/i) {
	    $name = $1;
	    $name =~ s(.*/)();
	}

	my $url;
	if ($type eq "text/plain") {
	    $url = sprintf("%s/display/%d/%d/%s/%s/%s/%s/%s", 
			  $url_prefix, $uid, $msgno, $id,
			  canon_encode($type,$encoding,$params,$description));
	} else {
	    $url = sprintf("%s/rawdisplay/%d/%s/%s/%s/%s/%s", 
			  $url_prefix, $msgno, $id,
			  canon_encode($type, $encoding, $params), $name);
	}
	#
	# Not sure if we want the target here (which makes these URLs appear
	# in a newly created window on browsers which support "target")
	# 21 Oct 1998. Let's try without for a while.
	#$r->print(qq[<a href="$url" target="display">$description ($type), $size</a>\n]);
	$r->print(qq[<a href="$url">$description ($type), $size</a>\n]);
    }
}

#
# Handle encodings of base64 and quoted-printable
# Called as decode_body_in_place($encoding, $body)
# As the name suggests, we modify the second argument in-place
#
sub decode_body_in_place {
    my $encoding = shift;
    return unless $encoding and defined($_[0]) and length($_[0]);
    $encoding = lc($encoding);
    for ($_[0]) {
	if ($encoding eq "base64") {
	    $_ = decode_base64($_);
	} elsif ($encoding eq "quoted-printable") {
	    #
	    # We need to change line endings CRLF -> LF first before doing
	    # the decode. Instead of doing that first and then calling
	    # MIME::QuotedPrint decode_qp() we do it all in one for speed.
	    #
	    s/[ \t]*\r?$//mg;
	    s/=\n//sg;
	    s/=([0-9a-fA-F]{2})/chr(hex($1))/ge;
	}
    }
}

sub cmd_rawdisplay {
    my $conn = shift;
    my $r = $conn->{request};
    my ($msgno, $mime_sect, $type, $encoding, $params, $name) = @_;
    ($type, $encoding, $params) = canon_decode($type, $encoding, $params);
    my $s = $conn->{maild};
    #
    # Send a message/delivery-status type (RFC1894) to the browser as
    # test/plain since otherwise most don't know what to do with it
    #
    if ($type eq "message/delivery-status") {
	$type = "text/plain";
    }
    $type .= "; $params" if $params;
    $r->content_type($type);
    print $s "body $msgno $mime_sect\n";
    chomp(my $size = <$s>);
#    $r->warn("rawdisplay: type=$type, encoding=$encoding, size=$size");#debug
    read($s, my $body, $size);
    #
    # Sanity check
    #
    if ($size != length($body)) {
	$r->warn("rawdisplay: only got ", length($body),
		 "bytes instead of $size while reading body");
    }
    decode_body_in_place($encoding, $body);
    # Try to stop extra \r characters from creeping in
    $r->header_out("Content-Transfer-Encoding" => "binary");

    $r->header_out("Content-Length" => length($body));
    $r->send_http_header;
#    $r->warn("rawdisplay: sending ", length($body), " bytes to client");#debug
    $r->print($body);
}

sub cmd_display {
    my ($conn, $uid, $msgno, $mime_sect, @mime_stuff) = @_;
    my ($type, $encoding, $params, $description) = canon_decode(@mime_stuff);
    my $r = $conn->{request};
    my $url_prefix = $conn->{url_prefix};
    my $callback = "display/$uid/$msgno/$mime_sect" . join("/", @mime_stuff);
    my $logout_callback = canon_encode($callback);
    my $s = $conn->{maild};
#    $r->warn("display ", join(", ", @_)); # debug

    my $body;
    my $subject;
    my $header_html;

    maild_set($s, "abook_return", $callback);
    print $s "nmsgs\n";
    chomp(my $nmsgs = <$s>);
    if ($msgno < 1 || $msgno > $nmsgs) {
	$r->content_type("text/plain");
	$r->send_http_header;
	$r->print("Bad message number: $msgno\n");
	return OK;
    }

    print $s "prev_next $msgno\n";
    chomp(my $line = <$s>);
    my ($prev_uid, $prev_msgno, $next_uid, $next_msgno) = split(' ', $line);
    my ($prev_frag, $next_frag);
    if ($prev_msgno) {
	$prev_frag = <<"EOT";
<a href="$url_prefix/display/$prev_uid/$prev_msgno">
<img src="/wing-icons/left.gif" border=0 alt="Prev"></a>
EOT
    } else {
	$prev_frag = '<img src="/wing-icons/left-inactive.gif" alt="      ">';
    }
    if ($next_msgno) {
	$next_frag = <<"EOT";
<a href="$url_prefix/display/$next_uid/$next_msgno">
<img src="/wing-icons/right.gif" border=0 alt="Next"></a>
EOT
    } else {
	$next_frag = '<img src="/wing-icons/right-inactive.gif" alt="      ">';
    }

    dont_cache($r, "text/html");
    print $s "structure $msgno\n";
    my $struct = _input_structure($r, $s);
    print $s "flags $msgno\n";
    chomp(my $flagstring = <$s>);
    my %flags = map { $_ => 1 } split(' ', $flagstring);
    my $is_multipart = (ref $struct eq "Wing::Multipart");
    if (defined($mime_sect)) {
	$subject = $description;
    } else {
	print $s "headers $msgno\n";
	chomp(my $size = <$s>);
	read($s, my $hdrtext, $size);
	$hdrtext =~ tr/\r//d;
	$hdrtext =~ s/\n\s+/ /gs;	# Fold header continuation lines
	my %headers = $hdrtext =~ /^(.*?): (.*)$/mg;
	$subject = $headers{Subject} || "(No subject)";
	$header_html = "<table>\n";
	while (my ($hdr, $val) = each %headers) {
	    next if $hdr eq "Subject";
	    $val = escape_html($val);
	    $header_html .= <<"EOT";
<tr><td align=left><strong>${hdr}:</strong></td><td align=left>$val</td></tr>
EOT
	}
	$header_html .= "</table>\n";
    }

    #
    # First show the command buttons
    #
    my $del_or_undel = $flags{"\\Deleted"} ? "undelete" : "delete";
    $r->print(<<"EOT");
<html><head><title>$subject</title></head>
<body>
<table width="100%"><tr>
<td>$prev_frag</td>
<td>$next_frag</td>
<td><a href="$url_prefix/list"><img src="/icons/back.gif" border=0 alt="Back"></a></td>
<td><a href="$url_prefix/download/$uid/msg$msgno">
  <img src="/wing-icons/download.gif" border=0 alt="Download"></a></td>
<td><a href="$url_prefix/reply/$uid/$msgno">
  <img src="/wing-icons/reply.gif" border=0 alt="Reply"></a></td>
<td><a href="$url_prefix/forward/$uid/$msgno">
  <img src="/wing-icons/forward.gif" border=0 alt="Forward"></a></td>
<td><a href="$url_prefix/save/move/$uid-$msgno/$msgno">
  <img src="/wing-icons/save.gif" border=0 alt="Save"></a></td>
<td><a href="$url_prefix/save/copy/$uid-$msgno/$msgno">
  <img src="/wing-icons/copy.gif" border=0 alt="Copy"></a></td>
<td><a href="$url_prefix/compose/fresh">
  <img src="/wing-icons/compose.gif" border=0 alt="Compose"></a></td>
<td><a href="$url_prefix/$del_or_undel/$uid/$msgno/display">
  <img src="/wing-icons/$del_or_undel.gif" border=0 alt="\u$del_or_undel"></a></td>
<td><a href="$url_prefix/abook_list">
  <img src="/wing-icons/address-books.gif" border=0 alt="Address Books"></a></td>
<td><a href="$url_prefix/logout//$logout_callback">
  <img src="/wing-icons/logout.gif" border=0 alt="Logout"></a></td>
</tr></table>
<br>
EOT
    #
    # Then any information message and the message number/subject as title
    #
    my $info_msg = info_message_html($s);
    $r->print($info_msg, <<"EOT");
<h3>Message $msgno/$nmsgs</h3>
<h1 align="center">$subject</h1>
EOT

    #
    #
    # Then any flag information (Deleted, New, ...)
    #
    my @info;
    push(@info, "Deleted") if $flags{"\\Deleted"};
    push(@info, "Answered") if $flags{"\\Answered"};
    push(@info, "Flagged") if $flags{"\\Flagged"};
    $r->print("<h3>(", join(", ", @info), ")</h3>\n") if @info;
    #
    # Then show the header information (unless we're showing a MIME subpart)
    #
    $r->print($header_html) if defined($header_html);

    #
    # Now show the MIME hierarchy for multipart messages
    #
    if ($is_multipart) {
	$r->print(<<"EOT");
<hr>
<h3>MIME structure of
<a href="$url_prefix/display/$uid/$msgno">this message</a></h3>
EOT
	_show_structure($r, $uid, $msgno, $struct, $url_prefix);
	$r->print("<hr>\n");
    }
	
    #
    # Finally show the body (or MIME subpart of the body) if it's
    # (a) single part or (b) we're doing an explicit $mime_sect or
    # (c) we're doing a multipart whose first part is text/plain
    # We need to be careful to get the right encoding
    #
    my $body_cmd;
    my $body_encoding;
    if (defined($mime_sect)) {
	$body_cmd = "body $msgno $mime_sect";
	$body_encoding = $encoding;
    }
    elsif ($is_multipart) {
	if ($struct->[0]->[1] eq "text/plain") {
	    $body_cmd = "body $msgno 1";
	    $body_encoding = $struct->[0]->[4];
 	}
    }
    else {
	$body_cmd = "body $msgno";
	$body_encoding = $struct->[4];
    }
    if (defined($body_cmd)) {
	print $s $body_cmd, "\n";
	chomp(my $size = <$s>);
	read($s, $body, $size);
	decode_body_in_place($body_encoding, $body);
	$body =~ s/</&lt;/g;
	#
	# The following regexp attempts to match "reasonable" URLs.
	# The general description in RFC1738 is too generic and
	# gives false positives on a whole load of things (e.g. 12:34).
	#
	$body =~ s{(?igx)
	    \b([a-z][a-z0-9+.-]{2,9}:[a-z0-9.%&=?/\\~\@:;,_+|-]+)
        }{<a href="$1">$1</a>};
	$r->print("<pre>\n", $body, "</pre>\n");
    }
    $r->print("</body></html>\n");
}

#sub structure {
#    my ($conn, $uid, $msgno) = @_;
#    my $r = $conn->{request};
#    $r->content_type("text/html");
#    $r->send_http_header;
#    my $s = $conn->{maild};
#    print $s "structure $msgno\n";
#    my $struct = _input_structure($r, $s);
#    $r->print(<<"EOT");
#<html><head><title>Structure of message $msgno</title></head>
#<body><h1 align="center">Structure of message $msgno</h1>
#EOT
#    my $url_prefix = $conn->{url_prefix};
#    _show_structure($r, $uid, $msgno, $struct, $url_prefix);
#    $r->print("</body></html>\n");
#}
    
sub cmd_download {
    my ($conn, $uid, $msgno) = @_;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    $msgno =~ s/^\D*//;
    print $s "headers $msgno all\n";
    chomp(my $size = <$s>);
    read($s, my $headers, $size);
    $headers =~ tr/\r//d;

    print $s "body $msgno\n";
    chomp($size = <$s>);
    read($s, my $body, $size);
    $r->content_type("text/plain");
    $r->send_http_header;
    $r->print($headers, $body);
}

sub cmd_chdir {
    my ($conn, $which) = @_;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my %in = $r->args;
    if (exists($in{cwd})) {
	maild_set($s, "cwd", url_decode($in{cwd}));
    }
    if (exists($in{filter})) {
	maild_set($s, "filter", url_decode($in{filter}));
    }
    if (!defined($which)) {
	$which = "browse";
    } elsif ($which ne "browse" && $which !~ /^(save_)?(copy|move)$/) {
	return wing_error($r, "subcommand must be browse/copy/move/save_copy/save_move");
    }
    return redirect($r, "$conn->{url_prefix}/mailboxes/$which");
}

sub cmd_logout {
    my ($conn, $confirm, $callback_raw) = @_;
    my $callback = canon_decode($callback_raw);
    my $r = $conn->{request};
    my $session = $conn->{session};
    my $s = $conn->{maild};
    if ($confirm ne "confirm") {
	my $url_prefix = $conn->{url_prefix};
	dont_cache($r, "text/html");
	$r->print(<<"EOT");
<html><head><title>Confirm logout</title></head>
<body>
<h1 align="center">Confirm logout</h1>
<table width="100%">
<tr>
<td align="center">
<a href="$url_prefix/$callback">
  <img src="/wing-icons/cancel-logout.gif" border=0 alt="Cancel logout"></a>
</td>
<td align="center">
<a href="$url_prefix/logout/confirm/$callback_raw" target="_parent">
  <img src="/wing-icons/confirm-logout.gif" border=0 alt="Confirm logout"></a>
</td>
</tr>
</table>
</body></html>
EOT
	return;
    }

    print $s "username\n";
    chomp(my $username = <$s>);
    print $s "logout\n";
    chomp(my $result = <$s>);
#    $r->warn("PID $$ cmd_logout connecting to database for $username");#debug
    my $dbh = DBI->connect(@WING_DBI_CONNECT_ARGS);
    if ($dbh) {
	my $rows = $dbh->do("delete from sessions where id = '$session'");
	$dbh->disconnect;
#	$r->warn("PID $$ cmd_logout disconnected from database");#debug
	$r->log_error("logout: session deletion failed") unless $rows == 1;
    } else {
	$r->log_error("logout: DBI->connect failed: $DBI::errstr");
    }
    #
    # Force expiry of session cookie so that next failed login attempt
    # doesn't present the stale one (resulting in a "no such session"
    # error instead of a "login incorrect" error).
    #
    my $exp = time2str(time - 1);
    $r->header_out("Set-Cookie" =>
		       make_wing_cookie($username, $session, $exp));
    my ($host, $path_info) = login_url();
    my $login_url = server_url($r, $host) . $path_info;
    return redirect($r, $login_url);
}

sub cmd_compose {
    my ($conn, $prepare) = @_;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my $url_prefix = $conn->{url_prefix};
    my $body_uptodate = 0;
    my $body;

    local(*BODY);
    print $s "tmpdir\n";
    chomp(my $body_file = <$s>);
    $body_file .= "/body";

    my $copy_outgoing = maild_get($s, "copy_outgoing");
    my $copy_outgoing_checked = $copy_outgoing ? " checked" : "";

    my $signature = maild_get($s, "signature");

    maild_set($s, "abook_return", "compose");
    my @header_list = split(' ', maild_get($s, "compose_headers"));
    my %headers;
    foreach my $h (@header_list) {
	if ($prepare eq "fresh") {
	    $headers{$h} = "";
	} else {
	    $headers{$h} = maild_get($s, "hdr_$h");
	}
    }
    if ($r->method eq "POST") {
	my %q = $r->content;
	$body = $q{body};
	if (defined($body)) {
	    $body =~ tr/\r//d;
	    _replace_body($r, $s, $body);
	    $body_uptodate = 1;
	}
	#
	# Process headers and submissions
	#
	my ($lookup, $submit, $redirect, $clear_headers, @pending_lookup);
	while (my ($key, $value) = each %q) {
	    if ($key =~ /^hdr_([A-Z][\w-]*)$/ && exists($headers{$1})) {
		$headers{$1} = $value;
		maild_set($s, $key, $value);
	    }
	    elsif ($key =~ /^abook_([A-Z][\w-]*)$/) {
		push(@pending_lookup, $1);
	    }
	    elsif ($key eq "clear_body") {
		$prepare = "fresh"; # equivalent to clearing out body
	    }
	    elsif ($key eq "clear_headers") {
		$clear_headers = 1;
	    }
	    elsif ($key eq "copy_outgoing") {
		my $newval = $value ? 1 : 0;
		if ($newval != $copy_outgoing) {
		    maild_set($s, "copy_outgoing", $newval);
		    $copy_outgoing = $newval;
		    $copy_outgoing_checked = $copy_outgoing ? " checked" : "";
		}
	    }
	    elsif ($key =~ /^sub_(send|save|include|list|attachments|abook_list|add_header|del_header)/) {
		$submit = $1;
	    }
	}

	if (defined($submit) && $submit ne "save") {
	    $redirect = $submit;
	}
	foreach my $hdr (@pending_lookup) {
	    #
	    # lookup value for header in address books and username table
	    #
	    my $result = _lookup_alias($conn, maild_get($s, "hdr_$hdr"));
	    $headers{$hdr} = $result;
	    maild_set($s, "hdr_$hdr", $result);
	}
	if (defined($redirect)) {
	    return redirect($r, "$url_prefix/$redirect");
	}
	if ($clear_headers) {
	    foreach my $h (@header_list) {
		maild_reset($s, "hdr_$h");
		$headers{$h} = "";
	    }
	}
    }

    #
    # We get here either because this is the first time on this
    # screen (i.e. it's method GET instead of POST) or else we've
    # fallen through the above (currently only possibly by
    # clicking on "Save").
    #
    if ($prepare eq "fresh") {
	truncate($body_file, 0);
	$body = ($signature =~ /\S/) ? "-- \n$signature" : "";
	$body_uptodate = 1;
    }
    if (!$body_uptodate) {
	my $body_existed = -e $body_file;
	if (!sysopen(BODY, $body_file, O_RDWR|O_CREAT, 0600)) {
	    my $err = $!;
	    $r->content_type("text/plain");
	    $r->send_http_header;
	    $r->print("failed to open body file: $err");
	    $r->warn("failed to open body file: $err");
	    return;
	}
	if ($body_existed) {
	    local($/); # slurp whole file
	    $body = <BODY>;
	} else {
	    $body = "";
	    if ($signature =~ /\S/) {
		$body = "-- \n$signature";
		print BODY $body;
	    }
	}
	close(BODY);
	$body_uptodate = 1;
    }
    dont_cache($r, "text/html");
    #
    # Removed <input type="submit" name="sub_save" value="Save">
    # from after Send button
    #
    $r->print(<<"EOT");
<html><head><title>Draft message</title>
<body>
<form method="POST" action="$url_prefix/compose">
<input type="submit" name="sub_list" value="Cancel">
<input type="submit" name="sub_send" value="Send">
<input type="submit" name="sub_include" value="Include">
<input type="submit" name="sub_attachments" value="MIME Attachments">
<input type="submit" name="sub_abook_list" value="Address Books">
<a href="$url_prefix/logout//compose">
  <img align="absmiddle" src="/wing-icons/logout.gif" border=0 alt="Logout"></a>
<br>
EOT
    #
    # Show any information message and start the table for the headers
    #
    my $info_msg = info_message_html($s);
    $r->print($info_msg, <<"EOT");
<table cellspacing=0 cellpadding=0>
EOT

    foreach my $h (@header_list) {
	my $value = escape_html($headers{$h});
	$r->print(<<"EOT");
<tr>
  <td>${h}:</td><td><input name="hdr_$h" value="$value" size="50"></td>
EOT
	$r->print(<<"EOT") if $header_is_address{$h};
  <td><input type="submit" name="abook_$h" value="Lookup"></td>
EOT
	$r->print("</tr>\n");
    }
    $r->print(<<"EOT");
</table>
<br>
<input type="submit" name="clear_headers" value="Clear Headers">
<input type="submit" name="clear_body" value="Clear Body">
<input type="submit" name="sub_add_header" value="Add new headers">
<input type="submit" name="sub_del_header" value="Remove headers">
Save copy in $SENT_MAIL_MAILBOX
<input type="checkbox" name="copy_outgoing" value="1"$copy_outgoing_checked>
<br>
<textarea name="body" rows="18" cols="80">
EOT
    $r->print($body, "</textarea></form></body></html>\n");
}

sub cmd_clear {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    print $s "tmpdir\n";
    chomp(my $tmpdir = <$s>);
    truncate("$tmpdir/body", 0);
    return redirect($r, "$conn->{url_prefix}/compose");
}

sub cmd_add_header {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my $url_prefix = $conn->{url_prefix};
    my @add;
    my $args = $r->args;
    while ($args =~ /header=([^&]+)/g) {
	push(@add, url_decode($1));
    }
    if (@add) {
	my @header_list = split(' ', maild_get($s, "compose_headers"));
	my %headers = map { $_ => 1 } @header_list;
	#
	# Canonify header names (e.g. turn "iN-REPLy-tO" into
	# "In-Reply-To") and add them (unless already present or illegal)
	#
	foreach my $h (@add) {
	    $h = lc($h);
	    $h =~ s/\b(\w)/uc($1)/eg;
	    push(@header_list, $h) unless exists $headers{$h}
				   || $h eq "From" || $h eq "Sender";
	    $headers{$h} = 1;
	}
	my $header_string = join(' ', @header_list);
	maild_set($s, "compose_headers", $header_string);
	return redirect($r, "$conn->{url_prefix}/compose");
    } else {
	dont_cache($r, "text/html");
	$r->print(<<"EOT");
<html><head><title>Add new headers</title>
<body>
<a href="$url_prefix/compose">
  <img src="/icons/back.gif" border=0 alt="Back"></a>
<img src="/icons/blank.gif" alt=" | ">
<a href="$url_prefix/logout//add_header">
  <img src="/wing-icons/logout.gif" border=0 alt="Logout"></a>
<h1 align="center">Add new headers</h1>
<form method="GET" action="$url_prefix/add_header">
<h2>Choose from these common headers</h2>
<select align="middle" name="header" multiple>
<option value="Bcc" selected>Bcc
<option value="Reply-To">Reply
<option value="Action">Action
<option value="Priority">Priority
<option value="In-Reply-To">In-Reply-To
<option value="Expires">Expires
<option value="Precedence">Precedence
</select>
<h2>or enter one here</h2>
<input align="middle" name="header">
<br>
<input type="submit" value="Add new headers">
<input type="reset" value="Clear">
</form>
</body></html>
EOT
    }
}

sub cmd_del_header {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my $url_prefix = $conn->{url_prefix};

    my @remove;
    my $args = $r->args;
    while ($args =~ /header=([^&]+)/g) {
	push(@remove, url_decode($1));
    }

    my @header_list = split(' ', maild_get($s, "compose_headers"));
    my %mandatory = map { $_ => 1 } split(/ /, $MANDATORY_COMPOSE_HEADERS);
    
    if (@remove) {
	#
	# Disallow headers in the removal list which are
	# either non-existent or mandatory.
	#
	my %headers = map { $_ => 1 } @header_list;
	foreach my $h (@remove) {
	    if ($headers{$h} && !$mandatory{$h}) {
		print $s "unset hdr_$h\n";
		@header_list = grep { $_ ne $h } @header_list;
	    }
	}
	my $header_string = join(' ', @header_list);
	maild_set($s, "compose_headers", $header_string);
	return redirect($r, "$conn->{url_prefix}/compose");
    } else {
	$r->content_type("text/html");
	$r->send_http_header;
	$r->print(<<"EOT");
<html><head><title>Remove headers</title>
<body>
<a href="$url_prefix/compose">
  <img src="/icons/back.gif" border=0 alt="Back"></a>
<img src="/icons/blank.gif" alt=" | ">
<a href="$url_prefix/logout//del_header">
  <img src="/wing-icons/logout.gif" border=0 alt="Logout"></a>
<h1 align="center">Remove headers</h1>
EOT
	@header_list = grep { !$mandatory{$_} } @header_list;
	if (@header_list) {
	    $r->print(<<"EOT");
<form method="GET" action="$url_prefix/del_header">
<h2>Choose which headers to remove</h2>
<select align="middle" name="header" multiple>
EOT
	    foreach my $h (@header_list) {
		$r->print(qq(<option value="$h">$h\n));
	    }
	    $r->print(<<"EOT");
</select>
<br>
<input type="submit" value="Remove Headers">
<input type="reset" value="Clear">
</form>
EOT
	} else {
	    $r->print(<<"EOT");
Only mandatory header remain: these cannot be removed.
EOT
	}
	$r->print("</body></html>\n");
    }
}

sub cmd_reply {
    my ($conn, $uid, $msgno) = @_;
    my $r = $conn->{request};
    my $s = $conn->{maild};

    my $signature = maild_get($s, "signature");
    $signature = "\n-- \n$signature" if $signature;
    print $s "headers $msgno Subject Message-Id Reply-To From\n";
    chomp(my $size = <$s>);
    read($s, my $headers, $size);
    $headers =~ tr/\r//d;
#    $r->warn("reply: headers are: $headers"); # debug
    my $replyto = "";
    my ($messageid) = $headers =~ /^Message-Id: (.*)$/im; 
    if ($headers =~ /^Reply-To: (.*)$/im) {
	$replyto = $1;
    } elsif ($headers =~ /^From: (.*)$/im) {
	$replyto = $1;
    }
    my $subject = "Re: your message";
    if ($headers =~ /^Subject: (.*)$/im) {
	$subject = $1;
	$subject = "Re: $subject" unless $subject =~ /^Re: /i;
    }
    maild_set($s, "hdr_To", $replyto);
    maild_set($s, "hdr_Subject", $subject);

    print $s "body $msgno 1\n";
    chomp($size = <$s>);
    #
    # XXX We ought to let the "In message 123 foo@bar writes..." stuff
    # be user configurable. This will have to do for now though.
    #
    my $intro = "In message $messageid $replyto writes:\n";
    read($s, my $body, $size);
    $body =~ s/^/> /mg;
    _replace_body($r, $s, $intro . $body . $signature);
    return redirect($r, "$conn->{url_prefix}/compose");
}

sub cmd_forward {
    my ($conn, $uid, $msgno) = @_;
    my $r = $conn->{request};
    my $s = $conn->{maild};

    my $signature = maild_get($s, "signature");
    $signature = "\n-- \n$signature" if $signature;

    print $s "zap_draft\n";
    print $s "headers $msgno all\n";
    chomp(my $size = <$s>);
    read($s, my $headers, $size);
    $headers =~ tr/\r//d;
#    $r->warn("forward: headers are: $headers"); # debug
    my $forwarded_from = "";
    if ($headers =~ /^Subject: (.*)$/im) {
	maild_set($s, "hdr_Subject", "$1 (fwd)");
    }
    if ($headers =~ /^From: (.*)$/im) {
	$forwarded_from .= " from $1";
    }

    print $s "body $msgno 1\n";
    chomp($size = <$s>);
    read($s, my $body, $size);
    $body = <<"EOT";
----- Forwarded message$forwarded_from -----

$headers

$body

-----End of forwarded message$forwarded_from -----
$signature
EOT
    _replace_body($r, $s, $body);
    return redirect($r, "$conn->{url_prefix}/compose");
}

sub cmd_change {
    my ($conn, $mailbox) = @_;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    $mailbox = canon_decode($mailbox);
    printf $s "change %s\n", maild_encode($mailbox);
    chomp(my $result = <$s>);
    if ($result eq "OK") {
	return redirect($r, "$conn->{url_prefix}/list");
    }
    $result =~ s/^NO //;
    $result = maild_decode($result);
    $r->content_type("text/plain");
    $r->send_http_header;
    $r->print("Failed to change to mailbox $mailbox: $result\n");
    return OK;
}

sub cmd_mailboxes {
    my ($conn, $which) = @_;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my $url_prefix = $conn->{url_prefix};

    if (!defined($which)) {
	$which = "browse";
    } elsif ($which ne "browse" && $which !~ /^(save_)?(copy|move)$/) {
	return wing_error($r, "subcommand must be browse/copy/move/save_copy/save_move");
    }

    my $info_msg = info_message_html($s);
    my $cwd = maild_get($s, "cwd");
    my $filter = maild_get($s, "filter");

    my $imap_filter = $filter;
    $imap_filter =~ tr/*/%/;
    $imap_filter = "%" if $imap_filter eq "";

    my $filter_html = ($filter eq "*") ? "" : escape_html($filter);
    my $cwd_html = escape_html($cwd);

    my $wildcard = length($cwd) ? "$cwd/$imap_filter" : $imap_filter;
#    $r->warn("wildcard = $wildcard");#debug
    #
    # The "filenames" we get out of the following list are full
    # pathnames (i.e. include any parent directories traversed).
    #
    printf $s "ls %s\n", maild_encode($wildcard);
    my @list;
    while (1) {
	chomp(my $line = <$s>);
	if (!$line) {
	    $r->log_error("browse: maild daemon vanished unexpectedly");
	    last;
	}
	last if $line eq "."; # the proper way to terminate the list
	my @info = canon_decode(split(' ', $line));
#	$r->warn("browse: ", join(", ", @info));#debug
	push(@list, \@info);
    }

    my $parent = $cwd;
    $parent =~ s((/+|^)[^/]+/?$)(); # strip trailing directory
    $parent = url_encode($parent);
    #
    # Grey out parent link if directory is already toplevel
    #
    my ($parent_icon, $parent_text);
    if ($cwd eq "") {
	$parent_icon = <<"EOT";
<img src="/wing-icons/left-inactive.gif" border=0 alt="[up] ">
EOT
	$parent_text = "Parent directory";
    } else {
	$parent_icon = <<"EOT";
<a href="$url_prefix/chdir/$which?cwd=$parent">
  <img src="/wing-icons/left.gif" border=0 alt="[up] "></a>
EOT
	$parent_text = <<"EOT";
<a href="$url_prefix/chdir/$which?cwd=$parent">Parent directory</a>
EOT
    }

    my $title;
    if ($which eq "browse") {
	$title = "Mailboxes";
    } elsif ($which =~ /^save_(.*)/) {
	$title = "\u$1 message(s) to mailbox ...";
    } else {
	my $copy_move_from = escape_html(maild_get($s, "copy_move_from"));
	$title = ($which eq "move") ? "Rename" : "Copy";
	$title .= " from $copy_move_from to ...";
    }
	
    dont_cache($r, "text/html");
    $r->print(<<"EOT");
<html><head><title>$title</title></head>
<body>
<table>
<tr>
<td><a href="$url_prefix/list">
  <img src="/icons/back.gif" border=0 alt="Back"></a></td>
<td><a href="$url_prefix/help/mailboxes">
  <img src="/wing-icons/help.gif" border=0 alt="Help"></a></td>
<td><a href="$url_prefix/logout//mailboxes">
  <img src="/wing-icons/logout.gif" border=0 alt="Logout"></a></td>
</tr>
</table>
$info_msg
<h2 align="center">$title</h2>
<form method="GET" action="$url_prefix/chdir/$which">
  Directory <input name="cwd" size="32" value="$cwd_html">
  Filter <input name="filter" size="12" value="$filter_html">
  <input type="submit" value="Open">
</form>
<br>
<table>
<tr>
  <td>$parent_icon</td>
  <td><img src="/icons/blank.gif" alt="&nbsp;"></td>
  <td>$parent_text</td>
</tr>
EOT
    @list = sort { $a->[0] cmp $b->[0] } @list;
    foreach my $i (@list) {
	my $name = shift @$i;
#	$r->warn("formatting name $name of length ", length($name));#debug
	my $noinferiors = 0;
	my $noselect = 0;
	my $marked = 0;
	my $unmarked = 0;
	foreach my $f (@$i) {
	    if ($f eq "noinferiors") {
		$noinferiors = 1;
	    } elsif ($f eq "noselect") {
		$noselect = 1;
	    } elsif ($f eq "marked") {
		$marked = 1;
	    } elsif ($f eq "unmarked") {
		$unmarked = 1;
	    }
	}

	#
	# Choose an image to show marked/unmarked/non-marked folders.
	# We used to show a red blob for marked and a grey blob for
	# not-marked-or-unmarked but it confused people. Now we just
	# put an "N" for "New" next to marked folders since that's
	# how we mark new messages when displaying their contents.
	#
	my $mark_img = "";
	if ($marked) {
	    #$mark_img = '<img src="/icons/ball.red.gif" alt="N">';
	    $mark_img = "N";
	} elsif ($unmarked) {
	    #$mark_img = '<img src="/icons/ball.gray.gif" alt="O">';
	} else {
	    #$mark_img = '<img src="/icons/blank.gif" alt="&nbsp;">';
	}
	    
	#
	# We don't cope with IMAP servers that allow mailboxes to be both
	# selectable and have inferiors.
	#

	#
	# We have three forms of each name entry:
	# $name_enc - the full pathname, URL encoded (for ...?name=$name_enc)
	# $name_canon - the full pathname, canon encoded (for .../$name_canon)
	# $name - the *basename* in HTML-encoded form for display
	#
	my $name_enc = url_encode($name);
	my $name_canon = canon_encode($name);
	$name =~ s(^.*/)();
	$name = escape_html($name);
#	$r->warn("cwd=$cwd, name=$name, name_enc=$name_enc, name_canon=$name_canon");#debug

	next if $name eq "";
	$r->print("<tr>");

	#
	# Prepare HTML for anchor: only have a "change to this mailbox"
	# anchor is we're in "browse" mode or we're copying/moving
	# messages to a mailbox.
	#
	my $a_change = "";
	my $a_end = "";
	if ($which eq "browse") {
	    $a_change = qq{<a href="$url_prefix/change/$name_canon">};
	    $a_end = "</a>";
	}
	elsif ($which =~ /^save_/) {
	    $a_change = qq{<a href="$url_prefix/do_save?save=y&name=$name_enc">};
	    $a_end = "</a>";
	}
	if (!$noselect) {
	    $r->print(<<"EOT");
<td>
  $a_change
  <img src="/icons/dir.gif" border=0 alt="&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;">$a_end
</td>
<td>
  $mark_img
</td>
<td>
  $a_change$name$a_end
</td>
EOT
	    $r->print(<<"EOT") if $which eq "browse" && $name_canon ne "INBOX";
<td>
  <a href="$url_prefix/copy_move_from/move/$name_canon">
    <img src="/wing-icons/rename.gif" border=0 alt="Rename"></a>
</td>
<td>
  <a href="$url_prefix/rm/mailbox/$name_canon">
    <img src="/wing-icons/delete.gif" border=0 alt="Delete"></a>
</td>
EOT
#
# Add the following when/if we support copying whole mailboxes
#<td>
#  <a href="$url_prefix/copy_move_from/copy/$name_canon">Copy</a>
#</td>
#
	} elsif (!$noinferiors) {
	    $r->print(<<"EOT");
<td>
  <a href="$url_prefix/chdir/$which?cwd=$name_enc">
    <img src="/wing-icons/right.gif" border=0 alt="[dir]"></a>
</td>
<td>
  $mark_img
</td>
<td>
  <a href="$url_prefix/chdir/$which?cwd=$name_enc">$name</a>
</td>
EOT
	    $r->print(<<"EOT") if $which eq "browse";
<td>
  <a href="$url_prefix/copy_move_from/move/$name_canon">
    <img src="/wing-icons/rename.gif" border=0 alt="Rename"></a>
</td>
<td>
  <a href="$url_prefix/rm/directory/$name_canon">
    <img src="/wing-icons/delete.gif" border=0 alt="Delete"></a>
</td>
EOT
	}
	$r->print("</tr>\n");
    }
    $r->print("</table><br>\n");
    if ($which eq "browse") {
	$r->print(<<"EOT");
<hr>
<form method="GET" action="$url_prefix/create">
Create
<select name="type" size=1>
  <option value="mailbox" selected>mailbox</option>
  <option value="directory" selected>directory</option>
</select>
with name
<input name="name">
<input type="submit" name="create" value="Create">
</form>
EOT
    } elsif ($which eq "copy" || $which eq "move") {
	my $button = ($which eq "copy") ? "Copy" : "Rename";
	$r->print(<<"EOT");
<form method="GET" action="$url_prefix/copy_move/$which">
New name
<input name="name">
<input type="submit" name="copy_move" value="$button">
<input type="submit" name="cancel" value="Cancel">
</form>
EOT
    } else {
	#
	# save_copy or save_move
	#
	my $copy_or_save = ($which eq "save_copy") ? "Copy" : "Save";
	$r->print(<<"EOT");
<form method="GET" action="$url_prefix/do_save">
$copy_or_save to new mailbox
<input name="name">
<input type="submit" name="save" value="$copy_or_save">
<input type="submit" name="cancel" value="Cancel">
</form>
EOT
    }
    $r->print("</body></html>\n");
}

sub cmd_rm {
    my ($conn, $type, $name) = @_;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    $name = canon_decode($name);
    $name =~ s(/$)();

    my $imap_name = $name;
    if ($type eq "directory") {
	$imap_name .= "/";
    } else {
	$type = "mailbox";
    }

#    $r->warn("rm $imap_name"); # debug
    printf $s "rm %s\n", maild_encode($imap_name);
    chomp(my $result = <$s>);
    if ($result eq "OK") {
	maild_set($s, "message", "\u$type $name has been deleted");
	return redirect($r, "$conn->{url_prefix}/mailboxes");
    }
    #
    # XXX Make error message prettier
    # In case of error we get back "NO imap_error_message_maild_encoded\n"
    $result =~ s/^NO //;
    $result = maild_decode($result);
    dont_cache($r, "text/plain");
    $r->print("Failed to delete $type $name: $result\n");
    return OK;
}


sub cmd_copy_move_from {
    my ($conn, $type, $name) = @_;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    $name = canon_decode($name);

#    $r->warn("set copy_move_from $name"); # debug
    maild_set($s, "copy_move_from", $name);
    if ($type ne "move") {
	$type = "copy";
    }
    return redirect($r, "$conn->{url_prefix}/mailboxes/$type");
}

sub cmd_copy_move {
    my ($conn, $type) = @_;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my %q = $r->args;

    if ($type ne "copy") {
	$type = "move";
    }

    if (!exists($q{copy_move})) {
	maild_set($s, "message", "Cancelled $type of directory or mailbox");
	return redirect($r, "$conn->{url_prefix}/mailboxes");
    }
    my $oldname = maild_get($s, "copy_move_from");

    my $newname = $q{name};
    my $cwd = maild_get($s, "cwd");
    $newname = "$cwd/$newname" if length($cwd);

    if ($type eq "move") {
#	$r->warn("move $oldname $newname"); # debug
	printf $s "move %s %s\n", maild_encode($oldname, $newname);
    } else {
#	$r->warn("copy $oldname $newname"); # debug
	printf $s "copy %s %s\n", maild_encode($oldname, $newname);
    }
    chomp(my $result = <$s>);
    if ($result eq "OK") {
	maild_set($s, "message",
		  sprintf("%s %s to %s",
			 ($type eq "copy") ? "Copied" : "Renamed",
			 $oldname, $newname));
	return redirect($r, "$conn->{url_prefix}/mailboxes");
    }
    #
    # XXX Make error message prettier
    # In case of error we get back "NO imap_error_message_maild_encoded\n"
    $result =~ s/^NO //;
    $result = maild_decode($result);
    dont_cache($r, "text/plain");
    $r->print("Failed to $type $oldname to $newname: $result\n");
    return OK;
}

sub cmd_create {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my %q = $r->args;

    if (!exists($q{create})) {
	maild_set($s, "message", "Cancelled creation of mailbox");
	return redirect($r, "$conn->{url_prefix}/mailboxes");
    }
    my $type = $q{type};
    $type = url_decode($type);

    my $name = $q{name};
    $name = url_decode($name);
    $name =~ s(/$)();

    my $cwd = maild_get($s, "cwd");
    my $imap_name = length($cwd) ? "$cwd/$name" : $name;
    if ($type eq "directory") {
	$imap_name .= "/";
    } else {
	$type = "mailbox";
    }

#    $r->warn("create $imap_name"); # debug
    printf $s "create %s\n", maild_encode($imap_name);
    chomp(my $result = <$s>);
    if ($result eq "OK") {
	maild_set($s, "message", "\u$type $name has been created");
	return redirect($r, "$conn->{url_prefix}/mailboxes");
    }
    #
    # XXX Make error message prettier
    # In case of error we get back "NO imap_error_message_maild_encoded\n"
    $result =~ s/^NO //;
    $result = maild_decode($result);
    dont_cache($r, "text/plain");
    $r->print("Failed to create $type $name: $result\n");
    return OK;
}

sub cmd_delete {
    my ($conn, $uid, $msgno) = @_;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    print $s "setflag $msgno \\Deleted\n";
    maild_set($s, "message", "Deleted message $msgno");
    return redirect($r, "$conn->{url_prefix}/list");
}

sub cmd_undelete {
    my ($conn, $uid, $msgno, $callback) = @_;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    print $s "clearflag $msgno \\Deleted\n";
    if ($callback eq "display") {
	$callback .= "/$uid/$msgno";
    }
    return redirect($r, "$conn->{url_prefix}/$callback");
}

sub cmd_expunge {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    print $s "expunge\n";
    maild_set($s, "message", "Messages tagged as deleted have been purged");
    return redirect($r, "$conn->{url_prefix}/list");
}

sub cmd_send {
    my $conn = shift;
    my $r = $conn->{request};
    my $url_prefix = $conn->{url_prefix};
    my $s = $conn->{maild};

    print $s "sendmail\n";
    chomp(my $reply = <$s>);
    if ($reply !~ s/^OK\s*//) {
	$r->content_type("text/plain");
	$r->send_http_header;
	$r->print("Failed to send message");
	return;
    }
    maild_set($s, "message", $reply);
    return redirect($r, "$conn->{url_prefix}/list");
}
    
sub cmd_save {
    my ($conn, $type, $called_from, $seq) = @_;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    if ($type ne "copy" && $type ne "move") {
	return wing_error($r, "save subcommand must be copy or move");
    }
    maild_set($s, "pending_save", "$type $called_from $seq");
    return redirect($r, "$conn->{url_prefix}/mailboxes/save_$type");
}

sub cmd_do_save {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my %q = $r->args;

    my ($type, $called_from, $seq) = split(' ', maild_get($s, "pending_save"));
    my $return_to;
    if ($called_from eq "list") {
	$return_to = "list";
    } else {
	my ($uid, $msgno) = split(/-/, $called_from);
	$return_to = "display/$uid/$msgno";
    }

    if (!exists($q{save})) {
	maild_set($s, "message", "Cancelled \l$type of message(s) $seq");
	return redirect($r, "$conn->{url_prefix}/$return_to");
    }
    my $name = $q{name};
    $name = url_decode($name);
    printf $s "save %s %s %s\n", $type, $seq, maild_encode($name);
    chomp(my $result = <$s>);
    if ($result eq "OK") {
	maild_set($s, "message",
		  sprintf("%s message(s) %s to mailbox %s",
		         ($type eq "copy") ? "Copied" : "Moved", $seq, $name));
	return redirect($r, "$conn->{url_prefix}/$return_to");
    } else {
	$result =~ s/^NO //;
	$result = maild_decode($result);
	$r->content_type("text/plain");
	$r->send_http_header;
	$r->print("Failed to save message(s) to mailbox $name: $result\n");
	return OK;
    }
}

sub cmd_attachments {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my $url_prefix = $conn->{url_prefix};
    my @attachments;
    print $s "lsattach\n";
    while (1) {
	chomp(my $comment = <$s>);
	if (!$comment) {
	    $r->log_error("attachments: maild daemon vanished unexpectedly");
	    last;
	}
	last if $comment eq "."; # the proper way to terminate the list
	$comment = maild_decode($comment);
	#
	# Netscape for Macintosh seems to URL-encode filenames with
	# spaces and Netscape Messenger URL-decodes names when it
	# displays them. We do the same, although I don't see why a
	# Content-Disposition header has anything to do with URL encoding.
	#
	push(@attachments, url_decode($comment));
    }
    dont_cache($r, "text/html");
    $r->print(<<"EOT");
<html><head><title>MIME Attachments</title></head>
<body>
<a href="$url_prefix/compose">
  <img src="/icons/back.gif" border=0 alt="Back"></a>
<img src="/icons/blank.gif" alt=" | ">
<a href="$url_prefix/logout//attachments">
  <img src="/wing-icons/logout.gif" border=0 alt="Logout"></a>
<h1>MIME Attachments</h1>
EOT

    if (@attachments) {
	$r->print("<table>\n");
	my $relnum = 1;

	foreach my $a (@attachments) {
	    $r->print(<<"EOT");
<tr>
  <td align="right">$relnum.</td>
  <td>$a</td>
  <td><a href="$url_prefix/detach/$relnum">
        <img src="/wing-icons/detach.gif" border=0 alt="Detach"></a></td>
</tr>
EOT
	    $relnum++;
	}
	$r->print("</table>\n<hr>\n");
    }
    else {
	$r->print("(No files yet attached to this message)");
    }
    $r->print(<<"EOT");
<h1>Attach file</h1>
<form action="$url_prefix/attach" method="POST" enctype="multipart/form-data">
File <input align="middle" type="file" name="file">
<br>
<input type="submit" value="Attach">
</form>
</body>
</html>
EOT
}

sub cmd_detach {
    my ($conn, $relnum) = @_;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    if ($relnum !~ /\D/ && $relnum >= 0) {
	print $s "detach $relnum\n";
    }
    dont_cache($r);
    return redirect($r, "$conn->{url_prefix}/attachments");
}

sub cmd_attach {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    print $s "attach\n";
    chomp(my $data = <$s>);
    if ($data eq ".") {
	return wing_error($r, "Attach failed: couldn't create attach file");
    }
    my ($relnum, $filename) = split(' ', $data);
    my ($error, $type, $client_filename) = _receive_upload($r, $filename);
    return wing_error($r, $error) if $error;

    #
    # Update the comment to be the client-local filename if possible
    #
    if (defined($client_filename)) {
	printf $s "attach %d comment %s\n",
	    $relnum, maild_encode($client_filename);
	printf $s "attach %d filename %s\n",
	    $relnum, maild_encode($client_filename);
    }
    #
    # Update with the MIME type if we have it, otherwise force octet-stream
    #
    $type ||= "application/octet-stream";
    printf $s "attach %d type %s\n", $relnum, maild_encode($type);

    #
    # Redirect client back to main MIME attachments screen
    #
    return redirect($r, "$conn->{url_prefix}/attachments");
}

sub cmd_include {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my $url_prefix = $conn->{url_prefix};
    if ($r->method ne "POST") {
	$r->content_type("text/html");
	$r->send_http_header;
	$r->print(<<"EOT");
<html><head><title>Include local file in message body</title></head>
<body>
<a href="$url_prefix/compose">
  <img src="/icons/back.gif" border=0 alt="Back"></a>
<img src="/icons/blank.gif" alt=" | ">
<a href="$url_prefix/logout//include">
  <img src="/wing-icons/logout.gif" border=0 alt="Logout"></a>
<h1 align="center">Include local file in message body</h1>
<form method="POST" action="$url_prefix/include" enctype="multipart/form-data">
File <input align="middle" type="file" name="file">
<br>
<input type="submit" value="Include">
</form>
</body>
</html>
EOT
	return;
    }
    print $s "tmpdir\n";
    chomp(my $tmpdir = <$s>);
    my $inc_file = "$tmpdir/include";
    my ($error, $type, $client_filename) = _receive_upload($r, $inc_file);
    if ($error) {
	$r->content_type("text/plain");
	$r->send_http_header;
	$r->print("Include failed: $error");
	return;
    }
    #
    # copy contents to body (just before sig indicator line if there is one)
    #
    my $bodyfh = IO::File->new("$tmpdir/body")
	or return wing_error($r, "Include failed appending to body file: $!");
    my $newbodyfh = IO::File->new(">$tmpdir/newbody")
	or return wing_error($r, "Include failed creating new body file: $!");
    my $incfh = IO::File->new("$tmpdir/include")
	or return wing_error($r, "Include failed re-opening include file: $!");
    my $done_include = 0;
    while (defined(my $line = <$bodyfh>)) {
	if (!$done_include && $line =~ /^-- $/) {
	    while (read($incfh, my $buffer, _CHUNK_SIZE)) {
		print $newbodyfh $buffer;
	    }
	    $done_include = 1;
	}
	print $newbodyfh $line;
    }
    if (!$done_include) {
	while (read($incfh, my $buffer, _CHUNK_SIZE)) {
	    print $newbodyfh $buffer;
	}
    }
    $incfh->close;
    $bodyfh->close;
    $newbodyfh->close;
    rename("$tmpdir/newbody", "$tmpdir/body")
	or return wing_error($r, "Include failed renaming new body file: $!");
    unlink("$tmpdir/include");
    return redirect($r, "$url_prefix/compose");
}

sub cmd_export {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    $r->content_type("text/plain");
    $r->send_http_header;

    #
    # Fake up a harmless envelope from line
    #
    print $s "username\n";
    chomp(my $username = <$s>);
    my $now = localtime;
    my $from_line = "From $username\@$SENDMAIL_FROM_HOSTNAME $now\n";

    print $s "nmsgs\n";
    chomp(my $nmsgs = <$s>);
    for (my $i = 1; $i <= $nmsgs; $i++) {
	print $s "headers $i all\n";
	chomp(my $size = <$s>);
	read($s, my $headers, $size);
	$headers =~ tr/\r//d;

	print $s "body $i\n";
	chomp($size = <$s>);
	read($s, my $body, $size);
	if (substr($body, -1) ne "\n") {
	    $body .= "\n"; # must ensure newline termination of message
	}
	$r->print($from_line, $headers, $body);
    }
}

sub cmd_manage {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my $url_prefix = $conn->{url_prefix};

    my $info_msg = info_message_html($s);
    my $wingdir = wing_directory($s);
    my $forward = "";
    my $vacation_message = "";
    my $vacation_active = -e "$wingdir/$VACATION_ACTIVE_FILE";
    if (-e "$wingdir/$VACATION_MESSAGE_FILE") {
	local($/) = undef; # slurp
	local(*MESS);
	open(MESS, "$wingdir/$VACATION_MESSAGE_FILE");
	$vacation_message = <MESS>;
	close(MESS);
    }

    {
	local($/) = undef; # slurp
	local(*FORWARD);
	open(FORWARD, "$wingdir/$FORWARD_FILE");
	$forward = <FORWARD>;
	close(FORWARD);
    }
    my $forward_html = escape_html($forward);
    my $vacation_message_html = escape_html($vacation_message);

    if ($r->method eq "POST") {
	my %q = $r->content;
	my @info;
	if (defined($q{set_forward})) {
	    $forward = $q{forward};
	    $forward_html = escape_html($forward);
	    #
	    # Sanity check forwarding address
	    #
	    s/\s*$//sg;
	    $forward .= "\n" if length($forward);
	    if (length($forward) > 256) {
		push(@info, "Forwarding address is too long");
	    } else {
		push(@info, do_write_file("$wingdir/$FORWARD_FILE", $forward)
			    ? "Forwarding address has been updated"
			    : "Failed to update forwarding address");
	    }
	}
	if (defined($q{set_vac_text})) {
	    $vacation_message = $q{vacation_message};
	    $vacation_message =~ tr/\r//d;
	    $vacation_message_html = escape_html($vacation_message);
	    #
	    # Remove trailing white space from message, check its length
	    # and update the vacation message file.
	    #
	    $vacation_message =~ s/\s*$//sg;
	    $vacation_message .= "\n" if length($vacation_message);
	    if (length($vacation_message) > 1024) {
		push(@info, "Vacation message is too long");
	    } else {
		push(@info, do_write_file("$wingdir/$VACATION_MESSAGE_FILE",
					  $vacation_message)
			    ? "Vacation message has been updated"
			    : "Failed to update vacation message");
	    }
	}
	if (defined($q{vac_on})) {
	    local(*ACTIVE);
	    sysopen(ACTIVE, "$wingdir/$VACATION_ACTIVE_FILE",
		    O_CREAT|O_RDWR, 0664);
	    close(ACTIVE);
	    $vacation_active = -e "$wingdir/$VACATION_ACTIVE_FILE";
	    push(@info, $vacation_active
			? "Vacation autoreply is now active"
			: "Failed to activate vacation autoreply");
	} elsif (defined($q{vac_off})) {
	    unlink map {
		"$wingdir/$_";
	    } ($VACATION_ACTIVE_FILE, @VACATION_DB_FILES);
	    $vacation_active = -e "$wingdir/$VACATION_ACTIVE_FILE";
	    push(@info, $vacation_active
			? "Failed to deactivate vacation autoreply"
			: "Vacation autoreply is now inactive");
	}
	if (@info) {
	    $info_msg = "<br><strong>"
			. join("\n<br>\n", @info)
			. "</strong><br>";
	}
    }

    my $vacation_blurb;
    if ($vacation_active) {
	$vacation_blurb = <<"EOT";
Your vacation autoreply is active: all mail sent to you will generate
an autoreply containing your vacation message. To deactivate your
vacation autoreply, use this button:
<br>
<input type="submit" name="vac_off" value="Deactivate vacation autoreply">
EOT
    } else {
	$vacation_blurb = <<"EOT";
Your vacation autoreply is not active. If you want every message sent
to you to generate an autoreply containing your vacation message,
use this button:
<br>
<input type="submit" name="vac_on" value="Activate vacation autoreply">
EOT
    }
    dont_cache($r, "text/html");

    $r->print(<<"EOT");
<html><head><title>Manage account</title></head>
<body>
<table>
<tr>
<td><a href="$url_prefix/list">
  <img src="/icons/back.gif" border=0 alt="Back"></a></td>
<td><img src="/icons/blank.gif" alt=" | "></td>
<td><a href="$url_prefix/logout//manage">
  <img src="/wing-icons/logout.gif" border=0 alt="Logout"></a></td>
</tr>
</table>
$info_msg
<h2 align="center">Manage account</h2>
<br>
Your disk quota is $DISK_QUOTA KB. For current disk usage, use this button:
<a href="$url_prefix/diskusage">
  <img src="/wing-icons/disk-usage.gif" border=0 align="absmiddle" alt="Disk Usage"></a>
<hr>
To change your password, use this button:
<a href="$url_prefix/chpass">
  <img src="/wing-icons/change-password.gif" border=0 align="absmiddle" alt="Change password"></a>
<hr>
To export the entire current mailbox to your browser in raw
format ("Berkeley" format, also known as "Unix" format), use this button:
<a href="$url_prefix/export">
  <img src="/wing-icons/export.gif" border=0 align="absmiddle" alt="Export"></a>
<hr>  
<form method="POST" action="$url_prefix/manage">
Forwarding address(es) (blank for no forwarding)
<br>
<input name="forward" size="50" value="$forward_html">
<input type="submit" name="set_forward" value="Update forwarding address">
<hr>
Vacation message body to send when autoreply is active
<br>
<textarea name="vacation_message" cols="70" rows="8">
$vacation_message_html</textarea>
<input type="submit" name="set_vac_text" value="Update text">
<br>
$vacation_blurb
</form>
</body></html>
EOT
}

#
# Change a user's password. Returns undef on success, otherwise returns
# a message to be displayed on the password changing screen.
#
sub do_chpass {
    my ($username, $oldpassword, $newpassword) = @_;
    my $info_msg = FascistCheck($newpassword);
    if ($info_msg) {
	return "Proposed password is not acceptable because $info_msg";
    }

    #
    # Solaris /usr/bin/passwd does a few checks of its own which
    # aren't caught by cracklib. We check for them here so that
    # the IMAP server doesn't just give a general "refused to change
    # password" error.
    #
    if (($newpassword =~ tr/[a-zA-Z]//) < 2
	|| ($newpassword =~ tr/[a-zA-Z]//c) < 1)
    {
	return "Password must contain at least two alphabetic characters"
	      ." and at least one non-alphabetic character";
    }
    my $lcpass = lc($newpassword);
    for (my $i = 0; $i < length($username); $i++) {
	my $rotate = substr($username, $i) . substr($username, 0, $i);
	if ($lcpass eq $rotate || $lcpass eq reverse($rotate))
	{
	    return "Password must not be a reverse or circular shift"
		  ." of your username";
	}
    }
    my $diffcount = 0;
    for (my $i = 0; $i < length($lcpass); $i++) {
	if (substr($lcpass, $i, 1) ne substr($oldpassword, $i, 1)) {
	    $diffcount++;
	}
    }
    if ($diffcount < 3) {
	return "New password must differ from old by at least 3 characters";
    }

    #
    # If we get this far we can send the request to the IMAP server
    #
    local(*CHPASS);
    my $rport = getservbyname("chpassd", "tcp") || 502;
    my $raddr = gethostbyname("$username.$WING_DOMAIN")
        or return "Change failed: can't find IMAP server from username";
    my $rsin = sockaddr_in($rport, $raddr);
    socket(CHPASS, AF_INET, SOCK_STREAM, 0)
	or return "Change failed: can't create socket to contact IMAP server";
    connect(CHPASS, $rsin)
	or return "Change failed: can't contact IMAP server. Please try later.";
    select(CHPASS); $| = 1; select(STDOUT);

    print CHPASS "$username\r\n$oldpassword\r\n$newpassword\r\n";
    my $result;
    {
	local($/) = "\r\n";
	chomp($result = <CHPASS>);
    }
    close(CHPASS);

    if ($result eq "OK") {
	return undef;
    } else {
        return "IMAP server refused to change password "
		. "(probably because old password was incorrect)";
    }
}

sub cmd_chpass {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my $url_prefix = $conn->{url_prefix};
    my $info_msg = "";

    print $s "username\n";
    chomp(my $username = <$s>);

    if ($r->method eq "POST") {
	my %q = $r->content;
	if (!defined($q{change_password})) {
	    maild_set($s, "message", "Cancelled password change");
	    return redirect($r, "$url_prefix/manage");
	}
	my $oldpassword = $q{oldpassword};
	my $newpassword = $q{newpassword};
	my $newpasswordagain = $q{newpasswordagain};
	if ($newpassword ne $newpasswordagain) {
	    $info_msg = "New password fields do not match: try again";
	} else {
	    $info_msg = do_chpass($username, $oldpassword, $newpassword);
	    if (!defined($info_msg)) {
		maild_set($s, "message",
			  "Password change successful: don't forget it");
		return redirect($r, "$url_prefix/manage");
	    }
	}
    }
    dont_cache($r, "text/html");
    $r->print(<<"EOT");
<html><head><title>Change password</title></head>
<body>
<table>
<tr>
<td><a href="$url_prefix/manage">
  <img src="/icons/back.gif" border=0 alt="Back"></a></td>
<td><img src="/icons/blank.gif" alt=" | "></td>
<td><a href="$url_prefix/logout//chpass">
  <img src="/wing-icons/logout.gif" border=0 alt="Logout"></a></td>
</tr>
</table>
<h2 align="center">Change password for $username</h2>
<br><strong>$info_msg</strong><br>
<form method="POST" action="$url_prefix/chpass">
<table>
  <tr>
    <td>Old password</td>
    <td><input type="password" name="oldpassword" size="16"></td>
  </tr>
    <td>New password</td>
    <td><input type="password" name="newpassword" size="16"></td>
  </tr>
  <tr>
    <td>Re-enter new password</td>
    <td><input type="password" name="newpasswordagain" size="16"></td>
  </tr>
</table>
<input type="submit" name="change_password" value="Change password">
<input type="submit" name="cancel" value="Cancel">
</form>
$PASSWORD_INFO
</body></html>
EOT
}

sub cmd_diskusage {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my $url_prefix = $conn->{url_prefix};

    print $s "username\n";
    chomp(my $username = <$s>);

    my $group = maild_get($s, "group");

#    $r->warn("PID $$ cmd_diskusage connected to database for $username");#debug
    my $dbh = DBI->connect(@WING_DBI_CONNECT_ARGS);
    my ($uid, $gid) = $dbh->selectrow_array(
	"select uid, gid from users where username = '$username'"
    );
    $dbh->disconnect;
#    $r->warn("PID $$ cmd_diskusage disconnected from database");#debug
    if (!defined($gid)) {
	return wing_error($r, "Can't find user/group id: $DBI::errstr");
    }

    my @usage;
    {
	local($/) = "\0";	# null terminated records
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
    dont_cache($r, "text/html");
    $r->print(<<"EOT");
<html><head><title>Disk Usage</title></head>
<body>
<table>
<tr>
<td><a href="$url_prefix/manage">
  <img src="/icons/back.gif" border=0 alt="Back"></a></td>
<td><img src="/icons/blank.gif" alt=" | "></td>
<td><a href="$url_prefix/logout//options">
  <img src="/wing-icons/logout.gif" border=0 alt="Logout"></a></td>
</tr>
</table>
<h2 align="center">Current Disk Usage</h2>
<table>
<tr><th align="right">Size/KB</th><th align="left">Mailbox</th></tr>
EOT

    my $total = 0;
    while (defined(my $u = shift @usage)) {
	$total += $u->[0];
	my $name_canon = canon_encode($u->[1]);
	my $name_html = escape_html($u->[1]);
	$r->print(<<"EOT");
<tr>
  <td align="right">$u->[0]</td>
  <td><a href="$url_prefix/change/$name_canon">$name_html</a></td>
</tr>
EOT
    }
    my $remaining = $DISK_QUOTA - $total;
    $r->print(<<"EOT");
</table>
Total usage $total KB out of $DISK_QUOTA KB with $remaining KB remaining.
</body></html>
EOT
}

sub cmd_options {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my $url_prefix = $conn->{url_prefix};
    my $info_msg = "";

    print $s "username\n";
    chomp(my $username = <$s>);

    my $list_size = maild_get($s, "list_size");
    my $signature = maild_get($s, "signature");
    my $compose_headers = maild_get($s, "compose_headers");
    my $copy_outgoing = maild_get($s, "copy_outgoing");

    $copy_outgoing = $copy_outgoing ? 1 : 0;
    my $copy_outgoing_checked = $copy_outgoing ? " checked" : "";

    my $portal = maild_get($s, "portal");
    my $portal_html = $portal ? "" : <<"EOT";
To switch to a portal view of your mail (your browser must support
frames), use this button:
<a href="$url_prefix/portal">
  <img src="/wing-icons/portal.gif" border=0 align="absmiddle" alt="Portal"></a>
<hr>
EOT

    my %q = $r->content;
    $r->content_type("text/html");
    $r->send_http_header;
    #
    # Set options according to %q
    #
    my $do_settings = defined($q{set}) ? 1 : 0;
    my $save_settings = defined($q{save}) ? 1 : 0;
    if ($do_settings || $save_settings) {
	my @errors;
	while (my ($key, $value) = each %q) {
	    $value =~ tr/\r//d;
	    if ($key eq "list_size" && $value ne $list_size) {
		if ($value =~ /^\d{1,4}$/) {
		    $list_size = $value;
		    maild_set($s, "list_size", $list_size);
		} else {
		    push(@errors, "Illegal message list number: $value.");
		}
	    } elsif ($key eq "signature" && $value ne $signature) {
		my @lines = split(/\n/, $value);
		if (@lines <= 4
		    && length($lines[0]) < 80 && length($lines[1]) < 80
		    && length($lines[2]) < 80 && length($lines[3]) < 80)
		{
		    $signature = join("\n", @lines);
		    maild_set($s, "signature", $signature);
		}
		else {
		    push(@errors,
			 "Signature does not comply with constraints.");
		}
	    }
	}
	my $new_copy_outgoing = $q{copy_outgoing} ? 1 : 0;
	if ($new_copy_outgoing != $copy_outgoing) {
	    $copy_outgoing = $new_copy_outgoing;
	    $copy_outgoing_checked = $copy_outgoing ? " checked" : "";
	    maild_set($s, "copy_outgoing", $copy_outgoing);
	}
	if (@errors) {
	    my $error = join("\n<br>\n", @errors);
	    $r->print(<<"EOT");
<html><head><title>Bad options</title></head>
<body>
<h1>Bad options</h1>
Some of the options you chose cannot be set:
<br>
$error
<br>
Please return to the <a href="$url_prefix/options">Options</a>
screen and try again.
</body>
</html>
EOT
	    return;
	}
    }
    if ($save_settings) {
#	$r->warn("PID $$ cmd_options connected to database for $username");#debug
	my $dbh = DBI->connect(@WING_DBI_CONNECT_ARGS);
	$dbh->{AutoCommit} = 1;
	my $done = 0;

	my $sql = "update options ";
	$sql .= "set listsize = $list_size";
	$sql .= sprintf(", signature = %s", $dbh->quote($signature));
	$sql .= sprintf(", composeheaders = %s",
			$dbh->quote($compose_headers));
	$sql .= sprintf(", copyoutgoing = '%s'", $copy_outgoing ? "t" : "f");
	$sql .= " where username = '$username'";
	$done = $dbh->do($sql);
#	$r->warn("return value $done from: $sql"); # debug
	if ($done eq "0E0") {
	    #
	    # If the user has never saved options before then we insert
	    # a row for the username (with all other fields null) and
	    # then redo the update. That saves messing about with the
	    # different SQL syntax for inserts and updates.
	    #
	    $dbh->do("insert into options (username) values ('$username')")
		and $done = $dbh->do($sql);
	}
	$info_msg = $done ? "Options have been set and saved"
			  : "Options could not be saved";
	$dbh->disconnect;
#	$r->warn("PID $$ cmd_options disconnected from database");#debug
    } elsif ($do_settings) {
	$info_msg = "Options have been set for this session only";
    }

    $r->print(<<"EOT");
<html><head><title>Options for username $username</title></head>
<body>
<table>
<tr>
<td><a href="$url_prefix/list">
  <img src="/icons/back.gif" border=0 alt="Back"></a></td>
<td><img src="/icons/blank.gif" alt=" | "></td>
<td><a href="$url_prefix/logout//options">
  <img src="/wing-icons/logout.gif" border=0 alt="Logout"></a></td>
</tr>
</table>
<br><strong>$info_msg</strong><br>
<h2 align="center">Options</h2>
<form method="POST" action="$url_prefix/options">
$portal_html
Number of messages listed in one screenful.
Enter 0 to list all messages on one screen.
<br>
<input size=4 name="list_size" value="$list_size">
<hr>
<input type="checkbox" name="copy_outgoing" value="1"$copy_outgoing_checked>
Save copy of outgoing messages in mailbox $SENT_MAIL_MAILBOX
<hr>
Signature to append to outgoing messages (maximum four lines
and 79 characters per line).
<br>
<textarea name="signature" rows=4 cols="80">
$signature
</textarea>
<hr>
<input type="submit" name="set" value="Set for this session">
<input type="submit" name="save" value="Set and save for future sessions">
<input type="reset" value="Reset">
</form>
</body>
</html>
EOT
}

sub cmd_help {
    my ($conn, $cmd) = @_;
    my $r = $conn->{request};
    my $url_prefix = $conn->{url_prefix};

    #
    # Sanity check command since we'll be using it to map to a filename
    #
    if (length($cmd) > 64 || $cmd !~ /^[a-z]\w*$/) {
	return wing_error($r, "Bad command: $cmd");
    }

    #
    # XXX Should abstract out filename mapping a bit more perhaps
    #
    local(*HELP);
    my $subr = $r->lookup_uri("/wing-help/$cmd.html");
    if (!defined($subr) || !open(HELP, $subr->filename)) {
	return wing_error($r, "No help available on $cmd");
    }
    $r->print(<<"EOT");
<html><head><title>Help</title></head>
<body>
<table>
<tr>
<td><a href="$url_prefix/$cmd">
  <img src="/icons/back.gif" border=0 alt="Back"></a></td>
<td><img src="/icons/blank.gif" alt=" | "></td>
<td><a href="$url_prefix/logout//$cmd">
  <img src="/wing-icons/logout.gif" border=0 alt="Logout"></a></td>
</tr>
</table>
EOT
    $r->send_fd(\*HELP);
    close(HELP);
}

use Wing::Abook;	# Wing::Connection handlers for address books
use Wing::Portal;	# Wing::Connection handlers for portal stuff

1;
