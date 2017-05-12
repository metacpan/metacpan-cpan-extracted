package Time::Simple::Range;

use Time::Simple;
use Time::Seconds ();
use Carp;

use base qw/ Class::Accessor /;

__PACKAGE__->mk_accessors(qw/ start end /);

our $VERSION = '1.2'; 

use overload
	'fallback'	=> 1,
	'bool'		=> 'bool',
	'""'		=> 'stringify',
	'='		=> 'clone',
;

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = bless $proto->SUPER::new(), $class;

	my ($start, $end) = @_;

	$self->start($start);
	$self->end($end);

	return $self;
}

sub to_time_simple
{
	my ($self, $arg) = @_;

	return undef
		unless defined $arg;

	if (ref($arg)) {
		return $arg
			if $arg->isa('Time::Simple');

		return $arg->hms
			if $arg->isa('DateTime')
			or $arg->isa('Time::Piece');

		$arg = Time::Simple->new($arg->time(0))
			if $arg->isa('Date::Calc::Object')
			and $arg->is_long
			and $arg->is_valid;
	}

	return Time::Simple->new($arg);
}

sub start
{
	my ($self, $arg) = @_;

	return $self->_start_accessor
		unless defined $arg;

	$arg = $self->to_time_simple($arg)
		or croak('invalid start time: ', $arg);

	return $self->_start_accessor($arg);
}

sub end
{
	my ($self, $arg) = @_;

	return $self->_end_accessor
		unless defined $arg;

	$arg = $self->to_time_simple($arg)
		or croak('invalid end time: ', $arg);

	return $self->_end_accessor($arg);
}
		

sub duration
{
	my $self = shift;

	return 0
		unless defined $self->start
		and defined $self->end;

	return Time::Seconds->new($self->end - $self->start);
}

sub minutes
{
	my $self = shift;

	return 0
		unless defined $self->start
		and defined $self->end;

        return $self->duration->minutes;
}

sub bool
{
	my $self = shift;
	return (defined $self->start && defined $self->end);
}

sub stringify
{
	my $self = shift;

	if ($self) {
		return $self->start . '-' . $self->end;
	} else {
		return 'incomplete range';
	}
}

sub clone
{
	my $self = shift;

	return new Time::Simple::Range(
		new Time::Simple($self->start),
		new Time::Simple($self->end));
}

1;

=head1 NAME

Time::Simple::Range - A range of Time::Simple objects

=head1 SYNOPSIS

 use Time::Simple::Range;

 my $range = new Time::Simple::Range('14:00:00', '15:00:00');

 print $range->start, "\n";
 print $range->end, "\n";
 print $range->duration, "\n";

=head1 DESCRIPTION

A range of Time::Simple objects

=head1 SEE ALSO

Time::Simple, Time::Seconds

=head1 AUTHOR

Alessandro Zummo, E<lt>a.zummo@towertech.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-09 by Alessandro Zummo

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.

=cut
