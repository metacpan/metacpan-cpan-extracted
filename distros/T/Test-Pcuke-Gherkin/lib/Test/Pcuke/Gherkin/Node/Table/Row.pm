package Test::Pcuke::Gherkin::Node::Table::Row;
use warnings;
use strict;

use base 'Test::Pcuke::Gherkin::Node';

use Carp;

=head1 NAME

Test::Pcuke::Gherkin::Node::Table::Row - row of the table wrapper object

=head1 SYNOPSIS

TODO SYNOPSIS

    use Test::Pcuke::Gherkin::Node::Table::Row;

    my $row = Test::Pcuke::Gherkin::Node::Table::Row->new();
    # TODO code example

=head1 METHODS

=head2 new

=cut

sub new {
	my ($class, $args) = @_;
	
	$args->{'_nsteps'}		= {pass=>0, fail=>0, undef=>0};
	$args->{'_nscenarios'}	= {pass=>0, fail=>0, undef=>0};
	
	my $instance = $class->SUPER::new(
		immutables	=> [qw{data executor}],
		properties	=> [qw{_nsteps _nscenarios}],
		args		=> $args
	);
	
	return $instance;
}

sub set_data {
	my ($self, $hash) = @_;
	$self->_set_immutable('data', $hash);
}

sub data { $_[0]->_get_immutable('data') }

sub nsteps {
	my ($self, $status) = @_;
	my $nsteps = $self->_get_property('_nsteps');
	
	return $status ? 
		  $nsteps->{$status}
		: $nsteps;
}

sub nscenarios {
	my ($self, $status) = @_;
	
	my $nscenarios;
	
	if ( $self->nsteps('fail') > 0 ) {
		$nscenarios = {fail => 1, pass => 0, undef => 0};
	}
	elsif ( $self->nsteps('undef') > 0 ) {
		$nscenarios = {fail => 0, pass => 0, undef => 1};
	}
	else {
		$nscenarios = {fail => 0, pass => 1, undef => 0};
	}
	
	return $status ? 
		  $nscenarios->{$status}
		: $nscenarios;
}

sub set_executor { $_[0]->_set_immutable('executor', $_[1] ) }
sub executor { $_[0]->_get_immutable('executor') }

sub execute {
	my ($self, $steps, $background) = @_;
	my $status;
	
	if ( $self->executor && $self->executor->can('reset_world') ) {
		$self->executor->reset_world;
	}
	
	if ($background) {
		$background->execute;
		$self->collect_stats($background);
	}
	
	foreach my $s ( @$steps ) {
		$s->set_params( $self->data );
		
		$s->execute();
		$self->collect_stats( $s );
		
		# TODO move this to collect_stats
		for ( @{ $s->param_names } ) {
			push @{ $status->{$_}->{status} },		$s->status;
		}
		
		$s->unset_params;
	}
	
	$self->_set_status($status);

}

sub collect_stats {
	my ($self, $step) = @_;
	
	my $nsteps = $self->nsteps;
	
	if ( $step->can('nsteps') ) {
		#background
		my $bg_nsteps = $step->nsteps;
		for (qw{pass fail undef}) {
			$nsteps->{$_} += $bg_nsteps->{$_};
		}
	}
	else {
		#step
		$nsteps->{ $step->status }++;
	}
	
	$self->_set_property('_nsteps', $nsteps);
}

sub _set_status {
	my ($self, $status) = @_;
	my $final_status;
	my $exceptions;
	
	for my $p ( keys %$status ) {
		for my $s ( @{ $status->{$p}->{status} } ) {
			if ( ! $final_status->{$p} ) {
				$final_status->{$p} = $s;
			}
			else {
				$final_status->{$p} = $s 	if $s eq 'undef' && $final_status->{$p} eq 'pass';
				$final_status->{$p} = $s	if $s eq 'fail';
				last						if $s eq 'fail';
			}
		}
	}
	
	$self->_set_property('status', $final_status);
}

sub status { $_[0]->_get_property('status') }

sub column_status {
	my ($self, $param_name) = @_;
	my $status = $self->status;
	
	return $status->{$param_name};
}


1; # End of Test::Pcuke::Gherkin::Node::Table::Row
__END__
=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-/home/tut/bin/src/test-pcuke-gherkin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=/home/tut/bin/src/Test-Pcuke-Gherkin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::Gherkin::Node::Table::Row


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=/home/tut/bin/src/Test-Pcuke-Gherkin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist//home/tut/bin/src/Test-Pcuke-Gherkin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d//home/tut/bin/src/Test-Pcuke-Gherkin>

=item * Search CPAN

L<http://search.cpan.org/dist//home/tut/bin/src/Test-Pcuke-Gherkin/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Andrei V. Toutoukine.

This program is released under the following license: artistic


=cut
