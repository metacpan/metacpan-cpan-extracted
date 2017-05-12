<%args>
$id
$set
</%args>
<%perl>
my $db = ZOOM::IRSpy::connect_to_registry();
my $conn = new ZOOM::Connection($db);
$conn->option(elementSetName => "zeerex");
my $query = cql_target($id);
my $rs = $conn->search(new ZOOM::Query::CQL($query));
my $n = $rs->size();
if ($n == 0) {
    return $m->comp("/details/error.mc",
		    title => "Error", message => "No such ID '$id'");
}

my $xc = irspy_xpath_context($rs->record(0));
my $title = $xc->find("e:databaseInfo/e:title");
</%perl>
     <h2><% xml_encode($title, "") %></h2>
<%perl>
my $expr = 'e:indexInfo/e:index[@search = "true"]/e:map/e:attr[
	@set = "'.$set.'" and @type = "1"]';
my @nodes = $xc->findnodes($expr);
my @aps = sort { $a <=> $b } map { $_->findvalue(".") } @nodes;

$n = @aps;
if ($n == 0) {
    print "     [none]\n";
    return;
}
</%perl>
     <table class="fullrecord" border="1" cellspacing="0" cellpadding="5" width="100%">
% foreach my $ap (@aps) {
% my $name = "[unknown]";
% $name = bib1_access_point($ap) if $set eq "bib-1";
% ### Should support translation of other attribute sets' access points
      <tr>
       <th><% $ap %></th>
       <td><% xml_encode($name) %></td>
      </tr>
% }
     </table>
