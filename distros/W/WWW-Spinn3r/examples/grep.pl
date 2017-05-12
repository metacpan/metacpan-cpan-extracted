#!/usr/bin/perl -s
use lib qw(../lib lib);
use WWW::Spinn3r; 
use DateTime;
use FileHandle;
use utf8;

binmode STDOUT, 'utf8';

$limit ||= 100;
$api   ||= 'feed3.getDelta';

usage();

my $rstr = shift @ARGV;
my $regex = qr($rstr);

my $CONFIG = { 
    vendor  => $vendor, 
    limit   => $limit, 
    want    => 'item',
    after   => DateTime->now()->subtract(minutes => 100),
    tier    => '0:10',
};

my $iter = WWW::Spinn3r->new( params => $CONFIG, api => $api, debug => 1 );

while (1) {
    my $item = $iter->next();
    my $title = $$item{title};
    my $link = $$item{link};
    my $description = $$item{description};
    if ($title =~ $regex or $description =~ $regex or $link =~ $regex) { 
        print "-" x 80 . "\n";
        print "Title: $title\n";
        print "Permalink: $link\n";
        print "Post: $description\n\n";
        print "-" x 80 . "\n";
    }
}

sub usage { 
    unless ($vendor and @ARGV) { 
        print "Grep the spinn3r feed with a perl regular expression\n";
        print "$0 -vendor=VENDOR REGEX\n";
        exit(1);
    }
}
