#!/usr/bin/perl
use warnings;
use strict;

my $data_dir = "data";
$data_dir = "t/$data_dir" unless -d $data_dir;

use Test::More qw(no_plan);
use Log::Log4perl qw(:easy);
use File::Temp qw(tempfile);
use XML::Simple;

# Log::Log4perl->easy_init($DEBUG);

my($fh, $outfile) = tempfile(CLEANUP => 1);

use XML::RSS::FromHTML::Simple;

my $f = XML::RSS::FromHTML::Simple->new({
    html_file => "$data_dir/art_eng.html",
    base_url  => "http://perlmeister.com",
    rss_file  => $outfile,
});

$f->link_filter( sub {
    my($url, $text) = @_;
    # print "URL=$url\n";
    if($url =~ m#linux-magazine\.com/#) {
        return 1;
    } else {
        return 0;
    }
});

$f->make_rss();

ok(-s $outfile, "RSS file created");

  # Read XML file back in
my $data = XMLin($outfile);

is($data->{item}->[0]->{link}, 
   'http://www.linux-magazine.com/issue/71/Perl_Link_Spam.pdf', 
   "Check RSS (first item)");

my %urls = map { $_->{link} => 1 } 
           @ { $data->{item} };

ok(!exists $urls{'http://www.perl.com/pub/a/2002/09/11/log4perl.html'},
   "Non linux-magazine url doesn't exist");

# Try rss_attrs

$f->link_filter( sub {
    my($url, $text, $processor) = @_;

#print "Found $url $text\n";

    if($url =~ m#issue/51#) {
        $processor->rss_attrs({
            description => 'This is cool stuff',
            title       => 'Where it all began',
        });
        return 1;
    } else {
        return 0;
    }
});

$f->make_rss();

  # Read XML file back in
$data = XMLin($outfile);

is($data->{item}->{title}, 'Where it all began', "Modified title");
is($data->{item}->{description}, 'This is cool stuff', "Modified desc");
is($data->{item}->{link}, 'http://www.linux-magazine.com/issue/51/Perl_Collecting_News_Headlines.pdf', "url check");

#use Data::Dumper;
#print Dumper($data);
