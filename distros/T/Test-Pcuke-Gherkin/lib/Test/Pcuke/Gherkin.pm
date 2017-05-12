package Test::Pcuke::Gherkin;

use warnings;
use strict;

use Test::Pcuke::Gherkin::Parser;
use Test::Pcuke::Gherkin::Lexer;

=head1 NAME

Test::Pcuke::Gherkin - roll your own cucumber

=head1 VERSION

Version 0.000001

=cut

our $VERSION = '0.000003';


=head1 SYNOPSIS

This module compiles text in Gherkin to the executable AST. If you don't like
L<Test::Pcuke> you can roll your own BDD cucumber-like tool!   

    use Test::Pcuke::Gherkin;

    my $feature = Test::Pcuke::Gherkin->compile($content, $executor);
    
    $feature->execute;
    ...


=head1 METHODS

=head2 compile $content, $executor

I<$content> is a text in Gherkin language. It should be decoded string,
not octets, especially if the text is written in language other than english

I<$executor> is (optional) object, that has execute() method.
If I<$executor> is not provided an internal and useless one is used to execute
the steps. See 'ON EXECUTORS' below;

Returns L<Test::Pcuke::Gherkin::Node::Feature> object (feature object)
=cut

sub compile {
	my ($self, $content, $executor) = @_;
	
	my $tokens = Test::Pcuke::Gherkin::Lexer->scan( $content );

	my $parser = Test::Pcuke::Gherkin::Parser->new( { executor => $executor } );
	
	return $parser->parse( $tokens );  
	
}

1; # End of Test::Pcuke::Gherkin
__END__

=head1 ON EXECUTORS

Executor that passed to the compile() method is an object whose behaviour depends on
your goals. It should have execute() method which accepts L<Test::Pcuke::Gherkin::Node::Step>
object so that it can do something with the step. For example:

	package Local::MyExecutor;
	
	sub execute {
		my ($self, $step) = @_;
		
		print $step->title;
		
		return 'undef';
	}
	
	1;

I<execute()> method is expected to return a status, which can be either a I<status string> or an object.
in the latter case the object is expected to have I<status()> method which return a I<status string>.

The meaning of the status string is:

=over

=item undef, 'undef', 'undefined' ( generally $status_string =~ /undef/ )
	The step is undefined

=item 0, q{}, 'fail', 'failure' (generally $status_string =~ /fail/ )
	The step execution is failed

=item 1, 'true string', 999, 'pass' (generally  $status_string =~ /pass/ )
	The step is passed
	
=back

If no executor is provided a dumb default is used. It says that all steps are undefined and
warns on each step that the executor does nothing with the step $step->title.

=head1 SEE ALSO

=over

=item L<Test::Pcuke> cucumber for Perl 5

=item L<https://github.com/cucumber/cucumber/wiki/> cucumber Wiki

=back



=head1 AUTHOR

"Andrei V. Toutoukine", C<< <"tut at isuct.ru"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-pcuke-gherkin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Pcuke-Gherkin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::Gherkin


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Pcuke-Gherkin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Pcuke-Gherkin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Pcuke-Gherkin>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Pcuke-Gherkin/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 "Andrei V. Toutoukine".

This program is released under the following license: artistic


=cut


