<%once>
sub print_navlink {
    my($params, $cond, $caption, $skip) = @_;

    if ($cond) {
	print('     <a href="', navlink($params, $caption, $skip),
	      '"', ">$caption</a>\n");
    } else {
	print qq[     <span class="disabled">$caption</span>\n];
    }
}

sub navlink {
    my($params, $caption, $skip) = @_;
    local $params->{_skip} = $skip;
    my $url = "?" . join("&", map { "$_=" . $params->{$_}  } sort keys %$params);
    $url = xml_encode($url);
    return $url;
}

# Just make this once; forge the connection on first use
our $conn = undef;
</%once>
<%perl>
my %params = map { ( $_, utf8param($r, $_)) } grep { &utf8param($r, $_) } &utf8param($r);
my $query;
if ($params{_query}) {
    $query = $params{_query};
} else {
    $query = "";
    foreach my $key (keys %params) {
	next if $key =~ /^_/;
	my $val = $params{$key};
	next if $val eq "";
	$query .= " and " if $query ne "";
	$query .= "$key = ($val)";
    }
}
$query = 'cql.allRecords=1' if $query eq "";

my $sort = $params{"_sort"};
if ($sort) {
    my $modifiers = "";
    if ($sort =~ s/(\/.*)//) {
	$modifiers = $1;
    }
    $query .= " or $sort=/sort";
    $query .= "-desc" if $params{_desc};
    $query .= $modifiers;
    $query .= " 0";
}

my $tried_to_open = 0;
if (!defined $conn) {
  OPEN:
    my $db = ZOOM::IRSpy::connect_to_registry();
    $conn = new ZOOM::Connection($db);
    $conn->option(elementSetName => "zeerex");
    $conn->option(count => 20);
}

my $rs;
eval { $rs = $conn->search(new ZOOM::Query::CQL($query)) };
if ($@ && ref $@ && $@->isa('ZOOM::Exception') &&
    $@->code() == ZOOM::Error::CONNECTION_LOST && !$tried_to_open) {
    $tried_to_open = 1;
    goto OPEN;
} elsif ($@) {
    die $@;
}

my $n = $rs->size();

my $skip = $params{"_skip"} || 0;
my $count = $params{"_count"} || 10;

my $first = $skip+1;
my $last = $first+$count-1;
$last = $n if $last > $n;
</%perl>
     <form method="get" action=""><p>
      <input type="text" name="_query" size="60" value="<% xml_encode($query) %>"/>
      <input type="submit" name="_search" value="Search"/>
     </p></form>
     <p>
% if ($n == 0) {
      No matches
% } elsif ($first > $n) {
%# "Can't happen"
      Past end of <% $n %> records
% } else {
      Records <% $first %> to <% $last %> of <% $n %><br/>
<%perl>
print_navlink(\%params, $skip > 0, "Prev", $count < $skip ? $skip-$count : 0);
print_navlink(\%params, $last < $n, "Next", $skip+$count);
</%perl>
% }
     </p>
% if ($n > 0 && $first <= $n) {
     <table width="100%">
      <tr class="thleft">
       <th>#</th>
       <th>Title</th>
       <th>Host Connection Reliability <& /help/link.mc, help => "info/reliability" &>
       </th>
       <th>Host</th>
       <th>Port</th>
       <th>DB</th>
       <th></th>
       <th></th>
      </tr>
% my @ids;
% $rs->records($first-1, $last-$first+1); ## Force pre-cache
% foreach my $i ($first .. $last) {
<%perl>
my $xc = irspy_xpath_context($rs->record($i-1));
my $title = $xc->find("e:databaseInfo/e:title") || "[UNTITLED]";
my $reliability = calc_reliability_string($xc);
my $host = $xc->find("e:serverInfo/e:host");
my $port = $xc->find("e:serverInfo/e:port");
my $db = $xc->find("e:serverInfo/e:database");
my $id = irspy_record2identifier($xc);
push @ids, $id;
</%perl>
      <tr style="background: <% ($i % 2) ? '#ffffc0' : 'white' %>">
       <td><% $i %></td>
       <td><a href="<% xml_encode("/full.html?id=" . uri_escape_utf8($id))
		%>"><% xml_encode($title) %></a></td>
       <td><% xml_encode($reliability, "", { nbsp => 1 }) %></td>
       <td><% xml_encode($host, "") %></td>
       <td><% xml_encode($port, "") %></td>
       <td><% xml_encode($db, "") %></td>
       <td>
	<a href="<% xml_encode("/admin/check.html?id=" . uri_escape_utf8($id))
		%>" title="Test this target">Test</a
	>&nbsp;<a href="<% xml_encode("/admin/edit.html?op=edit&id=" .
		uri_escape_utf8($id))
		%>" title="Edit this target's record">Edit</a
	>&nbsp;<a href="<% xml_encode("/raw.html?id=" . uri_escape_utf8($id))
		%>" title="Raw XML record">XML</a>
       </td>
      </tr>
% }
     </table>
<%perl>
print_navlink(\%params, $skip > 0, "Prev", $count < $skip ? $skip-$count : 0);
print_navlink(\%params, $last < $n, "Next", $skip+$count);
</%perl>
     <p>
      <a href="<% "/admin/check.html?" .
	xml_encode(join("&", map { "id=" . uri_escape_utf8($_) } @ids))
	%>">[Test all targets on this list]</a>
     </p>
     <p>
      <a href="<% "/stats.html?query=" . xml_encode(uri_escape_utf8($query))
	%>">[Statistics for targets on this list]</a>
     </p>
% }
