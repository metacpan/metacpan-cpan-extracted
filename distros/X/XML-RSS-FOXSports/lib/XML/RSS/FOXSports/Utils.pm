#================================================================================
# Copyright (c) Brian Perez 2005. All rights reserved.
#--------------------------------------------------------------------------------
# This library is free software; you can redistribute it  
# and/or modify it under the same terms as Perl itself.
#================================================================================
package XML::RSS::FOXSports::Utils;

use strict;
use warnings;

use Carp;
use XML::RSS::FOXSports::Constants qw(:all);

our $VERSION = '0.01';

my ($hfds, $vfds, $teams, $mw_url) = (HEADLINE_FEED_URLS, VIDEO_FEED_URLS, TEAM_TO_ID, MOST_WATCHED_URL);

sub new { bless {}, shift };
sub get_available_feeds          { keys %$hfds, keys %$vfds  }
sub get_available_headline_feeds { keys %$hfds }
sub get_available_video_feeds    { keys %$vfds }
sub get_available_leagues        { keys %$teams }
sub get_available_teams          { map { keys %{ $teams->{$_} } } keys %$teams }
sub get_available_leagues_teams  { $teams }
sub get_feed_url  { $hfds->{$_[1]} or  $vfds->{$_[1]} or croak "url for $_[1] feed was not found." }
sub get_feed_urls { values %{ $hfds }, values %{ $vfds }, $mw_url }


__END__


=head1 NAME

XML::RSS::FOXSports::Utils - Utility methods class for XML::RSS::FOXSports.

=head1 SYNOPSIS

#!/usr/local/bin/perl

use XML::RSS::FOXSports::Utils;

my $fspu  = XML::RSS::FOXSports::Utils->new();

my @ary = $fspu->get_available_feeds;
print "$_\n" foreach @ary;
print "\n";

@ary = $fspu->get_available_headline_feeds;
print "$_\n" foreach @ary;
print "\n";

@ary = $fspu->get_available_video_feeds;
print "$_\n" foreach @ary;
print "\n";

@ary = $fspu->get_available_leagues;
print "$_\n" foreach @ary;
print "\n";

@ary = $fspu->get_available_teams;
print "$_\n" foreach @ary;
print "\n";

my $hsh = $fspu->get_available_leagues_teams;
print "MLS Teams: \n";  
print "$_\n" foreach keys %{ $hsh->{'MLS'} };
print "\n";

my $url = $fspu->get_feed_url('MLB_VIDEO');
print "url\n";
print "\n";

@ary = $fspu->get_feed_urls;
print "$_\n" foreach @ary;

=head1 DESCRIPTION

XML::RSS::FOXSports::Utils is a class of methods used to describe  
the available feed interface options provided by XML::RSS::FOXSports. 

=head1 METHODS

=over 4

=item get_available_feeds

Returns a list of all headline and video feed names this package parses

=item get_available_headline_feeds

Returns a list of headline feed names this package parses

=item get_available_video_feeds

Returns a list of video feed names this package parses

=item get_available_leagues

Returns a list of league names that can be passed to the parse_team method

=item get_available_teams

Returns a list of all team names that can be passed to the parse_team method

=item get_available_leagues_teams

Returns a hash reference of teams names indexed by league name

=item get_feed_url($feed_name)

Returns the url of the named feed

=item get_feed_urls

Returns the urls for headline and video feeds

=back

=head1 AUTHOR

Brian Perez <perez@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright (c) Brian Perez 2005. All rights reserved.
This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut 

