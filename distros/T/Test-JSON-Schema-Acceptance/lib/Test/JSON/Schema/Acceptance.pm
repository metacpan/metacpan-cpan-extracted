use strict;
use warnings;
package Test::JSON::Schema::Acceptance; # git description: v1.004-2-g150a61e
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Acceptance testing for JSON-Schema based validators like JSON::Schema

our $VERSION = '1.005';

use 5.014;
no if "$]" >= 5.031009, feature => 'indirect';
use Test2::API ();
use Test2::Todo;
use Test2::Tools::Compare ();
use Try::Tiny;
use JSON::MaybeXS 1.004001;
use Storable 3.00 ();
use File::ShareDir 'dist_dir';
use Moo;
use MooX::TypeTiny 0.002002;
use Types::Standard 1.010002 qw(Str InstanceOf ArrayRef HashRef Dict Any HasMethods Bool Optional);
use Types::Common::Numeric 'PositiveOrZeroInt';
use Path::Tiny 0.069;
use List::Util 1.33 qw(any max sum0);
use namespace::clean;

has specification => (
  is => 'ro',
  isa => Str,
  lazy => 1,
  default => 'draft2020-12',
  predicate => '_has_specification',
);

has test_dir => (
  is => 'ro',
  isa => InstanceOf['Path::Tiny'],
  coerce => sub { path($_[0])->absolute('.') },
  lazy => 1,
  default => sub { path(dist_dir('Test-JSON-Schema-Acceptance'), 'tests', $_[0]->specification) },
);

has additional_resources => (
  is => 'ro',
  isa => InstanceOf['Path::Tiny'],
  coerce => sub { path($_[0])->absolute('.') },
  lazy => 1,
  default => sub { $_[0]->test_dir->parent->parent->child('remotes') },
);

has verbose => (
  is => 'ro',
  isa => Bool,
  default => 0,
);

has include_optional => (
  is => 'ro',
  isa => Bool,
  default => 0,
);

has skip_dir => (
  is => 'ro',
  isa => ArrayRef[Str],
  coerce => sub { ref($_[0]) ? $_[0] : [ $_[0] ] },
  lazy => 1,
  default => sub { [] },
);

has results => (
  is => 'rwp',
  init_arg => undef,
  isa => ArrayRef[Dict[
           file => InstanceOf['Path::Tiny'],
           map +($_ => PositiveOrZeroInt), qw(pass todo_fail fail),
         ]],
);

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my %args = @args % 2 ? ( specification => 'draft'.$args[0] ) : @args;
  $args{specification} = 'draft2020-12' if ($args{specification} // '') eq 'latest';
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

  warn "'skip_tests' option is deprecated" if $options->{skip_tests};

  my $ctx = Test2::API::context;

  if ($options->{add_resource}) {
    my $base = 'http://localhost:1234'; # TODO? make this customizable
    $ctx->note('adding resources from '.$self->additional_resources.' with the base URI "'.$base.'"...');
    $self->additional_resources->visit(
      sub {
        my ($path) = @_;
        return if not $path->is_file or $path !~ /\.json$/;
        my $data = $self->_json_decoder->decode($path->slurp_raw);
        my $file = $path->relative($self->additional_resources);
        my $uri = $base.'/'.$file;
        $options->{add_resource}->($uri => $data);
      },
      { recurse => 1 },
    );
  }

  $ctx->note('running tests in '.$self->test_dir.'...');
  my $tests = $self->_test_data;

  # [ { file => .., pass => .., fail => .. }, ... ]
  my @results;

  foreach my $one_file (@$tests) {
    my %results;
    next if $options->{tests} and $options->{tests}{file}
      and not grep $_ eq $one_file->{file},
        (ref $options->{tests}{file} eq 'ARRAY'
          ? @{$options->{tests}{file}} : $options->{tests}{file});

    $ctx->note('');

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

        my $todo;
        $todo = Test2::Todo->new(reason => 'Test marked TODO via deprecated "skip_tests"')
          if ref $options->{skip_tests} eq 'ARRAY'
            and grep +(($test_group->{description}.' - '.$test->{description}) =~ /$_/),
              @{$options->{skip_tests}};

        $todo = Test2::Todo->new(reason => 'Test marked TODO via "todo_tests"')
          if $options->{todo_tests}
            and any {
              my $o = $_;
              (not $o->{file} or grep $_ eq $one_file->{file}, (ref $o->{file} eq 'ARRAY' ? @{$o->{file}} : $o->{file}))
                and
              (not $o->{group_description} or grep $_ eq $test_group->{description}, (ref $o->{group_description} eq 'ARRAY' ? @{$o->{group_description}} : $o->{group_description}))
                and
              (not $o->{test_description} or grep $_ eq $test->{description}, (ref $o->{test_description} eq 'ARRAY' ? @{$o->{test_description}} : $o->{test_description}))
            }
            @{$options->{todo_tests}};

        my $result = $self->_run_test($one_file, $test_group, $test, $options);

        ++$results{ $result ? 'pass' : $todo ? 'todo_fail' : 'fail' };
      }
    }

    push @results, { file => $one_file->{file}, pass => 0, 'todo_fail' => 0, fail => 0, %results };
  }

  $self->_set_results(\@results);

  my $diag = $self->verbose ? 'diag' : 'note';

  $ctx->$diag("\n\n".'Results using '.ref($self).' '.$self->VERSION);

  my $submodule_status = path(dist_dir('Test-JSON-Schema-Acceptance'), 'submodule_status');
  if ($submodule_status->exists and $submodule_status->parent->subsumes($self->test_dir)) {
    chomp(my ($commit, $url) = $submodule_status->lines);
    $ctx->$diag('with commit '.$commit);
    $ctx->$diag('from '.$url.':');
  }
  if ($self->_has_specification) {
    $ctx->$diag('specification version: '.$self->specification);
  }
  else {
    $ctx->$diag('using custom test directory: '.$self->test_dir);
  }
  $ctx->$diag('optional tests included: '.($self->include_optional ? 'yes' : 'no'));

  $ctx->$diag('');
  my $length = max(10, map length $_->{file}, @$tests);
  $ctx->$diag(sprintf('%-'.$length.'s  pass  todo-fail  fail', 'filename'));
  $ctx->$diag('-'x($length + 23));
  $ctx->$diag(sprintf('%-'.$length.'s % 5d       % 4d  % 4d', @{$_}{qw(file pass todo_fail fail)}))
    foreach @results;

  my $total = +{ map { my $type = $_; $type => sum0(map $_->{$type}, @results) } qw(pass todo_fail fail) };
  $ctx->$diag('-'x($length + 23));
  $ctx->$diag(sprintf('%-'.$length.'s % 5d      % 5d % 5d', 'TOTAL', @{$total}{qw(pass todo_fail fail)}));
  $ctx->$diag('');

  $ctx->release;
}

sub _run_test {
  my ($self, $one_file, $test_group, $test, $options) = @_;

  my $test_name = $one_file->{file}.': "'.$test_group->{description}.'" - "'.$test->{description}.'"';

  my $pass; # ignores TODO status

  Test2::API::run_subtest($test_name,
    sub {
      my ($result, $schema_before, $data_before, $schema_after, $data_after);
      try {
        {
          local $Storable::flags = Storable::BLESS_OK | Storable::TIE_OK;
          local $Storable::canonical = 1;
          ($schema_before, $data_before) = map Storable::freeze(\$_),
            $test_group->{schema}, $test->{data};
        }

        $result = $options->{validate_data}
          ? $options->{validate_data}->($test_group->{schema}, $test->{data})
          : $options->{validate_json_string}->($test_group->{schema}, $self->_json_decoder->encode($test->{data}));

        {
          local $Storable::flags = Storable::BLESS_OK | Storable::TIE_OK;
          local $Storable::canonical = 1;
          ($schema_after, $data_after) = map Storable::freeze(\$_),
            $test_group->{schema}, $test->{data};
        }

        my $ctx = Test2::API::context;

        # skip the ugly matrix comparison
        my $expected = $test->{valid} ? 'true' : 'false';
        if ($result xor $test->{valid}) {
          my $got = $result ? 'true' : 'false';
          $ctx->fail('test failed', 'expected '.$expected.'; got '.$got);
          $pass = 0;
        }
        else {
          $ctx->ok(1, 'test passes: data is valid: '.$expected);
          $pass = 1;
        }

        $pass &&= Test2::Tools::Compare::is($data_after, $data_before, 'evaluator did not mutate data')
          if $data_before ne $data_after;
        $pass &&= Test2::Tools::Compare::is($schema_after, $schema_before, 'evaluator did not mutate schema')
          if $schema_before ne $schema_after;

        $ctx->release;
      }
      catch {
        chomp(my $exception = $_);
        my $ctx = Test2::API::context;
        $ctx->fail('died: '.$exception);
        $ctx->release;
      };
    },
    { buffered => 1, inherit_trace => 1 },
  );

  return $pass;
}

has _json_decoder => (
  is => 'ro',
  isa => HasMethods[qw(encode decode)],
  lazy => 1,
  default => sub { JSON::MaybeXS->new(allow_nonref => 1, utf8 => 1) },
);

# see JSON::MaybeXS::is_bool
my $json_bool = InstanceOf[qw(JSON::XS::Boolean Cpanel::JSON::XS::Boolean JSON::PP::Boolean)];

has _test_data => (
  is => 'lazy',
  isa => ArrayRef[Dict[
           file => InstanceOf['Path::Tiny'],
           json => ArrayRef[Dict[
             # id => Optional[Str],
             description => Str,
             comment => Optional[Str],
             schema => $json_bool|HashRef,
             tests => ArrayRef[Dict[
               # id => Optional[Str],
               data => Any,
               description => Str,
               comment => Optional[Str],
               valid => $json_bool,
             ]],
           ]],
         ]],
);

sub _build__test_data {
  my $self = shift;
  my @test_groups;

  $self->test_dir->visit(
    sub {
      my ($path) = @_;
      return if any { $self->test_dir->child($_)->subsumes($path) } @{ $self->skip_dir };
      return if not $path->is_file;
      return if $path !~ /\.json$/;
      my $data = $self->_json_decoder->decode($path->slurp_raw);
      return if not @$data; # placeholder files for renamed tests
      my $file = $path->relative($self->test_dir);
      push @test_groups, [
        scalar(split('/', $file)),
        {
          file => $file,
          json => $data,
        },
      ];
    },
    { recurse => $self->include_optional },
  );

  return [
    map $_->[1],
      sort { $a->[0] <=> $b->[0] || $a->[1]{file} cmp $b->[1]{file} }
      @test_groups
  ];
}

1;

__END__

=pod

=encoding UTF-8

=for stopwords validators Schemas ANDed ORed TODO

=head1 NAME

Test::JSON::Schema::Acceptance - Acceptance testing for JSON-Schema based validators like JSON::Schema

=head1 VERSION

version 1.005

=head1 SYNOPSIS

This module allows the
L<JSON Schema Test Suite|https://github.com/json-schema/JSON-Schema-Test-Suite> tests to be used in
perl to test a module that implements the JSON Schema specification ("json-schema"). These are the
same tests that many modules (libraries, plugins, packages, etc.) use to confirm support of
json-schema. Using this module to confirm support gives assurance of interoperability with other
modules that run the same tests in different languages.

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

This would determine if JSON::Schema's C<validate> method returns the right result for all of the
cases in the JSON Schema Test Suite, except for those listed in C<$skip_tests>.

=head1 DESCRIPTION

L<JSON Schema|http://json-schema.org> is an IETF draft (at time of writing) which allows you to
define the structure of JSON.

From the overview of the L<draft 2020-12 version of the
specification|https://json-schema.org/draft/2020-12/json-schema-core.html#rfc.section.3>:

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

This module allows other perl modules (for example JSON::Schema) to test that they are JSON
Schema-compliant, by running the tests from the official test suite, without having to manually
convert them to perl tests.

You are unlikely to want this module, unless you are attempting to write a module which implements
JSON Schema the specification, and want to test your compliance.

=head1 CONSTRUCTOR

  Test::JSON::Schema::Acceptance->new(specification => $specification_version)

Create a new instance of Test::JSON::Schema::Acceptance.

Available options (which are also available as accessor methods on the object) are:

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

C<draft2020-12>

=item *

C<latest> (alias for C<draft2020-12>)

=back

The default is C<latest>, but in the synopsis example, L<JSON::Schema> is testing draft 3
compliance.

(For backwards compatibility, C<new> can be called with a single numeric argument of 3 to 7, which
maps to C<draft3> through C<draft7>.)

=head2 test_dir

Instead of specifying a draft specification to test against, which will select the most appropriate
tests, you can pass in the name of a directory of tests to run directly. Files in this directory
should be F<.json> files following the format described in
L<https://github.com/json-schema-org/JSON-Schema-Test-Suite/blob/master/README.md>.

=head2 additional_resources

A directory of additional resources which should be made available to the implementation under the
base URI C<http://localhost:1234>. This is automatically provided if you did not override
C</test_dir>; otherwise, you need to supply it yourself, if any tests require it (for example by
containing C<< {"$ref": "http://localhost:1234/foo.json/#a/b/c"} >>). If you supply an
L</add_resource> value to L</acceptance> (see below), this will be done for you.

=head2 verbose

Optional. When true, prints version information and test result table such that it is visible
during C<make test> or C<prove>.

=head2 include_optional

Optional. When true, tests in subdirectories (most notably F<optional/> are also included.

=head2 skip_dir

Optional. Pass a string or arrayref consisting of relative path name(s) to indicate directories
(within the test directory as specified above with C<specification> or C<test_dir>) which will be
skipped. Note that this is only useful currently with C<include_optional => 1>, as otherwise all
subdirectories would be skipped anyway.

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

=head3 add_resource

Optional. A subroutine reference, which will be called at the start of L</acceptance> multiple
times, with two arguments: a URI (string), and a data structure containing schema data to be
associated with that URI, for use in some tests that use additional resources (see above). If you do
not provide this option, you will be responsible for ensuring that those additional resources are
made available to your implementation for the successful execution of the tests that rely on them.

For more information, see <https://json-schema.org/draft/2020-12/json-schema-core.html#rfc.section.9.1.2>.

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

=head2 results

After calling L</acceptance>, a list of test results are provided here. It is an arrayref of
hashrefs with four keys:

=over 4

=item *

file - the filename

=item *

pass - the number of pass results for that file

=item *

todo_fail - the number of fail results for that file that were marked TODO

=item *

fail - the number of fail results for that file (not including TODO tests)

=back

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

=for stopwords Karen Etheridge Daniel Perrett

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Daniel Perrett <dp13@sanger.ac.uk>

=back

=head1 COPYRIGHT AND LICENCE

This software is Copyright (c) 2015 by Ben Hutton.

This is free software, licensed under:

  The MIT (X11) License

=for Pod::Coverage BUILDARGS BUILD

=cut
