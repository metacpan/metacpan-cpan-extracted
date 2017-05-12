#!c:/perl/bin/perl -w
use strict;
use lib qw(../lib);
use Xpriori::XMS::ServerUtil;
my $oSvr = Xpriori::XMS::ServerUtil->new();

#STOP Server
print "STOP  : " . $oSvr->stopServer() . "\n";
#Create DB
print "CREATE: " . $oSvr->createDb() . "\n";
#START Server
print "START : " . $oSvr->startServer() . "\n";
