#!/usr/bin/perl
#   $Id: example-1.pl 56 2008-06-23 16:54:31Z adam $

=head1 NAME

Example-1 Very simple example

=head2 Example 1

This very simple example shows how to create a basic command line tool.
The script would be called from the command line with a call with a URI to
collect the RSS file from and the file to transform the XML with, and
output going to STDOUT.

=cut

use strict;
use XML::RSS::Tools;
my $rss = XML::RSS::Tools->new;
if (   $rss->rss_uri(shift)
    && $rss->xsl_file(shift)
    && $rss->transform )
{
    print $rss->as_string;
}
else {
    print $rss->as_string('error');
}

