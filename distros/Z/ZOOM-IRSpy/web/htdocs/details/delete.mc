<%args>
$id
$really => 0
</%args>
% if (!$really) {
     <h2>Warning</h2>
     <p class="error">
      Are you sure you want to delete the target
      <% xml_encode($id) %>?
     </p>
     <p>
      <a href="?really=1&amp;id=<% xml_encode(uri_escape_utf8($id)) %>">Yes</a><br/>
      <a href="/full.html?id=<% xml_encode(uri_escape_utf8($id)) %>">No</a><br/>
     </p>
% } else {
<%perl>
    my $db = ZOOM::IRSpy::connect_to_registry();
    my $conn = new ZOOM::Connection($db, 0,
				    user => "admin", password => "fruitbat",
				    elementSetName => "zeerex");
    ZOOM::IRSpy::_delete_record($conn, $id);
</%perl>
     <p>
      Deleted record
      <% xml_encode($id) %>
     </p>
% }
