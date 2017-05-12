#!/usr/bin/perl -w

use ExtUtils::testlib;
use Text::CHM;

print "Usage: test.pl <file.chm>\n" and exit
    if ( !$ARGV[0] || !($ARGV[0] =~ /\.chm$/) );

$chm = Text::CHM->new($ARGV[0]);
@files = $chm->get_filelist();

foreach $entry (@files)
{    
    $title = ($entry->{title}) ? $entry->{title} : 'No title';
    print $title. ' ' . $entry->{path}. ' ' .$entry->{size}, "\n" 
}

$chm->close();
