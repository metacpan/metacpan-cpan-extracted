=head1 NAME

WebService::BBC::MusicCharts - Retrieve and return UK music chart listings

=head1 SYNOPSIS

  use WebService::BBC::MusicCharts;

  my $chart = WebService::BBC::MusicCharts->new( chart => 'album' );
  my $count = 1;

  foreach my $title ($chart->titles) {
    print "At $count we have $title\n";
    $count++;
  }

=head1 DESCRIPTION

The WebService::BBC::MusicCharts module provides access to some of the BBCs
online music charts via a simple object-oriented interface.

It currently supports the singles chart, album chart and downloaded music
charts.

=head1 EXAMPLES

  use WebService::BBC::MusicCharts;

  my $albums = WebService::BBC::MusicCharts->new( chart => 'album' );

  foreach my $chart_position (1..40) {
    my $details = $albums->number($chart_position);
    print "$chart_position: ", $details->{title};
    print " by ", $details->{artist},"\n";
  }

=cut

#######################################################################

package WebService::BBC::MusicCharts;
use strict;
use warnings;
use LWP::Simple qw(get);
use Template::Extract;
use vars qw($VERSION);

$VERSION = "0.01";

my %charts = (
  album    => 'http://www.bbc.co.uk/radio1/chart/albums.shtml',
  download => 'http://www.bbc.co.uk/radio1/chart/downloads.shtml',
  singles  => 'http://www.bbc.co.uk/radio1/chart/singles.shtml',
);


=head1 METHODS

=over 4

=item new ( chart => 'chart type' )

This is the constructor for a new WebService::BBC::MusicCharts object.
The C<chart> argument is required (and can currently be 'album',
'download' or 'singles') and the module will C<die> if it is either
missing or passed an invalid value.

The constructor also does the actual page fetch, which may also C<die>
if the C<get> fails. Wrapping the C<new> invocation in an C<eval> isn't
a bad idea.

=back

=cut

#----------------------------------------#

sub new {
  my $class = shift;
  my $self = {@_};

  die "Unknown chart '$self->{chart}'" unless $charts{$self->{chart}};

  my @chart_entries = _get_entries($charts{$self->{chart}});

  push(@{$self->{entries}}, @chart_entries);

  bless ($self, $class);
  return $self;
}

#----------------------------------------#

=over 4

=item chart_type

Returns the type of chart that this instance represents. Mostly used
when I was debugging the module.

=back

=cut

sub chart_type {
  my $self = shift;
  return $self->{chart};
}

#----------------------------------------#

=over 4

=item titles

Returns an array containing all the titles from the chart this instance
represents.

=back

=cut

sub titles {
  my $self = shift;
  my @titles;

  foreach my $title (@{$self->{entries}}) {
    push(@titles, $title->{title});
  }

  return @titles;
}

#----------------------------------------#

=over 4

=item artists

Returns an array containing all the artists from the chart this instance
represents.

=back

=cut

# TODO merge the iterator methods in to one.

sub artists {
  my $self = shift;
  my @artists;

  foreach my $title (@{$self->{entries}}) {
    push(@artists, $title->{artist});
  }

  return @artists;
}

#----------------------------------------#

=over 4

=item number($num)

The number method must be called with a valid integer (it accepts any
between 1 and 40), it then returns a hash ref containing the details for
the song/album at that chart position.

The fields returned are:
  C<artist>         - the name of the artist
  C<title>          - the title of the single or album
  C<label>          - the owning record label
  C<this_week>      - the current chart position of the song/album
  C<last_week>      - The position this song/album was at last week. This
                       will either be a number, NEW or RE (re-entry)
  C<weeks_in_chart> - the number of weeks it's been in the chart

If called without an argument, or with one that's not between 1 and 40, it
will return undef.

=back

=cut

sub number {
  my $self = shift;
  my $number = shift;

  return unless $number;
  return unless $number =~ /^\d+$/;
  return if ($number < 1 || $number > 40);

  $number--; # we're using 0 offset arrays
  my $entry = $self->{entries}->[$number];

}

#----------------------------------------#

# internal function that parses the HTML, builds the objects internal
# state and passes it back to the constructor. Dense but not complex

sub _get_entries {
  my $chart_url = shift;
  my $extract = Template::Extract->new();
  my @chart_entries;

  my $chart_page = get($chart_url)
    or die "Failed to get chart.";

  # define the extraction template
  my $template = << 'END_OF_TEMPLATE';
[% FOREACH entries %]
[% ... %]
<td class="col1">[% thisweek %]</td>[% ... %]
<td class="col2">[% lastweek %]</td>[% ... %]
<td class="col3">([% weeksin %])</td>[% ... %]
<h4>[% artist %]</h4>[% ... %]
<h5>[% title  %]</h5>[% ... %]
<p>([% label %])[% ... %]
[% ... %]
[% END %]
END_OF_TEMPLATE

  for (@{$extract->extract($template, $chart_page)->{entries}}) {
    # tidy up "last week"
    $_->{lastweek} =~ m/^\s*(\w+)/;
    my $last_week = $1;

    my %entry_details = (
      artist         => $_->{artist},
      title          => $_->{title},
      label          => $_->{label},
      this_week      => $_->{thisweek},
      last_week      => $last_week,
      weeks_in_chart => $_->{weeksin}
    );

    push(@chart_entries, \%entry_details);
  }
  return @chart_entries;
}

#----------------------------------------#

1;

#######################################################################

=head1 DEPENDENCIES

WebService::BBC::MusicCharts requires the following modules:

L<LWP::Simple>

L<Template::Extract>

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2006 Dean Wilson.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dean Wilson <dean.wilson@gmail.com>

=cut
