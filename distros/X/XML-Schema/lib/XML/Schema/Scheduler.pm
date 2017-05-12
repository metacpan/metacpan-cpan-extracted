#============================================================= -*-perl-*-
#
# XML::Schema::Scheduler.pm
#
# DESCRIPTION
#   Module implementing an object class for scheduling actions around
#   an XML Schema.
#
# AUTHOR
#   Andy Wardley <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 2001 Canon Research Centre Europe Ltd.
#   All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id: Scheduler.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Scheduler;

use strict;
use base qw( XML::Schema::Base );
use vars qw( $VERSION $DEBUG $ERROR @SCHEDULES );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

# default schedule lists (can be overridden in a subclass)
@SCHEDULES = qw( before after );


#use constant TAIL => 0;
#use constant HEAD => 1;

#------------------------------------------------------------------------
# init()
#------------------------------------------------------------------------

*init_scheduler = \&init;

sub init {
    my ($self, $config) = @_;
    my ($s, $value, $schedule);
    my $class = ref $self;

    my ($schedules) = @{ $self->_baseargs( { first => 1 }, 
					   qw( @SCHEDULES ) ) };

    local $" = ', ';
    $self->DEBUG("Schedule lists for $class: [ @$schedules ]\n")
	if $DEBUG;

    foreach $s (@$schedules) {
	no strict 'refs';
	($schedule) = @{ $self->_baseargs("\@SCHEDULE_$s") };

	push(@$schedule, UNIVERSAL::isa($value, 'ARRAY') ? @$value : $value)
	    if defined ($value = $config->{"schedule_$s"});

	$self->{"_SCHEDULE_$s"} = $schedule;
	$self->DEBUG("_SCHEDULE_$s => [ @$schedule ]\n")
	    if $DEBUG;
    }
    $self->_schedule_method_factory(@$schedules);

    return $self;
}

#------------------------------------------------------------------------
# _schedule_method_factory(@methods)
#
# Iterates $m through each of the method names passed as arguments and
# installs two closures as the methods "schedule_$m" and "activate_$m"
# in the subclass package.  If the "schedule_$m" method is already
# defined then it skips this step (assumes that "activate_$m" is also
# defined but doesn't actually check).  These methods can then be used
# to schedule actions and subsequently activate them for each of the
# schedule lists defined for a subclass object.
#------------------------------------------------------------------------

sub _schedule_method_factory {
    my ($self, @methods) = @_;
    my $class = ref $self;
    foreach my $m (@methods) {
	no strict 'refs';
	if (defined &{$class . "::schedule_$m"}) {
	    $self->DEBUG("schedule_$m method already defined in $class, skipping\n")
		if $DEBUG;
	}
	else {
	    $self->DEBUG("creating schedule/action methods in $class\n")
		if $DEBUG;
	    *{$class . "::schedule_$m"} = sub { 
		my ($self, $action, $at_head) = @_;
		$at_head ||= 0;
		$self->DEBUG("schedule_$m($action, $at_head)\n")
		    if $DEBUG;
		if ($at_head) {
		    unshift(@{ $self->{"_SCHEDULE_$m"} }, $action);
		}
		else {
		    push(@{ $self->{"_SCHEDULE_$m"} }, $action);
		}
	    };
	    *{$class . "::activate_$m"} = sub { 
		my ($self, $infoset) = @_;
		$infoset = { result => $infoset } unless UNIVERSAL::isa($infoset, 'HASH');
		foreach my $action (@{ $self->{"_SCHEDULE_$m"} }) {
		    # TODO: check return value for ERROR/STOP/EXPLODE/etc
		    if (ref $action eq 'CODE') {
			$self->DEBUG("calling $action($self, $infoset)\n")
			    if $DEBUG;
			return unless defined &$action($self, $infoset);
		    }
		    elsif (ref $action eq 'ARRAY') {
			my ($object, $method, @args) = @$action;
			$self->DEBUG("calling $object->$method($self, $infoset, @args)\n")
			    if $DEBUG;
			return unless defined $object->$method($self, $infoset, @args);
		    }
		    else {
			$self->DEBUG("calling $self->$action($infoset)\n")
			    if $DEBUG;
			return unless defined $self->$action($infoset);
		    }
		}
		return $infoset;
	    };
	}
    }
}



    

1;

__END__

=head1 NAME

XML::Schema::Scheduler - schedule actions around an XML Schema

=head1 SYNOPSIS

    package XML::Schema::Attribute;
    use base qw( XML::Schema::Scheduler );

    package main;
    my $attr = XML::Schema::Attribute->new({
	name => $name,	    # object params
	type => $type,
        ...etc...
        before => $action,  # schedule params
	after  => [ $action, $action, ... ],
    };

    $attr->before();
    $attr->after();

=head1 DESCRIPTION

The XML::Schema::Scheduler module implements a base class (similar to a 
"mixin") from which other XML Schema modules can be derived.  This 
module implements the action scheduling functionality that allows 
events to be schedule before and/or after a schema validation event.

=head1 METHODS

=head2 init()

Initialiser method called automatically by the XML::Schema::Base new()
method or explicitly by the init() method of a derived object class.
This method examines the configuration hash for 'before' and/or
'after' parameters which are stored internally as the initial sets
of schedule actions.

=head2 schedule_before($action)

Add the specified $action to the 'before' schedule.

=head2 schedule_after($action)

Add the specified $action to the 'after' schedule.

=head2 before()

Run the scheduled 'before' events.  Returns a hash reference
representing the infoset generated and/or modified by the scheduled
actions.  An initial hash reference may be otherwise provided.

    $attr->before(\%infoset);

=head2 after()

Run the scheduled 'after' events.  Returns a hash reference
representing the infoset generated and/or modified by the scheduled
actions.  An initial hash reference may be otherwise provided.

    $attr->before(\%infoset);

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 VERSION

This is version $Revision: 1.1.1.1 $ of the XML::Schema::Scheduler module,
distributed with version 0.1 of the XML::Schema module set.

=head1 COPYRIGHT

Copyright (C) 2001 Canon Research Centre Europe Ltd.  All Rights
Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See also L<XML::Schema>.

