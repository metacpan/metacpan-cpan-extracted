{#hide from metacpan
	package BackgroundJob;
	
	use strict;
	use warnings;
	use Carp;
	use base qw(Tk::AppWindow::BaseClasses::Callback);
	
	sub new {
		my $class = shift;
		my $interval = shift;
		my $self = $class->SUPER::new(@_);
		$self->{INTERVAL} = $interval;
		$self->{COUNT} = 1;
		$self->{PAUSED} = 0;
		return $self;
	}
	
	sub execute {
		my $self = shift;
		return if $self->paused;
		my $interval = $self->{INTERVAL};
		my $count = $self->{COUNT};
		if ($count eq $interval) {
			$self->SUPER::execute(@_);
			$self->{COUNT} = 1;
		} else {
			$self->{COUNT} = $count + 1
		}
	}
	
	sub paused {
		my $self = shift;
		$self->{PAUSED} = shift if @_;
		return $self->{PAUSED}
	}
}

package Tk::AppWindow::Ext::Daemons;

=head1 NAME

Tk::AppWindow::Ext::Daemons - Run background processes easily

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.04";

use base qw( Tk::AppWindow::BaseClasses::Extension );

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['Daemons'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Easily run background jobs organized neatly system wide.

=head1 CONFIG VARIABLES

=over 4

=item B<-cycleinterval>

Default value 10 miliseconds. This is the base interval for the Deamons system. 

How often a job is executed is defined by their own interval parameter. The real interval time of a job is the base interval
multiplied by the job interval.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->addPreConfig(
		-cycleinterval => ['PASSIVE', undef, undef, 10],
	);
	$self->{JOBS} = {};
	return $self;
}

=head1 METHODS

=over 4

=cut

sub cycle {
	my $self = shift;
	delete $self->{'cycle_id'};
	my $jobs = $self->_jobs;
	for (keys %$jobs) {
		my $call = $jobs->{$_};
		$call->execute;
	}
	$self->cycleStart;
}

=item B<cyleActive>

Returns true if one or more background jobs are running.

=cut

sub cycleActive {
	return exists $_[0]->{'cycle_id'}
}

=item B<cyleStart>

Starts the job cycle unless it is running already.

=cut

sub cycleStart {
	my $self = shift;
	my $cycle = $self->configGet('-cycleinterval');
	$self->{'cycle_id'} = $self->after($cycle, ['cycle', $self]) unless $self->cycleActive;
}

=item B<cyleStop>

Stops the job cycle if it is running.

=cut

sub cycleStop {
	my $self = shift;
	my $id = $self->{'cycle_id'};
	$self->afterCancel($id) if defined $id;
	delete $self->{'cycle_id'};
}

=item B<jobAdd>I<($name, $interval, @call)>

Add the job I<$name> unless it already exists.
I<$interval> specifies after how many cycles the job is executed.
For details about I<@call> see L<Tk::AppWindow::BaseClasses::Callback>.

=cut

sub jobAdd {
	my ($self, $name, $interval, @call) = @_;

	unless (defined $name) {
		croak "You must specify a name";
		return
	}
	unless (defined $interval) {
		croak "You must specify an interval";
		return
	}
	unless (@call) {
		croak "No callback defined";
		return
	}
	
	my $new = new BackgroundJob($interval, @call);
	my $jobs = $self->_jobs;
	if (exists $jobs->{$name}) {
		croak "Job $name already exists";
		return
	}
	$jobs->{$name} = $new;
	$self->cycleStart;
}

=item B<jobExists>I<($name)>

Returns true if a job I<$name> is currently running.

=cut

sub jobExists {
	my ($self, $name) = @_;
	my $jobs = $self->_jobs;
	return exists $jobs->{$name}
}

=item B<jobGet>I<($name)>

Returns the job object of I<$name>.

=cut

sub jobGet {
	my ($self, $name) = @_;
	unless (defined $name) {
		croak "You must specify a name";
		return
	}
	my $jobs = $self->_jobs;
	unless (exists $jobs->{$name}) {
		croak "Job $name does not exist";
		return
	}
	return $jobs->{$name};
}

=item B<jobList>

Returns a list of running jobs.

=cut

sub jobList {
	my $self = shift;
	my $jobs = $self->_jobs;
	return keys %$jobs
}

=item B<jobPause>I<($name)>

Pauses job I<$name>.

=cut

sub jobPause {
	my ($self, $name) = @_;
	my $job = $self->jobGet($name);
	$job->paused(1) if defined $job;
}

=item B<jobRemove>I<($name)>

Removes job I<$name>.

=cut

sub jobRemove {
	my ($self, $name) = @_;
	my $job = $self->jobGet($name);
	my $jobs = $self->_jobs;
	delete $jobs->{$name} if defined $job;
	my @list = $self->jobList;
	$self->cycleStop unless @list;
}

=item B<jobResume>I<($name)>

Resumes job I<$name>

=cut

sub jobResume {
	my ($self, $name) = @_;
	my $job = $self->jobGet($name);
	$job->paused(0) if defined $job;
}

sub _jobs {
	return $_[0]->{JOBS}
}

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

L<Tk::AppWindow>

L<Tk::AppWindow::BaseClasses::Callback>

L<Tk::AppWindow::BaseClasses::Extension>

=cut

1;





