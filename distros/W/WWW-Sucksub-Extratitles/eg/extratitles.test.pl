#!/usr/bin/perl 
#***************************************************************************
use WWW::Sucksub::Extratitles;
my $mot= shift;
my $test=WWW::Sucksub::Extratitles->new(
						dbfile=> '/home/user/sksb_extrat.db',
						html =>'/home/user/sksb_extrat.html',
						motif=> $mot,
						debug=> 1,
						# fix the logout attribute unless you want
						# verbose output on STDOUT
						#logout=>'/home/user/sksb_extrat.txt',
						language=>'French',
						);

# update local db with scrapping extratitles
$test->update();
#then launch a search on local db
$test->search();
#result will be print on html attribute of $test object

#
#
