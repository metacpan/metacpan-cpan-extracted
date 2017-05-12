package Test::FITesque;

use warnings;
use strict;

use base qw(Exporter);
our @EXPORT_OK = qw(run_tests suite test);
our @EXPORT = @EXPORT_OK;

use Test::FITesque::Test;
use Test::FITesque::Suite;

=head1 NAME

Test::FITesque - the FITesque framework!

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 DESCRIPTION

L<Test::FITesque> is a framework designed to emulate the FIT L<http://fit.c2.com>
framework, but with a more perlish touch. While it is possible to use the FIT
framework from within perl, it has a lot of unnessecary overhead related to its
origins in the Java world.

I created L<Test::FITesque> for the following reasons:

=over

=item * 

I wanted to store my fixture tables in whatever format i wanted (JSON, YAML, Storable, etc)

=item *

I wanted to simplify the execution process to make it very transparent. I have
used FitNesse up to this point along with the perl server, but found that
the java framework was painful to debug and overly complex for the task it
needed to achieve.

=item *

I wanted to use the normal perl testing tools and utilities to fit my workflow
more closely.

=item *

I also wanted to be able to save the TAP output to more easily capture test
results over time to track regressions and problematic tests.

=back

=head1 INTRODUCTION

FITesque starts with creating FITesque fixtures which are simply packages which
allow for the creation of objects upon which methods can be called.

  package MyApp::Test::Fixture;

  use strict;
  use warnings;
  use base qw(Test::FITesque::Fixture);
  use Test::More;

  file_exists : Test {
    my ($self, $file) = @_;

    ok -e $file, qq{File '$file' exists};
  }

This simple fixture can now be run with a very basic and simple test.

  my $test = Test::FITesque::Test->new({
    data => [
      ['MyApp::Test::Fixture'],
      ['file_exists', '/etc/hosts']
    ]  
  });
  $test->run_tests();


The data option is simply a table of data to use when executing the fixture
test. The first row must refer to the name of the L<Test::FITesque::Fixture>
based fixture you wish to execute (like MyApp::Test::Fixture above). Any
other cells in this row will be passed to the new() method on the Fixture
class.

The following rows are all method calls on an instance of the Fixture
class. This first cell must refer to a method name in the Fixture class,
all following cells will be passed to the methods as arguments.

The run_tests() method on the FITesque test will simply run these methods
in the order specified while taking care of maintaing TAP test count
and the like underneath.

If you have more than one instance of a test to run, you can add it to a
suite.

  my $suite = Test::FITesque::Suite->new({
    data => [$test1, $test2, $test3]  
  });
  $suite->run_tests();

This will also allow you to run test fixtures in a more dynamic fashion
while still taking care of TAP test count.

Suites can not only take a list of tests to run, but also suites themselves.

The L<Test::FITesque> package also supplies some handy helper functions
to wrap most of the logic up for you. Please see the SYNOPSIS below for
more information.

=head1 SYNOPSIS

  use Test::FITesque;

  run_tests {
    suite { ... },
    test { 
      ['MyApp::Test::Fixture'],
      ['file_exists', '/etc/hosts']
    }
  };

=head1 EXPORTED FUNCTIONS

=head2 test

  test {
    ['Fixture::Class'],
    ['divides',    qw(8 4 2)],
    ['multiplies', qw(5 6 30)],
    ['adds',       qw(4 3 7)],
  }

This function will return a L<Test::FITesque::Test> object. It takes a coderef 
which returns a list of array references of which the first must refer to your
FITesque fixture.

=cut

sub test (&@) {
  my $coderef = shift;
  my (@results) = $coderef->();

  my $test = Test::FITesque::Test->new({ data => \@results });
  return $test;
}

=head2 suite

  suite {
    test {
      ...  
    },
    test {
      ...
    },
    suite {
      test {
        ...
      }
    },
  }

This function will return a L<Test::FITesque::Suite> object. It takes a coderef
which returns a list of L<Test::FITesque::Test> objects or/and 
L<Test::FITesque::Suite> objects.

=cut

sub suite (&@) { 
  my $coderef = shift;
  my @results = $coderef->();

  my $suite = Test::FITesque::Suite->new({ data => \@results });
  return $suite;
}

=head2 run_tests

  run_tests {
    suite {
      ...
    },
    test {
      ...
    }
  }

This function takes a coderef of suite and/or test objects. This will then
wrap these all into a suite and call L<Test::FITesque::Suite>'s L<run_tests>
method.

=cut

sub run_tests (&@) { 
  my $coderef = shift;
  my @results = $coderef->();

  my $tester;
  if(@results > 1){
    $tester = Test::FITesque::Suite->new({ data => \@results });
  } else {
    $tester = shift @results;
  }

  $tester->run_tests;
}

=head1 SEE ALSO

L<Test::FITesque::Fixture>, L<Test::FITesque::Test>, L<Test::FITesque::Suite>

=head1 TEST COVERAGE

This distribution is heavily unit and system tested for compatability with
L<Test::Builder>. If you come across any bugs, please send me or submit failing
tests to Test-FITesques RT queue. Please see the 'SUPPORT' section below on
how to supply these.

 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 File                           stmt   bran   cond    sub    pod   time  total
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 blib/lib/Test/FITesque.pm     100.0  100.0    n/a  100.0  100.0    5.2  100.0
 .../Test/FITesque/Fixture.pm  100.0  100.0  100.0  100.0  100.0   29.1  100.0
 ...ib/Test/FITesque/Suite.pm  100.0  100.0  100.0  100.0  100.0   14.6  100.0
 ...lib/Test/FITesque/Test.pm  100.0  100.0  100.0  100.0  100.0   51.1  100.0
 Total                         100.0  100.0  100.0  100.0  100.0  100.0  100.0
 ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 AUTHOR

Scott McWhirter, C<< <konobi at cpan.org> >>

=head1 TODO

=over

=item *

Add more documentation

=item *

Add some cookbook examples

=item *

Look at some of the Fixture base class code to see if it can be restructured to
allow for more evil coderef support.

=item *

Update code to take advantage of newer Test::Harness/Test::Builder features.

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-fitesque at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-FITesque>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 LIMITATIONS

Due to limitations in the TAP protocol and perl's TAP tools such as
L<Test::Harness>, all Fixture tables have to be held in memory. It also means
that Fixture tables cannot be treated as a stream so there is no easy way
to seperate out which tables output is which. To remedy this, I suggest that
you pass a 'name' parameter to the Fixture classes constructor and print this
to screen or use the diag() function from L<Test::More>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::FITesque

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-FITesque>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-FITesque>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-FITesque>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-FITesque>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Scott McWhirter, all rights reserved.

This program is released under the following license: BSD. Please see the
LICENSE file included in this distribution for details.

=cut

1; # End of Test::FITesque
