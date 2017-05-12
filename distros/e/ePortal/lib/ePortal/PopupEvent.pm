#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#
#----------------------------------------------------------------------------


package ePortal::PopupEvent;
	use base qw/ePortal::ThePersistent::Support/;
    our $VERSION = '4.5';

	use ePortal::Global;



############################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{Attributes}{id} ||= {};
    $p{Attributes}{event_time} ||= {
            label => 'Дата/время наступления события (план)',
            dtype => 'DateTime',
        };
    $p{Attributes}{username} ||= {
        label => 'Автор (хозяин) события (если есть)',
        maxlength => 64,
        };
    $p{Attributes}{originator} ||= {
        label => 'Объект ePortal, инициатор события',
        description => 'ePortal::Package:ID',
        maxlength => 80,
        };
    $p{Attributes}{instance} ||= {
        label => 'Every originator may have a number of instances',
        maxlength => 64,
        };
    $p{Attributes}{memo} ||= {};

    $self->SUPER::initialize(%p);
}##initialize



############################################################################
sub restore_where	{	#12/24/01 4:02
############################################################################
    my ($self, %p) = @_;

	if (exists $p{originator} and ref $p{originator}) {
        $self->add_where( \%p, '(originator=?)', ref($p{originator}) . ':' . $p{originator}->id);
		delete $p{originator};
	}

	if ($p{unsent}) {
		# past events and next events in 2.5 minutes (refresh is once a 5 min)
        my $half_of_refresh_interval = int($ePortal->refresh_interval / 2);
        $self->add_where( \%p, "event_time <= date_add(now(), interval $half_of_refresh_interval second)");
		delete $p{unsent};
    }

	$p{order_by} = 'event_time DESC' if not defined $p{order_by};

	$self->SUPER::restore_where(%p);
}##restore_where



# ------------------------------------------------------------------------
package ePortal::PopupEvent::CalendarEvent;
	use base qw/ePortal::PopupEvent/;
    our $VERSION = '4.5';

	use ePortal::Global;

############################################################################
# Function: new
# Parameters: Calendar object
############################################################################
sub new	{	#01/22/02 2:32
############################################################################
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $calendar = shift;

	# inherited contructor
    my $self = $class->SUPER::new(Table => 'PopupEvent');

	# store reference to calendar object for future use
	$self->{calendar} = $calendar;

	# try to find an object
	if ( ref($calendar) ) {
		$self->restore_where(originator => $calendar);
		$self->clear if ! $self->restore_next;
		$self->initialize_from_calendar;
	}

	return $self;
}##new


############################################################################
sub initialize_from_calendar	{	#01/22/02 2:35
############################################################################
	my $self = shift;
	my $calendar = $self->{calendar};

	if (ref($calendar)) {
		$self->originator( ref($calendar) . ':' . $calendar->id );
		$self->event_time( $calendar->datestart );
        $self->username( $calendar->parent->uid );
        $self->memo( '[' . $calendar->datestart . '] ' . $calendar->title );
	}
}##initialize_from_calendar


1;

