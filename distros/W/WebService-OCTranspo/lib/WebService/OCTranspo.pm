package WebService::OCTranspo;
use strict;
use warnings;

use WWW::Mechanize;
use HTML::Form::ForceValue;
use HTML::TableExtract;
use HTTP::Status;

use Carp;

our $VERSION = '0.027';

my $DEBUG = 0;
sub DEBUG { $DEBUG };

sub new
{
	my ($class, $args) = @_;

	if( $args->{debug} ) {
		$DEBUG = $args->{debug};
	}

	my $self = {
		stop_data => {},
	};
	$self->{mech} = WWW::Mechanize->new(
		cookie_jar => {},
		agent      => 'WebService-OCTranspo/' . $VERSION,
		quiet      => 1,
	);

	bless $self, $class;
	return $self;
}

# TODO: schedule_for_stop should return an object, not a hashref.
sub schedule_for_stop
{
	my( $self, $args ) = @_;

	foreach my $key ( qw( stop_id route_id date) ) {
		if( ! exists $args->{$key} ) {
			croak qq{$key argument required for schedule_for_stop()};
		}
	}

	# Force date into Eastern time, if it isn't already
	$args->{date}->set_time_zone('America/Toronto');

	$self->_reset();
	$self->_select_date( $args->{date} );
	$self->{stop_data}{date} = $args->{date};

	if( ! $self->_select_stop( $args->{stop_id} ) ) {
		die "Stop $args->{stop_id} does not seem to exist";
	}

	$self->{stop_data}{stop_number} = $args->{stop_id};

	if( !  $self->_select_route( $args->{route_id} ) ) {
		die "Route $args->{route_id} does not service that stop";
	}

	$self->{stop_data}{route_number} = $args->{route_id};

	return $self->_parse_schedule();
}

sub _reset
{
	my ($self) = @_;

	$self->{stop_data} = {};
	# Get the form page
	warn 'Fetching start page for new session' if DEBUG;

	# More evil.  Their broken HTML has an <input type='input' ...>
	# which is completely invalid.  So... catch the warning from
	# HTML::Form and ignore it.
	local $SIG{__WARN__} = sub {
		warn $_[0] unless $_[0] =~ m/^Unknown input type 'input' at/;
	};

	$self->{mech}->get('http://www.octranspo.com/tps/jnot/sptStartEN.oci');
}

sub _select_date
{
	my ($self, $date) = @_;
	# Select the form
	warn 'Selecting form via mech' if DEBUG;
	$self->{mech}->form_name('spt_date');
	warn $self->{mech}->current_form->dump if DEBUG;

	my $form = $self->{mech}->current_form();

	# Disable 'readonly' attribute
	$form->find_input( 'travelDate' )->readonly(0);
	$form->find_input( 'visibleDate' )->readonly(0);

	warn 'Forcing form values' if DEBUG;
	# Force some values.  Yes, all this duplication is necessary.
	$form->force_value('theDate',     $date->ymd);
	$form->force_value('travelDate',  $date->ymd);
	$form->force_value('visibleDate', $date->month_name . ' ' . $date->day);
	$form->force_value('theTime',     '0000');

	warn 'Submitting date form' if DEBUG;
	$self->{mech}->click();

	return 1;
}

sub _select_stop
{
	my ($self, $stop_id) = @_;
	# Select a stop number
	warn 'Selecting stop form' if DEBUG;
	$self->{mech}->form_name('spt_choose560');
	warn $self->{mech}->current_form->dump if DEBUG;
	$self->{mech}->current_form->force_value('the560number', $stop_id);
	warn 'Submitting stop form' if DEBUG;
	$self->{mech}->click();

	# Confirm the stop
	warn 'Selecting stop confirm form' if DEBUG;
	if( ! defined $self->{mech}->form_name('spt_confirm560') ) {
		return 0;
	}
	warn $self->{mech}->current_form->dump if DEBUG > 1;

	$self->{stop_data}{stop_name} = $self->_extract_stop_name(
		$stop_id,
		$self->{mech}->content
	);

	warn 'Submitting stop confirm form' if DEBUG;
	$self->{mech}->click();

	return 1;
}

sub _extract_stop_name
{
	my ($self, $stop_id, $content) = @_; 
	warn "Looking for stop name in page content" if DEBUG;

	my ($name) = $content =~ m{
		Is\sthis\sthe\sright\sbus\sstop\?</div>
		\s+
		\($stop_id\)
		\s+
		([^<]+)<
	}sx;

	if( $name ) {
		$name =~ s/\s+$//;
		warn "Found name $name" if DEBUG;

		return $name;
	}

	return 'unknown';
}

sub _select_route
{
	my ($self, $route_id) = @_;
	# By now we may have data for one-route stops, but not for
	# multi-route stops.  
	# Need to parse the output and:
	# a) if it's asking for a route number, find the one we want and select
	# the appropriate checkbox
	# b) if it's not, parse the output for the stop data
	if( ! defined $self->{mech}->form_name('spt_selectRoutes') ) {
		# No route form, so it's a single-route stop
		return 1;
	}
	warn "Looking for $route_id" if DEBUG;

	my ($checkname) = $self->{mech}->content =~ m{<label for="(check\d+)">$route_id\b};

	if( !$checkname ) {
		return 0;
	}

	warn "Got checkbox name $checkname" if DEBUG;

	$self->{mech}->form_name('spt_selectRoutes');
	warn $self->{mech}->current_form->dump if DEBUG;
	$self->{mech}->current_form()->force_value($checkname, 1);
	$self->{mech}->click();

	return 1;
}

sub _parse_schedule
{
	my ($self) = @_;

	$self->{stop_data}{route_name} = $self->_extract_route_name(
		$self->{stop_data}{route_number},
		$self->{mech}->content,
	);

	my %schedule = %{ $self->{stop_data} };
	$schedule{times} = [];
	$schedule{notes} = {};

	warn $self->{mech}->content if DEBUG > 2;

	my $te = HTML::TableExtract->new( attribs => { class => 'spt_table' } );
	$te->parse( $self->{mech}->content );

	foreach my $ts ( $te->tables ) {
		warn 'Table (', join(q{,}, $ts->coords), '):' if DEBUG;
		foreach my $row ( $ts->rows ) {
			foreach my $cell ( @$row ) {
				next if ! defined $cell;
				$cell =~ s/^\s+//s;
				$cell =~ s/\s+$//s;
				$cell =~ s/\s+/ /gs;
				if( $cell =~ m/^\d+:\d+/ ) {
					push @{$schedule{'times'}}, $cell;
				}
			}
		}
	}

	warn "Now looking for stop note info" if DEBUG;

	$te = HTML::TableExtract->new( headers => [ 'Stop Note Information' ] );
	$te->parse( $self->{mech}->content ) ;

	if( $te->tables ) { 
		foreach my $row ($te->rows) {
			my ($key, $value) = split(/\s*-\s*/, $row->[0], 2);
			$schedule{notes}{$key} = $value;
		}
	}

	return \%schedule;
}

sub _extract_route_name
{
	my ($self, $route_id, $content) = @_; 
	warn "Looking for route name in page content" if DEBUG;

	my ($name) = $content =~ m{
		$route_id
		\s
		-
		\s
		([^<]+)
	}sx;

	if( $name ) {
		$name =~ s/\s+$//;
		warn "Found name $name" if DEBUG;

		return $name;
	}

	return 'unknown';
}

1;
__END__

=head1 NAME
 
WebService::OCTranspo - Access Ottawa bus schedule information from www.octranspo.com
 
=head1 SYNOPSIS
 
    use WebService::OCTranspo;
    my $oc = WebService::OCTranspo->new();

    my $schedule = $oc->schedule_for_stop({
	stop_id  => $stop,
	route_id => $route,
	date     => DateTime->now(),
    });

    print "$s->{route_number} - $s->{route_name} departing $s->{stop_name} ($s->{stop_number})\n";

    foreach my $time ( @{ $s->{times} } ) {
	print " $time\n";
    }

  
=head1 DESCRIPTION
 
This module provides access to some of the bus schedule information
available from OCTranspo -- the public transit service in Ottawa,
Ontario, Canada.
 
=head1 METHODS

=head2 new ( ) 

Creates a new WebService::OCTranspo object

=head2 schedule_for_stop ( $args )

Fetch schedule for a single route at a single stop.  Returns reference
to hash containing schedule info for that route at that stop.

B<$args> must be a hash reference containing all of:

=over 4

=item stop_id

The numeric ID of the bus stop.  This should be the "560 Code"
displayed at each stop, usually used for retrieving the bus stop
information by phone.

=item route_id

The bus route number.  Use integers only -- 'X' routes should omit the
X suffix.

=item date

A DateTime object

=back

Return hashref contains:

=over 4

=item stop_number

4-digit OC Transpo stop number

=item stop_name

Name of stop, or 'unknown' if not found

=item route_number

1 to 3 digit OC Transpo route number

=item route_name

Name of route, or 'unknown' if not found

=item times

Reference to array of scalars representing stop times in local Ottawa
time.  Time values will be in one of two formats:  C<HH:MM> for plain
times with no modifier, and C<HH:MM (X)> where X is the identifier of a
route note mentioned in the B<notes> section of the returned data.

=item notes

Reference to hash, containing note_identifier => note.

=back

This method will C<die> if the stop is not found, the route is not
found, as well as on any WWW::Mechanize or HTML::Form errors that might
be thrown.

=head1 DEPENDENCIES

L<WWW::Mechanize>, L<HTML::Form::ForceValue>, L<HTML::TableExtract>, 
L<HTTP::Status>, L<DateTime>

=head1 INCOMPATIBILITIES

There are no known incompatibilities with this module, but they
probably do exist.
 
=head1 BUGS AND LIMITATIONS

Current known issues:

=over 4

=item *

If the desired route leaves a stop in more than one direction (ie:
Transitway stations) this module will only show the first one found on
the page.  Some way of specifying direction is needed.

=item *

Stops must be specified by number, and not by name or nearest
intersection, even though the OCTranspo website allows the alternate
methods.

=item *

None of the advanced features (route planner, etc) are supported yet.

=item * 

Should implement shortcuts to specify a weekday, Saturday, or Sunday
schedule instead of requiring a DateTime object.

=back
 
Please report any new problems to the author.
Patches are welcome.
 
=head1 AUTHOR
 
Dave O'Neill (dmo@dmo.ca)
 
=head1 LICENCE AND COPYRIGHT

Copyright (C) 2007 Dave O'Neill

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
