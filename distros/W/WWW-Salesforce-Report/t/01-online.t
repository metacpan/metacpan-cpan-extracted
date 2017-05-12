use strict;
use warnings;
use Test::More;
use English '-no_match_vars';
use lib "../lib";
use vars qw($user $pass $report_id);
require 't/sfdc.cfg';

BEGIN {
    use_ok( 'WWW::Salesforce::Report' ) || print "Bail out!
";
}

diag( "\nTesting WWW::Salesforce::Report $WWW::Salesforce::Report::VERSION, Perl $], $^X" );

SKIP: {
    skip "Please set username and password in sfdc.cfg to enable online esting",
         5
         unless $user && pass && $report_id;
    
    my $sfr;
    eval {
        $sfr = WWW::Salesforce::Report->new(
            id       => $report_id,
            user     => $user,
            password => $pass );
    };
    
    ok(
        !$EVAL_ERROR,
        "Test new with id, user and password"
    );
    
    ok(
        $sfr->name()   eq $report_id . ".db3",
        "Test local cache file name"
    );
    
    ok(
        $sfr->format() eq "csv",
        "Test csv format"
    );

    
    # Login to salesforce.com
    my $result;
    eval {
        $result = $sfr->login();
    };
    ok(
        !$EVAL_ERROR && $result,
        "Test salesforce.com login"    
    );
    
    eval {
        $result = $sfr->login_server();  
    };
    
    ok(
        !$EVAL_ERROR && $result,
        "Test salesforce.com login server"
    );
    
    diag("Logged in to $result");
    
    eval {
        $result = $sfr->get_report();
    };
    ok(
        !$EVAL_ERROR && $result,
        "Test get_report()"
    );
    
    ok(
        -e $sfr->name(),
        "Test database creation"
    );
    
    # Test database structure
    my $dbh;
    eval {
        $dbh= DBI->connect("dbi:SQLite:dbname=". $sfr->name() ,"","");
    };
    ok( !$EVAL_ERROR, "Test database connection");
    
    my @tables = $dbh->tables('%', '%', '%','TABLE');
    my @expected = ( '"main"."notifications"',  '"main"."report"', '"main"."sqlite_sequence"' );
    is_deeply( \@tables, \@expected, "Test database table names");
    
    my %result;
    eval {
        %result = $sfr->query(query => "select * from report");
    };
    ok( !$EVAL_ERROR, "Test report query");
    
    ok(
        $result{num_fields} != 0,
        "Test number of fields"
    );
    ok(
        scalar @{ $result{fields} } != 0,
        "Test field names array"
    ); 
    ok(
        scalar @{ $result{data} } != 0,
        "Test query data"
    );
    
    eval {
        $result = $sfr->get_report(format => "xls");
    };
    ok(
        !$EVAL_ERROR && $result,
        'Test get_report(format => "xls")'
    );
    
    ok(
        $sfr->name()   eq $report_id . ".xls",
        "Test local xls file name"
    );
    
    ok(
        $sfr->format() eq "xls",
        "Test xls format"
    );
    
    # This should croak because of unknown format
    eval {
        $result = $sfr->get_report(format => "popo");
    };
    ok(
        $EVAL_ERROR,
        'Test get_report(format => "popo")'
    );
    
    
    
}

done_testing();