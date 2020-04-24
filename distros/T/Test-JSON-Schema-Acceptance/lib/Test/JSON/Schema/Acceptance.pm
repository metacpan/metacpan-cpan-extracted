package Test::JSON::Schema::Acceptance; # git description: 0.0.1-12-g1f33ab6
# ABSTRACT: Acceptance testing for JSON-Schema based validators like JSON::Schema

our $VERSION = '0.990';

use 5.010;
use strict;
use warnings;

use Test::More ();
use Test::Fatal ();
use Cwd ();
use JSON ();

#pod =for :header =for stopwords validators
#pod
#pod =head1 SYNOPSIS
#pod
#pod This module allows the L<JSON Schema Test Suite|https://github.com/json-schema/JSON-Schema-Test-Suite> tests to be used in perl to test a module that implements json-schema.
#pod These are the same tests that many modules (libraries, plugins, packages, etc.) use to confirm support of json-schema.
#pod Using this module to confirm support gives assurance of interoperability with other modules that run the same tests in different languages.
#pod
#pod In the JSON::Schema module, a test could look like the following:
#pod
#pod   use Test::More;
#pod   use JSON::Schema;
#pod   use Test::JSON::Schema::Acceptance;
#pod
#pod   my $accepter = Test::JSON::Schema::Acceptance->new(3);
#pod
#pod   # Skip tests which are known not to be supported or which cause problems.
#pod   my $skip_tests = ['multiple extends', 'dependencies', 'ref'];
#pod
#pod   $accepter->acceptance( sub{
#pod     my ( $schema, $input ) = @_;
#pod     return JSON::Schema->new($schema)->validate($input);
#pod   }, {
#pod     skip_tests => $skip_tests
#pod   } );
#pod
#pod   done_testing();
#pod
#pod This would determine if JSON::Schema's C<validate> method returns the right result for all of the cases in the JSON Schema Test Suite, except for those listed in C<$skip_tests>.
#pod
#pod =head1 DESCRIPTION
#pod
#pod L<JSON Schema|http://json-schema.org> is an IETF draft (at time of writing) which allows you to define the structure of JSON.
#pod
#pod The abstract from L<draft 4|https://tools.ietf.org/html/draft-zyp-json-schema-04> of the specification:
#pod
#pod =over 4
#pod
#pod JSON Schema defines the media type "application/schema+json",
#pod a JSON based format for defining the structure of JSON data.
#pod JSON Schema provides a contract for what JSON data is required
#pod for a given application and how to interact with it.
#pod JSON Schema is intended to define validation, documentation,
#pod hyperlink navigation, and interaction control of JSON data.
#pod
#pod =back
#pod
#pod L<JSON::Schema|https://metacpan.org/pod/JSON::Schema> is a perl module created independently of the specification, which aims to implement the json-schema specification.
#pod
#pod This module allows other perl modules (for example JSON::Schema) to test that they are json-schema compliant, by running the tests from the official test suite, without having to manually convert them to perl tests.
#pod
#pod You are unlikely to want this module, unless you are attempting to write a module which implements json-schema the specification, and want to test your compliance.
#pod
#pod
#pod =head1 CONSTRUCTOR
#pod
#pod =over 1
#pod
#pod =item C<< Test::JSON::Schema::Acceptance->new($schema_version) >>
#pod
#pod Create a new instance of Test::JSON::Schema::Acceptance.
#pod
#pod Accepts optional argument of $schema_version.
#pod This determines the draft version of the schema to confirm compliance to.
#pod Default is draft 4 (current), but in the synopsis example, JSON::Schema is testing draft 3 compliance.
#pod
#pod =back
#pod
#pod =cut

sub new {
  my $class = shift;
  return bless { draft => shift || 4 }, $class;
}

#pod =head1 SUBROUTINES/METHODS
#pod
#pod =head2 acceptance
#pod
#pod =for stopwords truthy falsey
#pod
#pod Accepts a sub and optional options in the form of a hash.
#pod The sub should return truthy or falsey depending on if the schema was valid for the input or not.
#pod
#pod =head3 options
#pod
#pod The only option which is currently accepted is skip_tests, which should be an array ref of tests you want to skip.
#pod You can skip a whole section of tests or individual tests.
#pod Any test name that contains any of the array refs items will be skipped, using grep.
#pod You can also skip a test by its number.
#pod
#pod =cut

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
              Test::More::todo_skip 'Test explicitly skipped. - '  . $subtest_name, 1
              if (grep { $subtest_name =~ /$_/} @$skip_tests) ||
                grep $_ eq "$test_no", @$skip_tests;
          }

          my $result;
          my $exception = Test::Fatal::exception{
            if(ref($test->{data}) eq 'ARRAY' || ref($test->{data}) eq 'HASH'){
              $result = $code->($schema, $json->encode($test->{data}));
            } else {
              # $result = $code->($schema, $json->encode([$test->{data}]));
              $result = $code->($schema, JSON->new->allow_nonref->encode($test->{data}));
            }
          };

          my $test_desc = $test_group_test->{description} . ' - ' . $test->{description} . ($exception ? ' - and died!!' : '');
          Test::More::ok(!$exception && _eq_bool($test->{valid}, $result), $test_desc) or
            Test::More::diag(
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

  my $mod_dir = Cwd::abs_path(__FILE__) =~ s~Acceptance\.pm~/test_suite~r; # Find the modules directory... ~

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

#pod =head1 ACKNOWLEDGEMENTS
#pod
#pod =for stopwords Signes
#pod
#pod Daniel Perrett <perrettdl@cpan.org> for the concept and help in design.
#pod
#pod Ricardo Signes <rjbs@cpan.org> for direction to and creation of Test::Fatal.
#pod
#pod Various others in #perl-help.
#pod
#pod =cut

1; # End of Test::JSON::Schema::Acceptance

__END__

=pod

=encoding UTF-8

=for stopwords validators

=head1 NAME

Test::JSON::Schema::Acceptance - Acceptance testing for JSON-Schema based validators like JSON::Schema

=head1 VERSION

version 0.990

=head1 SYNOPSIS

This module allows the L<JSON Schema Test Suite|https://github.com/json-schema/JSON-Schema-Test-Suite> tests to be used in perl to test a module that implements json-schema.
These are the same tests that many modules (libraries, plugins, packages, etc.) use to confirm support of json-schema.
Using this module to confirm support gives assurance of interoperability with other modules that run the same tests in different languages.

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

L<JSON::Schema|https://metacpan.org/pod/JSON::Schema> is a perl module created independently of the specification, which aims to implement the json-schema specification.

This module allows other perl modules (for example JSON::Schema) to test that they are json-schema compliant, by running the tests from the official test suite, without having to manually convert them to perl tests.

You are unlikely to want this module, unless you are attempting to write a module which implements json-schema the specification, and want to test your compliance.

=head1 CONSTRUCTOR

=over 1

=item C<< Test::JSON::Schema::Acceptance->new($schema_version) >>

Create a new instance of Test::JSON::Schema::Acceptance.

Accepts optional argument of $schema_version.
This determines the draft version of the schema to confirm compliance to.
Default is draft 4 (current), but in the synopsis example, JSON::Schema is testing draft 3 compliance.

=back

=head1 SUBROUTINES/METHODS

=head2 acceptance

=for stopwords truthy falsey

Accepts a sub and optional options in the form of a hash.
The sub should return truthy or falsey depending on if the schema was valid for the input or not.

=head3 options

The only option which is currently accepted is skip_tests, which should be an array ref of tests you want to skip.
You can skip a whole section of tests or individual tests.
Any test name that contains any of the array refs items will be skipped, using grep.
You can also skip a test by its number.

=head1 ACKNOWLEDGEMENTS

=for stopwords Signes

Daniel Perrett <perrettdl@cpan.org> for the concept and help in design.

Ricardo Signes <rjbs@cpan.org> for direction to and creation of Test::Fatal.

Various others in #perl-help.

=head1 SUPPORT

bugs may be submitted through L<https://github.com/karenetheridge/Test-JSON-Schema-Acceptance/issues>.

=head1 AUTHOR

Ben Hutton (@relequestual) <relequest@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Ben Hutton Karen Etheridge Daniel Perrett

=over 4

=item *

Ben Hutton <bh7@sanger.ac.uk>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Ben Hutton <relequestual@gmail.com>

=item *

Daniel Perrett <dp13@sanger.ac.uk>

=back

=head1 COPYRIGHT AND LICENCE

This software is Copyright (c) 2015 by Ben Hutton.

This is free software, licensed under:

  The MIT (X11) License

=cut
