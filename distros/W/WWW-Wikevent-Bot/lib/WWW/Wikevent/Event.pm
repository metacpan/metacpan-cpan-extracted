package WWW::Wikevent::Event;
#
# Copyright 2007 Mark Jaroski
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of either:
# 
# a) the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version,
# or
# b) the "Artistic License" which comes with this Kit.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
# 
# You should have received a copy of the Artistic License with this Kit,
# in the file named "Artistic".
# 
# You should also have received a copy of the GNU General Public License
# along with this program in the file named "Copying". If not, write to
# the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
# Boston, MA 02111-1307, USA or visit their web page on the internet at
# http://www.gnu.org/copyleft/gpl.html.

use strict;
use overload q{""} => 'to_string';
use Date::Parse;
use Date::Format;
use Encode;
use utf8;

=head1 NAME

WWW::Wikevent::Event

=cut

=head1 SYNOPSIS

  use WWW::Wikevent::Event;

  my $event = WWW::Wikevent::Event->new();

but more usually you will get an event object from a Wikevent bot:

  my $bot = WWW::Wikevent::Bot->new();
  my $event = $bot->add_event();

Then use accessor methods to set event data:

  $event->name( 'Hideout Block Party' );
  $event->price( '$10' );
  $event->date( '2007-09-09' );
  $event->locality( 'Chicago' );
  $event->venue( 'The Hideout' );

etcetera.  Then:

  print $event;

which will print the event out as wikitext.

=cut

=head1 DESCRIPTION

WWW::Wikevent::Event is a package which will help you write scraper scripts
for gathering events from venue and artist websites and for inclusion in
the Free content events compendium, Wikevent.

The module takes care of building up an event tag for Wikevent, so you can
get busy with the fun work of scraping a venue's web pages for the
data.

=cut

=head1 CONSTANTS

=over

=item $REQ_WARNING;

The warning given if you print an event which is missing required
attributes.  In fact there really aren't any truly required attributes, but
these are needed to correctly place an event on the Wikevent site.

=back

=cut

my $REQ_WARNING = "The following attributes are missing:\n";

=head1 CONSTRUCTORS

=cut

=head2 new

  my $event = WWW::Wikevent::Event->new();

Creates and returns a new event object.

=cut

sub new {
    my $pkg = shift;
    my $self = bless {}, $pkg;
    $self->{'who'} = [];
    $self->{'what'} = [];
    return $self;
}

=head1 ACCESSORS

=cut

=head2 name

  $event->name( $name );
  my $name = $event->name();

The name of the event.

=cut

sub name {
    my ( $self, $name ) = @_;
    if ( $name ) {
        $self->{'name'} = $name;
        $self->{'name'} =~ s{(\w+)}{\u\L$1}g;
    }
    return $self->{'name'};
}

=head2 date
 
  $event->date( $date_string );
  my $date_string = $event->date();

The date of the event.

While Wikevent will accept and try to work with a number of date formats,
in practice the very best results will be achieved by using the a format
like '2007-09-20'.

=cut

sub date {
    my ( $self, $date ) = @_;
    $self->{'date'} = $date if $date;
    return $self->{'date'};
}

=head2 time

  $event->time( $time_string );
  my $time_string = $event->time();

The start time of the event.

Wikevent accepts a fairly wide range of formats for the time fields.  You
can use am/pm times like this: "9pm", "9:15pm", or if you prefer 24 hour
times like this:  "15:30" or even the French style "15h30".

=cut

sub time {
    my ( $self, $time ) = @_;
    $self->{'time'} = $time if $time;
    return $self->{'time'};
}

=head2 endtime

  $event->endtime( $time_string );
  my $time_string = $event->endtime();
  
The time at which your event ends.

See C<time> for details.

=cut

sub endtime {
    my ( $self, $endtime ) = @_;
    $self->{'endtime'} = $endtime if $endtime;
    return $self->{'endtime'};
}

=head2 duration

   $event->duration( $duration_string );
   my $duration_string = $event->duration();

The duration of the event.

An alternative to setting the endtime, this field accepts pretty much the same
format as the time fields.

=cut

sub duration {
    my ( $self, $duration ) = @_;
    $self->{'duration'} = $duration if $duration;
    return $self->{'duration'};
}

=head2 price

  $event->price( $price_string );
  my $price_string = $event->price();

The price of attending, and some short info.

This is a free text string, but should be used sparingly to report ticket
and door prices.

=cut

sub price {
    my ( $self, $price ) = @_;
    $self->{'price'} = $price if $price;
    return $self->{'price'};
}

=head2 tickets

    $event->tickets( $tickets_url );
    my $tickets_url = $event->tickets();

A URL which points to the venue's e-commerce page, if there is one.

This field must be a URL or it won't work.  Please pay attention to any
rules that the venue site might have about "deep" linking, and do make sure
that you only link to the venue site, or it's designated agent, NEVER to
some 3rd party.

=cut

sub tickets {
    my ( $self, $tickets ) = @_;
    $self->{'tickets'} = $tickets if $tickets;
    return $self->{'tickets'};
}

=head2 restrictions

  $event->restrictions( $restrictions );
  my $restrictions = $event->restrictions();

Any restrictions placed on attendance.

In many jursidtictions there are limits on who can attend events at which
alcohol is being sold, for instance.  This field is for recording those
rules, examples might be "21 and over", or "18 and over", or "All Ages".

=cut

sub restrictions {
    my ( $self, $restrictions ) = @_;
    $self->{'restrictions'} = $restrictions if $restrictions;
    return $self->{'restrictions'};
}

=head2 lang

   $event->lang( $language_code );
   my $language_code = $event->lang();

A comma seperated list of two letter language codes for languages which
will be used on stage at the event.

=cut

sub lang {
    my ( $self, $lang ) = @_;
    $self->{'lang'} = $lang if $lang;
    return $self->{'lang'};
}

=head2 locality

  $event->locality( $locality );
  my $locality = $event->locality();

The city, town, or village in which the event is taking place.

=cut

sub locality {
    my ( $self, $locality ) = @_;
    $self->{'locality'} = $locality if $locality;
    return $self->{'locality'};
}

=head2 venue

  $event->venue( $venue );
  my $venue = $event->venue();

The club, hall, auditorium, or street where the event is taking place.

=cut

sub venue {
    my ( $self, $venue ) = @_;
    $self->{'venue'} = $venue if $venue;
    return $self->{'venue'};
}

=head2 desc

  $event->desc( $wikitext );
  my $wikitext = $event->desc();

A discription of the event in Mediawiki wikitext.

For a complete description of the Wikitext markup language please see the
L<http://mediawiki.org>.

=cut

sub desc {
    my ( $self, $desc ) = @_;
    $self->{'desc'} = $desc if $desc;
    return $self->{'desc'};
}

=head2 who

  $event->who( @who );
  $event->who( $who_ref );
  my @who = $event->who();
  my $who_ref = $event->who();

An array, or array reference, of names of artists, etc. appearing at the
event.

It's best to use this field and its related methods only if you can't
include the appropriate markup in the description wikitext itself.  Don't
do both, since this list will be printed out as a wikitext unordered list
at the top of the event description.

=cut

sub who {
    my $self = shift;
    if ( @_ && ref $_[0] eq 'ARRAY' ) {
        $self->{'who'} = shift;
    } elsif ( @_ ) {
        $self->{'who'} = \@_;
    }
    return wantarray ? @{$self->{'who'}} : $self->{'who'};
}

=head2 what

  $event->what( @what );
  $event->what( $what_ref );
  my @what = $event->what();
  my $what_ref = $event->what();

An array, or array reference, of names of cateogories to which this event
belongs.

=cut

sub what {
    my $self = shift;
    if ( @_ && ref $_[0] eq 'ARRAY' ) {
        $self->{'what'} = shift;
    } elsif ( @_ ) {
        $self->{'what'} = \@_;
    }
    return wantarray ? @{$self->{'what'}} : $self->{'what'};
}

=head1 METHODS

=cut

=head2 add_who

  $event->add_who( $name );

Add a single artist, organizer, etc. to the C<who> list.

=cut

sub add_who {
    my ( $self, $who ) = @_;
    push @{$self->{'who'}}, $who;
    return $self->who();
}

=head2 add_what

  $event->add_what( $category );

Add a single category to the C<what> list.


=cut

sub add_what {
    my ( $self, $what ) = @_;
    push @{$self->{'what'}}, $what;
    return $self->what();
}

=head2 who_string

  $who_tags = $this->who_string();

Renders the C<who> list as a as tags for inclusion in the event
description.

=cut

sub who_string {
    my $self = shift;
    my $string = '';
    foreach my $who ( $self->who() ) {
        $string .= "* <who>$who</who>\n";
    }
    return $string eq '' ? undef : $string; 
}

=head2 what_string

  $what_tags = $this->what_string();

Renders the C<what> list as a as tags for inclusion in the event
description.


=cut

sub what_string {
    my $self = shift;
    my @ret;
    foreach my $what ( $self->what() ) {
        push @ret, "<what>$what</what>";
    }
    if ( length( @ret ) > 0 ) {
        return join( ', ', @ret );
    } else {
        return undef;
    }
}

=head2 to_string

  my $event_tag = $event->to_string();

Renders the event as an Event tag for inclusion on Wikevent.

=cut

sub to_string {
    my ( $e, $bot) = @_;
    my @attrs = qw{ name date time endtime duration lang
                    price tickets restrictions locality venue };
    my @req = qw{ name date time venue locality };
    my @missing;
    foreach my $key ( @req ) {
        if ( ! defined ( $e->{$key} ) ) {
            push @missing, $key;
        }
    }
    warn $REQ_WARNING . join( ', ', @missing) . "\n"
            if ( defined( $missing[0] ) );
    my $attrs = '';
    foreach my $key ( @attrs ) {
        next unless defined $e->{$key};
        $attrs .= "    $key=\"$e->{$key}\"\n";
    }
    my $desc = $e->desc();
    my $who = $e->who_string(); 
    my $what = $e->what_string();
    my $by = "<by>$bot</by>" if defined $bot;
    my $event = "<event\n$attrs>";
    $event .= "$who\n" if $who;
    $event .= "$desc\n" if $desc;
    $event .= "$what\n" if $what;
    $event .= "$by\n" if $by;
    $event .= "</event>\n";
    return $event;
}

1;

__END__

=head1 BUGS

Please submit bug reports to the CPAN bug tracker at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=www-wikevent-bot>.

=head1 DISCUSSION

Discussion should take place on the Wiki, probably on the page 
L<http://wikevent.org/en/Wikevent:Perl library>

=head1 AUTHORS

=over

=item Mark Jaroski <mark@geekhive.net> 

Original author, maintainer

=back

=head1 LICENSE

Copyright (c) 2004-2005 Mark Jaroski. 

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

