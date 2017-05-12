#!/usr/bin/perl
#   $Id: example-4.pl 56 2008-06-23 16:54:31Z adam $

=head1 NAME

Example-4 Using a single XSLT stylesheet

=head2 Example 4

In this example we turn off RSS normalisation, and use a single XSLT stylesheet to deal with all
possible RSS feeds. As before we take inputs from the command line in the form of a URI of the RSS feed
and a file location for the stylesheet. The actual Perl is largely as in the previous example.

=cut


use strict;
use XML::RSS::Tools;
my $rss  = XML::RSS::Tools->new;
$rss->set_version(0);            # This turns normalisation off
eval {
  print $rss->rss_uri(shift)->xsl_file(shift)->transform->as_string;
  };
print $rss->as_string('error') if ($@);
