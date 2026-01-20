package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Role::Fromable

=cut

$test->for('name');

=tagline

Fromable Role

=cut

$test->for('tagline');

=abstract

Fromable Role for Perl 5

=cut

$test->for('abstract');

=includes

method: from

=cut

$test->for('includes');

=synopsis

  package Person;

  use Venus::Class 'attr', 'with';

  with 'Venus::Role::Fromable';

  attr 'fname';
  attr 'lname';

  sub from_name {
    my ($self, $name) = @_;

    my ($fname, $lname) = split / /, $name;

    return {
      fname => $fname,
      lname => $lname,
    };
  }

  package main;

  my $person = Person->from(name => 'Elliot Alderson');

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'Person')

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Person');
  ok $result->does('Venus::Role::Fromable');

  $result
});

=description

This package modifies the consuming package and provides methods for
dispatching to constructor argument builders.

=cut

$test->for('description');

=method from

The from method takes a key and value(s) and dispatches to the corresponding
argument builder named in the form of C<from_${name}> which should return
arguments required by the constructor. The constructor will be called with the
arguments returned from the argument builder and a class instance will be
returned. If the key is omitted, the data type of the first value will be used
as the key (or name), i.e. if the daya type of the first value is a string this
method will attempt to dispatch to a builder named C<from_string>.

=signature from

  from(any @values) (object)

=metadata from

{
  since => '4.15',
}

=example-1 from

  # given: synopsis;

  $person = Person->from(name => 'Elliot Alderson');

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'Person')

  # $person->fname;

  # "Elliot"

  # $person->lname;

  # "Alderson"

=cut

$test->for('example', 1, 'from', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Person');
  ok $result->does('Venus::Role::Fromable');
  is $result->fname, 'Elliot';
  is $result->lname, 'Alderson';

  $result
});

=example-2 from

  # given: synopsis;

  $person = Person->from('', 'Elliot Alderson');

  # Exception! "No name provided to \"from\" via package \"Person\""

=cut

$test->for('example', 2, 'from', sub {
  my ($tryable) = @_;
  my $result = $tryable->fault->result;
  ok $result->isa('Venus::Fault');
  is $result->{message}, "No name provided to \"from\" via package \"Person\"";

  $result
});

=example-3 from

  # given: synopsis;

  $person = Person->from(undef, 'Elliot Alderson');

  # Exception! "No name provided to \"from\" via package \"Person\""

=cut

$test->for('example', 3, 'from', sub {
  my ($tryable) = @_;
  my $result = $tryable->fault->result;
  ok $result->isa('Venus::Fault');
  is $result->{message}, "No name provided to \"from\" via package \"Person\"";

  $result
});

=example-4 from

  # given: synopsis;

  $person = Person->from('fullname', 'Elliot Alderson');

  # Exception! "Unable to locate class method \"from_fullname\" via package \"Person\""

=cut

$test->for('example', 4, 'from', sub {
  my ($tryable) = @_;
  my $result = $tryable->fault->result;
  ok $result->isa('Venus::Fault');
  is $result->{message}, "Unable to locate class method \"from_fullname\" via package \"Person\"";

  $result
});

=example-5 from

  # given: synopsis;

  $person = Person->from('Elliot Alderson');

  # Exception! "Unable to locate class method \"from_string\" via package \"Person\""

=cut

$test->for('example', 5, 'from', sub {
  my ($tryable) = @_;
  my $result = $tryable->fault->result;
  ok $result->isa('Venus::Fault');
  is $result->{message}, "Unable to locate class method \"from_string\" via package \"Person\"";

  $result
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Role/Fromable.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
