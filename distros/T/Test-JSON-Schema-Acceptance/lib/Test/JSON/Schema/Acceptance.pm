package Test::JSON::Schema::Acceptance;

use 5.010;
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Cwd 'abs_path';
use JSON;

=head1 NAME

Test::JSON::Schema::Acceptance - Acceptance testing for JSON-Schema based validators like JSON::Schema

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';

=head1 SYNOPSIS

This module allows the L<JSON Schema Test Suite|https://github.com/json-schema/JSON-Schema-Test-Suite> tests to be used in perl to test a module that implements json-schema.
These are the same tests that many modules (libraries, plugins, packages, etc.) use to confirm support of json-scheam.
Using this module to confirm support gives assurance of interoperability with other modules that run the same tests in differnet languages.

In the JSON::Schema module, a test could look like the following:

  use Test::More;
  use JSON::Schema;
  use Test::JSON::Schema::Acceptance;

  my $accepter = Test::JSON::Schema::Acceptance->new(3);

  # Skip tests which are known not to be supported or which cause problems.
  my $skip_tests = ['multiple extends', 'dependencies', 'ref'];

  $accepter->acceptance( sub{
    my ( $schema, $input ) = @_;
    return JSON::Schema->new($schema)->validate($input);
  }, {
    skip_tests => $skip_tests
  } );

  done_testing();

This would determine if JSON::Schema's C<validate> method returns the right result for all of the cases in the JSON Schema Test Suite, except for those listed in C<$skip_tests>.

=head1 DESCRIPTION

L<JSON Schema|http://json-schema.org> is an IETF draft (at time of writing) which allows you to define the structure of JSON.

The abstract from L<draft 4|https://tools.ietf.org/html/draft-zyp-json-schema-04> of the specification:

=over 4
JSON Schema defines the media type "application/schema+json",
a JSON based format for defining the structure of JSON data.
JSON Schema provides a contract for what JSON data is required
for a given application and how to interact with it.
JSON Schema is intended to define validation, documentation,
hyperlink navigation, and interaction control of JSON data.
=back

L<JSON::Schema|https://metacpan.org/pod/JSON::Schema> is a perl module created independantly of the specification, which aims to implement the json-schema specification.

This module allows other perl modules (for example JSON::Schema) to test that they are json-schema compliant, by running the tests from the official test suite, without having to manually convert them to perl tests.

You are unliekly to want this module, unless you are attempting to write a module which implements json-schema the specification, and want to test your compliance.


=head1 CONSTRUCTOR

=over 1

=item C<< Test::JSON::Schema::Acceptance->new($schema_version) >>

Create a new instance of Test::JSON::Schema::Acceptance.

Accepts optional argument of $schema_version.
This determins the draft version of the schema to confirm compliance to.
Default is draft 4 (current), but in the synopsis example, JSON::Schema is testing draft 3 compliance.

=cut

sub new {
  my $class = shift;
  return bless { draft => shift || 4 }, $class;
}

=head1 SUBROUTINES/METHODS

=head2 acceptance

Accepts a sub and optional options in the form of a hash.
The sub should return truthy or falsey depending on if the schema was valid for the input or not.

=head3 options

The only option which is currently accepted is skip_tests, which should be an array ref of tests you want to skip.
You can skip a whole section of tests or individual tests.
Any test name that contains any of the array refs items will be skipped, using grep.
You can also skip a test by its number.

=cut

sub acceptance {
  my ($self, $code, $options) = @_;
  my $tests = $self->_load_tests;

  my $skip_tests = $options->{skip_tests} // {};
  my $only_test = $options->{only_test} // undef;

  $self->_run_tests($code, $tests, $skip_tests, $only_test);

}

sub _run_tests {
  my ($self, $code, $tests, $skip_tests, $only_test) = @_;
  my $json = JSON->new;

  local $Test::Builder::Level = $Test::Builder::Level + 2;

  my $test_no = 0;
  foreach my $test_group (@{$tests}) {

    foreach my $test_group_test (@{$test_group->{json}}){

      my $test_group_cases = $test_group_test->{tests};
      my $schema = $test_group_test->{schema};

      foreach my $test (@{$test_group_cases}) {
        $test_no++;
        next if defined $only_test && $test_no != $only_test;
        my $subtest_name = $test_group_test->{description} . ' - ' . $test->{description};

        TODO: {
          if (ref $skip_tests eq 'ARRAY'){
            todo_skip 'Test explicitly skipped. - '  . $subtest_name, 1
              if (grep { $subtest_name =~ /$_/} @$skip_tests) ||
                grep $_ eq "$test_no", @$skip_tests;
          }

          my $result;
          my $exception = exception{
            if(ref($test->{data}) eq 'ARRAY' || ref($test->{data}) eq 'HASH'){
              $result = $code->($schema, $json->encode($test->{data}));
            } else {
              # $result = $code->($schema, $json->encode([$test->{data}]));
              $result = $code->($schema, JSON->new->allow_nonref->encode($test->{data}));
            }
          };

          my $test_desc = $test_group_test->{description} . ' - ' . $test->{description} . ($exception ? ' - and died!!' : '');
          ok(!$exception && _eq_bool($test->{valid}, $result), $test_desc) or
            diag(
              "#$test_no \n" .
              'Test file "' . $test_group->{file} . "\"\n" .
              'Test schema - ' . $test_group_test->{description} . "\n" .
              'Test data - ' . $test->{description} . "\n" .
              ($exception ? "$exception " : "") . "\n"
            );
        }
      }
    }
  }
}

sub _load_tests {
  my $self = shift;

  my $mod_dir = abs_path(__FILE__) =~ s~Acceptance\.pm~/test_suite~r; # Find the modules directory... ~

  my $draft_dir = $mod_dir . "/tests/draft" . $self->{draft} . "/";

  opendir (my $dir, $draft_dir) ;
  my @test_files = grep { -f "$draft_dir/$_"} readdir $dir;
  closedir $dir;
  # warn Dumper(\@test_files);

  my @test_groups;

  foreach my $file (@test_files) {
    my $fn = $draft_dir . $file;
    open ( my $fh, '<', $fn ) or die ("Could not open schema file $fn for read");
    my $raw_json = '';
    $raw_json .= $_ while (<$fh>);
    close($fh);
    my $parsed_json = JSON->new->allow_nonref->decode($raw_json);
    # my $parsed_json = JSON::from_json($raw_json);

    push @test_groups, { file => $file, json => $parsed_json };
  }

  return \@test_groups;
}


# Forces the two variables passed, into boolean context.
sub _eq_bool {
  return !(shift xor shift);
}

=head1 AUTHOR

Ben Hutton (@relequestual), C<< <relequest at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to via github at L<https://github.com/Relequestual/Test-JSON-Schema-Acceptance/issues>.

=head1 SUPPORT

Users' IRC: #json-schema on irc.perl.org

=for :html
L<(click for instant chatroom login)|http://chat.mibbit.com/#json-schema@irc.perl.org>

For questions about json-schema in general IRC: #json-schema on chat.freenode.net

=for :html
L<(click for instant chatroom login)|http://chat.mibbit.com/#json-schema@chat.freenode.net>

You can also look for information at:

=over 3

=item * Github issues (report bugs here)

L<https://github.com/Relequestual/Test-JSON-Schema-Acceptance/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-JSON-Schema-Acceptance>

=item * Search Meta CPAN

L<http://search.cpan.org/pod/Test::JSON::Schema::Acceptance/>

=back


=head1 ACKNOWLEDGEMENTS

Daniel Perrett <perrettdl@cpan.org> for the concept and help in design.

Ricardo SIGNES <rjbs@cpan.org> for direction to and creation of Test::Fatal.

Various others in #perl-help.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Ben Hutton (@relequestual).

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1; # End of Test::JSON::Schema::Acceptance
