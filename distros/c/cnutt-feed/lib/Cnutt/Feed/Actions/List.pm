package Cnutt::Feed::Actions::List;

use strict;
use warnings;

=head1 NAME

Cnutt::Feed::Actions::List - List the feeds of a webpage

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.0';

=head1 DESCRIPTION

This file is part of cnutt-feed. You should read its documentation.

=cut

use XML::Feed;

=head2 ls

Given an url, display the list of feeds found on the page.

=cut

sub ls {
    my ($roptions, $url) = @_;
    my %options = %{$roptions};

    print "Searching feeds in $url...\n" if $options{verbose};

    # get the feeds list
    my @feeds = XML::Feed->find_feeds($url);

    # print list
    map {print $_, "\n"} @feeds;

    my $count = @feeds;
    print "Found $count feed(s)\n" if $options{verbose};
}

1;

