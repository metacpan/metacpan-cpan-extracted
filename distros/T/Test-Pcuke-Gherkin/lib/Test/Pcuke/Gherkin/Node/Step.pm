package Test::Pcuke::Gherkin::Node::Step;

use warnings;
use strict;

use base 'Test::Pcuke::Gherkin::Node';

use Carp;
use Test::Pcuke::Gherkin::Executor::Status;

=head1 NAME

Test::Pcuke::Gherkin::Node::Step - Step of the scenario of the feature

=head1 SYNOPSIS

	This module is used internally by L<Test::Pcuke::Gherkin>
	 
=head1 METHODS

=head2 new $conf

Creates new step. $conf is a hashref that may contain
the settings for the object. Without $conf the corresponding properties are
unset. The keys of hashref are

=over

=item type
	Type of the step: 'Given', 'when', 'then', 'and', 'but', '*'
	 
=item title
	Title of the step (probably without the type)

=item text
	Multiline text associated with the step 

=item table
	Table associated with the step

=item executor
	Executor object, see L<Test::Pcuke::Gherkin>

=back

=cut

sub new {
	my ($self, $args) = @_;
	
	my $new_step = $self->SUPER::new(
		immutables	=> [qw{type title text table executor}],
		args		=> $args,
	);
	
	return $new_step;
	
}

=head2 type

Returns the type of the step

=cut

sub type { $_[0]->_get_immutable('type') || q{}; }

=head2 set_type $type

Sets the type of the step. Type is an immutable property
and may be set only once. Trying to set it more than once
is a fatal error

=cut

sub set_type {
	my ($self, $type) = @_;
	$self->_set_immutable('type', $self->_normalize_type($type));
}

# TODO I18n ????
sub _normalize_type {
	my ($self, $type) = @_;
	$type = uc $type;
	confess q{The type of the step must be one of 'GIVEN',WHEN','THEN','AND', 'BUT', '*'}
		unless grep { $_ eq $type } qw{GIVEN WHEN THEN AND BUT *};
	return $type;	
}


=head2 title

Returns the title of the step. If the step is parametrized,
i.e. the original title contails placeholders in angle brackets
(Scenario Outline steps), they are replaced with the step parameters
if those are set.

=cut

sub title {
	my $self = shift;
	my $title = $self->_get_immutable('title');
	
	return q{} unless $title;
	
	my $params = $self->_get_property('_step_parameters');
	
	return $title unless $params;
	
	foreach my $p (keys %$params) {
		my $v = $params->{$p};
		$title =~ s/<$p>/"$v"/g;
	} 
	
	return $title;
}

=head2 set_title $title

Sets the title. Title is an immutable property.

=cut

sub set_title { $_[0]->_set_immutable('title', $_[1]); }

=head2 set_text

Sets the text. Text is an immutable property

=cut

sub set_text {
	my ($self, $text) = @_;
	$self->_set_immutable('text', $text);
}

=head2

Returns the text associated with the step.

=cut

sub text { $_[0]->_get_immutable('text') }

=head2

Returns the table associated with the step

=cut

sub table { $_[0]->_get_immutable('table') }

=head2 set_table

Returns the tyable associated with the text

=cut

sub set_table {
	my($self, $table) = @_;
	$self->_set_immutable('table', $table );
}

=head2 set_params $hash

Sets the step parameters which are used to replace the
placeholders in the title if any. For example,
if the title is 'm = <m>' the hash is {m => 'MMM'}
then the title() returns 'm = "MMM"'

Note: this method is used in execute() and probably
should be private. Don't use it %-)

=cut

sub set_params {
	my ($self, $hash) = @_;
	confess "parameters must be a hash!"
		unless ref $hash eq 'HASH';
		
	$self->_set_property('_step_parameters', $hash );
}

=head2 ubset_params

Unsets params that are set by set_params. 

Must be private, don't use

=cut

sub unset_params {
	my ($self) = @_;
	$self->_set_property('_step_parameters', undef);
}

=head2 param_names

returns the names of the placeholders in the title
If title is ' <m> = <n>' then returns ['m', 'n']
or ['n', 'm']

Must be private?

=cut

sub param_names {
	my $self = shift;
	my %params = map { $_ => 1 } ( $self->_get_immutable('title') =~ /<([^>]+)>/g );
	return [ keys %params ];
}

=head2 executor

Returns the executor object. See L<Test::Pcuke::Gherkin>

=cut

sub executor { $_[0]->_get_immutable('executor') }

=head2 execute

Executes the step.

=cut

sub execute {
	my ($self) = @_;
	
	my $result = $self->executor->execute( $self );
	
	$self->_set_result($result);

}

sub _set_result {
	my ($self, $result) = @_;
	
	$result = $self->_make_result_object($result)
		unless ref $result;
	
	$self->_set_property('_result', $result);
}

sub _make_result_object {
	my ($self, $result) = @_;
	
	my $normalized = 'undef';
	
	if ( defined $result ) {
		$normalized = 'pass'
			if $result =~ /pass/ || $result;
		$normalized = 'fail'
			if $result =~ /fail/ || ! $result;
		$normalized = 'undef'
			if $result =~ /undef/;
	}
	
	return Test::Pcuke::Gherkin::Executor::Status->new($normalized);
}

=head2 result

Returns a result object. If the executor returns a string, then
L<Test::Pcuke::Gherkin::Executor::Status> object is created
with the normalized status which is one of 'pass', 'undef', or 'fail'

=cut

sub result { $_[0]->_get_property('_result') }

=head2 status

Returns the status of the sexecuted step. The result object that is returned 
by executor->execute is asked for that.
 
=cut

sub status {
	my ($self) = @_;
	return $self->result->status || 'undef';
}


1; # End of Test::Pcuke::Gherkin::Node::Step
__END__
=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-/home/tut/bin/src/test-pcuke-gherkin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=/home/tut/bin/src/Test-Pcuke-Gherkin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::Gherkin::Node::Step


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

