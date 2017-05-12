package Test::Pcuke::StepDefinition;

use warnings;
use strict;

use Carp;

use Test::Pcuke::Executor;
use Test::Pcuke::Executor::StepFailure;
use Test::Pcuke::Expectation;

use base 'Exporter';

our @EXPORT = qw{Given When Then And But expect};

our $_executor;

=head1 NAME

Test::Pcuke::StepDefinition - Provides the commands for steps' definitions

=head1 SYNOPSIS

This module is used to define steps. If you are L<pcuke> user
then you probably want save your step definitions to
<your project>/features/step_definitions/steps.pm. Content
of that file could look like this:

	package steps;
	use utf8;		# for i18n-zed regexps
	use warnings;
	use strict;
	
	use Test::Pcuke::StepDefinition;
	
	Given qr{^a calculator instance$} => sub {
    	my ($world, $text, $table) = @_;
        $world->{_calculator} = Local::Adder->new;
	};
	
	Given qr{^I have entered "([^"]+)" into the calculator} => sub {
		my ($world, $text, $table) = @_;
		push @{ $world->{_arguments} }, $1;
	};

	When qr{^I press "([^"]+)"$} => sub {
		my ($world, $text, $table) = @_;
		my ($a1, $a2) = @{ $world->{_arguments} };
		$world->{_result} = $world->{_calculator}->add( $a1, $a2 );
	};

	Then qr{^the result should be "([^"]+)" on the screen$} => sub {
		my ($world, $text, $table) = @_;
		expect( $world->{_result} )->equals($1);
	};
	
	1; # Do not forget this number. pcuke uses require

Note that if you can use native language in *.feature file
you can't currently use native language for Given, When etc.


=head1 EXPORT

Given, When, Then, And, But

=head1 SUBROUTINES

=head2 Given $regexp $coderef

Synonym of the add_step.

=cut

sub Given ($$) {
	my ($regexp, $coderef) = @_;
	add_step('GIVEN', $regexp, $coderef);
}

=head2 When $regexp $coderef

Synonym of the add_step.

=cut

sub When ($$) {
	add_step('WHEN',@_);
}

=head2 Then $regexp $coderef

Synonym of the add_step.

=cut

sub Then ($$) {
	add_step('THEN',@_)
}

=head2 And $regexp $coderef

Synonym of the add_step.

=cut

sub And ($$) {
	add_step('AND',@_)
}

=head2 But $regexp $coderef

Synonym of the add_step.

=cut

sub But ($$) {
	add_step('BUT',@_)
}

=head2 add_step $regexp, $coderef

Add a definition for a step whose title match $regexp.

See L<Test::Pcuke::Executor>->add_definition().

=cut

sub add_step {
	my ($type, $regexp, $coderef) = @_;
	
	$_executor ||= Test::Pcuke::Executor->new();
	$_executor->add_definition(
		step_type	=> $type,
		regexp		=> $regexp,
		code		=> $coderef,
	);
}

=head2 expect $object

Return L<Test::Pcuke::Expectation> object. Use it for tests in step definitions 

=cut

sub expect {
	my ($object) = @_;
	return Test::Pcuke::Expectation->new($object, {throw => 'Test::Pcuke::Executor::StepFailure'});
}

1; # End of Test::Pcuke::StepDefinition
__END__
=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-pcuke at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Pcuke>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::StepDefinition


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


