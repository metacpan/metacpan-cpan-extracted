<%args>
$id
</%args>
<%perl>
my $db = ZOOM::IRSpy::connect_to_registry();
my $conn = new ZOOM::Connection($db);
$conn->option(elementSetName => "zeerex");
my $query = cql_target($id);
my $rs = $conn->search(new ZOOM::Query::CQL($query));
my $n = $rs->size();
if ($n == 0) {
    $m->comp("/details/error.mc",
	     title => "Error", message => "No such ID '$id'");
} else {
    my $xc = irspy_xpath_context($rs->record(0));
    my @fields = (
		  [ Name => "e:databaseInfo/e:title",
		    lang => "en", primary => "true" ],
		  [ Country => "i:status/i:country" ],
		  [ "Last Checked" => "i:status/i:probe[last()]" ],
		  [ Protocol => "e:serverInfo/\@protocol" ],
		  [ Host => "e:serverInfo/e:host" ],
		  [ Port => "e:serverInfo/e:port" ],
		  [ "Database Name" => "e:serverInfo/e:database" ],
		  [ "Type of Library" => "i:status/i:libraryType" ],
#		  [ "Username (if needed)" => "e:serverInfo/e:authentication/e:user" ],
#		  [ "Password (if needed)" => "e:serverInfo/e:authentication/e:password" ],
		  [ "Server ID" => 'i:status/i:serverImplementationId/@value' ],
		  [ "Server Name" => 'i:status/i:serverImplementationName/@value' ],
		  [ "Server Version" => 'i:status/i:serverImplementationVersion/@value' ],
		  [ Description => "e:databaseInfo/e:description",
		    lang => "en", primary => "true" ],
		  [ Author => "e:databaseInfo/e:author" ],
		  [ Contact => "e:databaseInfo/e:contact" ],
		  [ "URL to Hosting Organisation" => "i:status/i:hostURL" ],
		  [ Extent => "e:databaseInfo/e:extent" ],
		  [ History => "e:databaseInfo/e:history" ],
		  [ "Language of Records" => "e:databaseInfo/e:langUsage" ],
		  [ Restrictions => "e:databaseInfo/e:restrictions" ],
		  [ Subjects => "e:databaseInfo/e:subjects" ],
		  [ "Implementation ID" => "i:status/i:implementationId" ],
		  [ "Implementation Name" => "i:status/i:implementationName" ],
		  [ "Implementation Version" => "i:status/i:implementationVersion" ],
		  [ "Reliability/reliability" => \&calc_reliability_wrapper, $xc ],
		  [ "Services" => \&calc_init_options, $xc ],
		  [ "Bib-1 Use attributes" => \&calc_ap, $xc, "bib-1" ],
		  [ "Dan-1 Use attributes" => \&calc_ap, $xc, "dan-1" ],
		  [ "Bath Profile searches" => \&calc_bath, $xc ],
		  [ "Operators" => \&calc_boolean, $xc ],
		  [ "Named Result Sets" => \&calc_nrs, $xc ],
		  [ "Record syntaxes" => \&calc_recsyn, $xc ],
		  [ "Explain" => \&calc_explain, $xc ],
		  [ "Multiple OPAC records" => \&calc_mor, $xc ],
		  );
    my $title = $xc->find("e:databaseInfo/e:title");
</%perl>
     <h2><% xml_encode($title, "") %></h2>
     <table class="fullrecord" border="1" cellspacing="0" cellpadding="5" width="100%">
<%perl>
    foreach my $ref (@fields) {
	my($caption, $xpath, @args) = @$ref;
	my($data, $linkURL);
	if (ref $xpath && ref($xpath) eq "CODE") {
	    ($data, $linkURL) = &$xpath($id, @args);
	} else {
	    $data = $xc->find($xpath);
	}
	if ($data) {
	    print "      <tr>\n";
	    $caption =~ s/\/(.*)//;
	    my $help = $1;
	    my($linkstart, $linkend) = ("", "");
	    if (defined $linkURL) {
		$linkstart = '<a href="' . xml_encode($linkURL) . '">';
		$linkend = "</a>";
	    }
</%perl>
       <th><% xml_encode($caption) %><%
	!defined $help ? "" : $m->comp("/help/link.mc", help =>"info/$help")
	%></th>
       <td><% $linkstart . xml_encode($data) . $linkend %></td>
      </tr>
%	}
%   }
     </table>
     <p>
% my $target = irspy_identifier2target($id);
% $target =~ s/^tcp://; # Apparently ZAP can't handle the leading "tcp:"
      <a href="<% xml_encode("http://targettest.indexdata.com/targettest/search/index.zap?" .
	join("&",
	     "target=" . uri_escape_utf8($target),
	     "name=" . uri_escape_utf8($title),
	     "attr=" . join(" ", _list_ap($xc, "bib-1")),
	     "formats=" . calc_recsyn($id, $xc, " ")))
	%>">Search this target.</a>
     </p>
% }
<%perl>

sub calc_reliability_wrapper {
    my($id, $xc) = @_;
    return calc_reliability_string($xc);
}

sub calc_init_options {
    my($id, $xc) = @_;

    my @ops;
    my @nodes = $xc->findnodes('e:configInfo/e:supports/@type');
    foreach my $node (@nodes) {
	my $type = $node->value();
	if ($type =~ s/^z3950_//) {
	    push @ops, $type;
	}
    }

    return join(", ", @ops);
}

sub calc_ap {
    my($id, $xc, $set) = @_;

    my @aps = _list_ap($xc, $set);
    my $n = @aps;
    return "[none]" if $n == 0;

    my $res = "";
    my($first, $last);
    foreach my $ap (@aps) {
	if (!defined $first) {
	    $first = $last = $ap;
	} elsif ($ap == $last+1) {
	    $last++;
	} else {
	    # Got a complete range
	    $res .= ", " if $res ne "";
	    $res .= "$first";
	    $res .= "-$last" if $last > $first;
	    $first = $last = $ap;
	}
    }

    # Leftovers
    if (defined $first) {
	$res .= ", " if $res ne "";
	$res .= "$first";
	$res .= "-$last" if $last > $first;
    }

    return ("$n access points: $res",
	    "/ap.html?id=$id&set=$set");
}

sub _list_ap {
    my($xc, $set) = @_;

    my $expr = 'e:indexInfo/e:index[@search = "true"]/e:map/e:attr[
	@set = "'.$set.'" and @type = "1"]';
    my @nodes = $xc->findnodes($expr);
    return sort { $a <=> $b } map { $_->findvalue(".") } @nodes;
}

sub calc_bath {
    my($id, $xc) = @_;

    my @nodes = $xc->findnodes('i:status/i:search_bath[@ok = "1"]');
    my $res = join(", ", map { $_->findvalue('@name') } @nodes);
    $res = "[none]" if $res eq "";
    return $res;
}

sub calc_boolean {
    my($id, $xc) = @_;

    ### Note that we are currently interrogating an IRSpy extension.
    #	The standard ZeeRex record should be extended with a
    #	"supports" type for this.
    my @nodes = $xc->findnodes('i:status/i:boolean[@ok = "1"]');
    my $res = join(", ", map { $_->findvalue('@operator') } @nodes);
    $res = "[none]" if $res eq "";
    return $res;
}

sub calc_nrs { _calc_boolean(@_, 'i:status/i:named_resultset[@ok = "1"]') }
sub calc_mor { _calc_boolean(@_, 'i:status/i:multiple_opac[@ok = "1"]') }

sub _calc_boolean {
    my($id, $xc, $xpath) = @_;

    my @nodes = $xc->findnodes($xpath);
    return @nodes ? "Yes" : "No";
}

sub calc_recsyn {
    my($id, $xc, $sep) = @_;
    $sep = ", " if !defined $sep;

    my @nodes = $xc->findnodes('e:recordInfo/e:recordSyntax');
    my $res = join($sep, map { $_->findvalue('@name') } @nodes);
    $res = "[none]" if $res eq "";
    return $res;
}

sub calc_explain {
    my($id, $xc) = @_;

    my @nodes = $xc->findnodes('i:status/i:explain[@ok = "1"]');
    my $res = join(", ", map { $_->findvalue('@category') } @nodes);
    $res = "[none]" if $res eq "";
    return $res;
}
</%perl>
