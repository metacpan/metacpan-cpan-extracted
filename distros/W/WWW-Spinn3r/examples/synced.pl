#!/usr/bin/perl -s
use lib qw(../lib lib);
use WWW::Spinn3r;
use WWW::Spinn3r::Synced; 
use DateTime;
use FileHandle;
use utf8;

binmode STDOUT, 'utf8';

$limit ||= 25;

usage();

my $CONFIG = { 
    vendor  => $vendor, 
    limit   => $limit, 
    after   => DateTime->now()->subtract(days => 120),
};

my $iter = WWW::Spinn3r::Synced->new( params => $CONFIG, debug => 1 );

my $both = 0;
my $all = 0;

while (1) {
    my ($p, $f) = @{ $iter->next() };
    $all++;
    my $link = $$p{link};
    print "publisher_type: $$p{'weblog:publisher_type'}\n";
    if ($p and $f) { 
        print "feed+permalink: $link\n";
        $both++;
    } else { 
        print "permalink_only: $link\n";
    }
    printf("overlap: %5.3f%\n", ($both / $all) * 100)
}

sub usage { 
    unless ($vendor) { 
        print "Synchronized walk - mostly for testing memory usage\n";
        print "$0 -vendor=VENDOR\n";
        exit(1);
    }
}
