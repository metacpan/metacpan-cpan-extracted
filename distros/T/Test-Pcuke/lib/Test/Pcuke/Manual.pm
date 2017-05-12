package Test::Pcuke::Manual;

=head1 NAME

Test::Pcuke::Manual - is a proto manual for Test::Pcuke package.

=head1 CUCUMBER

Cucumber is a behaviour-driven development tool that allows you to define
and execute software acceptance tests. The tests themselves are written in
pretty plain (your) native language. This plain native language is called Gherkin.

For example, if your native language is German (aka Deutsch), then Gherkin
looks like this:

	# language: de
	Funktionalität: Addition
	
		Um dumme Fehler zu vermeiden
		möchte ich als Matheidiot
		die Summe zweier Zahlen gesagt bekommen

	Grundlage: der Taschenrechner
		Angenommen der Taschenrechner instance 
		
 	Szenariogrundriss: Zwei Zahlen hinzufügen
		Angenommen ich habe <Eingabe_1> in den Taschenrechner eingegeben
		Und ich habe <Eingabe_2> in den Taschenrechner eingegeben
		Wenn ich <Knopf> drücke
		Dann sollte das Ergebniss auf dem Bildschirm <Ausgabe> sein

		Beispiele:
			| Eingabe_1 | Eingabe_2 | Knopf | Ausgabe |
			| 20        | 30        | add   | 50      |
 			| 2         | 5         | add   | 7       |
 			| 0         | 40        | add   | 40      |

English speaker would prefer the following Gherkin:

	# language: en
	Feature: Addition
	
		In order to avoid silly mistakes
		As a math idiot 
		I want to be told the sum of two numbers

		Background: calculator
			Given a calculator instance
		
		Scenario Outline: Add two numbers
			Given I have entered <input_1> into the calculator
			And I have entered <input_2> into the calculator
			When I press <button>
			Then the result should be <output> on the screen

			Examples:
    		  | input_1 | input_2 | button | output |
 		   	  | 20      | 30      | add    | 50     |
    		  | 2       | 5       | add    | 7      |
	    	  | 0       | 40      | add    | 40     |

These examples express some expectations of the I<customer> on the software being developed
by the I<developer>. Both are expected to write these Gherkin texts together. Then the
developer provides I<definitions> which turn each such a text into a set of acceptance tests.
Then I<cucumber> tool reads these defenitions and executes Gherkin files one by one reporting
on failures and success.

Original cucumber tool is developed using Ruby language and does not support Perl. That's 
why...

=head1 PCUKE

For example we develop a Local::Adder module that adds one number to the other. As a developers
we sit down with the customer and write down the texts shown above. Let's consider the english
example line by line.

=head2 Gherkin explained

	# language: en

The first line is a pragma. Pragmas tell something important to the B<pcuke> parser.
Here we say that we use English for Gherkin statements. Note that English is a default
language and this line is not required.

	Feature: Addition

This statement names the piece of functionality that is described in the file. "Feature:"
is a I<keyword>, "Addition" is a I<title> that best describes the functionality. There should
be exactly one I<Feature> statement per Gherkin file.
	
	In order to avoid silly mistakes
	As a math idiot 
	I want to be told the sum of two numbers

This is an optional narrative that describes in detail what feature title says in short.
It is for human consuption only.

	Background: calculator

This keyword declares steps that should be executed before each scenario. 

	Given a calculator instance

This is a precondition common to all scenarios.
		
	Scenario Outline: Add two numbers

This statement declares the template for scenarios. "Scenario Outline:" is a I<keyword>
while "Add two numbers" is a I<title>. Each scenario consists of steps that have names
"Given", "When" and  "Then". These steps describe preconditions, events and
expected results respectively. There are steps with the special names "And" and
"But". These steps extend the previous "Given", "When", or "Then" step.

	Given I have entered <input_1> into the calculator

The first step describes precondition: I enter a parameter, named "input_1"
into the calculator. 

	And I have entered <input_2> into the calculator

The second step adds another precondition, I enter a value of a parameter named "input_2".

	When I press <button>

The third step describes an event, that I press something named <button>

	Then the result should be <output> on the screen

The last step describes the expected behaviour: result should be the same as the value
of the parameter <output>

	Examples:

This keyword declares a usage of the scenario template. It has no title. Below a table is given.
The first row contains headings of the columns that must correspond to the names of the parameters
in the step titles of the scenario outline.

The rows from second on describe one scenario each:

    | input_1 | input_2 | button | output |
    | 20      | 30      | add    | 50     |
   
This row corresponds to the scenario with the following steps:
 
	Given I have entered "20" into the calculator
	And I have entered "30" into the calculator
	When I press "add"
	Then the result should be "50" on the screen

Each of the following rows describe two more scenarios:
 
   | 2       | 5       | add    | 7      |
   | 0       | 40      | add    | 40     |


Put this Gherkin text into <your calculator project root>/features/addition.feature file
(copy and paste from the CUCUMBER section above!). Now you can launch B<pcuke> from the
<your calculator project root>. The output should look like:

	localhost:~/src/<your calculator project root>$ pcuke 
	Feature: Addition

        In order to avoid silly mistakes
    	As a math idiot
        I want to be told the sum of two numbers

    Scenario Outline: Add two numbers
      Given I have entered <input_1> into the calculator
      And I have entered <input_2> into the calculator
      When I press <button>
      Then the result should be <output> on the screen

    Examples:
      | input_1 | input_2 | button | output |
      |      20 |      30 |    add |     50 |
      |       2 |       5 |    add |      7 |
      |       0 |      40 |    add |     40 |
    

	3 scenarios (3 undefined)
	15 steps (15 undefined)
	
	localhost:~/src/<your calculator project root>$  

Pcuke says that it found 3 scenarios (one per each row in the table), 15 steps
(1 step in background + 4 steps in template) times 3 scenarios, and all steps and
scenarios are undefined.

=head2 Step Definitions

We should define steps. For that reason we create a file
<your calculator project root>/step_definitions/steps.pm with the
following content:

	package steps;
	use warnings;
	use strict;
	
	use Test::Pcuke::StepDefinition;
	
	Given qr{^a calculator instance$} => sub {
		# TODO
	};

	Given qr{^I have entered "([^"]+)" into the calculator} => sub {
		# TODO
	};
	
	When qr{I press "([^"]+)"} => sub {
		
	};
	
	Then qr{the result should be "([^"]+)" on the screen} => sub {
		
	};

	1; # Do not forget this number. pcuke uses require()!
	 
Now launch B<pcuke> again to see (some output is skipped):

	...............
	3 scenarios
	15 steps

Everything is defined and pass. This is because we do not do anything in
our steps! Note however that we did not enter a definition like 

	And qr{^I have entered "([^"]+)" into the calculator} => sub { ... }

because it coincides with the corresponding Given definition. Simply speaking
the name of the step is not important at all. The rest of the title IS important.

Now let's do some actual work. in steps.pm edit a background step definition:

	Given qr{^a calculator instance$} => sub {
		my ($world, $text, $table) = @_;
		$world->{_calculator} = Local::Adder->new;
	};

Launching the B<pcuke> we see that a background step is failed three times, before
execution of each of three scenarios. This is because we have not loaded Local::Adder!

Let's add two files. The first one is <your calculator project root>/lib/Local/Adder.pm:

	package Local::Adder;

	use warnings;
	use strict;

	sub new {
		my ($class) = @_;
		bless {}, $class;
	}

	1;

The second is <your calculator project root>/features/support/env.pm

	package Local::Adder::env;

	use warnings;
	use strict;

	require 'lib/Local/Adder.pm';

	1; # this number is important

Now B<pcuke> says that all steps are defined again.

Let's define the rest of the steps. Edit the <your calculator project root>/step_definitions/steps.pm
file:

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

Now B<pcuke> says that "When" step fails. That's because there is no add method
in Adder. Define it in <your calculator project root>/lib/Local/Adder.pm:

	sub add { $_[1] + $_[2]; }

Now all the steps pass which means that we have finished the feature.

=head1 BDD

See the RSpec book:

David Chelimsky, I<The RSpec Book. Behaviour-Driven Development with RSpec, Cucumber
and Friends>. - The Pragmatic Bookshelf, 2010. - (ISBN-10: 1-934356-37-9,
ISBN-13: 978-934356-37-1).    

=head1 GHERKIN

See Cucumber Wiki: L<https://github.com/cucumber/cucumber/wiki/>



=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-/home/tut/bin/src/test-pcuke at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=/home/tut/bin/src/Test-Pcuke>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::Manual


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=/home/tut/bin/src/Test-Pcuke>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist//home/tut/bin/src/Test-Pcuke>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d//home/tut/bin/src/Test-Pcuke>

=item * Search CPAN

L<http://search.cpan.org/dist//home/tut/bin/src/Test-Pcuke/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Andrei V. Toutoukine.

This program is released under the following license: artistic


=cut

1; # End of Test::Pcuke::Manual
