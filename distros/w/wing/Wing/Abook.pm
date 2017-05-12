#
# WING - Web-IMAP/NNTP Gateway
#
# Wing/Abook.pm
#
# Author: Malcolm Beattie, mbeattie@sable.ox.ac.uk
#
# This program may be distributed under the GNU General Public License (GPL)
#
# 23 Feb 1999  Release version 0.5
#
package Wing::Connection;
use Wing::Shared;
use SQL;
use strict;

sub abook_path2id {
    my ($abook, $our_username, $our_groupname) = @_;
    $abook =~ s{^(\w+)/}{};
    my $username = $1 || $our_username;
    my $tag = $abook;
    sql_select([id => \my $id], from => "abook_ids",
	       username => $username, tag => $tag);
    sql_fetch or return 0;
    my $ok = 0;
    if ($username eq $our_username) {
	$ok = 1;
    } else {
	# Check permissions
	sql_select([type => \my $type], [name => \my $name],
		   from => "abook_perms", id => $id);
	while (sql_fetch) {
	    $ok ||= $type eq "o"
		    || $type eq "u" && $name eq $our_username
		    || $type eq "g" && $name eq $our_groupname;
	}
    }
    return $ok ? $id : -1
}

#
# At WING login time we do
#
sub init_abook_ids {
    my ($s, $username, $groupname) = @_;
    my $list = maild_get($s, "abook_list");
    my %done;
    #
    # Add the $DEFAULT_ABOOK address book with a "search it" default
    # at the end of the list. It will only be included at that point
    # if no earlier entry mentions it explicitly.
    #
    foreach my $p (maild_decode(split(/:/, $list)), "+$DEFAULT_ABOOK") {
	my ($active, $abook) = unpack("aa*", $p);
	my $flags = ($active eq "+") ? ABOOK_ACTIVE : 0;
	$flags |= ABOOK_OWNED unless $abook =~ m(/); # no slash means we own it
	my $id = abook_path2id($abook, $username, $groupname);
	if ($id == -1) {
	    Apache->request->warn("init_abook_ids: $abook: permission denied");#debug
	    # permission denied
	} elsif ($id == 0) {
	    Apache->request->warn("init_abook_ids: $abook: no such abook");#debug
	    # no such address book
	} else {
	    next if $done{$id};
	    printf $s "abook_add %s %d %s\n", maild_encode($id, $flags, $abook);
	    $done{$id} = 1;
	}
    }
    sql_select([tag => \my $tag], [id => \my $id], from => "abook_ids",
	       username => $username);
    while (sql_fetch) {
	if (!$done{$id}++) {
	    printf $s "abook_add %s %s %s\n",
		maild_encode($id, ABOOK_OWNED, $tag);
	}
    }
}

sub _html_select {
    my ($name, $default, $values) = @_;
    my $html = qq(<select name="$name" size=1>\n);
    foreach my $v (@$values) {
	my ($desc, $val);
	if (ref $v eq "ARRAY") {
	    ($desc, $val) = @$v;
	} else {
	    $desc = $val = $v;
	}
	my $selected = ($val eq $default) ? " selected" : "";
	$desc = escape_html($desc);
	$html .= qq(<option value="$val"$selected>$desc\n);
    }
    $html .= "</select>\n";
    return $html;
}

sub _load_abook_info ($) {
    my $s = shift;
    my $info = [];
    print $s "lsabooks\n";
    while (1) {
	chomp(my $line = <$s>);
	if (!$line) {
	    Apache->request->log_error("_load_abooks: maild daemon vanished");
	    last;
	}
	last if $line eq "."; # the proper way to terminate the list
	push(@$info, [maild_decode(split(' ', $line))]);
	#Apache->request->warn("_load_abook_info: id=$info->[-1][0], flags=$info->[-1][1], name=$info->[-1][2]");#debug
    }
    return $info;
}

sub _find_abook_id ($$;$) {
    my ($info, $name, $flags) = @_;
    $flags = 0 unless defined $flags;	# only return entries with these set
    my @ids = map { $_->[0] }
		  grep { $_->[2] eq $name && (($_->[1] & $flags) == $flags) }
		      @$info;
    return ((@ids == 1) ? $ids[0] : undef);
}

sub _find_abook_ix ($$) {
    my ($info, $id) = @_;
    for (my $ix = 0; $ix < @$info; $ix++) {
	return $ix if $info->[$ix]->[0] == $id;
    }
    return -1;
}

sub _lookup_one_alias {
    my ($dbh, $id_clause, $alias) = @_;
    return $alias unless is_legal_alias($alias);
    my $alias_quoted = $dbh->quote($alias);
    my ($first_name, $last_name, $email) = $dbh->selectrow_array(<<"EOT");
select first_name, last_name, email
from abook_aliases
where $id_clause
and alias = $alias_quoted
EOT
    if ($email) {
	if ($email =~ /,/) {
	    # It's a list
	    return $email;
	} else {
	    return "$first_name $last_name <$email>";
	}
    }
    if ($alias =~ /^[a-z][a-z0-9]{0,7}$/) {
	#
	# See if it's a username
	#
	my ($sender) = $dbh->selectrow_array(
	    "select sender from users where username = $alias_quoted"
	);
	if ($sender) {
	    return $sender;
	}
    }
    return undef;
}

sub _split_addresses {
    my $addresses = shift;
    #
    # XXX For now, we don't worry about commas in comments nor
    # about trying to allow white space to separate addresses.
    # We just split on /\s*,\s*/ to find multiple addresses.
    #
    return split(/\s*,\s*/, $addresses);
}

#
# _lookup_alias looks up a list of (potential) aliases in the default
# address book list (and, if not found there, in the username list).
# The list is passed as a single string containing an RFC822 list of
# addresses (i.e. comma separated).
# It returns a corresponding list (as a string of the same form) where
# each successfully found alias is replaced by the email address in the
# form "First Last <address>" (or just "address1, address2, ..." if the
# alias resolves to a list--i.e. resolves to a string that contains a
# comma). Each unfound address is included without change.
#

sub _lookup_alias {
    my ($conn, $addresses) = @_;
    my $s = $conn->{maild};
    my $abook_info = _load_abook_info($s);
    my @ids = map { $_->[0] } grep { $_->[1] & ABOOK_ACTIVE } @$abook_info;
    if (!@ids) {
	#
	# We *have* to catch this case of no ids since SQL barfs with
	# a syntax error on "...where id in ()". Of course, it's an
	# easy optimisation too.
	#
	return $addresses;
    }
    my $id_clause = "id in (" . join(",", @ids) . ")";

    my @results;
    my @in = _split_addresses($addresses);
    #
    # Verify that at least one is a possible alias before diving into
    # connecting to the database and wading through them.
    #
    my $may_contain_alias = 0;
    foreach my $alias (@in) {
	$may_contain_alias = 1 if is_legal_alias($alias);
    }
    return $addresses unless $may_contain_alias;

    #
    # OK, at least one address in there may be an alias. Connect to
    # the database and start resolving them.
    #
    my @nextin;
    my $dbh = DBI->connect(@WING_DBI_CONNECT_ARGS);

    # Allow alias recursion up to a given maximum level
    my $recurse_max = 5;

    for (my $i = 0; @in && $i < $recurse_max; $i++) {
	while (defined(my $alias = shift @in)) {
	    my $r = _lookup_one_alias($dbh, $id_clause, $alias);
	    if (defined($r)) {
		push(@nextin, _split_addresses($r));
	    } else {
		push(@results, $alias);
	    }
	}
	@in = @nextin;
	@nextin = ();
    }

    $dbh->disconnect;
    return join(", ", @results, @in);
}

sub _resolve_address ($$$$) {
    my ($conn, $first_name, $last_name, $address) = @_;
    
    my $email = _lookup_alias($conn, $address);
    if ($email =~ /,/ || $email ne $address) {
	return $email;
    } elsif ($first_name ne "" && $last_name ne "") {
	return "$first_name $last_name <$email>";
    } elsif ($last_name ne "") {
	return "$last_name <$email>";
    } elsif ($first_name ne "") {
	return "$first_name <$email>";
    } else {
	return $email;
    }
}

sub _list_entries ($$$$) {
    my ($conn, $results, $inc_abook, $callback) = @_;
    my $r = $conn->{request};
    my $url_prefix = $conn->{url_prefix};

    if (@$results == 0) {
	$r->print("No entries");
	return;
    }
    $r->print("<table><tr>\n");
    $r->print("<th>Address book</th>\n") if $inc_abook;
    $r->print(<<"EOT");
<th align="left">Alias</th>
<th align="left">First name</th>
<th align="left">Last name</th>
<th align="left">Comment</th>
<th align="left">Address</th>
</tr>
EOT
    foreach my $res (@$results) {
	my ($abook, $alias, $first_name, $last_name, $comment, $email) = @$res;
	my ($abook_enc, $alias_enc, $first_name_enc, $last_name_enc,
	    $comment_enc, $email_enc) = url_encode(@$res);
	my ($abook_html, $alias_html, $first_name_html, $last_name_html,
	    $comment_html, $email_html) = map { escape_html($_) } @$res;
	my $addr = join("/", canon_encode($first_name, $last_name, $email));
	$r->print("<tr>\n");
	$r->print(<<"EOT") if $inc_abook;
<td><a href="$url_prefix/abook_search?abook=$abook_enc&key0=alias&op0=matches&val0=*&search=Search">$abook</a></td>
EOT
	$r->print(<<"EOT");
<td><a href="$url_prefix/abook_entry?alias=$alias_enc&first_name=$first_name_enc&last_name=$last_name_enc&comment=$comment_enc&email=$email_enc">$alias</a></td>
<td>$first_name_html</td>
<td>$last_name_html</td>
<td>$comment_html</td>
<td>$email_html</td>
<td><a href="$url_prefix/add_address/$callback/To/$addr">T</a></td>
<td><a href="$url_prefix/add_address/$callback/Cc/$addr">C</a></td>
<td><a href="$url_prefix/add_address/$callback/Bcc/$addr">B</a></td>
</tr>
EOT
    }
    $r->print("</table>\n");
}

sub cmd_abook_search {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my $url_prefix = $conn->{url_prefix};
    my @search = (["alias", "is", ""]);
    my $cond;		# any or all
    my $abook;		# abook to search
    my $do_search = 0;	# "Search" button hit
    my @results;	# Holds search results

    my $info_msg = info_message_html($s);
    my $abook_return = maild_get($s, "abook_return") || "list";
    my $abook_info = _load_abook_info($s);
    my %q = ($r->method eq "POST") ? $r->content : $r->args;

    while (my ($key, $value) = each %q) {
	if ($key =~ /^key(\d)$/) {
	    $search[$1][0] = $value;
	} elsif ($key =~ /^op(\d)$/) {
	    $search[$1][1] = $value;
	} elsif ($key =~ /^val(\d)$/) {
	    $search[$1][2] = $value;
	} elsif ($key eq "cond") {
	    $cond = $value;
	} elsif ($key eq "abook") {
	    $abook = $value;
	} elsif ($key eq "add_cond" && @search < 10) {
	    push(@search, ["alias", "is", ""]);
	} elsif ($key eq "add_entry") {
	    my $abook = url_encode($q{abook});
	    # XXX Maybe search other fields for "alias is ..." and
	    # pre-fill-in alias field for abook_entry
	    return redirect($r, "$url_prefix/abook_entry?abook=$abook");
	} elsif ($key eq "search") {
	    $do_search = 1;
	}
    }
    if ($do_search) {
	#
	# Here is where we actually do a search
	#
	my $dbh = DBI->connect(@WING_DBI_CONNECT_ARGS);
	my @where;	# SQL where clause expressions
	foreach my $s (@search) {
	    my $expr;
	    my ($field, $op, $value) = @$s;
	    if ($field eq "alias") {
		$expr = "alias";
	    } elsif ($field eq "first name") {
		$expr = "first_name";
	    } elsif ($field eq "last name") {
		$expr = "last_name";
	    } elsif ($field eq "comment") {
		$expr = "comment";
	    } elsif ($field eq "address") {
		$expr = "email";
	    } else {
		return wing_error($r, "bad search field: $field");
	    }

	    if ($op eq "is") {
		$expr .= " = " . $dbh->quote($value);
	    } elsif ($op eq "begins") {
		$value =~ s/([%\\-])/\\$1/g;
		$expr .= " like " . $dbh->quote("$value%");
	    } elsif ($op eq "ends") {
		$value =~ s/([%\\-])/\\$1/g;
		$expr .= " like " . $dbh->quote("%$value");
	    } elsif ($op eq "contains") {
		$value =~ s/([%\\-])/\\$1/g;
		$expr .= " like " . $dbh->quote("%$value%");
	    } elsif ($op eq "matches") {
		#
		# Convert a glob-style pattern (* and ?) to SQL LIKE (% and -)
		#
		$value =~ s/([%\\-])/\\$1/g;
		$value =~ tr/*?/%-/;
		$expr .= " like " . $dbh->quote($value);
	    } else {
		return wing_error($r, "bad search operator: $op");
	    }
	    push(@where, $expr);
	}
	my $combiner = ($cond eq "any") ? "or" : "and";
	#
	# Put together address book id(s) to search
	#
	my @ids;
	if ($abook eq "") {
	    # default address book list
	    @ids = map { $_->[0] } grep { $_->[1] & ABOOK_ACTIVE } @$abook_info;
	} else {
	    @ids = _find_abook_id($abook_info, $abook);
	}
	my $id_clause;
	if (@ids == 0) {
	    return wing_error($r, "no address books to search");
	} elsif (@ids == 1) {
	    $id_clause = "id = $ids[0]";
	} else {
	    $id_clause = "id in (" . join(",", @ids) . ")";
	}
	my %id2name = map { $_->[0] => $_->[2] } @$abook_info;
	my $sql = sprintf("select id,alias,first_name,last_name,comment,email "
			 ."from abook_aliases where %s and (%s)",
			  $id_clause, join(" $combiner ", @where));
#	$r->warn("abook_search: $sql"); # debug

	#
	# Prepare and execute the SQL query and pull back the results
	#
	my $sth = $dbh->prepare($sql)
	    or return wing_error($r, "DBI prepare failed: $DBI::errstr");
	$sth->execute
	     or return wing_error($r, "DBI execute failed: $DBI::errstr");
	while (my @row = $sth->fetchrow_array) {
#	    $r->warn("row: ", join(", ", @row)); # debug
	    $row[0] = $id2name{$row[0]};
	    push(@results, \@row);
	}
	$sth->finish;
	$dbh->disconnect;
    }

    dont_cache($r, "text/html");
    $r->print(<<"EOT");
<html><head><title>Address book search</title>
<body>
<table><tr>
<td><a href="$url_prefix/$abook_return">
  <img src="/icons/back.gif" border=0 alt="Back"></a>
</td>
<td><a href="$url_prefix/abook_list/abook_search">
  <img src="/wing-icons/address-books.gif" border=0 alt="Address Books"></a>
</td>
<td><a href="$url_prefix/compose">
  <img src="/wing-icons/compose.gif" border=0 alt="Compose"></a>
</td>
<td><a href="$url_prefix/logout//abook_search">
  <img src="/wing-icons/logout.gif" border=0 alt="Logout"></a>
</td>
<tr></table>
$info_msg
<h2 align="center">Address book search</h2>
<form method="POST">
Search in
EOT
    $r->print(_html_select("abook", $abook,
			   [["default list" => ""],
			    map { $_->[2] } (@$abook_info)]));
    $r->print("\n<br>\nfor entries where\n");
    $r->print(_html_select("cond", $cond, ["any", "all"]));
    $r->print("of the following conditions hold\n<table>\n");
    my @poss_keys = ("alias", "first name", "last name", "comment", "address");
    my @poss_ops = ("is", "begins", "ends", "contains", "matches");
    for (my $i = 0; $i < @search; $i++) {
	my $html_val = escape_html($search[$i][2]);
	$r->print("<tr><td>\n",
		  _html_select("key$i", $search[$i][0], \@poss_keys),
		  "</td><td>\n",
		  _html_select("op$i", $search[$i][1], \@poss_ops),
		  "</td><td>\n",
		  qq(<input name="val$i" value="$html_val" size="30">\n),
		  "</td></tr>\n");
    }
    $r->print(<<"EOT");
</table>
<input type="submit" name="search" value="Search">
<input type="submit" name="add_cond" value="Add condition">
<input type="submit" name="add_entry" value="New address book entry">
</form>
EOT
    if ($do_search) {
	_list_entries($conn, \@results, 1, "abook_search");
    }

    $r->print("</body></html>\n");
}

sub cmd_abook_open {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my $url_prefix = $conn->{url_prefix};
    my @results;
    my $abook_return = maild_get($s, "abook_return") || "list";
    my $info_msg = info_message_html($s);

    my %q = $r->args;
    my $abook = $q{abook};
    if ($abook) {
	maild_set($s, "cur_abook", $abook);
    } else {
	$abook = maild_get($s, "cur_abook");
    }
    my $abook_enc = url_encode($abook);
    my $abook_html = escape_html($abook);
    my $callback = canon_encode("abook_open?abook=$abook_enc");

    my $abook_info = _load_abook_info($s);

    my $id = _find_abook_id($abook_info, $abook)
	or return wing_error($r, "Address book '$abook' not in search list");

    my $dbh = DBI->connect(@WING_DBI_CONNECT_ARGS);
    my $sth = $dbh->prepare(
	"select id, alias, first_name, last_name, comment, email"
	." from abook_aliases where id = $id"
    ) or return wing_error($r, "DBI prepare failed: $DBI::errstr");
    $sth->execute or return wing_error($r, "DBI execute failed: $DBI::errstr");
    while (my @row = $sth->fetchrow_array) {
	push(@results, \@row);
    }
    $sth->finish;
    $dbh->disconnect;

    dont_cache($r, "text/html");
    $r->print(<<"EOT");
<html><head><title>Address book `$abook_html'</title>
<body>
<table><tr>
<td><a href="$url_prefix/$abook_return">
  <img src="/icons/back.gif" border=0 alt="Back"></a>
</td>
<td><a href="$url_prefix/abook_list/abook_open">
  <img src="/wing-icons/address-books.gif" border=0 alt="Address Books"></a>
</td>
<td>
  <a href="$url_prefix/abook_search?abook=$abook_enc">
  <img src="/wing-icons/address-search.gif" border=0 alt="Address search"></a>
</td>
<td><a href="$url_prefix/compose">
  <img src="/wing-icons/compose.gif" border=0 alt="Compose"></a>
</td>
<td><a href="$url_prefix/logout//abook_open">
  <img src="/wing-icons/logout.gif" border=0 alt="Logout"></a>
</td>
<tr></table>
$info_msg
<h2 align="center">Address book `$abook_html'</h2>
EOT

    _list_entries($conn, \@results, 0, $callback);

    $r->print(<<"EOT");
<hr>
<p>To include an entry as an addressee on the Compose screen,
click "T", "C," or "B" (for "To", "Cc" or "Bcc" respectively).</p>
<p>To display an entry in full, click on the relevant alias name.
You can modify, delete or copy an alias in this way.</p>
<p>To add a new entry, use this button:
<a href="$url_prefix/abook_entry?abook=$abook_enc">
  <img src="/wing-icons/add-new-entry.gif" border=0
    align="absmiddle" alt="Add new entry"></a>
</p>
</body></html>
EOT
}

sub cmd_abook_entry {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my $url_prefix = $conn->{url_prefix};
    my ($abook, $alias, $first_name, $last_name, $comment, $email);
    my $info_msg = info_message_html($s);
    my $abook_info = _load_abook_info($s);

    my %q = ($r->method eq "POST") ? $r->content : $r->args;
    ($abook, $alias, $first_name, $last_name, $comment, $email)
	= @q{"abook","alias","first_name","last_name","comment","email"};
    if (defined($q{add_update})) {
	my $id = _find_abook_id($abook_info, $abook, ABOOK_OWNED)
	    or return wing_error($r, "invalid address book '$abook'");
	sql_connect(@WING_DBI_CONNECT_ARGS);
#	local($SIG{__WARN__}) = sub { $r->warn("sql_debug: @_") };
#	sql_debug(1);
	sql_table("abook_aliases");
	sql_select(["count(*)" => \my $count], id => $id, alias => $alias);
	sql_fetch;
	my @fields = ([first_name => \$first_name],
		      [last_name => \$last_name],
		      [comment => \$comment],
		      [email => \$email]);
	if ($count) {
	    # entry already present: update it
	    sql_update(@fields, id => $id, alias => $alias);
	    $info_msg .= "\nUpdated entry for alias ".escape_html($alias);
	    $alias = $first_name = $last_name = $comment = $email = "";
	} else {
	    # entry not present: insert it if it's a reasonable alias
	    if (is_legal_alias($alias)) {
		sql_insert([id => \$id], [alias => \$alias], @fields);
		$info_msg .= "\nAdded entry for alias ".escape_html($alias);
		$alias = $first_name = $last_name = $comment = $email = "";
	    } else {
		$info_msg .= sprintf("\nIllegal alias: %s\n<br>\n%s\n",
				     escape_html($alias), $LEGAL_ALIAS_RULES);
	    }
	}
	sql_disconnect;
    } elsif (defined($q{delete_entry})) {
	sql_connect(@WING_DBI_CONNECT_ARGS);
	my $rows = sql_delete(from => "abook_aliases", alias => $alias);
	sql_disconnect;
	if ($rows == 1) {
	    $info_msg .= "\n<br>Alias $alias has been deleted";
	    $alias = $first_name = $last_name = $comment = $email = "";
	} else {
	    $info_msg .= "\n<br>No entry in address book '$abook' for $alias";
	}
    } elsif (defined($q{add_to_To})) {
	my $address = _resolve_address($conn, $first_name, $last_name, $email);
	printf $s "add_address To %s\n", canon_encode($address);
	$info_msg .= "\n<br>Added to To header: ".escape_html($address);
    } elsif (defined($q{add_to_Cc})) {
	my $address = _resolve_address($conn, $first_name, $last_name, $email);
	printf $s "add_address Cc %s\n", canon_encode($address);
	$info_msg .= "\n<br>Added to Cc header: ".escape_html($address);
    } elsif (defined($q{add_to_Bcc})) {
	my $address = _resolve_address($conn, $first_name, $last_name, $email);
	printf $s "add_address Bcc %s\n", canon_encode($address);
	$info_msg .= "\n<br>Added to Bcc header: ".escape_html($address);
    }
    $abook ||= maild_get($s, "cur_abook") || $DEFAULT_ABOOK;
    maild_set($s, "cur_abook", $abook);

    my $alias_enc = url_encode($alias);
    my $abook_enc = url_encode($abook);
    # XXX Fix up html encoding for other fields
    dont_cache($r, "text/html");
    $r->print(<<"EOT");
<html><head><title>Entry for address book `$abook'</title>
<body>
<table><tr>
<td><a href="$url_prefix/abook_open?abook=$abook_enc">
  <img src="/icons/back.gif" border=0 alt="Back"></a>
</td>
<td><a href="$url_prefix/abook_list/abook_entry">
  <img src="/wing-icons/address-books.gif" border=0 alt="Address Books"></a>
</td>
<td><a href="$url_prefix/abook_search?abook=$abook_enc&key0=alias&op0=is&val0=$alias_enc">
  <img src="/wing-icons/address-search.gif" border=0 alt="Address Search"></a>
</td>
<td><a href="$url_prefix/compose">
  <img src="/wing-icons/compose.gif" border=0 alt="Compose"></a>
</td>
<td><a href="$url_prefix/logout//abook_entry">
  <img src="/wing-icons/logout.gif" border=0 alt="Logout"></a>
</td>
</tr></table>
$info_msg
<h1 align="center">Entry for address book
`<a href="$url_prefix/abook_open?abook=$abook_enc">$abook</a>'</h1>
<form method="POST">
<table>
<tr>
  <td>Alias</td>
  <td><input name="alias" value="$alias" size="20"></td>
</tr>
<tr>
  <td>First/Last name</td>
  <td><input name="first_name" value="$first_name" size="20"></td>
  <td><input name="last_name" value="$last_name" size="20"></td>
</tr>
<tr>
  <td>Comment</td>
  <td colspan=2><input name="comment" value="$comment" size="43"></td>
</tr>
<tr>
  <td>Address(es)</td>
  <td colspan=2><input name="email" value="$email" size="43"></td>
</tr>
</table>
<br>
Update address book
EOT
    my @names = map { $_->[2] } grep { $_->[1] & 2 } @$abook_info;
    $r->print(_html_select("abook", $abook, \@names));
    $r->print(<<"EOT");
<input type="submit" name="add_update" value="Add/Update entry">
<input type="submit" name="delete_entry" value="Delete entry">
<br>
<input type="submit" name="add_to_To" value="Add to To">
<input type="submit" name="add_to_Cc" value="Add to Cc">
<input type="submit" name="add_to_Bcc" value="Add to Bcc">
</form>
</body></html>
EOT
}

sub cmd_abook_list {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my $url_prefix = $conn->{url_prefix};
    my $abook_info = _load_abook_info($s);
    my $abook_max = @$abook_info - 1;
    my $do_save = 0;	# save settings for future sessions
    my $done_adjust = 0;# settings have been adjusted this time through

    my $info_msg = info_message_html($s);
    my $abook_return = maild_get($s, "abook_return") || "list";
    if ($r->method eq "POST") {
	my %q = $r->content;
	while (my ($key, $value) = each %q) {
	    if ($key eq "create_add") {
		my $abook = $q{abook};
		#
		# Sanity check address book name. Don't use
		# is_legal_abook_name yet since we want to allow
		# names of the form "username/foo".
		#
		if (length($abook) > 256) {
		    return wing_error($r, "address book name too long: $abook");
		}
		#
		# XXX Fix this spaghetti
		#
		if (_find_abook_id($abook_info, $abook)) {
		    $info_msg .= "\n<br>Address book $abook already in list";
		} else {
		    print $s "username\n";
		    chomp(my $username = <$s>);
		    my $group = maild_get($s, "group");
		    sql_connect(@WING_DBI_CONNECT_ARGS);
		    my $id = abook_path2id($abook, $username, $group);
		    if ($id == 0) {
			if ($abook =~ m(/)) {
			    # XXX Ought to allow explicit "ourusername/foo"
			    $info_msg .= "\n<br><strong>No such address book "
					. "and can't create it</strong>";
			} elsif (!is_legal_abook_name($abook)) {
			    $info_msg .= sprintf(
	"\n<br><strong>Illegal address book name: %s</strong><br>\n%s\n",
	 escape_html($abook), $LEGAL_ABOOK_RULES);
			} else {
			    # Doesn't exist: create it
			    sql_select(["nextval('abook_ids_seq')" => \$id]);
			    sql_fetch or $r->log_error("abook_ids_seq failed");
			    sql_insert(into => "abook_ids",
				       [id => \$id],
				       [username => \$username],
				       [tag => \$abook]);
			    printf $s "abook_add %s %s %s\n",
				maild_encode($id, ABOOK_OWNED|ABOOK_ACTIVE,
					     $abook);
			    $info_msg .= "\n<br><strong>Created address book $abook</strong>";
			    $done_adjust = 1;
			}
		    } elsif ($id == -1) {
			$info_msg .= "\n<br><strong>Permission denied for"
				    ." address book $abook</strong>";
		    } else {
			#
			# Add existing address book to our search list
			# It can't be ours since we always force all our
			# address books into abook_list
			#
			printf $s "abook_add %s %s %s\n",
			    maild_encode($id, ABOOK_ACTIVE, $abook);
			$info_msg .= "\n<br><strong>Added address book $abook</strong>";
			$done_adjust = 1;
		    }
		    sql_disconnect;
		}
	    } elsif ($key eq "search") {
		return redirect($r, "$url_prefix/abook_search?"
				  . "search=Search&key0=alias&op0=is&val0="
				  . url_encode($q{alias}));
	    } elsif ($key eq "update_save") {
		$do_save = 1;
	    }
	}
	if ($done_adjust) {
	    $abook_info = _load_abook_info($s);
	}
	if ($do_save) {
	    #
	    # Save address book list (order plus whether to search)
	    # for future sessions.
	    #
	    my @list = map { (($_->[1] & ABOOK_ACTIVE) ? "+" : "-") . $_->[2] }
			@$abook_info;
	    print $s "username\n";
	    chomp(my $username = <$s>);
	    my $dbh = DBI->connect(@WING_DBI_CONNECT_ARGS);
	    my $list_q = $dbh->quote(join(":", @list));
	    my $done = $dbh->do(
	      "update options set abooklist=$list_q where username='$username'"
	    );
	    if ($done eq "0E0") {
		# User has never saved any options yet: insert instead
		$done = $dbh->do(
		  "insert into options (username, abooklist) values "
		  ."($username, $list_q)"
		);
	    }
	    $info_msg = $done ? "Address book search list has been saved"
			      : "Address book search list could not be saved";
	    $dbh->disconnect;
	}
    }
    dont_cache($r, "text/html");
    $r->print(<<"EOT");
<html><head><title>Address books</title>
<body>
<table><tr>
<td><a href="$url_prefix/$abook_return">
  <img src="/icons/back.gif" border=0 alt="Back"></a>
</td>
<td><a href="$url_prefix/help/abook_list">
  <img src="/wing-icons/help.gif" border=0 alt="Help"></a>
</td>
<td><a href="$url_prefix/abook_search">
  <img src="/wing-icons/address-search.gif" border=0 alt="Address Search"></a>
</td>
<td><a href="$url_prefix/abook_import">
  <img src="/wing-icons/import-address-book.gif" border=0
    alt="Import Address Book"></a>
</td>
<td><a href="$url_prefix/logout//abook_list">
  <img src="/wing-icons/logout.gif" border=0 alt="Logout"></a>
</td>
</tr></table>
$info_msg
<h2 align="center">Address books</h2>
<table>
EOT
    for (my $ix = 0; $ix < @$abook_info; $ix++) {
	my ($id, $flags, $name) = @{$abook_info->[$ix]};
	my $name_html = escape_html($name);
	my $name_enc = url_encode($name);
	my $active_html;
	my $up_html;
	my $down_html;
	my $buttons_html;

	if ($flags & ABOOK_ACTIVE) {
	    $active_html = <<"EOT";
<a href="$url_prefix/abook_adjust/deactivate/$ix">
  <img src="/wing-icons/plus.gif" border=0 alt="+"></a>
EOT
	} else {
	    $active_html = <<"EOT";
<a href="$url_prefix/abook_adjust/activate/$ix">
  <img src="/wing-icons/minus.gif" border=0 alt="+"></a>
EOT
	}

	if ($flags & ABOOK_OWNED) {
	    $buttons_html = <<"EOT";
<a href="$url_prefix/abook_perms/$ix">
  <img src="/wing-icons/permissions.gif" border=0 alt="Permissions"></a>
EOT
	    $buttons_html .= <<"EOT" unless $name eq "personal";
</td>
<td><a href="$url_prefix/abook_adjust/delete/$ix">
  <img src="/wing-icons/delete.gif" border=0 alt="Delete"></a>
EOT
	} else {
	    $buttons_html = <<"EOT";
<a href="$url_prefix/abook_adjust/drop/$ix">
  <img src="/wing-icons/drop.gif" border=0 alt="Drop"></a>
EOT
	}


	if ($ix > 0) {
	    $up_html = <<"EOT";
<a href="$url_prefix/abook_adjust/up/$ix">
  <img src="/wing-icons/arrow-up.gif" alt="Up" border=0></a>
EOT
	} else {
	    $up_html = <<"EOT";
<img src="/wing-icons/arrow-up-inactive.gif" alt="&nbsp;&nbsp;" border=0>
EOT
	}
	if ($ix < @$abook_info - 1) {
	    $down_html = <<"EOT";
<a href="$url_prefix/abook_adjust/down/$ix">
  <img src="/wing-icons/arrow-down.gif" alt="Down" border=0></a>
EOT
	} else {
	    $down_html = <<"EOT";
<img src="/wing-icons/arrow-down-inactive.gif" alt="&nbsp;&nbsp;&nbsp;&nbsp;" border=0>
EOT
	}
	$r->print(<<"EOT");
<tr>
<td>$active_html</td>
<td><a href="$url_prefix/abook_open?abook=$name_enc">$name_html</a></td>
<td>$up_html</td>
<td>$down_html</td>
<td>$buttons_html</td>
</tr>
EOT
    }
    $r->print(<<"EOT");
</table>
<form method="POST">
<input type="submit" name="update_save" value="Update for future sessions">
<br>
Address book <input name="abook">
<input type="submit" name="create_add" value="Create/Add to list">
<br>
Quick search for alias <input name="alias">
<input type="submit" name="search" value="Search">
</form>
</body></html>
EOT
}

sub cmd_abook_adjust {
    my ($conn, $cmd, $ix) = @_;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my $url_prefix = $conn->{url_prefix};
    my $abook_info = _load_abook_info($s);
    my $max = @$abook_info - 1;

    $ix += 0;
    if ($cmd eq "up" && $ix > 0 && $ix <= $max) {
	printf $s "abook_reposition %d %d\n", $ix, $ix - 1;
	maild_set($s, "message", "Address book search position adjusted");
    } elsif ($cmd eq "down" && $ix >= 0 && $ix < $max) {
	printf $s "abook_reposition %d %d\n", $ix, $ix + 1;
	maild_set($s, "message", "Address book search position adjusted");
    } elsif ($cmd eq "drop" && $ix >= 0 && $ix <= $max
	     && !($abook_info->[$ix]->[1] & ABOOK_OWNED)) {
	print $s "abook_drop $ix\n";
	maild_set($s, "message", "Address book dropped from search list");
    } elsif ($cmd eq "delete" && $ix >= 0 && $ix <= $max) {
	my ($id, $flags, $name) = @{$abook_info->[$ix]};
	if (!($flags & ABOOK_OWNED)) {
	    maild_set($s, "message",
		      "You cannot delete an address book which you do not own");
	} elsif ($name eq "personal") {
	    maild_set($s, "message",
		      "You cannot delete your personal address book");
	} else {
	    my $dbh = DBI->connect(@WING_DBI_CONNECT_ARGS);
	    $dbh->do("delete from abook_aliases where id = $id");
	    $dbh->do("delete from abook_perms where id = $id");
	    $dbh->do("delete from abook_ids where id = $id");
	    $dbh->disconnect;
	    print $s "abook_drop $ix\n";
	    maild_set($s, "message", "Address book $name has been deleted");
	}
    } elsif ($cmd eq "activate" && $ix >= 0 && $ix <= $max) {
	my $flags = $abook_info->[$ix]->[1] | ABOOK_ACTIVE;
	print $s "abook_flags $ix $flags\n";
	maild_set($s, "message", "Address book activated in search list");
    } elsif ($cmd eq "deactivate" && $ix >= 0 && $ix <= $max) {
	my $flags = $abook_info->[$ix]->[1] & ~ABOOK_ACTIVE;
	print $s "abook_flags $ix $flags\n";
	maild_set($s, "message", "Address book deactivated in search list");
    } else {
	return wing_error($r, "bad command for abook_adjust: $cmd");
    }
    return redirect($r, "$url_prefix/abook_list");
}

sub cmd_abook_perms {
    my ($conn, $ix) = @_;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my $url_prefix = $conn->{url_prefix};
    my $abook_info = _load_abook_info($s);
    $ix += 0;

    if ($ix < 0 || $ix >= @$abook_info) {
	return wing_error($r, "Bad address book index: $ix");
    }
    my ($id, $flags, $abook) = @{$abook_info->[$ix]};
    if (!($flags & ABOOK_OWNED)) {
	return wing_error($r, "Address book '$abook' not owned by you");
    }
    my $abook_html = escape_html($abook);
    my $abook_enc = url_encode($abook);
    my $group = maild_get($s, "group");

    my %q = $r->args;
    my %ok_user;
    my %ok_group;
    my $ok_all = 0;
    my $info_msg = "";

    sql_connect(@WING_DBI_CONNECT_ARGS);
    sql_table("abook_perms");
    sql_select([type => \my $type], [name => \my $name], id => $id);
    while (sql_fetch) {
	if ($type eq "a") {
	    $ok_all = 1;
	} elsif ($type eq "u") {
	    $ok_user{$name} = 1;
	} elsif ($type eq "g") {
	    $ok_group{$name} = 1;
	} else {
	    $r->warn("bad type '$type' in abook_perms for id $id");
	}
    }

    if (defined($name = $q{drop_user})) {
	return wing_error($r, "User $name not in list") unless $ok_user{$name};
	sql_delete(id => $id, type => "u", name => $name);
	delete $ok_user{$name};
	$info_msg = "Dropped $name from list of permitted users";
    } elsif (defined($name = $q{drop_group})) {
	return wing_error($r,"Group $name not in list") unless $ok_group{$name};
	sql_delete(id => $id, type => "g", name => $name);
	delete $ok_group{$name};
	$info_msg = "Dropped $name from list of permitted groups";
    } elsif (defined($q{drop_all})) {
	return wing_error($r, "Permission to all not currently granted")
	    unless $ok_all;
	sql_delete(id => $id, type => "a");
	$info_msg = "Permission for all has been dropped";
	$ok_all = 0;
    } elsif (defined($q{allow})) {
	$name = $q{name};
	my $type = $q{type};
	return wing_error($r, "Bad user or group name '$name'")
	    unless $name =~ /^[a-z0-9]{1,8}$/;
	if ($type eq "u") {
	    return wing_error($r, "$name already in list of permitted users")
		if $ok_user{$name};
	    $ok_user{$name} = 1;
	} elsif ($type eq "g") {
	    return wing_error($r, "$name already in list of permitted groups")
		if $ok_group{$name};
	    $ok_group{$name} = 1;
	} else {
	    return wing_error($r, "Bad type '$type': must be 'u' or 'g'");
	}
	sql_insert([id => \$id], [type => \$type], [name => \$name]);
    } elsif (defined($q{allow_all})) {
	return wing_error($r, "Permission to all already granted") if $ok_all;
	$ok_all = 1;
	sql_begin;
	sql_delete(id => $id);
	sql_insert([id => \$id], [type => \"a"], [name => \"*"]);
	sql_commit;
    }

    my @users_html = map {
	qq(<a href="$url_prefix/abook_perms/$ix?drop_user=$_">$_</a>)
    } sort keys %ok_user;
    if (!@users_html) {
	@users_html = "(none)";
    }

    my @groups_html = map {
	qq(<a href="$url_prefix/abook_perms/$ix?drop_group=$_">$_</a>)
    } sort keys %ok_group;
    if (!@groups_html) {
	@groups_html = "(none)";
    }

    $r->print(<<"EOT");
<html><head><title>Permissions for address book `$abook_html'</title>
<body>
<table><tr>
<td><a href="$url_prefix/abook_list">
  <img src="/icons/back.gif" border=0 alt="Back"></a>
</td>
<td><a href="$url_prefix/logout//abook_perms">
  <img src="/wing-icons/logout.gif" border=0 alt="Logout"></a></td>
</tr></table>
$info_msg
<h2 align="center">Permissions for address book `$abook_html'</h2>
EOT

    if ($ok_all) {
	$r->print(<<"EOT");
Permission to all has been granted for this address book.
<br>
To drop this permission, use this button:
<a href="$url_prefix/abook_perms/$ix?drop_all=1">
  <img align="absmiddle" src="/wing-icons/drop-permission.gif" border=0 alt="Drop Permission"></a>
EOT
    } else {
	$r->print("<h4>Usernames that have been granted access</h4>\n",
		  join(", ", @users_html),
		  "\n",
		  "<h4>Groups that have been granted access</h4>\n",
		  join(", ", @groups_html),
		  "\n<hr>\n");
	$r->print(<<"EOT");
<h4>Changing permissions</h4>
<p>You are in group $group</p>
<p>To drop permission for a particular user or group, click on
its name in the appropriate list above.</p>
<p>To grant permission to a particular user or group, enter the name
below and press the "Allow" button.</p>
<form>
<br>
Allow access to
<select name="type" size=1>
<option value="u" selected>user
<option value="g">group
</select>
<input size=8 name="name">
<input type="submit" name="allow" value="Allow">
</form>
To grant permission for everybody to access the address book, use
this button:
<a href="$url_prefix/abook_perms/$ix?allow_all=1">
  <img align="absmiddle" src="/wing-icons/allow-all.gif" border=0 alt="Allow all"></a>
EOT
    }
    $r->print("</body></html>\n");
}

sub cmd_add_address {
    my ($conn, $callback, $hdr, $first_name, $last_name, $email) = @_;
    ($first_name, $last_name, $email) =
	canon_decode($first_name, $last_name, $email);
    my $r = $conn->{request};
    my $s = $conn->{maild};

    my $address = _resolve_address($conn, $first_name, $last_name, $email);
    $callback = canon_decode($callback);
    #
    # Sanity check
    #
    if (length($address) > 1024) {
	return wing_error($r, "Address too long: ". escape_html($address));
    }
    if ($hdr ne "To" && $hdr ne "Cc" && $hdr ne "Bcc") {
	return wing_error($r, "Bad header: $hdr");
    }
    printf $s "add_address $hdr %s\n", canon_encode($address);
    maild_set($s, "message", "Added to $hdr header: ".escape_html($address));
    return redirect($r, "$conn->{url_prefix}/$callback");
}

#
# For importing address books we need MIME::Parser
#
use MIME::Parser;

sub _receive_abook_upload {
    my $r = shift;
    my ($type, $abook, $lines);
    my $size = $r->header_in("Content-Length");
    if ($size > $ABOOK_IMPORT_SIZE_LIMIT) {
	return <<"EOT";
Address book uploaded was too large. Your client wanted to send
$size bytes (including MIME overhead data) but the size limit is
$ABOOK_IMPORT_SIZE_LIMIT bytes.
EOT
    }
    my $buffer = "";  # must reset $buffer or Apache::read appends to it
    my $didread = $r->read($buffer, $size);
    if ($didread != $size) {
	return "client failed to upload correct data size";
    }
    
#    $r->warn("raw data: $buffer");#debug
    my $parser = MIME::Parser->new(output_to_core => "ALL");
    $buffer =~ /^--(.*)\r\n/
	or return "Badly formatted MIME form from client";
    $buffer = "Content-Type: multipart/form-data;boundary=$1\r\n\r\n$buffer";
    my $ent = $parser->parse_data($buffer);
    $buffer = "";
    
    my $num = $ent->parts;
#    $r->warn("$num MIME parts");#debug
    for (my $i = 0; $i < $num; $i++) {
	my $part = $ent->parts($i);
	my $name = $part->head->mime_attr("content-disposition.name");
#	$r->warn("part $i name=$name");#debug
	if ($name eq "abook") {
	    $abook = $part->body->[0];
#	    $r->warn("abook=$abook");#debug
	    if (!is_legal_abook_name($abook)) {
		return "Illegal address book name chosen. $LEGAL_ABOOK_RULES";
	    }
	} elsif ($name eq "type") {
	    $type = $part->body->[0];
#	    $r->warn("type=$type");#debug
	    return "Illegal format chosen" unless $type eq "pine";
	} elsif ($name eq "file") {
	    $lines = $part->body;
#	    $r->warn("lines=$lines");#debug
	}
    }

    if (!defined($lines)) {
	return "No address book file uploaded";
    }

    return ($abook, $type, $lines);
}

sub _next_pine_abook_entry {
    my $lines = shift;
    my $line;
    do {
	$line = shift @$lines;
    } while $line =~ /^#/;
    return () unless $line;
    $line .= shift @$lines while $lines->[0] =~ s/^\s+//;
    $line =~ tr/\r\n//d; # either, not just both together
    my ($alias, $full_name, $email, $fcc, $comment) = split(/\t/, $line);
    next if $alias eq "";
    $email .= "";	# ensure it's not undef
    $comment .= "";	# ensure it's not undef
    for ($email) {
	s/^\(//;
	s/\)$//;
    }
    my $first_name = "";
    my $last_name = "";
    if ($full_name =~ /^"(.*)"$/) {
	$last_name = $1;
    } elsif ($full_name =~ /^(.*?),\s*(.*)$/) {
	$first_name = $2;
	$last_name = $1;
    } else {
	$last_name = $full_name;
    }
    return ($alias, $first_name, $last_name, $comment, $email);
}

sub cmd_abook_import {
    my $conn = shift;
    my $r = $conn->{request};
    my $s = $conn->{maild};
    my $url_prefix = $conn->{url_prefix};
    my $info_msg = info_message_html($s);
    my ($type, $abook, $lines);

    if ($r->method eq "POST") {
	($abook, $type, $lines) = _receive_abook_upload($r);
	if (!defined($lines)) {
	    $info_msg = $abook;
	    $abook = "";
	    goto show_form;
	}

	my $abook_info = _load_abook_info($s);
	my $id = _find_abook_id($abook_info, $abook, ABOOK_OWNED);
	if ($id) {
	    $info_msg .= <<"EOT";
Address book $abook already exists. Please give the name of an
address book you want to create to hold the newly imported data.
EOT
	    goto show_form;
	}

	sql_connect(@WING_DBI_CONNECT_ARGS);
#	local($SIG{__WARN__}) = sub { $r->warn("sql_debug: @_") };#debug
#	sql_debug(1);#debug

	# Create the new address book
	print $s "username\n";
	chomp(my $username = <$s>);

	sql_select(["nextval('abook_ids_seq')" => \$id]);
	sql_fetch or $r->log_error("abook_ids_seq failed");
	sql_insert(into => "abook_ids",
		   [id => \$id], [username => \$username], [tag => \$abook]);
	printf $s "abook_add %s %s %s\n",
	    maild_encode($id, ABOOK_OWNED|ABOOK_ACTIVE, $abook);
	# $abook_info now out of date (would need to _load_abook_info if nec)

	sql_table("abook_aliases");
	my ($alias, $first_name, $last_name, $comment, $email);
	my @fields = ([id => \$id],
		      [alias => \$alias],
		      [first_name => \$first_name],
		      [last_name => \$last_name],
		      [comment => \$comment],
		      [email => \$email]);

	my $count = 0;
	while (($alias, $first_name, $last_name, $comment, $email) =
		_next_pine_abook_entry($lines))
	{
	    if (!is_legal_alias($alias)) {
		$info_msg .= "\nOmitted entry with illegal alias: '$alias'. ";
	    } else {
		$count++;
		sql_insert(@fields);
#		$r->warn("a=$alias fn=$first_name ln=$last_name c=$comment e=$email");#debug
	    }
	}
	sql_disconnect;
	$info_msg .= "\nImported $count entries into new address book $abook";
	$abook = "";
    }

  show_form:

    $info_msg = "<strong>$info_msg</strong>";
    my $abook_html = escape_html($abook);
    dont_cache($r, "text/html");
    $r->print(<<"EOT");
<html><head><title>Import address book</title>
<body>
<table><tr>
<td><a href="$url_prefix/list">
  <img src="/icons/back.gif" border=0 alt="Back"></a>
</td>
<td><a href="$url_prefix/abook_list">
  <img src="/wing-icons/address-books.gif" border=0 alt="Address Books"></a>
</td>
<td><a href="$url_prefix/logout//abook_import">
  <img src="/wing-icons/logout.gif" border=0 alt="Logout"></a>
</td>
</tr></table>
$info_msg
<h1 align="center">Import address book</h1>
<form method="POST" action="$url_prefix/abook_import"
  enctype="multipart/form-data">
<table>
<tr>
  <td>Import
    <select size=1 name="type">
      <option value="pine" selected>Pine</option>
    </select>
    format address book file</td>
  <td><input type="file" name="file"></td>
</tr>
<tr>
  <td>and create new address book with name</td>
  <td><input name="abook" value="$abook_html"></td>
</tr>
</table>
<br>
<input type="submit" value="Import">
</form>
</body></html>
EOT
}

1;
