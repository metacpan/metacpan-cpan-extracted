# Copyright 2010 Pedro Paixao
use strict;
use lib "../lib";
use WWW::Salesforce::Report;


my $sfr = WWW::Salesforce::Report->new(
        id       => "your_report_id",
        user     => "your_user",
        password => "your_password",
        verbose  => 1,
);
    
$sfr->login();
if( $sfr->login_server() ) {
    $sfr->get_report();
    $sfr->write();
}
else {
    print "Error could not login to salesforce.com\n";
}

print "Done\n";
