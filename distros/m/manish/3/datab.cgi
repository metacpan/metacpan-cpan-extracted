#!/usr/bin/perl -w
    use CGI qw(:all);
    use DBI;
    use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
    print start_html();
    print "Content-type:text/html\n\n";
    print <<END_OF_HTML ;
    Content-type: text/html
    <html>
    <head>
    <title>Example of Perl calling MySQL</title>
    </head>

    <body bgcolor="white">

        
    # database information
    $db="manish";
    $host="perldb";
    $userid="root";
    $passwd="password";
    $connectionInfo="dbi:mysql:$db;$host";

    # make connection to database
    $dbh = DBI->connect($connectionInfo,$userid,$passwd);

    # prepare and execute query
    $query = "SELECT * FROM people WHERE Age > 30 ORDER BY Name";
    $sth = $dbh->prepare($query);
    $sth->execute();

    # assign fields to variables
    $sth->bind_columns(\$Name, \$Age, \$id);

    # output name list to the browser
    print "Names in the people database:<p>\n";
    print "<table>\n";
    while($sth->fetch()) {
       print "<tr><td>$Name<td>$Age\n";
    }
    print "</table>\n";
    print "</body>\n";
    print "</html>\n";
    END_OF_HTML
    $sth->finish();
    # disconnect from database
    $dbh->disconnect;
    
print end_html;



