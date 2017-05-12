

use Test::More;
use English '-no_match_vars';
use lib "../lib";

BEGIN {
    use_ok( 'WWW::Salesforce::Report' ) || print "Bail out!
";
}

# should fail with no params
my $srf;
eval {
    $sfr = WWW::Salesforce::Report->new();
};
ok($EVAL_ERROR , "Calling new()" );

# should fail missing user, password
eval {
    $sfr = WWW::Salesforce::Report->new(
        id => "0000000",
    );
};
ok($EVAL_ERROR , "Calling new with id but no user/password");

# should fail missing password
eval {
    $sfr = WWW::Salesforce::Report->new(
        id => "0000000",
        user => "user",
    );
};
ok($EVAL_ERROR , "Calling new with id and user but no password");

# should not fail
eval {
    $sfr = WWW::Salesforce::Report->new(
        id => "0000000ABC",
        user => "user",
        password =>"password",
    );
};
ok(!$EVAL_ERROR , "Calling new with id, user and password should work");
ok( $sfr->name() eq "0000000ABC.db3", "Test local cache file name id");
ok( $sfr->format() eq "csv", "Test default format id");


# should not fail
eval {
    $sfr = WWW::Salesforce::Report->new(
        file => "t/report.csv",
    );
};
ok(!$EVAL_ERROR , "Calling new with just file should work");

# test if the defaults were set properly...
# Accessing internals directly Ugly I know...
ok( $sfr->{ verbose } == 0, "Testing default verbose value");
ok( $sfr->{ convert_dates } == 1, "Testing default convert_dates");
ok( $sfr->{ login_url } eq "https://login.salesforce.com/?un=USER&pw=PASS",
   "Testing default login_url");
ok( $sfr->{ csv_report_url }
        eq "https://SERVER.salesforce.com/REPORTID?export=1&enc=UTF-8&xf=csv",
    "Testing default csv_report_url");
ok( $sfr->{ xls_report_url }
        eq "https://SERVER.salesforce.com/REPORTID?export=1&enc=UTF-8&xf=xls",
    "Default xls_report_url is bad");
ok(!$sfr->{ id },       "Reading from local file id should be null");
ok(!$sfr->{ password }, "Reading from local file password should be null");

ok( $sfr->name() eq "t/report.csv.db3", "Test local cache file name");
ok( $sfr->format() eq "csv", "Test default format");


done_testing();