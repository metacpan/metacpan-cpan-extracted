<%args>
$filename => undef
</%args>
% if (!defined $filename) {
   <p>
    Please note that this form expects a
    <a href="http://explain.z3950.org/"
	>ZeeRex record</a>
    only, not an entire
    <a href="http://www.loc.gov/standards/sru/explain/"
	>SRU explainResponse</a>.
   <p>
   <form method="post" action=""
	    enctype="multipart/form-data">
    <p>
     ZeeRex file to upload:
     <input type="file" name="filename" size="50"/>
     <br/>
     <input type="submit" name="_submit" value="Submit"/>
    </p>
   </form>
% return;
% }
<%perl>

my $fin;

# Apache2.0 
if ($r->isa('Apache2::RequestRec')) {
    require Apache2::Request;
    require Apache2::Upload;
    my $req = new Apache2::Request($r);
    my $upload = $req->upload('filename');
    $fin = $upload->fh();
} 

# Apache 1.3
else {
    $fin = $r->upload()->fh();
}

if (!defined $fin) {
    $m->comp("/details/error.mc", msg => "Upload cancelled");
    return;
}

my $xml = join("", <$fin>);
my $xc = irspy_xpath_context($xml);
my $id = irspy_record2identifier($xc);
my $db = ZOOM::IRSpy::connect_to_registry();
my $conn = new ZOOM::Connection($db, 0,
				user => "admin", password => "fruitbat",
				elementSetName => "zeerex");
ZOOM::IRSpy::_rewrite_zeerex_record($conn, $xc->getContextNode());
</%perl>
     <p>
      Upload OK.
     </p>
     <p>
      Proceed to
      <a href="<% xml_encode("/full.html?id=" . uri_escape_utf8($id))
	%>">the new record</a>.
     </p>
