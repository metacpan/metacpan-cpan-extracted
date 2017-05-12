#!/usr/bin/perl

# This is a regression test for:
# http://rt.cpan.org/Public/Bug/Display.html?id=5438
# based on the original script supplied with the report.

use strict;
use warnings;

use XML::RSS::LibXML;
use File::Spec;

use Test::More;

if (eval "require Test::Differences") {
    Test::Differences->import;
    plan tests => 2;
}
else {
    plan skip_all => 'Test::Differences required';
}

{
    my $dir = File::Spec->catdir("t", "generated");
    if (! -d $dir) {
        mkdir($dir) or die "Could not create directory $dir: $!";
    }

    my $rss_file = File::Spec->catfile($dir, "charset1-generated.xml");


    my %rss_new = (version => '1.0', encoding => 'iso-8859-1', output => '1.0');
    my $rss = XML::RSS::LibXML->new(%rss_new);

    #
    # Add a channel
    #

    $rss->channel (title => "Channel Title",
               link  => "http://channel.url/",
               description => "Channel Description");

    #
    # Add an item with accented characters
    #

    $rss->add_item (title => "Item Title",
            link => "http://item.url/",
            description => "Item Description (&copy;)");

    #
    # Save RSS content to file.
    #

    open (RSS, ">", $rss_file) || 
        die "Unable to open $rss_file.";


    my $rss1 = $rss->as_string;
    print RSS $rss1;

    close (RSS);

    #
    # Now read it back in
    #

    $rss = XML::RSS::LibXML->new(%rss_new);
    $rss->parsefile($rss_file);

    #
    # save it again
    #

    open (RSS, ">", $rss_file) || die "Unable to open $rss_file.";

    my $rss2 = $rss->as_string;
    print RSS $rss2;

    close (RSS);

    eq_or_diff($rss1, $rss2, 'got the same RSS both times'); 

    #
    # And read it back in again.
    #

    $rss = new XML::RSS::LibXML;
    $rss->parsefile($rss_file);

    # Check that no exception was thrown along the way.
    ok(1);
}
