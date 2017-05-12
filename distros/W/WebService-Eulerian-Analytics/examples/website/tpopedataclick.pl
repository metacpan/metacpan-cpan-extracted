#!/usr/bin/perl -w
#
# $Id: tpopedataclick.pl,v 1.3 2008-09-21 23:30:08 cvscore Exp $

use strict;
use WebService::Eulerian::Analytics::Website;
use WebService::Eulerian::Analytics::Website::TPOpedataClick;

my %h_api_params	= (
 apikey	=> '',
 host	=> '',
);

my $website_name	= 'MY_WEBSITE';	# name of the targeted website
my $tpope_name		= 'MY_CAMPAIGN';# name of the targeted campaign
my $tpmedia_name	= 'MY_TPMEDIA';	# name of the targeted tpmedia
my $date_from		= '01/08/2008';	# timeperiod include all day
my $date_to		= '02/08/2008';	# timeperiod include all day

my $website		= new WebService::Eulerian::Analytics::Website( %h_api_params );
my $tpopedataclick 	= new WebService::Eulerian::Analytics::Website::TPOpedataClick( %h_api_params );

# fetch the id of the website by it's name via Website Service
my $rh_website	= $website->getByName( $website_name );

die $website->faultstring		if ( $website->fault );

# fetch the log data in Website/TPOpedataClick service by TPOpe
my $ra_log	= $tpopedataclick->getLogByTPOpeName($rh_website->{website_id},{
 tpope_name	=> $tpope_name,
 date_from	=> $date_from,
 date_to	=> $date_to,
});

die $tpopedataclick->faultstring	if ( $tpopedataclick->fault );

for ( @{ $ra_log } ) {
 print "date ".localtime($_->{epoch})." | IP : ".$_->{ip}." | Channel Information : level0=".$_->{channel_0}." level1=".$_->{channel_1}." level2=".$_->{channel_2}."\n";
}

# fetch the log data in Website/TPOpedataClick service by TPMedia
$ra_log = $tpopedataclick->getLogByTPMediaName($rh_website->{website_id},{
 tpmedia_name	=> $tpmedia_name,
 date_from	=> $date_from,
 date_to	=> $date_to,
});

die $tpopedataclick->faultstring	if ( $tpopedataclick->fault );

for ( @{ $ra_log } ) {
 print "date ".localtime($_->{epoch})." | IP : ".$_->{ip}." | Channel Information : level0=".$_->{channel_0}." level1=".$_->{channel_1}." level2=".$_->{channel_2}." | Outbound campaign : ".$_->{tpope_name}."\n";
}


1;
__END__
