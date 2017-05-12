# $Id$
# Test local file loading methods
#
# Copyright 2010 Pedro Paixao (paixaop at gmail dot com)
#
use Test::More;
use English '-no_match_vars';
use lib "../lib";
use strict;
use DBI;
use File::Spec;

BEGIN {
    use_ok( 'WWW::Salesforce::Report' ) || print "Bail out!
";
}

# should not fail
my $sfr;
my $path = File::Spec->rel2abs( File::Spec->curdir() );
my @dirs =($path);
my $file = File::Spec->catfile( @dirs,  "report.csv");
if( !-e $file ) { 
   @dirs = ($path, "t");
   $file = File::Spec->catfile( @dirs,  "report.csv");
}
ok(-e $file, "Report.csv file exists: $file");
   
diag("\nReading file: $file");
eval {
    $sfr = WWW::Salesforce::Report->new(
        file => $file,
    );
};
ok(!$EVAL_ERROR , "Testing new() with just file " . $EVAL_ERROR);

ok( $sfr->name() =~ /report.csv.db3$/, "Test local cache file name");
ok( $sfr->format() eq "csv",            "Test default format");

# We are reading from a local file setting format to XLS should fail!
eval {
    $sfr->format(format => "xls" );
};
ok( $EVAL_ERROR,   "Test set format xls with local file " . $EVAL_ERROR);

ok( $sfr->format(format => "csv" ) eq "csv",   "Test set format csv");
ok( $sfr->{ url } eq $sfr->{ csv_report_url }, "Test CSV URL");
ok( $sfr->name() =~ /report.csv.db3$/,          "Test name CSV");

ok( $sfr->cache() eq 1,            "Test default local cache");
ok( $sfr->cache(cache => 0) eq 0,  "Test set local cache to disabled");
ok( $sfr->cache(cache => 1) eq 1,  "Test set local cache to enabled");

ok( $sfr->login() == 0,        "Test login with local file");
ok( $sfr->login_server() == 0, "Test login_server with local file");

ok( $sfr->primary_key() eq "__id", "Test default primary key");

my $data;
eval {
    $data = $sfr->get_report();
};
ok(!$EVAL_ERROR, "Test get_report");

my $expected =<<__HERE;
"Opportunity Owner","Opportunity Owner Email","Opportunity Name","Amount"
"John Doe","john\@domain.com","Big Opp","492203.79"
"Jane Doe","jane\@domain.com","Huge Opp","210456.20"
__HERE
chomp $expected;
ok($data eq $expected, "Test read data");
ok(-e $sfr->name(), "Test database creation");

my $db_name = $sfr->name();
ok($db_name =~ /report.csv.db3$/, "Test database name");

# Test database structure
my $dbh;
eval {
    $dbh= DBI->connect("dbi:SQLite:dbname=". $db_name,"","");
};
ok( !$EVAL_ERROR, "Test database connection " . $EVAL_ERROR);

my @tables = $dbh->tables('%', '%', '%','TABLE');
my @expected = ( '"main"."notifications"',  '"main"."report"', '"main"."sqlite_sequence"' );
is_deeply( \@tables, \@expected, "Test database table names");

my %result;
eval {
    %result = $sfr->query(query => "select * from report");
};
ok( !$EVAL_ERROR, "Test report query " . $EVAL_ERROR);

ok( $result{num_fields} == 6, "Test number of fields");
@expected = qw( __hash __id OpportunityOwner OpportunityOwnerEmail OpportunityName Amount);
is_deeply( $result{fields}, \@expected, "Test report table fields");

@expected = (
    {
        __id                 => 1,
        __hash                => "160b81d482ba7b79124846235ce298fe",
        Amount                => "492203.79",
        OpportunityOwner      => "John Doe",
        OpportunityName       => "Big Opp",
        OpportunityOwnerEmail => "john\@domain.com",
    },
    {
        __id                  => 2,
        __hash                => "86a03dbf911babc7f3bf36f8c75118f6",
        Amount                => "210456.20",
        OpportunityOwner      => "Jane Doe",
        OpportunityName       => "Huge Opp",
        OpportunityOwnerEmail => "jane\@domain.com",
    },
);
is_deeply( $result{data}, \@expected, "Test report query result");

# Test file writing
my $name;
eval {
    $name = $sfr->write(compress => 0);
};
ok(
    !$EVAL_ERROR,
    "Test write no compress " . $EVAL_ERROR
);
ok(
    $name =~ /report.csv$/,
    "Test write file name"
);
ok(
    -e $name,
    "Test write file exists"
);

eval {
    $name = $sfr->write();
};
ok(
    !$EVAL_ERROR,
    "Test write no compress " . $EVAL_ERROR
);
ok(
    $name =~ /report.zip$/,
    "Test write zip file name"
);

ok(
   -e $name,
    "Test write zip file exists"
);
# delete the file, no garbage
unlink($name);

# Test with baddly formated files
diag "A couple of DB errors will be generated. Ignore them";
$file = File::Spec->catfile( @dirs,  "bad_report_1.csv");
diag("\nReading file: $file");
eval {
    $sfr = WWW::Salesforce::Report->new(
        file => $file,
    );
};
ok(!$EVAL_ERROR , "Testing new() with just file bad_report_1.csv " . $EVAL_ERROR);

eval {
    $data = $sfr->get_report();
};
ok($EVAL_ERROR, "Test get_report bad_report_1.csv. " . $EVAL_ERROR);

$file = File::Spec->catfile( @dirs,  "bad_report_2.csv");
diag("\nReading file: $file");
eval {
    $sfr = WWW::Salesforce::Report->new(
        file => $file,
    );
};
ok(!$EVAL_ERROR , "Testing new() with just file bad_report_2.csv " . $EVAL_ERROR);

eval {
    $data = $sfr->get_report();
};
ok($EVAL_ERROR, "Test get_report bad_report_2.csv " . $EVAL_ERROR);

eval {
    $sfr = WWW::Salesforce::Report->new(
        file => "this_file_does_not_exist.csv",
    );
};
ok($EVAL_ERROR , "Testing for non existing local file " . $EVAL_ERROR);

# Test file writing

done_testing();