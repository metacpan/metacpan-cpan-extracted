#!/usr/bin/perl -s
use lib qw(../lib lib);
use WWW::Spinn3r; 

usage();

my $feed = WWW::Spinn3r->new( from_file => $filename, debug => 1 );

while (my $item = $feed->next()) { 
    print "Title: $$item{title}\n";
    print "Type: $$item{'weblog:publisher_type'}\n";
}

sub usage { 
    unless ($filename) { 
        print "$0 -vendor=VENDOR -filename=FILENAME\n";
        exit(1);
    }
}
