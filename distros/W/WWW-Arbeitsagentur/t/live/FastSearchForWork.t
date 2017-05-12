#!/usr/bin/perl -w 

use strict;
use warnings;

use Test::More tests => 5;
use WWW::Mechanize;

BEGIN{
    use_ok('WWW::Arbeitsagentur::Search::FastSearchForWork');
    
}

###################################
### create direcotry for downloads:
use File::Path;

my $path = "download/";

if (! -e $path){
    mkpath($path) || die ("Could not create temporary download directory! $!");
}
###
###################################


my $search = WWW::Arbeitsagentur::Search::FastSearchForWork->new(
								 path		=> $path,
								 job_typ	=> 1,
								 plz_filter	=> qr/.+/,
								 _module_test	=> 1,
								 beruf		=> 'Fachinformatiker/in - Anwendungsentwicklung',								 
								 );
is(ref($search), 'WWW::Arbeitsagentur::Search::FastSearchForWork', 'Create FastSearch Object');

is($search->search(), 1, "Search was succcessful");
is($search->save_results, 0, "Save Result");

my ($job_offer) = <$path*>;
like( $job_offer, qr/1\d+-\d+-S\.html/, "Save Job-Offer");

rmtree($path, 0) || die ("Could not delete temporary download directory! $!");


sub WWW::Mechanize::dump_content{};
