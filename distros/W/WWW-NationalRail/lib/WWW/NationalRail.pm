package WWW::NationalRail;

use warnings;
use strict;
use 5.006_001;
use Carp;
use HTML::TableExtract;
use WWW::Mechanize;
use base qw(Class::Accessor);

our $VERSION = "0.1";

__PACKAGE__->mk_accessors(qw(from to via out_date out_type out_hour out_minute
    ret_date ret_type ret_hour ret_minute));
__PACKAGE__->mk_ro_accessors(qw(outward_summary return_summary
    outward_detail return_detail error));

my $url = "http://www.nationalrail.co.uk/planmyjourney/";

sub search {
    my $self = shift;
    my $mech = new WWW::Mechanize;
    delete $self->{error}; # reset error
    $mech->get($url);

    # National Rail use odd field names
    $mech->field( "0", $self->{from});
    $mech->field( "1", $self->{to});
    $mech->field( "11", $self->{out_date});
    $mech->field( "14", $self->{ret_date}) if $self->{ret_date};
    $mech->field( "3", $self->{via});
    $mech->field( "9", $self->{out_type}) if $self->{out_type};
    $mech->field( "outHourField", sprintf "%02d", $self->{out_hour})
        if defined $self->{out_hour};
    $mech->field( "outMinuteField", sprintf "%02d", $self->{out_minute})
        if defined $self->{out_minute};
    $mech->field( "retHourField", sprintf "%02d", $self->{ret_hour})
        if defined $self->{ret_hour};
    $mech->field( "retMinuteField", sprintf "%02d", $self->{ret_minute})
        if defined $self->{ret_minute};

    $mech->submit_form();

    if ($mech->content =~ m!<FONT class="error">(.*)</FONT>!) {
        $self->{error} = "National Rail error: $1";
        return;
    }
    if ($mech->content =~ m!<div class="bluetitle">You searched for (.*)</div>!) {
        $self->{error} = "Unknown station: $1";
        return;
    }

    # At this point we are looking at a page that says "We are getting the
    # train times for the journey you have requested". Click the link. If we
    # get the same page click it again.
    while ($mech->find_link(url => "Display_Timetable.asp")) {
        $mech->follow_link(url => "Display_Timetable.asp");
    }

    $self->{_summary} = $mech->content;
    $self->_parseSummary();
    $mech->follow_link(url => "Matrix_Journey_Details.asp");
    $self->{_detail} = $mech->content;
    $self->_parseDetail();
    return 1;
}

sub _parseSummary {
    my $self = shift;
    my $te = new HTML::TableExtract( depth => 2 );
    $te->parse($self->{_summary});
    my @directions = qw(outward return);
    my @fields = qw(depart arrive changes duration);

    foreach my $ts ($te->table_states) {
        # check if we have already seen both directions
        my $direction = shift @directions or carp "summary parse error";
        my $summary;
        my $row_num = 0;
        foreach my $row ($ts->rows) { # one field per row
            defined $row->[1] and $row->[1] ne "" or next; # careful of '0's
            my $field = lc shift @$row;
            # check field name is as expected
            if ($fields[$row_num] ne $field) {
                # don't worry if single journey and we are looking for a return
                # that isn't there
                return if $row_num == 0 and $direction eq "return";
                carp "summary parse error";
            }
            $summary->[$_]{$field} = $row->[$_] for 0..$#$row; # transpose
            $row_num++;
        }
        @$summary or carp "summary parse error";
        $self->{$direction . "_summary"} = $summary;
    }
}

sub _parseDetail {
    my $self = shift;
    my $te = new HTML::TableExtract( );
    $te->parse($self->{_detail});
    my $direction;
    foreach my $ts ($te->table_states) {
        if ($ts->depth eq 3) {
            (($ts->rows)[0]->[0]) =~ /^(.*) Journey: /
                    or carp "direction not found";
            $direction = lc $1;
        }
        next if $ts->depth != 2 or $ts->rows == 1;
        $direction or carp "direction not found";
        my $journey = {};
        my @legs;
        foreach my $row ($ts->rows) {
            next if not $row->[0] or $row->[0] eq "Station";
            if ($row->[0] =~ /DURATION: ([0-9:]+)/) { 
                $journey->{duration} = $1;
            } else {
                my %leg;
                @leg{qw(station arrive depart travelby operator)} = map {
                    s/[^a-zA-Z0-9: ]//g;
                    $_ ne "" ? $_ : undef; # careful of '0's
                } @$row;
                push @legs, \%leg;
            }
        }
        $journey->{legs} = \@legs;
        push @{$self->{$direction . "_detail"}}, $journey;
    }
}

1;

=head1 NAME

WWW::NationalRail - Perl interface to the UK rail timetable

=head1 SYNOPSIS

  use WWW::NationalRail;

  my $rail = WWW::NationalRail->new({
    from        => "London",
    to          => "Cambridge",
    out_date    => "18/12/05",
    out_type    => "depart",
    out_hour    => 9,
    out_minute  => 0,
    ret_date    => "18/12/05",
    ret_type    => "depart",
    ret_hour    => 17,
    ret_minute  => 0,
  });

  $rail->search or die $rail->error();

  my $os = $rail->outward_summary; # array reference
  my $rs = $rail->return_summary;

  $os->[0]{depart}      # "09:06"
  $os->[0]{arrive}      # "10:25"
  $os->[0]{changes}     # "0" 
  $os->[0]{duration}    # "1:19" 

  my $od = $rail->outward_detail;
  my $rd = $rail->return_detail;

  $od->[0]->{duration}; # "1:19"

  my $legs = $od->[0]{legs} # array reference

  $legs->[0]{station}   # "LONDON KINGS CROSS"
  $legs->[0]{arrive}    # undef
  $legs->[0]{depart}    # "09:06"
  $legs->[0]{travelby}  # "Train"
  $legs->[0]{operator}  # "WAGN RAIL"

  $rail->ret_hour(19);  # change search parameters
  $rail->search();      # and search again

=head1 DESCRIPTION

WWW::NationalRail is a Perl interface to the UK national rail timetable at
http://www.nationalrail.co.uk/planmyjourney/

=over 4

=item new()

The constructor accepts the arguments for the search as a has
reference. The from and to fields are required, the rest are optional and will
use a National Rail supplied default.

=over 11

=item from

Departure station.

=item to

Destination station.

=item via

Via station.

=item out_date

Outbound date in the format "DD/MM/YY". Defaults to today.

=item out_type

Possible values are "depart" to search by outbound departure time or
"arrive" to search by outbound arrival time. Defaults to "depart".

=item out_hour

Outbound hour, 0 to 23. Defaults to sometime in the near future.

=item out_minute

Outbound minute, 0 to 59. Defaults to sometime in the near future.

=item ret_date

Return date in the format "DD/MM/YY". Leave blank for one-way.

=item ret_type

Similar to out_type. Either "depart or "arrive". Defaults to "depart".

=item ret_hour

Return hour, 0 to 23. Leave blank for one-way.

=item ret_minute

Return minute, 0 to 59. Leave blank for one-way.

=back

=item search()

Object method to run the search and parse the results.

=item outbound_summary() and return_summary()

Each returns a reference to an array of hashes.
For journeys in one direction return_summary() will be undef.
The hash representing a summary has four fields:

=over 9

=item depart

Time of departure.

=item arrive

Time of arrival.

=item changes

Number of changes.

=item duration

Duration of the journey.

=back

=item outbound_details() and return_details()

Each returns a reference to an array of hashes.
For journeys in one direction return_details() will be undef.
The hash representing a journey has four two fields:

=over 9

=item legs

Reference to an array of hashes.

=item duration 

Duration of the journey.

=back

The legs hash has four five fields:

=over 9

=item station

Name of the station.

=item arrive

Time of arrival at this station, undef for the first leg.

=item depart

Time of departure from this station, undef for the last leg.

=item travelby

Means of transport, will usually be train, but could also be foot,
coach, or tube.

=item operator

The train operating company.

=back

=back

=head1 AUTHOR

Edward Betts, C<< <edward@debian.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Edward Betts

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
