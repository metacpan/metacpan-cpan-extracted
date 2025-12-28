package Test::WWW::Mechanize::Driver;
use Carp; use strict; use warnings;
use Test::WWW::Mechanize::Driver::YAMLLoader;
use Test::WWW::Mechanize::Driver::Util qw/ :all /;
require Test::WWW::Mechanize::Driver::MagicValues;
use Test::Builder;
require URI;
use Storable qw/dclone/;

my $Test = Test::Builder->new;
our $VERSION = '1.1';
our $TODO;
our $CURRENT_GROUP;

=pod

=head1 NAME

Test::WWW::Mechanize::Driver - Drive Test::WWW::Mechanize Object Using YAML Configuration Files

=head1 SYNOPSIS

 use strict; use warnings;
 use Test::WWW::Mechanize::Driver;
 Test::WWW::Mechanize::Driver->new(
   load => [ glob( "t/*.yaml" ) ]
 )->run;


 use strict; use warnings;
 use Test::WWW::Mechanize::Driver;
 Test::WWW::Mechanize::Driver->new->run; # runs basename($0)*.{yaml.yml,dat}

=head1 DESCRIPTION

Write Test::WWW::Mechanize tests in YAML. This module will load the tests
make a plan and run the tests. Supports every-page tests, SKIP, TODO, and
any object supporting the Test::WWW::Mechanize interface.

This document focuses on the Test::WWW::Mechanize::Driver object and the
options it can take. See the L<Manual|Test::WWW::Mechanize::Driver::Manual>
for a full description of the test data file format.

=head1 USAGE

=head3 new

 Test::WWW::Mechanize::Driver->new( [ OPTIONS ] )

=over 4

=item add_to_plan

Number of tests running outside of Driver control. Use this option if your
test script perfoirms other tests such as build-up of mock objects.

=item after_response

=item after_response_tests

C<after_response> is a callback sub triggered once per test group (is not
triggered by submit_form_ok or other actions) immediately after the initial
response is received. If any tests are run in the callback, the
C<after_response_tests> option must be set to the number of tests to be run
each time so that the driver may make the proper plan.

=item base

Base URL for any test uris which are not absolute. If not defined, all test
uris must be absolute.

=item load

Array ref of file names which should be loaded by the Driver. These tests
are loaded at object creation time.

=item loader

Name of loader package or object with C<package-E<gt>load( $file )> method.
Defaults to C<Test::WWW::Mechanize::Driver::YAMLLoader>.

=item mechanize

Override default mechanize object. The default object is:

 Test::WWW::Mechanize->new(cookie_jar => {})

=item no_plan

When true, calling C<-E<gt>run> will not print a test plan.

=back

=cut

our %valid_params = map +($_,1),
qw/
    add_to_plan after_response after_response_tests base load loader mechanize no_plan
/;
sub new {
  my $class = shift;
  my %x = @_;
  my ($invalid) = grep !$valid_params{$_}, keys %x;
  croak "Invalid Parameter '$invalid'" if defined($invalid);

  # Create loader so that "require YAML" happens early on
  $x{loader} ||= Test::WWW::Mechanize::Driver::YAMLLoader->new;

  my $x = bless \%x, $class;
  $x->load;
  return $x;
}

=head3 load

 num tests loaded = $tester->load( test filenames )

Load tests.

=cut

sub load {
  my $x = shift;

  $$x{load} = [ $$x{load} ] if HAS($x, 'load') and !ref($$x{load});

  push @{$$x{load}}, @_;

  my $t = $x->tests;
  $x->_load;
  $x->tests - $t;
}

=head3 tests

 num tests = $tester->tests()

Calculate number of tests currently loaded

=cut

sub tests {
  my $x = shift;
  my $tests = $$x{add_to_plan} || 0;
  return $tests unless $$x{groups};
  $tests += $x->_tests_in_group($_) for @{$$x{groups}};
  return $tests;
}

=head3 test_groups

 num groups = $tester->test_groups()

Return number of test groups currently loaded

=cut

sub test_groups {
  my $x = shift;
  return 0 unless $$x{groups};
  return 0 + @{$$x{groups}};
}

=head3 run

 $tester->run()

Run each group of tests

=cut

sub run {
  my $x = shift;
  $x->_autoload unless $$x{_loaded};
  die "No test groups!" unless $$x{groups};
  $x->_ensure_plan;
  $x->_run_group( $_ ) for @{$$x{groups}};
}

=head3 mechanize

 mech = $tester->mechanize()

Return or construct mechanize object

=cut

sub mechanize {
  my $x = shift;
  return $$x{mechanize} if $$x{mechanize};
  require Test::WWW::Mechanize;
  $$x{mechanize} = Test::WWW::Mechanize->new(cookie_jar => {});
}

=head1 INTERNAL METHODS

=head3 _ensure_plan

 $tester->_ensure_plan()

Feed a plan (expected_tests) to Test::Builder if a plan has not yet been given.

=cut

sub _ensure_plan {
  my $x = shift;
  $Test->expected_tests($x->tests) unless $Test->expected_tests;
}

=head3 _run_group

 $tester->_run_group( group hash )

Run a group of tests. Performs group-level actions (SKIP, TODO) and tests
initial request.

=cut

sub _run_group {
  my ($x, $group) = @_;
  $CURRENT_GROUP = $group;

  if ($$group{SKIP}) {
    local $TODO = undef;
    $Test->skip($$group{SKIP}) for 1..$x->_tests_in_group($group);
    return;
  }

  local $TODO = $$group{TODO};
  $x->_make_initial_request( $group );
  $x->_run_test( $group, $_ ) for @{$$group{_actions}};
}

=head3 _make_initial_request

 $tester->_make_initial_request( group hash )

Perform initial GET, POST, ... request. Makes after_response callback if
present.

=cut

sub _make_initial_request {
  my ($x, $group) = @_;
  my $method = ($$group{method} ||= 'GET');
  my @params = ($$group{parameters} ? $$group{parameters} : ());
  my $label = $x->_test_label($group, "$method $$group{uri}", @{$$group{_id}});

  if (uc($method) eq 'GET') {
    my $uri = build_uri( $$group{uri}, @params );
    $x->mechanize->get_ok( $uri, $label );
  }
  elsif (uc($method) eq 'POST') {
    $x->mechanize->post_ok( $$group{uri}, @params, $label );
  }
  else { die "Unimplemented request method: '$method'" }

  $$x{after_response}->($x->mechanize, $group) if $$x{after_response};
  return 1;
}

=head3 _run_test

 $tester->_run_test( group hash, test hash )

Run an individual test. Tests (an action) at theis stage should be in one
of the following forms:

 { sub => sub { ... do stuff },
 }

 { name => "mechanize method name",
   args => [ array of method arguments ],
 }

=cut

sub _run_test {
  my ($x, $group, $test) = @_;

  if ($$test{sub}) {
    return $$test{sub}->();
  }

  my $t = $$test{name};
  $x->mechanize->$t( @{$$test{args}} );
}

=head3 _load

 $tester->_load()

Open test files (listed in C<@{$$x{load}}>) and attempt to load each
contained document. Each testfile is loaded only once.

=cut

sub _load {
  my $x = shift;
  return unless HAS($x, 'load') and 'ARRAY' eq ref($$x{load});

  for my $file (@{$$x{load}}) {
    next if $$x{_loaded}{$file}++;

    my @docs = eval { $$x{loader}->load( $file ) };
    die "While parsing test file '$file':\n$@" if $@ or !@docs;

    my $document = 1;
    $x->_load_doc( $_, [$file, $document++] ) for @docs;

    # local configs last only until end of file
    $x->_clear_local_config;
  }
}

=head3 _load_doc

 $tester->_load_doc( any doc, id array )

Determine document type and hand off to appropriate loaders.

=cut

sub _load_doc {
  my ($x, $doc, $id) = @_;

  if (!ref($doc)) {
    return 1;
  }

  elsif ('HASH' eq ref($doc)) {
    $x->_push_local_config($doc);
  }

  elsif ('ARRAY' eq ref($doc)) {
    my $test = 1;
    $x->_load_group($_, [@$id, $test++]) for @$doc;
  }

  else {
    die "Unknown document type ".ref($doc);
  }
}

=head3 _load_group

 $tester->_load_group( non-canonical group hash, id array )

Actually perform test "loading". As test groups are loaded the they are:

 * canonicalized:
     - all tests moved to actions array with one test per entry
     - url misspelling -> uri
     - uri -> $$x{base}/uri if necessary
 * tagged: the test's location in the file is inserted into the test hash

=cut

our %config_options = map +($_,1),
qw/
    uri parameters method description SKIP TODO
/;
our %config_aliases =
qw/
    url     uri
    parms   parameters
    params  parameters
/;

# mech methods
our %scalar_tests = map +($_,1),
qw/
    title_is title_like title_unlike
    base_is base_like base_unlike
    content_is content_contains content_lacks content_like content_unlike
    page_links_content_like page_links_content_unlike
    links_ok click_ok
/;

# values are mech methods
our %aliases =
qw/
    is          content_is
    contains    content_contains
    lacks       content_lacks
    like        content_like
    unlike      content_unlike
/;

# mech methods
our %bool_tests = map +($_,1), qw/ page_links_ok html_lint_ok /;
our %kv_tests = map +($_,1),
qw/
    has_tag has_tag_like
    link_status_is link_status_isnt
    link_content_like link_content_unlike
/;
our %hash_tests = map +($_,1), qw/ submit_form_ok follow_link_ok /;
our %mech_action = map +($_,1),
qw/
    get put reload back follow_link form_number form_name
    form_with_fields field select set_fields set_visible tick untick
    click click_button submit submit_form add_header delete_header
    save_content dump_links dump_images dump_forms dump_all redirect_ok
    request credentials stuff_inputs
/;

sub _load_group {
  my ($x, $group, $id) = @_;
  $x->_apply_local_config( $group );

  # We're all about convenience here, For example, I want to be able to
  # perform simple contains tests without setting up an "_actions" sequence.
  # To do that, we need to munge the group hash a bit.
  my @keys = keys %$group;
  my @actions;
  for (@keys) {
    # the actual "actions" element, pushed to end of actions array so it
    # happens after the toplevel actions.
    if ($_ eq 'actions') {
      for (@{delete $$group{actions}}) {
        while (my ($k, $v) = each %$_) {
          push @actions, { name => $k, args => $v };
        }
      }
    }

    # leave internal configuration options where they are
    elsif (TRUE( \%config_options, $_ )
        or TRUE( \%config_aliases, $_ )
          ) {
      $$group{$config_aliases{$_}} = $$group{$_} if TRUE( \%config_aliases, $_ ) and !HAS( $group, $config_aliases{$_} );
      next;
    }

    # Put anything that looks like a test action on the front of the action
    # list (again, so that explicit action sequences occur after transplanted
    # initial load actions).
    elsif (TRUE( \%scalar_tests, $_ )
        or TRUE( \%bool_tests, $_ )
        or TRUE( \%kv_tests, $_ )
        or TRUE( \%hash_tests, $_ )
        or TRUE( \%mech_action, $_ )
        or TRUE( \%aliases, $_ )
        or $x->mechanize->can($_)
          ) { unshift @actions, { name => $_, args => $$group{$_}, _transplant => 1 } }

    # anything else is considered a custom config value and will be
    # preserved in the top level group hash.
  }

  $$group{uri} = URI->new_abs($$group{uri}, $$x{base})->as_string if $$x{base};

  $$group{_id} = $id;
  $$group{_actions} = $x->_prepare_actions( $group, \@actions, $id );
  push @{$$x{groups}}, $group;
}

=head3 _prepare_actions

 canon-test (actions) array = $x->_prepare_actions( canon-group hash, actions array, group id array )

Prepare array of actions by:

 * expanding aliases
 * expanding tests

=cut

sub _prepare_actions {
  my ($x, $group, $actions, $id) = @_;
  my @expanded;

  my $action = 1;
  for my $a (@$actions) {
    $$a{name} = $aliases{$$a{name}} if HAS( \%aliases, $$a{name} );

    push @expanded, $x->_expand_tests($group, $a, [@$id, $action++])
  }

  return \@expanded;
}


=head3 _expand_tests

 list of canon-tests = $tester->_expand_tests( canon-group hash, non-canon action item, id array )

Expand a logical action item into possibly many explicit test items. When
executed, each test item will increment the test count be exactly 1.

 * prepares argument list

=cut

sub _expand_tests {
  my ($x, $group, $action, $id) = @_;
  my $name = $$action{name};
  my $args = $$action{args};
  my $test = 'a';

  # SCALAR TESTS
  if (TRUE( \%scalar_tests, $name )) {
    return map
      +{ %$action, args => [(($name =~ /_like$/) ? qr/$_/ : $_), $x->_test_label($group, $name, @$id, $test)], id => [@$id, $test++] },
        ('ARRAY' eq ref($args)) ? @$args : $args;
  }

  # KV TESTS
  if (TRUE( \%kv_tests, $name )) {
    my @tests;
    while (my ($k, $v) = each %$args) {
      push @tests,
        { %$action, id => [@$id, $test++],
          args => [$k, (($name =~ /(?:_|_un)like$/) ? qr/$v/ : $v),
                   $x->_test_label($group, $name, @$id, $test)],
        };
    }
    return @tests;
  }

  # HASH TESTS
  if (TRUE( \%hash_tests, $name )) {
    my @tests;
    $$action{id} = [@$id, $test++];
    $$action{args} = [$$action{args}, $x->_test_label($group, $name, @{$$action{id}})];
    push @tests, $action;
    return @tests;
  }

  # BOOLEAN TESTS
  if (TRUE( \%bool_tests, $name )) {
    $$action{id} = $id;
    $$action{args} = [ $x->_test_label($group, $name, @$id) ];
    return $action;
  }

  # MECHANIZE ACTIONS
  if (TRUE( \%mech_action, $name )) {
    $$action{id} = $id;
    $$action{sub} = sub {
      my $res = eval {
        $x->mechanize->$name( ('ARRAY' eq ref($args)) ? @$args
                            : ('HASH'  eq ref($args)) ? %$args
                            : $args
                            );
        1;
      };
      # plain mechanize actions don't report "ok". Force a test based on
      # just evaluation fatality since we take an action spot.
      local $Test::Builder::Level = $Test::Builder::Level + 1;
      $Test->diag( "$name: $@" ) if $@;
      $Test->ok(($res and !$@), "$name mechanize action");
    };
    return $action;
  }

  die "Invalid action: '$name'";
}

=head3 _test_label

 label = $tester->_test_label( group, name, id list )

Convert id components into something human-readable. For example:

 "[description] content_contains: file basic.yml, doc 3, group 5, test 2.b"

=cut

sub _test_label {
  my ($x, $group, $name, $file, $doc, $group_no, @id) = @_;
  local $" = '.';

  my $desc = "";
  $desc = "[$$group{description}] " if defined($$group{description});

  my $test = "";
  $test = ", test @id" if @id;

  "$desc$name: file $file, doc $doc, group $group_no$test"
}

=head3 _tests_in_group

 $tester->_tests_in_group($group)

Calculates number of tests attributable to the given group. Accounts for
initial requerst, explicit actions, and tests in any callbacks.

=cut

sub _tests_in_group {
  my ($x, $group) = @_;
  my $tests = 0;

  # 1 test for the initial request
  $tests += 1;

  # tests performed in callbacks
  for (qw/after_response_tests before_request_tests/) {
    $tests += $$x{$_} || 0;
  }

  # 1 test for each action in the group
  $tests += 0+@{$$group{_actions}};

  return $tests;
}

=head3 _autoload

 $tester->_autoload()

Attempt to load test files based on current script name. removes .t or .pl
from C<$0> and globs C<base*.{yaml,yml,dat}>

=cut

sub _autoload {
  my $x = shift;
  my $glob = $0;
  $glob =~ s/\.(?:t|pl)$//;
  my @autoload = grep +(-r $_), glob("$glob*.{yaml,yml,dat}");
  $x->load( @autoload );
}

=head3 _clear_local_config

 $tester->_clear_local_config()

Configs local to a series of test documents should be cleared after each
file is loaded.

=cut

sub _clear_local_config {
  my $x = shift;
  $$x{_local_config} = {};
}

=head3 _push_local_config

Merge a new configuration into the local configuration. called for each
hash document in a test configuration file.

=cut

sub _push_local_config {
  my ($x, $config) = @_;
  $$x{_local_config} ||= {};
  %{$$x{_local_config}} = (%{$$x{_local_config}}, %$config);
}

=head3 _apply_local_config

Merge a new configuration into the local configuration. called for each
hash document in a test configuration file.

=cut

sub _apply_local_config {
  my ($x, $group) = @_;
  $$x{_local_config} ||= {};
  %$group = (%{dclone($$x{_local_config})}, %$group);
}




1;

=head1 TODO

=over 4

=item test and perhaps implement proper enctype="multipart/form-data" file uploads

=item HEAD, PUT, DELETE requests

=item Custom Request headers (probably as a "headers" top level hash item so avoid using that as a custom field)

=back

=cut

=head1 AUTHOR

The original version of this code written by Dean Serenevy while under
contract with National Financial Management who graciously allowed me to
release it to the public.

 Dean Serenevy
 dean@serenevy.net
 https://serenevy.net/

=head1 LICENSE

This software is hereby placed into the public domain. If you use this
code, a simple comment in your code giving credit and an email letting
me know that you find it useful would be courteous but is not required.

The software is provided "as is" without warranty of any kind, either
expressed or implied including, but not limited to, the implied warranties
of merchantability and fitness for a particular purpose. In no event shall
the authors or copyright holders be liable for any claim, damages or other
liability, whether in an action of contract, tort or otherwise, arising
from, out of or in connection with the software or the use or other
dealings in the software.

=head1 SEE ALSO

L<WWW::Mechanize>, L<Test::WWW::Mechanize>

=cut
