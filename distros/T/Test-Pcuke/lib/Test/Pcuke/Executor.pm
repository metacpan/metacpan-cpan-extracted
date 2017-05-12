package Test::Pcuke::Executor;

use warnings;
use strict;

use Carp;
use Encode qw{decode};

use Test::Pcuke::World;
use Test::Pcuke::Executor::Status;

{
	my $self; # this is a singleton
	
=head1 NAME

Test::Pcuke::StepRunner - Runner of the steps.

=head1 METHODS

=head2 new

	Returns singleton object

=cut

	sub new {
		my ($class, $encoding) = @_;
	
		$self ||= bless ( { 
			_step_definitions	=> {},
			_encoding			=> $encoding, 
		}, $class );
	
		$self->set_world();
	
		return $self;
	}
	
=head2 destroy

Destroys the singleton so that the next new() creates another object

=cut

	sub destroy { undef $self }
}

=head2 add_definition %definition

Adds a step definition. Keys of the %definition are:

=over

=item step_type
One of 'GIVEN', 'WHEN', 'THEN', 'AND', 'BUT', '*'

=item regexp
A regular expression against that the step title should match

=item coderef
A reference to the code which should be executed if the
title of the step matches the regexp

=back

=cut	
	
sub add_definition {
	my $self = shift;
	my %args = @_;
	my %def;
	
	my @known_keys = qw{step_type regexp code};
	
	@def{ @known_keys } = @args{ @known_keys };
	
	$def{step_type} =  $def{step_type} ?
		  uc $def{step_type}
		: q{};
	
	confess 'Incorrect step type. Must be GIVEN|WHEN|THEN|AND'
		unless grep { $_ eq $def{step_type} } qw{GIVEN WHEN THEN AND BUT *};

	confess 'Regexp required'
		unless $def{regexp};
	
	$def{regexp} = decode($self->{_encoding}, $def{regexp})
		if $self->{_encoding};
	
	$def{code} ||= \&_nop;
	
	$self->{_step_definitions}->{ $def{regexp} } = $def{code};
}

=head2 execute $step

Executes the step. Finds the first definition to whose regexp the step title match,
then calls code of that definition passing to it three arguments

=over

=item $world
Test::Pcuke::World, the object, which is the same for any step inside a scenario

=item $text
A multiline text associated with the step in *.feature file

=item $table
A Test::Pcuke::Gherkin::Node::Table object for the table associated with the step in 
the *.feature file

=back 

Returns Test::Pcuke::Executor::Status object with the status of the execution, which
is 'undef' if no suitable definition is found.

=cut

sub execute {
	my ($self, $step) = @_;
	my $title = $step->title;
	
	my ($status, $exception) = ('undef', undef);
	
	foreach( keys %{ $self->{_step_definitions} } ) {
		if ( $title =~ $_ ) {
			$exception = $self->_try_definition($_, $step);
			$status = $exception ? 'fail' : 'pass'; 
			last;
		}
	}
	
	return Test::Pcuke::Executor::Status->new($status, $exception);
}

sub _try_definition {
	my ($self, $key, $step) = @_;
	
	my $exception;
		
	local $@;
	eval {
		$self->{_step_definitions}->{$key}->($self->world, $step->text, $step->table);
	};
	
	$exception = $@;
	
	if ( my $class = ref $exception ) {
		die $exception
			if $class ne 'Test::Pcuke::Executor::StepFailure';
	}
	
	return $exception;
}

=head2 reset_world

This method resets the $world object that is passed to step definition

=cut
sub reset_world { $_[0]->set_world }

=head2 set_world $world?
 
Set the new world

=cut

sub set_world {
	my ($self, $new_world) = @_;
	
	$self->{_world} = $new_world ?
		  $new_world
		: Test::Pcuke::World->new;	
}

=head2 world

Returns the current world object that is passed to step definitions

=cut

sub world { $_[0]->{_world} }


sub _nop { }

1; # End of Test::Pcuke::StepRunner
__END__
=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-pcuke at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Pcuke>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::StepRunner


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Pcuke>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Pcuke>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Pcuke>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Pcuke/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Andrei V. Toutoukine.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


