use strict;
use warnings;
package Test::JSON::Schema::Acceptance; # git description: v0.991-12-ge50ddad
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Acceptance testing for JSON-Schema based validators like JSON::Schema

our $VERSION = '0.992';

no if "$]" >= 5.031009, feature => 'indirect';
use Test::More ();
use Test::Fatal ();
use JSON::MaybeXS 1.004001;
use File::ShareDir 'dist_dir';
use Moo;
use MooX::TypeTiny 0.002002;
use Types::Standard 1.010002 qw(Str InstanceOf ArrayRef HashRef Dict Any HasMethods);
use Path::Tiny;
use List::Util 1.33 'any';
use namespace::clean;

has specification => (
  is => 'ro',
  isa => Str,
  lazy => 1,
  default => 'draft2019-09',
);

has test_dir => (
  is => 'ro',
  isa => InstanceOf['Path::Tiny'],
  coerce => sub { path($_[0])->absolute('.') },
  lazy => 1,
  default => sub { path(dist_dir('Test-JSON-Schema-Acceptance'), 'tests', $_[0]->specification) },
);

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my %args = @args % 2 ? ( specification => 'draft'.$args[0] ) : @args;
  $args{specification} = 'draft2019-09' if ($args{specification} // '') eq 'latest';
  $class->$orig(\%args);
};

sub BUILD {
  my $self = shift;
  -d $self->test_dir or die 'test_dir does not exist: '.$self->test_dir;
}

sub acceptance {
  my $self = shift;
  my $options = +{ ref $_[0] eq 'CODE' ? (validate_json_string => @_) : @_ };

  die 'require one or the other of "validate_data", "validate_json_string"'
    if not $options->{validate_data} and not $options->{validate_json_string};

  die 'cannot provide both "validate_data" and "validate_json_string"'
    if $options->{validate_data} and $options->{validate_json_string};

  $self->_run_tests($self->_test_data, $options);

}

sub _run_tests {
  my ($self, $tests, $options) = @_;

  Test::More::note('running tests in '.$self->test_dir.'...');

  warn "'skip_tests' option is deprecated" if $options->{skip_tests};

  my %results; # results by file

  foreach my $one_file (@$tests) {
    next if $options->{tests} and $options->{tests}{file}
      and not grep $_ eq $one_file->{file},
        (ref $options->{tests}{file} eq 'ARRAY'
          ? @{$options->{tests}{file}} : $options->{tests}{file});

    foreach my $test_group (@{$one_file->{json}}) {
      next if $options->{tests} and $options->{tests}{group_description}
        and not grep $_ eq $test_group->{description},
          (ref $options->{tests}{group_description} eq 'ARRAY'
            ? @{$options->{tests}{group_description}} : $options->{tests}{group_description});

      foreach my $test (@{$test_group->{tests}}) {
        next if $options->{tests} and $options->{tests}{test_description}
          and not grep $_ eq $test->{description},
            (ref $options->{tests}{test_description} eq 'ARRAY'
              ? @{$options->{tests}{test_description}} : $options->{tests}{test_description});

        local $::TODO = 'Test marked TODO via "todo_tests"'
          if $options->{todo_tests} and
            any {
              my $o = $_;
              (not $o->{file} or grep $_ eq $one_file->{file}, (ref $o->{file} eq 'ARRAY' ? @{$o->{file}} : $o->{file}))
                and
              (not $o->{group_description} or grep $_ eq $test_group->{description}, (ref $o->{group_description} eq 'ARRAY' ? @{$o->{group_description}} : $o->{group_description}))
                and
              (not $o->{test_description} or grep $_ eq $test->{description}, (ref $o->{test_description} eq 'ARRAY' ? @{$o->{test_description}} : $o->{test_description}))
            }
            @{$options->{todo_tests}};

        my $result = $self->_run_test($one_file, $test_group, $test, $options);
        ++$results{$one_file->{file}}->{ $result ? 'pass' : 'fail' };
      }
    }
  }

  Test::More::note '';
  Test::More::note sprintf('%-25s pass  fail', 'filename');
  Test::More::note '-'x36;
  Test::More::note sprintf('%-25s  %3d   %3d', $_, $results{$_}{pass} // 0, $results{$_}{fail} // 0)
    foreach sort keys %results;
  Test::More::note '';
}

sub _run_test {
  my ($self, $one_file, $test_group, $test, $options) = @_;

  TODO: {
    local $::TODO = 'Test marked TODO via "skip_tests"'
      if ref $options->{skip_tests} eq 'ARRAY' and
        grep +(($test_group->{description}.' - '.$test->{description}) =~ /$_/), @{$options->{skip_tests}};

    my $result;
    my $exception = Test::Fatal::exception {
      $result = $options->{validate_data}
        ? $options->{validate_data}->($test_group->{schema}, $test->{data})
        : $options->{validate_json_string}->($test_group->{schema}, $self->_json_decoder->encode($test->{data}));
    };

    my $got = $result ? 'true' : 'false';
    my $expected = $test->{valid} ? 'true' : 'false';

    local $Test::Builder::Level = $Test::Builder::Level + 3;

    my $pass = Test::More::is($got, $expected,
      $one_file->{file}.': "'.$test_group->{description}.'" - "'.$test->{description}.'"');
    $pass = Test::More::fail($exception) if $exception;

    return $pass;
  }
}

has _json_decoder => (
  is => 'ro',
  isa => HasMethods[qw(encode decode)],
  lazy => 1,
  default => sub { JSON::MaybeXS->new(allow_nonref => 1, utf8 => 1) },
);

has _test_data => (
  is => 'lazy',
  isa => ArrayRef[Dict[
           file => Str,
           json => ArrayRef[Dict[
             description => Str,
             schema => InstanceOf['JSON::PP::Boolean']|HashRef,
             tests => ArrayRef[Dict[
               data => Any,
               description => Str,
               valid => InstanceOf['JSON::PP::Boolean'],
             ]],
           ]],
          ]],
);

sub _build__test_data {
  my $self = shift;
  my @test_groups;

  # note that we do not recurse into subdirs by default.
  foreach my $file (sort $self->test_dir->children) {
    next if not $file->is_file;
    next if $file !~ /\.json$/;

    push @test_groups, {
      file => $file->basename,
      json => $self->_json_decoder->decode($file->slurp_raw),
    };
  }

  return \@test_groups;
}

1;

__END__

=pod

=encoding UTF-8

=for stopwords validators Schemas ANDed ORed TODO

=head1 NAME

Test::JSON::Schema::Acceptance - Acceptance testing for JSON-Schema based validators like JSON::Schema

=head1 VERSION

version 0.992

=head1 SYNOPSIS

This module allows the L<JSON Schema Test Suite|https://github.com/json-schema/JSON-Schema-Test-Suite> tests to be used in perl to test a module that implements the JSON Schema specification ("json-schema").
These are the same tests that many modules (libraries, plugins, packages, etc.) use to confirm support of json-schema.
Using this module to confirm support gives assurance of interoperability with other modules that run the same tests in different languages.

In the JSON::Schema module, a test could look like the following:

  use Test::More;
  use JSON::Schema;
  use Test::JSON::Schema::Acceptance;

  my $accepter = Test::JSON::Schema::Acceptance->new(specification => 'draft3');

  $accepter->acceptance(
    validate_data => sub {
      my ($schema, $input_data) = @_;
      return JSON::Schema->new($schema)->validate($input_data);
    },
    todo_tests => [ { file => 'dependencies.json' } ],
  );

  done_testing();

This would determine if JSON::Schema's C<validate> method returns the right result for all of the cases in the JSON Schema Test Suite, except for those listed in C<$skip_tests>.

=head1 DESCRIPTION

L<JSON Schema|http://json-schema.org> is an IETF draft (at time of writing) which allows you to define the structure of JSON.

From the overview of the L<draft 2019-09 version of the
specification|https://json-schema.org/draft/2019-09/json-schema-core.html#rfc.section.3>:

=over 4

This document proposes a new media type "application/schema+json" to identify a JSON Schema for
describing JSON data. It also proposes a further optional media type,
"application/schema-instance+json", to provide additional integration features. JSON Schemas are
themselves JSON documents. This, and related specifications, define keywords allowing authors to
describe JSON data in several ways.

JSON Schema uses keywords to assert constraints on JSON instances or annotate those instances with
additional information. Additional keywords are used to apply assertions and annotations to more
complex JSON data structures, or based on some sort of condition.

=back

This module allows other perl modules (for example JSON::Schema) to test that they are JSON Schema-compliant, by running the tests from the official test suite, without having to manually convert them to perl tests.

You are unlikely to want this module, unless you are attempting to write a module which implements JSON Schema the specification, and want to test your compliance.

=head1 CONSTRUCTOR

  Test::JSON::Schema::Acceptance->new(specification => $specification_version)

Create a new instance of Test::JSON::Schema::Acceptance.

Available options are:

=head2 specification

This determines the draft version of the schema to confirm compliance to.
Possible values are:

=over 4

=item *

C<draft3>

=item *

C<draft4>

=item *

C<draft6>

=item *

C<draft7>

=item *

C<draft2019-09>

=item *

C<latest> (alias for C<draft2019-09>)

=back

The default is C<latest>, but in the synopsis example, L<JSON::Schema> is testing draft 3 compliance.

(For backwards compatibility, C<new> can be called with a single numeric argument of 3 to 7, which maps to
C<draft3> through C<draft7>.)

=head2 test_dir

Instead of specifying a draft specification to test against, which will select the most appropriate tests,
you can pass in the name of a directory of tests to run directly. Files in this directory should be F<.json>
files following the format described in
L<https://github.com/json-schema-org/JSON-Schema-Test-Suite/blob/master/README.md>.

=head1 SUBROUTINES/METHODS

=head2 acceptance

=for stopwords truthy falsey

Accepts a hash of options as its arguments.

(Backwards-compatibility mode: accepts a subroutine which is used as C<validate_json_string>,
and a hashref of arguments.)

Available options are:

=head3 validate_data

A subroutine reference, which is passed two arguments: the JSON Schema, and the B<inflated> data
structure to be validated.

The subroutine should return truthy or falsey depending on if the schema was valid for the input or
not.

Either C<validate_data> or C<validate_json_string> is required.

=head3 validate_json_string

A subroutine reference, which is passed two arguments: the JSON Schema, and the B<JSON string>
containing the data to be validated.

The subroutine should return truthy or falsey depending on if the schema was valid for the input or
not.

Either C<validate_data> or C<validate_json_string> is required.

=head3 tests

Optional. Restricts tests to just those mentioned (the conditions are ANDed together, not ORed).
The syntax can take one of many forms:

  # run tests in this file
  tests => { file => 'dependencies.json' }

  # run tests in these files
  tests => { file => [ 'dependencies.json', 'refRemote.json' ] }

  # run tests in this file with this group description
  tests => {
    file => 'refRemote.json',
    group_description => 'remote ref',
  }

  # run tests in this file with these group descriptions
  tests => {
    file => 'const.json',
    group_description => [ 'const validation', 'const with object' ],
  }

  # run tests in this file with this group description and test description
  tests => {
    file => 'const.json',
    group_description => 'const validation',
    test_description => 'another type is invalid',
  }

  # run tests in this file with this group description and these test descriptions
  tests => {
    file => 'const.json',
    group_description => 'const validation',
    test_description => [ 'same value is valid', 'another type is invalid' ],
  }

=head3 todo_tests

Optional. Mentioned tests will run as L<"TODO"|Test::More/TODO: BLOCK>. Uses arrayrefs of
the same hashref structure as L</tests> above, which are ORed together.

  todo_tests => [
    # all tests in this file are TODO
    { file => 'dependencies.json' },
    # just some tests in this file are TODO
    { file => 'boolean_schema.json', test_description => 'array is invalid' },
    # .. etc
  ]

=head1 ACKNOWLEDGEMENTS

=for stopwords Perrett Signes

Daniel Perrett <perrettdl@cpan.org> for the concept and help in design.

Ricardo Signes <rjbs@cpan.org> for direction to and creation of Test::Fatal.

Various others in #perl-help.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/karenetheridge/Test-JSON-Schema-Acceptance/issues>.

=head1 AUTHOR

Ben Hutton (@relequestual) <relequest@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Ben Hutton Daniel Perrett

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Ben Hutton <relequestual@cpan.org>

=item *

Daniel Perrett <dp13@sanger.ac.uk>

=back

=head1 COPYRIGHT AND LICENCE

This software is Copyright (c) 2015 by Ben Hutton.

This is free software, licensed under:

  The MIT (X11) License

=for Pod::Coverage BUILDARGS BUILD

=cut
