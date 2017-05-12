#################################################################################
####This Perl module represents the CPAN name space WebService::Jamendo::RSS.####
####################Written by Gerald L. Hevener, M.S.###########################
##############AKA: jackl0phty in the whitehat hacker community.##################
#########This module is licensed under the same terms as Perl itself.############
#########Maintainer's Email:  hevenerg {[AT]} marshall {[DOT]} edu.##############
#After years of using free (as in beer) software, thought I'd try to give back. #
#################################################################################

# declare package name
package WebService::Jamendo::RSS;

use 5.006000;
use strict;
use warnings;
use Carp;
use XML::Twig;
use LWP::Simple;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use WebService::Jamendo::RSS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
		get_popular_albums_this_week get_latest_albums get_latest_albums_usa get_this_week_most_100_listened_to
		get_jamendo_blog get_jamendo_forums download_popular_albums_this_week_xml get_jamendo_news
		download_latest_albums_xml download_latest_albums_usa_xml download_this_week_most_100_listened_to_xml 
		download_jamendo_blog_xml download_jamendo_forums_xml download_jamendo_news_xml
);

our $VERSION = '0.01';

# declare variables for popular albums this week 
my $popular_albums_this_week_url = "http://www.jamendo.com/en/rss/popular-albums";
my $popular_albums_this_week_root;
my $popular_albums_this_week_xml;
my $popular_albums_this_week_twig = new XML::Twig(TwigRoots => {'item' => 1, pretty_print => 'indented'});

# declare variables for latest albums
my $latest_albums_url = "http://www.jamendo.com/en/rss/last-albums";
my $latest_albums_root;
my $latest_albums_xml;
my $latest_albums_twig = new XML::Twig(TwigRoots => {'item' => 1, pretty_print => 'indented'});

# declare variables for latest albums in the USA
my $latest_albums_usa_url = "http://www.jamendo.com/en/rss/last-albums/USA";
my $latest_albums_usa_root;
my $latest_albums_usa_xml;
my $latest_albums_usa_twig = new XML::Twig(TwigRoots => {'item' => 1, pretty_print => 'indented'});

# declare variables for this week most 100 listened to
my $this_week_most_100_listened_to_url = "http://www.jamendo.com/en/rss/top-track-week";
my $this_week_most_100_listened_to_root;
my $this_week_most_100_listened_to_xml;
my $this_week_most_100_listened_to_twig = new XML::Twig(TwigRoots => {'item' => 1, pretty_print => 'indented'});

# declare variables for jamendo blog rss feed
my $jamendo_blog_url = "http://feeds.feedburner.com/JamendoBlogEnglish?format=xml";
my $jamendo_blog_root;
my $jamendo_blog_xml;
my $jamendo_blog_twig = new XML::Twig(TwigRoots => {'item' => 1, pretty_print => 'indented'});

# declare variables for jamendo forums rss feed
my $jamendo_forums_url = "http://www.jamendo.com/fr/forums/discussions/?Feed=RSS2";
my $jamendo_forums_root;
my $jamendo_forums_xml;
my $jamendo_forums_twig = new XML::Twig(TwigRoots => {'item' => 1, pretty_print => 'indented'});

# declare variables for jamendo news rss feed
my $jamendo_news_url = "http://www.jamendo.com/en/rss/newsfeed/bf0b52ca330f6ca9e88801e3f0c26c68775909";
my $jamendo_news_root;
my $jamendo_news_xml;
my $jamendo_news_twig = new XML::Twig(TwigRoots => {'item' => 1, pretty_print => 'indented'});

# preloaded methods go here.
######################Begin Primary Subroutines##########################

sub get_popular_albums_this_week {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        $popular_albums_this_week_twig->parsefile("popular_albums_this_week.xml");

        #set root of the twig (channel).
        $popular_albums_this_week_root = $popular_albums_this_week_twig->root;

        #get popular albums this week.
        foreach my $popular_albums_this_week ($popular_albums_this_week_root->children('item')) {

                print $popular_albums_this_week->first_child_text('title');
                print "\n";
        }

# sub get_popular_albums_this_week()
}

sub get_latest_albums {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #parse xml file for latest albums.
        $latest_albums_twig->parsefile("latest_albums.xml");

        #set root of the twig (channel).
        $latest_albums_root = $latest_albums_twig->root;

        #get latest albums.
        foreach my $latest_albums_titles ($latest_albums_root->children('item')) {

                print $latest_albums_titles->first_child_text('title');
                print "\n";
        }

# sub get_latest_albums()
}

sub get_latest_albums_usa {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #parse xml file for latest albums in usa.
        $latest_albums_usa_twig->parsefile("latest_albums_usa.xml");

        #set root of the twig (channel).
        $latest_albums_usa_root = $latest_albums_usa_twig->root;

        #get recent albums in usa.
        foreach my $latest_albums_usa_titles ($latest_albums_usa_root->children('item')) {

                print $latest_albums_usa_titles->first_child_text('title');
                print "\n";
        }

# sub get_latest_albums_usa() 
}

sub get_this_week_most_100_listened_to {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #parse xml file for this week's most 100 listened to.
        $this_week_most_100_listened_to_twig->parsefile("this_week_most_100_listened_to.xml");

        #set root of the twig (channel).
        $this_week_most_100_listened_to_root = $this_week_most_100_listened_to_twig->root;

        #get this week's most 100 listened to.
        foreach my $this_week_most_100_listened_to_titles ($this_week_most_100_listened_to_root->children('item')) {

                print $this_week_most_100_listened_to_titles->first_child_text('title');
                print "\n";
        }

# sub get_this_week_most_100_listened_to()
}

sub get_jamendo_blog {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #parse xml file for jamendo's primary blog.
        $jamendo_blog_twig->parsefile("jamendo_blog.xml");

        #set root of the twig (channel).
        $jamendo_blog_root = $jamendo_blog_twig->root;

        #get jamendo's primary blog.
        foreach my $jamendo_blog_titles ($jamendo_blog_root->children('item')) {

                print $jamendo_blog_titles->first_child_text('title');
                print "\n";
        }

# sub get_jamendo_blog()
}

sub get_jamendo_forums {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #parse xml file for jamendo's forums.
        $jamendo_forums_twig->parsefile("jamendo_forums.xml");

        #set root of the twig (channel).
        $jamendo_forums_root = $jamendo_forums_twig->root;

        #get jamendo's forums.
        foreach my $jamendo_forums_titles ($jamendo_forums_root->children('item')) {

                print $jamendo_forums_titles->first_child_text('title');
                print "\n";
        }

# sub get_jamendo_forums()
}

sub get_jamendo_news {

        #Turn on strict and warnings.
        use strict;
        use warnings;

        #parse xml file for jamendo's forums.
        $jamendo_news_twig->parsefile("jamendo_news.xml");

        #set root of the twig (channel).
        $jamendo_news_root = $jamendo_news_twig->root;

        #get jamendo's news.
        foreach my $jamendo_news_titles ($jamendo_news_root->children('item')) {

                print $jamendo_news_titles->first_child_text('title');
                print "\n";
        }

# sub get_jamendo_news()
}

######################End of primary subroutines##########################

#######Begin subroutines that download RSS feeds from Jamendo.com#########

sub download_popular_albums_this_week_xml {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #get xml using LWP::Simple.
        $popular_albums_this_week_xml = get $popular_albums_this_week_url;

        #get rid of non-ascii chars.
        $popular_albums_this_week_xml =~ s/[^[:ascii:]]+//g;

        #save XML to file.
        open( my $POPULAR_ALBUMS_THIS_WEEK_FH, ">", "popular_albums_this_week.xml" ) or confess "Can't open file: $!";

                #print popular albums this week to file in PWD.
                print $POPULAR_ALBUMS_THIS_WEEK_FH "$popular_albums_this_week_xml";

        close($POPULAR_ALBUMS_THIS_WEEK_FH);

# sub download_recent_videos_xml()
}

sub download_latest_albums_xml {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #get xml using LWP::Simple.
        $latest_albums_xml = get $latest_albums_url;

        #get rid of non-ascii chars.
        $latest_albums_xml =~ s/[^[:ascii:]]+//g;

        #save XML to file.
        open( my $LATEST_ALBUMS_FH, ">", "latest_albums.xml" ) or confess "Can't open file: $!";

                #print latest albums to file in PWD.
                print $LATEST_ALBUMS_FH "$latest_albums_xml";

        close($LATEST_ALBUMS_FH);

# sub download_latest_albums_xml()
}

sub download_latest_albums_usa_xml {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #get xml using LWP::Simple.
        $latest_albums_usa_xml = get $latest_albums_usa_url;

        #get rid of non-ascii chars.
        $latest_albums_usa_xml =~ s/[^[:ascii:]]+//g;

        #save XML to file.
        open( my $LATEST_ALBUMS_USA_FH, ">", "latest_albums_usa.xml" ) or confess "Can't open file: $!";

                #print recent latest albums in usa to file in PWD.
                print $LATEST_ALBUMS_USA_FH "$latest_albums_usa_xml";

        close($LATEST_ALBUMS_USA_FH);

# sub download_latest_albums_usa_xml().
}

sub download_this_week_most_100_listened_to_xml {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #get xml using LWP::Simple.
        $this_week_most_100_listened_to_xml = get $this_week_most_100_listened_to_url;

        #get rid of non-ascii chars.
        $this_week_most_100_listened_to_xml =~ s/[^[:ascii:]]+//g;

        #save XML to file.
        open( my $THIS_WEEK_MOST_100_LISTENED_TO_FH, ">", "this_week_most_100_listened_to.xml" ) or confess "Can't open file: $!";

                #print highest rated videos to file in PWD.
                print $THIS_WEEK_MOST_100_LISTENED_TO_FH "$this_week_most_100_listened_to_xml";

        close($THIS_WEEK_MOST_100_LISTENED_TO_FH);

# sub download_this_week_most_100_listened_to_xml().
}

sub download_jamendo_blog_xml {
	#Turn on strict and warnings.
	use strict;
	use warnings;

        #get xml using LWP::Simple.
        $jamendo_blog_xml = get $jamendo_blog_url;

        #get rid of non-ascii chars.
        $jamendo_blog_xml =~ s/[^[:ascii:]]+//g;

        #save XML to file.
        open( my $JAMENDO_BLOG_FH, ">", "jamendo_blog.xml" ) or confess "Can't open file: $!";

                #print jamendo's blog to file in PWD.
                print $JAMENDO_BLOG_FH "$jamendo_blog_xml";

        close($JAMENDO_BLOG_FH);

# sub download_jamendo_blog_xml.
}

sub download_jamendo_forums_xml {
        #Turn on strict and warnings.
        use strict;
        use warnings;

        #get xml using LWP::Simple.
        $jamendo_forums_xml = get $jamendo_forums_url;

        #get rid of non-ascii chars.
        $jamendo_forums_xml =~ s/[^[:ascii:]]+//g;

        #save XML to file.
        open( my $JAMENDO_FORUMS_FH, ">", "jamendo_forums.xml" ) or confess "Can't open file: $!";

                #print jamendo's forums to file in PWD.
                print $JAMENDO_FORUMS_FH "$jamendo_forums_xml";

        close($JAMENDO_FORUMS_FH);

# sub download_jamendo_blog_xml.
}

sub download_jamendo_news_xml {

        #Turn on strict and warnings.
        use strict;
        use warnings;

        #get xml using LWP::Simple.
        $jamendo_news_xml = get $jamendo_news_url;

        #get rid of non-ascii chars.
        $jamendo_news_xml =~ s/[^[:ascii:]]+//g;

        #save XML to file.
        open( my $JAMENDO_NEWS_FH, ">", "jamendo_news.xml" ) or confess "Can't open file: $!";

                #print jamendo news to file in PWD.
                print $JAMENDO_NEWS_FH "$jamendo_news_xml";

        close($JAMENDO_NEWS_FH);

# sub download_jamendo_news_xml().
}

# Modules must return a true value
1;
