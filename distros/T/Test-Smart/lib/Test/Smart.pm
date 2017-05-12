package Test::Smart;

use strict;
use warnings;

our $VERSION = '0.02';
my $CLASS = __PACKAGE__;
my $interface;

use base 'Test::Builder::Module';
use Test::Smart::Question;
use Test::Smart::Interface;

our @EXPORT = qw(initialize get_yes get_no);
our @EXPORT_OK = qw(ask answer);

=head1 OBSOLETE

Test::AskAnExpert is the successor module, the name is better and there have
been some compatability breaking changes. You don't want this.

=head1 NAME

Test::Smart - Test things that require Human Intelligence automatically. (By asking someone)

=head1 SYNOPSIS

  use Test::Smart import => [qw(ask answer)],tests => 7;

Start up the Human Interface:

  initialize("Test::Smart::Interface::Subclass",'Subclass args'...);
  
Synchronously submit and wait for a yes or a no answer:

  get_yes("Question");
  get_no("Question");

Same, but with timeouts: (In seconds)

  get_yes("Need a fast asnwer",10);
  get_no("Need a fast denial",10);

Submit an asynchronous question:

  $question = ask("This could take a while");

Check the answer:

  answer($question,'yes');
  answer($question,'no');

The check can timeout too:

  answer($question,'yes',10);

=head1 DESCRIPTION

Test::Smart aims to fill a hole in the current set of testing tools by
integrating an automated method for asking testing questions that computers
cannot easily answer like: "Is this meteorologically sound?" or "Does this
output fit into category x?" or "Is this distrobution quality?" and still
allow standard test tools to work properly in terms of generating reports,
locking the doors if the tests aren't passing, etc. etc.

Test::Smart is built on Test::Builder and will play nice with Test::Simple,
Test::More, and anything they play nice with. To provide Smart answers to
conceptual questions we cheat by asking people instead of actually solving a
Very Hard Problem regarding machine intelligence. This requires a little more
overhead as we need to set up a way to talk to people, and provide them some
(but not too much) time to tender an answer.

=head2 initialize($interface_name, @interface_params)

The initialize function must be called before using any of Test::Smart's
functions to load a Human Interface, otherwise the default (skip when sent
a query) will load. To specify something other than the default pass a subclass
of Test::Smart::Interface. @InterfaceParameters are any Interface specific
parameters, consult the documentation of the Interface you're using for what 
(if anything) to pass here.

On error it returns false, allowing you to try multipule Interfaces in a short-
circuit style before giving up:

  initialize("Test::Smart::Telepathy")
    or initialize("Test::Smart::AskLarry",say_please=>1)
    or skip_all("No good interfaces available");

Note that skip_all isn't required, if no Interface is specified Test::Smart will
use a default Interface that simply skips if its asked to test anything.

=cut

sub initialize {
  my ($interface_name,@interface_params) = @_;

  eval " require $interface_name ";

  return undef if $@;

  $interface = $interface_name->load(@interface_params);

  return 1 if defined($interface);
  $interface = Test::Smart::Interface->load();
  return undef;
}

=head2 get_yes/get_no ($question, $name, [$Timeout])

Test::Smart provides two methods for the programmers who don't want to muck
with asynchronous interaction, get_yes and get_no. get_yes passes when the question asked
is answered yes, get_no the opposite. They are slim wrappers arround ask and
answer, taking a plain text question, test name, and optionally a timeout
in the same way.

=cut

sub get_yes {
  my ($question,$name,$timeout) = @_;
  my $Qobj = ask($question,$name);
  answer($Qobj,'yes',$timeout);
}

sub get_no {
  my ($question,$name,$timeout) = @_;
  my $Qobj = ask($question,$name);
  answer($Qobj,'no',$timeout);
}

=head2 ask($question_text, $test_name)

B<NOTE:> This does not actually run any tests!

ask is a very self explanatory function: it sends a question to be answered by
whatever is on the other side of the Interface (Test::Smart::Pass anyone?). 
It returns a Test::Smart::Question object which is later used for retrieving
the answer. Since this is the factory for Test::Smart::Question objects it also
optionally takes the test name the question is bound to, though this can
be changed with the C<name> method. If there was an error in asking the question
the object will have its skip parameters set so when C<answer> is called on it
the test will be skipped. Read the L<Test::Smart::Question> documentation if you'd
like to query the object your self and do something other than skip the test
(like re-initialize to a different Interface and ask again, or BAIL_OUT).

$QuestionText should be plaintext with no markup, the Interface is expected to
format it nicely for the human on the other side (e.g. if its an HTML interface
give them nice links) to make their life a little easier.

=cut

sub ask {
  my ($question,$name) = @_;

  # Ask the interface
  my $Qobj = $interface->submit($question,$name);

  return $Qobj if defined $Qobj and $Qobj->isa('Test::Smart::Question');

  # Error! The interface has failed us! Skip this question when someone
  # looks for the answer.
  $Qobj = Test::Smart::Question->new(question=>$question,id=>"skip",name=>$name);
  $Qobj->skip("Interface Error: ".$interface->err);
  return $Qobj;
}

=head2 answer($question_obj, $expected, [$timeout])

answer takes a previously asked question and waits until an answer is ready
or optionally $Timeout seconds have passed and then executes typical test
magic.

$QuestionObj should be a Test::Smart::Question object returned by ask or
correctly constructed otherwise. $Expected can be any capitalization of yes or
no and will be checked against the answer in the question for the test.

=cut

sub answer {
  my ($Qobj,$expected,$timeout) = @_;
  my $tb = $CLASS->builder;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  # This should be something smarter than die in the future...
  die "Expecting something other than yes or no" if $expected !~ /yes|no/i;

  # Skips
  return $tb->skip("Invalid Question") unless defined $Qobj and $Qobj->isa('Test::Smart::Question');
  return $tb->skip($Qobj->skip) if defined($Qobj->skip);

  # Wait for it..
  # Needs timestamps
  until($interface->has_answer($Qobj)) {
    sleep 1;
  }

  # Get the answer and skip on error
  $interface->answer($Qobj) or return $tb->skip("Interface Error: ".$interface->err);

  # The ok call checks the answer against yes or no and takes the name provided earlier.
  my ($answer,$comment) = $Qobj->answer;
  $tb->ok($answer eq $expected,$Qobj->name) or 
    $tb->diag("Got: $answer Expected: $expected\n","Commentary: $comment\n");
}

=head1 EXPORTS

By default C<get_yes> and C<get_no> are exported, to get C<ask> and C<answer>
pass import => [qw(ask answer)] to the use line.

=head1 BUGS

This is the first version, it probably has some. Bug reports, failing tests,
and patches are all welcome.

=head1 TODO

Timeouts. I haven't done them yet, but they'll be in the next release. I promise.

Test::Smart::Interface::CGI and Test::Smart::Interface::DBI. These would 
probably be more useful than the current File interface which exists more to
prove it can be done than anything.

=head1 SUPPORT

All bugs should be filed via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Smart>

For other issues, or commercial enhancement or support, contact the author.

=head1 SEE ALSO

L<Test::Smart::Interface>,L<Test::Smart::Question>

=head1 AUTHOR

Edgar A. Bering, E<lt>trizor@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Edgar A. Bering

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
