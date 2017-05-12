<%args>
$debug => undef
$title
$component
</%args>
<%once>
use URI::Escape qw(uri_escape uri_escape_utf8);
use ZOOM;
use ZOOM::IRSpy::Web;
use ZOOM::IRSpy::Utils qw(utf8param trimField utf8paramTrim isodate xml_encode cql_target cql_quote
                          irspy_xpath_context irspy_make_identifier
			  irspy_record2identifier
			  irspy_identifier2target modify_xml_document
			  bib1_access_point calc_reliability_string);
</%once>
% $r->content_type("text/html; charset=utf-8");
% my $text = $m->scomp($component, %ARGS);
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html 
     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
 <head>
  <title>IRSpy: <% xml_encode($title) %></title>
  <link rel="stylesheet" type="text/css" href="/style.css"/>
 </head>
 <body>
  <table border="0" cellpadding="0" cellspacing="0" width="100%">
   <tr class="banner">
    <td>
     <table width="100%">
      <tr>
       <td align="left">
	<br/>
	<h1><a class="logo" href="/">IRSpy</a></h1>
       </td>
       <td align="right">
	<br/>
	<h1 class="title"><% xml_encode($title) %></h1>
       </td>
      </tr>
     </table>
    </td>
   </tr>
  </table>
  <table border="0" cellpadding="0" cellspacing="0" width="100%">
   <tr class="panel3">
    <td align="left">
     &nbsp; <!-- Force display -->
     <!-- Lmenu left -->
    </td>
    <td>
     <!-- Lmenu middle -->
    </td>
    <td align="right">
     <!-- Lmenu right -->
    </td>
   </tr>
  </table>
  <p></p>
  <table border="0" cellpadding="0" cellspacing="0" width="100%">
   <tr>
    <td valign="top" class="panel1">
     <p>
      <a href="/"><b>Home</b></a><br/>
      <!-- <a href="/admin/all.html">Test&nbsp;all&nbsp;targets</a><br/> -->
      <a href="/find.html">Find a target</a><br/>
      <a href="/add_target.html">Add a target</a><br/>
      <a href="/upload.html">Upload a target</a><br/>
      <a href="/stats.html">Statistics</a><br/>
     </p>
     <p>
      <b>Show targets</b>
      <br/>
% foreach my $i ('a' .. 'z') {
      <a href="/find.html?dc.title=^<% $i %>*&amp;_sort=dc.title&amp;_count=9999&amp;_search=Search"><tt><% uc($i) %></tt></a>
% }
      <a href="/find.html?cql.allRecords=1+not+dc.title+=/regexp/firstInField+[a-z].*&amp;_sort=dc.title&amp;_count=9999&amp;_search=Search">[Others]</a>
     </p>
<%perl>
# Find the identifier to use in the record-specific menu, if any.  If
# the identifier components are all present (e.g. because a record has
# just been edited or copied) we make an ID from those; otherwise we
# use the "id" parameter, if specified.
my $id = utf8param($r, "id");
{
    # Make up ID for newly created records.
    my $protocol = utf8param($r, "protocol");
    my $host = utf8param($r, "host");
    my $port = utf8param($r, "port");
    my $dbname = utf8param($r, "dbname");
    #warn "id='$id', protocol='$protocol' host='$host', port='$port', dbname='$dbname'";
    #warn "%ARGS = {\n" . join("", map { "\t'$_' => '" . $ARGS{$_} . ",'\n" } sort keys %ARGS) . "}\n";
    if (defined $protocol && defined $host &&
	defined $port && defined $dbname) {
	$id = irspy_make_identifier($protocol, $host, $port, $dbname);
	#warn "id set to '$id'";
    }
}
</%perl>
% if (defined $id) {
     <div class="panel2">
      <b>This Target</b>
      <br/>
      <a href="<% xml_encode("/full.html?id=" . uri_escape_utf8($id)) %>">Show details</a>
      <br/>
      <a href="<% xml_encode("/admin/edit.html?op=edit&id=" . uri_escape_utf8($id)) %>">Edit details</a>
      <br/>
      <a href="<% xml_encode("/admin/edit.html?op=copy&id=" . uri_escape_utf8($id)) %>">Copy target</a>
      <br/>
      <a href="<% xml_encode("/admin/delete.html?id=" . uri_escape_utf8($id)) %>">Delete target</a>
      <p>
       <a href="<% xml_encode("/admin/check.html?id=" . uri_escape_utf8($id)) . "&amp;test=Quick" %>">Quick Test</a>
       <br/>
       <a href="<% xml_encode("/admin/check.html?id=" . uri_escape_utf8($id)) . "&amp;test=Main" %>">Full Test</a>
      </p>
      <p>
       <a href="<% xml_encode("/raw.html?id=" . uri_escape_utf8($id)) %>">XML</a>
      </p>
<%doc><!-- Maybe this would be too heavyweight -->
      <br/>
% my $host = "bagel.indexdata.dk";
% my $port = 210;
      <a href="/find.html?net.host=<% $host %>&net.port=<% $port %>&_search=Search"
	>All databases on this server</a>
</%doc>
     </div>
% }
     <p>
      <b>Documentation</b>
      <br/>
      <a href="/doc.html">Contents</a>
     </p>
     <p>&nbsp;</p>
     <p>
      <a href="http://validator.w3.org/check?uri=referer"><img
        src="/valid-xhtml10.png"
        alt="Valid XHTML 1.0 Strict" height="31" width="88" /></a>
      <br/>
      <a href="http://jigsaw.w3.org/css-validator/"><img
	src="/vcss.png"
	alt="Valid CSS!" height="31" width="88" /></a>
     </p>
    </td>
    <td class="spacer">&nbsp;</td>
    <td valign="top">
% print $text;
    </td>
   </tr>
  </table>
  <p/>
  <hr/>
  <div class="right">
   <small>
    Powered by <a style="text-decoration: none"
	href="http://indexdata.com/"
	>Index&nbsp;Data</a>.
    <br/>
    Report errors and omissions to <a style="text-decoration: none"
	href="mailto:irspy@indexdata.com"
	            >irspy@indexdata.com</a>
   </small>
  </div>
 </body>
</html>
