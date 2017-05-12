package Xacobeo::Timer;

=encoding utf8

=head1 NAME

Xacobeo::Timer - A custom made timer.

=head1 SYNOPSIS

	use Xacobeo::Timer;
	
	# As a one time use
	my $timer = Xacobeo::Timer->start("Long operation");
	do_long_operation();
	$timer->elapsed(); # Displays the time elapsed
	
	# A simple stop watch (the destructor displays the time elapsed)
	my $TIMER = Xacobeo::Timer->new("Method calls");
	sub hotspot {
		$TIMER->start();
		# Very slow stuff here
		$TIMER->stop();
	}

=head1 DESCRIPTION

This package provides a very simple timer. This timer is used for finding hot
spots in the application.

The timer is quite simple it provides the method L</start> that starts the timer
and the method L</stop> that stops the timer and accumulates the elapsed time.
The method L</show> can be used to print the time elapsed so far while the
method L</elapsed> returns the time elapsed so far.

When an instance of this class dies (because it was undefed or collected by the
garbage collector) the builtin Perl desctrutor will automatically call the
method L</show>. But if the method I<show> or I<elapsed> was called during the
lifetime of the instance then the destructor will not invoke the method I<show>.

=head1 METHODS

The package defines the following methods:

=cut

use 5.006;
use strict;
use warnings;

use Time::HiRes qw(time);

use Xacobeo::I18n qw(__);


=head2 new

Creates a new Timer.

Parameters:

=over

=item * $name (Optional)

The name of the timer.

=back

=cut

sub new {
	my ($class, $name) = @_;

	my $self = {
		elapsed   => 0,
		name      => $name,
	};

	bless $self, ref($class) || $class;

	return $self;
}



=head2 start

Starts the timer. If this sub is called without a blessed instance then a new
Timer will be created.

Parameters:

=over

=item * $name (optional)

The name is used only when called without a blessed instance.

=back

=cut

sub start {
	my ($self, @params) = @_;
	if (!ref $self) {
		$self = $self->new(@params);
	}

	$self->{start} = time;
	return $self;
}



=head2 stop

Stops the timer and adds accumulates the elapsed time. If the timer wasn't
started previously this results in a no-op.

=cut

sub stop {
	my $self = shift;

	my $start = delete $self->{start};
	if (defined $start) {
		$self->{elapsed} += time - $start;
	}

	return $self;
}



=head2 show

Prints the elapsed time. This method stops the timer if it was started
previously and wasn't stopped.

=cut

sub show {
	my $self = shift;

	if ($self->{start}) {
		$self->stop();
	}

	my $name = $self->{name};
	printf __("Time: %-20s %.4fs\n"),
		(defined $name ? $name : __('Unnamed')),
		$self->elapsed
	;

	return $self;
}



=head2 elapsed

Returns the total time elapsed so far. If the timer was already started the
pending time will not be taking into account.

=cut

sub elapsed {
	my $self = shift;
	$self->{displayed} = 1;
	return $self->{elapsed};
}


sub DESTROY {
	my $self = shift;
	$self->show() unless $self->{displayed};
	return;
}


# A true value
1;


=head1 AUTHORS

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008,2009 by Emmanuel Rodriguez.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

