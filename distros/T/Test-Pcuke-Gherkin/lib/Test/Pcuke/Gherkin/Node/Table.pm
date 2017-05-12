package Test::Pcuke::Gherkin::Node::Table;

use warnings;
use strict;
use Carp;
use Scalar::Util qw{blessed};

use base 'Test::Pcuke::Gherkin::Node';

use Test::Pcuke::Gherkin::Node::Table::Row;

=head1 NAME

Test::Pcuke::Gherkin::Node::Table - table in Gherkin

=head1 SYNOPSIS

TODO Synopsis

    use Test::Pcuke::Gherkin::Node::Table;

    my $table = Test::Pcuke::Gherkin::Node::Table->new();


=head1 METHODS

=head2 new

=cut

sub new {
	my ($self, $args) = @_;
	
	$args->{'_nsteps'}		= {pass=>0, undef=>0, fail=>0};
	$args->{'_nscenarios'}	= {pass=>0, undef=>0, fail=>0};
	
	my $new_instance = $self->SUPER::new(
		immutables	=> [qw{executor}],
		properties	=> [qw{_nsteps _nscenarios}],
		args		=> $args,
	);
	
	if ( $args->{headings} ) {
		$new_instance->set_headings( $args->{headings} );
		if ( $args->{rows} ) {
			$new_instance->add_rows( $args->{rows} );
		}
	}
	
	
	return $new_instance;
}

sub headings { $_[0]->_get_immutable('headings') || [] }

sub set_headings {
	my ($self, $headings) = @_;
	
	if ( ref $headings ne 'ARRAY' ) {
		local $@;
		$headings = eval { [ keys %{$headings->data}] };
		
		confess "headings must be either arrayref or Table::Row"
			if $@;
	}
	
	$self->_set_immutable('headings', $headings);
}

sub add_row {
	my ($self, $row) = @_;
	
	if ( ref $row eq 'ARRAY' ) {
		$row = $self->_make_row( $row );
	}
	elsif ( blessed $row && $row->can('data') ) { # probably isa Table::Row
		$self->_set_check_headings($row); # dies if headings differ
	}
	else {
		confess "add_row takes either arrayref or Table::Row";
	}
	
	$row->set_executor( $self->_get_immutable('executor') );
	
	$self->_add_property('rows', $row);
}

sub _set_check_headings {
	my ($self, $row) = @_;
	
	my @t_heads = sort @{ $self->headings };
	
	if ( ! @t_heads ) {
		$self->set_headings( $row );
	}
	else {
		my @r_heads = sort keys %{ $row->data };
		confess "incorrect number of columns in the row"
			if @r_heads != @t_heads;
		confess "headings of a row are different from that of the table!"
			if join('', @t_heads) ne join('',@r_heads);
	}
}

sub _make_row {
	my ($self, $data) = @_;
	my ($hash, $row);
	
	my @headings = @{ $self->_get_immutable('headings') };
	$self->_no_headings_exception() unless @headings;
	
	if ( @headings == @$data ) {
		$hash = { map { shift @headings => $_ } @$data };
		$row = Test::Pcuke::Gherkin::Node::Table::Row->new();
		$row->set_data( $hash );
	}
	else {
		confess "The number of columns in the row must correspond to the number of headings";
	}
	
	return $row;
}

sub add_rows {
	my ($self, $rows) = @_;
	foreach (@$rows) {
		$self->add_row($_);
	}
}

sub rows { $_[0]->_get_property('rows') }

sub hashes {
	my ($self) = @_;
	my $result;
	
	for my $row ( @{ $self->rows } ) {
		push @$result, $row->data;
	} 
	
	return $result;
};

sub execute {
	my ($self, $steps, $background) = @_;
	
	for my $row ( @{ $self->rows } ) {
		$row->execute($steps, $background);
		$self->collect_stats( $row );
	}
}

sub collect_stats {
	my ($self, $row) = @_;
	
	my $nsteps			= $self->nsteps;
	my $nscenarios		= $self->nscenarios;
	
	my $r_nsteps		= $row->nsteps;
	my $r_nscenarios	= $row->nscenarios;
	
	for (qw{pass fail undef}) {
		$nsteps->{$_}		+= $r_nsteps->{$_};
		$nscenarios->{$_}	+= $r_nscenarios->{$_};
	}
	
	$self->_set_property('_nsteps', $nsteps);
	$self->_set_property('_nscenarios', $nscenarios);
}

sub nsteps {
	my ($self, $status) = @_;
	my $nsteps = $self->_get_property('_nsteps');
	
	return $status ?
		  $nsteps->{$status}
		: $nsteps;
}

sub nscenarios {
	my ($self, $status) = @_;
	my $nscenarios = $self->_get_property('_nscenarios');
	
	return $status ?
		  $nscenarios->{$status}
		: $nscenarios;
}


sub _no_headings_exception { confess "headings must be set before adding the rows" }


1; # End of Test::Pcuke::Gherkin::Node::Table
__END__
=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-/home/tut/bin/src/test-pcuke-gherkin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=/home/tut/bin/src/Test-Pcuke-Gherkin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::Gherkin::Node::Table


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
