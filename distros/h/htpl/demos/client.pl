use HTML::HTPL::Client;

$client = new HTML::HTPL::Client("http://localhost/htpl/server.htpl",
          "admin", "admin");

$result = $client->get("whoami()");

print "Server answered whoami(): $result\n";

$result = $client->get("square(2)", "IDEA:cool key");

print "Server answered square(2): $result\n";
