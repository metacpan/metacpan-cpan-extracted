#
# WING - Web-IMAP/NNTP Gateway
#
# Wing/Portal.pm
#
# Author: Malcolm Beattie, mbeattie@sable.ox.ac.uk
#
# This program may be distributed under the GNU General Public License (GPL)
#
#
#
package Wing::Connection;
use Wing::Shared;
use SQL;
use Outline;
use strict;

sub cmd_portal {
    my ($conn, $rhs_url) = @_;
    my $r = $conn->{request};
    my $s = $conn->{maild};

    my $rand = time().rand(2<<30); # blech

    if (defined($rhs_url)) {
	$rhs_url = canon_decode($rhs_url);
    } else {
	$rhs_url = "list/last/$rand";
    }
    my $url_prefix = $conn->{url_prefix};
    maild_set($s, "portal", 1);


    $r->content_type("text/html");
    $r->send_http_header;
    $r->print(<<"EOT");
<html>
<head>
<title>$WING_SERVICE_NAME Portal View</title>
<base href="$url_prefix/">
</head>
<frameset cols="215,*" framespacing=1 border=1>
<frame src="links//$rand" name="winglinks">
<frame src="$rhs_url" name="wing">
<noframes>
You have configured your $WING_SERVICE_NAME account to use the portal
view but your browser does not support frames. You can choose either
to continue with an <a href="list/last">email-only view</a>
or else you can <a href="logout//list">logout</a>.
</noframes>
</frameset>
</html>
EOT
}

sub _looks_like_url {
    my $s = shift;
    if ($s =~ m{^([a-z][a-z0-9+.-]{2,9}:[a-z0-9.%&=?/\\~\@:;,_+|-]+)$}i) {
        return 1;
    }
    return 0;
}

sub _linkline_to_html {
    my $line = shift;
    my $item;
#    Apache->request->warn("linkline: $line"); # debug
    if ($line =~ /^</) {
	# assumed to be raw HTML
	$item = $line;
    } elsif ($line =~ /^\w/) {
	# a description and/or URL
	my @parts = split(/ /, $line); # not white-space split via ' '
	if (_looks_like_url($parts[-1])) {
	    my $url = pop @parts;
	    my $desc = @parts ? join(" ", @parts) : $url;
	    $item = qq(<a href="$url">$desc</a>);
	} else {
	    $item = "<big>$line</big>";
	}
    } else {
	# unrecoginised line format. Silently use it verbatim.
	$item = $line;
    }
    return $item;
}

sub _parse_links {
    my ($links_source, $url_prefix, $template) = @_;
    my $links = "<table>\n";

    my $o = Outline->new;

    my $cur = shift @$links_source;
    my $cur_level = 0;
    $cur_level++ while $cur =~ s/^\s*\.\s*//;

    while (defined($cur)) {
	chomp $cur;
	my $next = shift @$links_source;
	my $next_level = 0;
	$next_level++ while $next =~ s/^\s*\.\s*//;

	if ($cur_level < $next_level) {
	    $o->start_sublist($cur);
	} elsif ($cur_level == $next_level) {
	    $o->add_item($cur);
	} else { # $cur_level > $next_level
	    $o->add_item($cur);
	    $o->end_sublist;
	}
	$cur_level = $next_level;
	$cur = $next;
    }

    $o->walk($template, sub {
	my ($level, $item, $open, $t) = @_;
	if (!defined($item)) {
	    # end of sub-list but we don't do anything special here
	    return;
	}
	if ($item =~ s/^=//) {
	    $links .= "$item\n";
	} elsif ($item eq "-") {
	    $links .= "</table><hr><table>\n";
	} elsif ($item =~ /^\s*$/) {
	    $links .= "<tr></tr>\n";
	} elsif (defined($item)) {
	    $item = _linkline_to_html($item);
	    $links .= "<tr>" . qq(<td>&nbsp;&nbsp;</td>) x $level . "<td>";
	    if (defined($open)) {
		my $img;
		if ($open) {
		    $img = <<"EOT";
<img src="/icons/small-minus.gif" border=0 valign="middle" alt="- ">
EOT
		} else {
		    $img = <<"EOT";
<img src="/icons/small-plus.gif" border=0 valign="middle" alt="+ ">
EOT
		}
		chomp $img; # remove trailing \n before forthcoming </a>
		$links .= <<"EOT";
<a href="$url_prefix/$t" target="_self">$img</a></td><td colspan="99"><big>$item</big>
EOT
	    } else {
		$links .= <<"EOT";
<img src="/icons/bullet.gif" border=0 valign="middle" alt="* "></td>
<td colspan="99">$item
EOT
	    }
	    $links .= "</td></tr>\n";
	}
    });

    $links .= "</table>\n";
    return $links;
}

sub cmd_links {
    my ($conn, $template) = @_;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my $portal = maild_get($s, "portal");
    my $url_prefix = $conn->{url_prefix};
    $template = $LINKS_TEMPLATE if $template eq "";

    print $s "username\n";
    chomp(my $username = <$s>);

    my $wingdir = wing_directory($s);
    my @links_source = split(/\n/, $DEFAULT_LINKS);

    if (-e "$wingdir/$LINKS_FILE") {
        local(*LINKS);
        open(LINKS, "$wingdir/$LINKS_FILE");
        push(@links_source, "-", <LINKS>);
        close(LINKS);
    }
    my $links = _parse_links(\@links_source, "$url_prefix/links", $template);

    my $header = $portal ? <<"EOT" : <<"EOT";
<html>
<head>
<title>Links</title>
<base href="$url_prefix/" target="wing">
</head>
<body>
<table>
<tr>
<td>
$LINKS_LOGO
</td>
<td><a href="list/last">
 <img src="/wing-icons/mail.gif" border=0 align="absmiddle" alt="Mail"></a>
<p>
<a href="edit_links">
  <img src="/wing-icons/edit-links.gif"
    border=0 align="absmiddle" alt="Edit Links"></a>
<p>
<a href="no_portal" target="_parent">
  <img src="/wing-icons/no-portal.gif" border=0
    align="absmiddle" alt="No Portal"></a>
<p>
<a href="logout//list">
  <img src="/wing-icons/logout.gif"
    border=0 align="absmiddle" alt="Logout"></a>
</td>
</tr>
</table>
<hr>
EOT
<html>
<head>
<title>Links</title>
<base href="$url_prefix/">
</head>
<body>
<table>
<tr>
<td><a href="list/last">
  <img src="/icons/back.gif" border=0 align="absmiddle" alt="Back"></a></td>
<td><a href="edit_links">
  <img src="/wing-icons/edit-links.gif"
    border=0 align="absmiddle" alt="Edit Links"></a></td>
<td><a href="logout//list">
  <img src="/wing-icons/logout.gif"
    border=0 align="absmiddle" alt="Logout"></a></td>
</tr>
</table>
<h1 align="center">Links</h1>
EOT

    dont_cache($r, "text/html");
    $r->print($header, $links, "</body></html>\n");
}

sub cmd_edit_links {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my $url_prefix = $conn->{url_prefix};
    my $wingdir = wing_directory($s);
    my $portal = maild_get($s, "portal");
    my $rand = time() . rand(2<<30);

#    $r->warn("in edit_links with method ", $r->method); # debug
    my $links = "";
    if (-e "$wingdir/$LINKS_FILE") {
	local($/) = undef; # slurp
	local(*LINKS);
	open(LINKS, "$wingdir/$LINKS_FILE");
	$links = <LINKS>;
	close(LINKS);
#	$r->warn("read links file:\n", substr($links, 0, 40),"\n"); # debug
    }

    if ($r->method eq "POST") {
	my %q = $r->content;
	$links = $q{links};
	$links =~ tr/\r//d;
	$links =~ s/\s*$//sg;
	$links .= "\n";
#	$r->warn("POSTed links field:\n", substr($links, 0, 40),"\n"); # debug
	if (defined($links)) {
	    if (length($links) > $MAX_LINKS_LENGTH) {
		maild_set($s, "message",
			  "Links field too long. "
			  ."Maximum allowed is $MAX_LINKS_LENGTH bytes");
	    } elsif (exists($q{ok})) {
		if (do_write_file("$wingdir/$LINKS_FILE", $links)) {
		    maild_set($s, "message", "Links file has been updated");
		} else {
		    maild_set($s, "message", "Failed to update links file");
		}
	    }
	}

	my $callback;
	if ($portal) {
	     $callback = "portal/" . canon_encode("edit_links/$rand");
	} else {
	     $callback = "links";
	}
	return redirect($r, "$url_prefix/$callback");
    }
    my $links_html = escape_html($links);
    my $target = $portal ? 'target="_parent"' : "";
    my $back = $portal ? "list/last" : "links";
    my $info_msg = info_message_html($s);
    dont_cache($r, "text/html");
    $r->print(<<"EOT");
<html><head><title>Edit Links</title></head>
<body>
<table>
<tr>
<td><a href="$url_prefix/$back">
  <img src="/icons/back.gif" border=0 alt="Back"></a></td>
<td><img src="/icons/blank.gif" alt=" | "></td>
<td><a href="$url_prefix/help/edit_links">
  <img src="/wing-icons/help.gif" border=0 alt="Help"></a></td>
<td><img src="/icons/blank.gif" alt=" | "></td>
<td><a href="$url_prefix/logout//edit_links">
  <img src="/wing-icons/logout.gif" border=0 alt="Logout"></a></td>
</tr>
</table>
$info_msg
<h2 align="center">Edit Links</h2>

<form method="POST" $target action="$url_prefix/edit_links/$rand">
<textarea name="links" rows="24" cols="80">
$links_html
</textarea>
<br>
<input type="submit" name="ok" value="OK">
<input type="reset" value="Reset">
</form>
</body>
</html>
EOT
}

sub cmd_no_portal {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};

    my $url_prefix = $conn->{url_prefix};
    maild_set($s, "portal", 0);
    return redirect($r, "$url_prefix/list/last");
}

1;
