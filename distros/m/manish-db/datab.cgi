#!/usr/bin/perl -w

   use DBI;
print header;
print start_html();
print <<EndHtml ;
    Content-type: text/html

    <html>
    <head>
    <title>Example of Perl calling MySQL</title>
    </head>

    <body bgcolor="white">

    EndHtml
    
    # database information
    $db="manish";
    $host="perldb";
    $userid="root";
    $passwd="password";
    $connectionInfo="dbi:mysql:$db;$host";

    # make connection to database
    $dbh = DBI->connect($connectionInfo,$userid,$passwd);

    # prepare and execute query
    $query = "SELECT * FROM people ";
    $sth = $dbh->prepare($query);
    $sth->execute();

    # assign fields to variables
    #$sth->bind_columns(\$Name, \$Age, \$id);

    # output name list to the browser
    print "Names in the people database:<p>\n";
    print "<table>\n";
    while($sth->fetch()) {
       print "<tr><td>$Name<td>$Age\n";
    }
    print "</table>\n";
    print "</body>\n";
    print "</html>\n";

    $sth->finish();

    # disconnect from database
    $dbh->disconnect;



