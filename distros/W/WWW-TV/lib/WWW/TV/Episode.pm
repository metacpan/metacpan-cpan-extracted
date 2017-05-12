=head1 NAME

WWW::TV::Episode - Parse TV.com for TV Episode information.

=head1 SYNOPSIS

  use WWW::TV::Episode qw();
  my $episode = WWW::TV::Series->new(id => '475567');

  # with optional paramers

  print $episode->summary;

=head1 DESCRIPTION

The L<WWW::TV::Episode> module parses TV.com episode information using
L<LWP::UserAgent>. Unfortunately I can't see a way to search for an episode
by name, so I haven't implemented it. It is probably possible to do so if you
populate a series object and grep $series->episodes for the episode name you
are searching for.

=head1 METHODS

=cut

package WWW::TV::Episode;
use strict;
use warnings;

our $VERSION = '0.14';

use Carp qw(croak);
use LWP::UserAgent qw();

=head2 new

    The new() method is the constructor. It takes the id of the show
    assuming you have previously looked that up.

        # default usage
        my $episode = WWW::TV::Episode->new(id => 924072);

        # change user-agent from the default of "libwww-perl/#.##"
        my $episode = WWW::TV::Episode->new(id => 924072, agent => 'WWW::TV');

    It also (optionally) takes the name of the episode. This is not used
    in any way to search for the episode, but is used as initial data
    population for that field so that the html isn't parsed if you only
    want an object with the name. This is used by the L<WWW::TV::Series>
    object to populate a big array of episodes that have names without
    needing to fetch any pages.

        # pre-populate episode name
        my $episode = WWW::TV::Episode->new(id => 924072, name => 'Run!');

=cut

sub new {
    my $class = ref $_[0] ? ref(shift) : shift;

    my %data;

    if (@_ == 1) {
        $data{id} = shift;
    }
    elsif (scalar(@_) % 2 == 0) {
        %data = @_;
    }

    croak 'No id given to constructor' unless exists $data{id};
    croak "Invalid id: $data{id}" unless ($data{id} =~ /^\d+$/ && $data{id});

    return bless {
        id     => $data{id},
        name   => $data{name},
        _agent => $data{agent},
        _site  => $data{site},
        filled => {
            id => 1,
            $data{name}
                ? (name => 1)
                : (),
        },
    }, $class;
}

=head2 id

    The ID of this episode, according to TV.com

=cut

sub id {
    my $self = shift;

    return $self->{id};
}

=head2 name

    Returns a string containing the name of the episode.

=cut

sub name {
    my $self = shift;

    unless (exists $self->{filled}->{name}) {
        $self->{filled}->{name} = 1;
        ($self->{name}) = $self->_html =~ m{
            <h2\sclass="module_title">(.*)</h2>\n
            \s*<ul\sclass="ep_stats">
        }x;
    }

    return $self->{name};
}

=head2 summary

    Returns a string containing basic information about this series.

=cut

sub summary {
    my $self = shift;

    unless (exists $self->{filled}->{summary}) {
        $self->{filled}->{summary} = 1;
        ($self->{summary}) = $self->_html =~ m{
            <p\sclass="deck">(.*?)</p>
        }smx;
        $self->{summary} =~ s/<br ?\/?>/\n/g;
        $self->{summary} =~ s/<a href="[^"]+">.*?<\/a>//g;
        $self->{summary} =~ s/^\s*//;
        $self->{summary} =~ s/\s*$//;
    }

    return $self->{summary};
}

=head2 season_number

    Returns the season number that this episode appeared in.

=cut

sub season_number {
    my $self = shift;

    unless (exists $self->{filled}->{season_number}) {
        $self->_fill_vitals;
    }

    return $self->{season_number};
}

=head2 episode_number

    Returns the overall number of this episode. Note, this is not
    necessarily the production order of the episodes, but is the order
    in which they aired.

=cut

sub episode_number {
    my $self = shift;

    unless (exists $self->{filled}->{episode_number}) {
        $self->_fill_vitals;
    }

    return $self->{episode_number};
}

=head2 format_details ($format_str)

    Returns episode details using a special format string, similar to printf:
       %I - series ID
       %N - series name
       %s - season number
       %S - season number (0-padded to two digits, if required)
       %i - episode ID
       %e - episode number
       %E - episode number (0-padded to two digits, if required)
       %n - episode name
       %d - date episode first aired

    The default format is:
       %N.s%Se%E - %n (eg: "Heroes.s1e02 - Don't Look Back")

=cut

sub format_details {
    my $self = shift;

    my $format_str = shift || '%N.s%Se%E - %n';

    # format subs .. expecting $_[0] is $self
    my %formats = (
       'I'  => sub { $_[0]->series_id },
       'N'  => sub { $_[0]->series->name },
       's'  => sub { $_[0]->season_number },
       'S'  => sub { sprintf('%02d', $_[0]->season_number) },
       'i'  => sub { $_[0]->id },
       'e'  => sub { $_[0]->episode_number },
       'E'  => sub { sprintf('%02d', $_[0]->episode_number) },
       'n'  => sub { $_[0]->name },
       'd'  => sub { $_[0]->first_aired },
    );

    # substitution
    $format_str =~
            s/
                # look for single character format specifier
                %([a-zA-Z])
            /
                # use format sub if found, otherwise leave as-is
                $formats{$1} ? $formats{$1}->($self) : "\%$1"

            /sgex;

    return $format_str;
}

=head2 first_aired

    Returns a string of the date this episode first aired in ISO 8601 (yyyy-mm-dd) format.

=cut

sub first_aired {
    my $self = shift;

    unless (exists $self->{filled}->{first_aired}) {
        $self->_fill_vitals;
    }

    return $self->{first_aired};
}

=head2 stars

    Returns a list of the stars that appeared in this episode.

    # in scalar context, returns a comma-delimited string
    my $stars = $episode->stars;

    # in array context, returns an array
    my @stars = $episode->stars;

=cut

sub stars {
    my $self = shift;

    unless (exists $self->{filled}->{stars}) {
        my ($stars) = $self->_html =~ m{
          <dl\s*>\s*
          <dt>Stars?:</dt>\s*
          (<dd>.*?</dd>)\s*
          </dl>
        }x;

        $self->{stars} = $self->_parse_people($stars);
        $self->{filled}->{stars} = 1;
    }

    return $self->{stars};
}

=head2 guest_stars

    Returns a list of the guest stars that appeared in this episode.

    # in scalar context, returns a comma-delimited string
    my $guest_stars = $episode->guest_stars;

    # in array context, returns an array
    my @guest_stars = $episode->guest_stars;

=cut

sub guest_stars {
    my $self = shift;

    unless (exists $self->{filled}->{guest_stars}) {
        my ($stars) = $self->_html =~ m{
          <dl\s*(?:class="last")?\s*>\s*
          <dt>Guest\sStars?:</dt>\s*
          (<dd>.*?</dd>)\s*
          </dl>
        }x;

        $self->{guest_stars} = $self->_parse_people($stars);
        $self->{filled}->{guest_stars} = 1;
    }

    return $self->{guest_stars};
}

=head2 recurring_roles

    Returns a list of the people who have recurring roles
    that appeared in this episode

    # in scalar context, returns a comma-delimited string
    my $recurring_roless = $episode->recurring_roless;

    # in array context, returns an array
    my @recurring_roless = $episode->recurring_roless;

=cut

sub recurring_roles {
    my $self = shift;

    unless (exists $self->{filled}->{recurring_roles}) {
        my ($stars) = $self->_html =~ m{
          <dl\s*>\s*
          <dt>Recurring\sRoles?:</dt>\s*
          (<dd>.*?</dd>)\s*
          </dl>
        }x;

        $self->{recurring_roles} = $self->_parse_people($stars);
        $self->{filled}->{recurring_roles} = 1;
    }

    return $self->{recurring_roles};
}

sub _parse_people {
    my $self = shift;
    my $stars = shift or return;

    my @stars;
    for my $star (split /<\/dd>/, $stars) {
        next unless $star =~ m{<a href="[^"]+">(.*?)</a>};
        push @stars, $1;
    }

    return join(', ', @stars);
}

=head2 writers

    Returns a list of the people that wrote this episode.

    # in scalar context, returns a comma-delimited string
    my $writers = $episode->writers;

    # in array context, returns an array
    my @writers = $episode->writers;

=cut

sub writers {
    my $self = shift;

    unless (exists $self->{filled}->{writers}) {
        my ($writers) = $self->_html =~ m{
          <dl\s*>\s*
          <dt>Writers?:</dt>\s*
          (<dd>.*?</dd>)\s*
          </dl>
        }x;

        $self->{writers} = $self->_parse_people($writers);
        $self->{filled}->{writers} = 1;
    }

    return $self->{writers};
}

=head2 directors

    Returns a list of the people that directed this episode.

    # in scalar context, returns a comma-delimited string
    my $directors = $episode->directors;

    # in array context, returns an array
    my @directors = $episode->directors;

=cut

sub directors {
    my $self = shift;

    unless (exists $self->{filled}->{directors}) {
        my ($directors) = $self->_html =~ m{
          <dl\s*>\s*
          <dt>Directors?:</dt>\s*
          (<dd>.*?</dd>)\s*
          </dl>
        }x;

        $self->{directors} = $self->_parse_people($directors);
        $self->{filled}->{directors} = 1;
    }

    return $self->{directors};
}

=head2 agent ($value)

Returns the current user agent setting, and sets to $value if provided.

=cut

sub agent {
    my $self = shift;   # may be called as $self or $class
    my $value = shift;

    if (ref $self) {
        if (defined $value) {    
            $self->{_agent} = $value;
        }
        return ($self->{_agent} || LWP::UserAgent::_agent);
    } else {
        return ($value || LWP::UserAgent::_agent);
    }
}

=head2 site ($value)

Returns the current mirror site setting, and sets to $value if provided.

Default site is "www"; other options include: us, uk, au

=cut

sub site {
    my $self = shift;  # may be called as $self or $class
    my $value = shift;

    if (ref $self) {
        if (defined $value) {
          if ($value =~ /^(au|uk|us|www|)$/i) {
            $self->{_site} = $value;
          } else {
            warn "Ignoring unknown site value: [$value]\n";
          }
        }
        return ($self->{_site} || 'www');
    } else {
        return ($value || 'www');
    }
}

=head2 url

    Returns the url that was used to create this object.

=cut

sub url {
    my $self = shift;

    return sprintf('http://%s.tv.com/episode/%d/summary.html', $self->site, $self->id);
}

=head2 season

    Returns an array of other episodes for the same season of this series.

=cut

sub season {
    my $self = shift;
    my @episodes = $self->series->episodes( season => $self->season_number );
    return wantarray ? @episodes : \@episodes;
}

=head2 series_id

    Returns the series ID for this episode.

=cut

sub series_id {
    my $self = shift;

    unless (exists $self->{filled}->{series_id}) {
        my ($id) = $self->_html =~ m{<a href=".*/show/(\d+)/cast\.html">};
        $self->{series_id} = $id;
        $self->{filled}->{series_id} = 1;
   }

    return $self->{series_id};
}

=head2 series

    Returns an L<WWW::TV::Series> object which is the complete series
    that this episode is a part of.

=cut

sub series {
    my $self = shift;

    unless (exists $self->{filled}->{series}) {
        if ($self->series_id) {
            require WWW::TV::Series;
            $self->{series} = WWW::TV::Series->new(id => $self->series_id);
            $self->{filled}->{series} = 1;
        } else {
            croak "Can't find series_id for this episode";
        }
    }

    return $self->{series};
}

sub _fill_vitals {
    my $self = shift;

    ($self->{season_number}, $self->{episode_number}, $self->{first_aired})
        = $self->_html
        =~ m{
            <ul\sclass="ep_stats">
              <li>.*?</li>
              <li><span>Season:</span>\s*(.*?)\s*</li>
              <li><span>Episode:</span>\s*(.*?)\s*</li>
              (?:<li><span>First\sAired:</span>\s*(?:\w*?\s*)?(\d+/\d+/\d+|n/a)\s*</li>)?
              (?:<li><span>Prod\sCode:</span>\s*.*\s*</li>)?
            </ul>
        }sx;

    $self->{filled}->{$_} = 1 for qw(episode_number season_number first_aired);

    return $self->_parse_first_aired;
}

sub _parse_first_aired {
    my $self = shift;

    if (not defined $self->{first_aired}) {
      $self->{first_aired} = 'n/a';
    }

    return if $self->{first_aired} eq 'n/a';

    my ($month, $day, $year) = split('/', $self->{first_aired});
    $self->{first_aired} = sprintf('%04d-%02d-%02d', $year, $month, $day);

    return 1;
}

sub _html {
    my $self = shift;

    unless ($self->{filled}->{html}) {
        my $ua = LWP::UserAgent->new( agent => $self->agent );
        my $rc = $ua->get($self->url);

        croak sprintf('Unable to fetch page for series %s', $self->id)
            unless $rc->is_success;
        $self->{html} =
            join(
                "\n",
                map { s/^\s*//; s/\s*$//; $_ }
                split /\n/, $rc->content
            );
        $self->{filled}->{html} = 1;
    }

    return $self->{html};
}

1;

__END__

=head1 SEE ALSO

L<WWW::TV::Series>

=head1 KNOWN ISSUES

There isn't yet any caching support. I don't see a need for it, but if you feel
the need to implement it then don't let me stop you.

There also isn't support for proxy servers yet. LWP should use it from your
environment if you really need it, but who still uses them anyway? Isn't it all
done transparently these days.

=head1 BUGS

Please report any bugs or feature requests through the web interface
at L<http://rt.cpan.org/Dist/Display.html?Queue=WWW-TV>.

=head1 AUTHORS

Danial Pearce C<cpan@tigris.id.au>

Stephen Steneker C<stennie@cpan.org>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2008 Danial Pearce C<cpan@tigris.id.au>. All rights reserved.

Some parts copyright 2007-2008 Stephen Steneker C<stennie@cpan.org>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
