package Time::Checkpoint::Sequential;
# ABSTRACT: Report timing between checkpoints in code
use strict;
use warnings;

our $VERSION = '0.002';

=head1 NAME

Time::Checkpoint::Sequential - record time taken between points in code

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use Time::Checkpoint::Sequential;
 my $checkpoint = Time::Checkpoint::Sequential->new(report_on_destroy => 0);
 slow_operation();
 $checkpoint->mark('Perform some operation');
 another_operation();
 $checkpoint->mark('Do something else');
 $checkpoint->report(sub { warn " Timing info: @_\n"; });

=head1 DESCRIPTION

=cut

use Time::HiRes ();
use List::Util ();

=head1 METHODS

=cut

=head2 new

Instantiate the object.

Accepts the following named parameter: 

=over 4

=item * report_on_destroy - if true, will call L</report> when destroyed, default is true

=back

=cut

sub new {
	my $class = shift;
	my %args = @_;
	bless {
		report_on_destroy => 1,
		items => [],
		'last' => Time::HiRes::time,
		maxlen => 0,
		%args,
	}, $class;
}

=head2 mark

Records this event. Takes a scalar which will be used as the name for this event.

=cut

sub mark {
	my $self = shift;
	my $name = shift;
	my $now = Time::HiRes::time;

# Record name and number of milliseconds since last event
	push @{$self->{items}}, [ $name, 1000.0 * ($now - $self->{last}) ];
	$self->{maxlen} = List::Util::max(length($name), $self->{maxlen});
	$self->{last} = $now;
	return $self;
}

=head2 reset_timer

Updates the timer so that the next recorded event will be from now, rather than the last time.

=cut

sub reset_timer {
	my $self = shift;
	my $now = Time::HiRes::time;
	$self->{last} = $now;
	return $self;
}

=head2 report

Generates a report. Pass a code ref to customise the output (will be called for each item and then a final
time for the total).

=cut

sub report {
	my $self = shift;
	my $code = shift || sub { print STDERR " @_\n"; };

	my $l = $self->{maxlen};
	my $total = 0;
	foreach my $item (@{$self->{items}}) {
		$code->(sprintf "%-$l.${l}s %9.3fms", @$item);
		$total += $item->[1];
	}
	$code->(sprintf "%-$l.${l}s %9.3fms", "Total:", $total);
}

=head2 DESTROY

Shows report when this object goes out of scope, unless disabled in the constructor.

=cut

sub DESTROY {
	my $self = shift;
	$self->report if $self->{report_on_destroy};
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Time::Checkpoint> which does almost the same as this but not quite in the way I wanted.

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.