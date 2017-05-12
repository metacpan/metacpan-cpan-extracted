<%doc>
Here are the headings in the Z-Spy version:
	The ten most commonly supported Bib-1 Use attributes
	Record syntax support by database
	Explain support
	Z39.50 Protocol Services Support
	Z39.50 Server Atlas
	Top Domains
	Implementation
You can see his version live at
	http://targettest.indexdata.com/stat.php
Or a static local copy at ../../../archive/stats.html

There may be way to generate some of this information by cleverly
couched searchges, but it would still be necessary to trawl the
records in order to find all the results, so we just take the path of
least resistance and look at all the records by hand.
</%doc>
<%args>
$query => undef
$reload => 0
</%args>
<%perl>
my $key = defined $query ? $query : "";
my $from_cache = 1;
my $stats = $m->cache->get($key);
if (!defined $stats || $reload) {
    $from_cache = 0;
    my $db = ZOOM::IRSpy::connect_to_registry();
    $stats = new ZOOM::IRSpy::Stats($db, $query);
    $m->cache->set($key, $stats, "1 day");
}
</%perl>
     <h2>Statistics for <% xml_encode($stats->{host}) %></h2>
     <h3><% $stats->{n} %> targets analysed
      <% defined $query ? "for '" . xml_encode($query) . "'" : "" %></h3>
% if ($from_cache) {
     <p>Reusing cached result</p>
% } else {
     <p>Recalculating stats</p>
% }
<& table, stats => $stats, data => "bib1AccessPoints",
	title => "The twenty most commonly supported Bib-1 Use attributes",
	headings => [ "Attribute", "Name"], maxrows => 20, 
	col3 => sub { bib1_access_point(@_) } &>
<& table, stats => $stats, data => "recordSyntaxes",
	title => "Record syntax support by database",
	headings => [ "Record Syntax"], maxrows => 30 &>
<& table, stats => $stats, data => "explain",
	title => "Explain Support",
	headings => [ "Explain Category"] &>
<& table, stats => $stats, data => "z3950_init_opt",
	title => "Z39.50 Protocol Services Support",
	headings => [ "Service"] &>
<& table, stats => $stats, data => "domains",
	title => "Top Domains",
	headings => [ "Top Domain"] &>
<& table, stats => $stats, data => "implementation",
	title => "Implementation",
	headings => [ "Name" ], maxrows => 20 &>
%#
%#
<%def table>
<%args>
$stats
$data
$title
$maxrows => 10
@headings
$col3 => undef
</%args>
     <h3><% $title %></h3>
     <table border="1">
      <thead>
       <tr>
% foreach my $heading ("#", @headings, "# Targets") {
	<th><% xml_encode($heading) %></th>
% }
       </tr>
      </thead>
      <tbody>
<%perl>
my $hr;
$hr = $stats->{$data};
my @sorted = sort { $hr->{$b} <=> $hr->{$a} || $a <=> $b } keys %$hr;
my $n = @sorted; $n = $maxrows if @sorted > 10 && $n > $maxrows;
foreach my $i (1..$n) {
    my $key = $sorted[$i-1];
</%perl>
      <tr>
       <td><% $i %></td>
       <td><% xml_encode(substr($key, 0, 54), "HUH?") %></td>
% if (defined $col3) {
       <td><% xml_encode(&$col3($key), "HUH2?") %></td>
% }
       <td><% xml_encode($hr->{$key}, "HUH3?") . " (" .
	int(10000*$hr->{$key}/$stats->{n})/100 . "%)" %></td>
      </tr>
% }
      </tbody>
     </table>
</%def>
