package Test::Plan;

use 5.005;

use strict;
use warnings FATAL => qw(all);

use Config;
use Exporter;
use Test::Builder ();

use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION @SkipReasons);

@ISA = qw(Exporter);

$VERSION = 0.03;

@EXPORT = qw(need
             plan
             need_module
             need_min_perl_version
             need_min_module_version
             need_perl_iolayers
             need_threads
             need_perl
             under_construction
             skip_reason);

my $Test = Test::Builder->new;


# you need to load Test::More before Test::Plan if
# modules want to use functions in their own namspaces
if ($INC{'Test/More.pm'}) {

  no warnings qw(redefine);

  *Test::More::plan = \&plan;
}

sub import {

  # this is why the warnings pragma sucks - I know better
  # than Exporter whether the warnings it is about to throw
  # are ok or not, but
  #   no warnings qw(redefine);
  # doesn't work here by design.
  local $^W=0;

  shift->export_to_level(1, undef, @_ ? @_ : @EXPORT);
}


#---------------------------------------------------------------------
# plan() intelligently.  essentially a combination of
# Apache::Test::plan() and Test::More::plan()
#---------------------------------------------------------------------
sub plan {

  my @plan = @_;

  # Apache::Test::plan()
  if (@plan % 2) {

    my $condition = pop @plan;
    my $ref = ref $condition;
    my $meets_condition = 0;

    if ($ref) {
      if ($ref eq 'CODE') {
        # plan tests $n, \&foo;
        $meets_condition = $condition->();
      }
      elsif ($ref eq 'ARRAY') {
        # plan tests $n, [qw(CGI Foo::Bar)];
        $meets_condition = need_module($condition);
      }
      else {
        die "don't know how to handle a condition of type $ref";
      }
    }
    else {
      # we have the verdict already: true/false
      $meets_condition = $condition ? 1 : 0;
    }

    unless ($meets_condition) {
      my $reason = join ', ',
        @SkipReasons ? @SkipReasons : '';

      @SkipReasons = ();  # reset

      $Test->plan(skip_all => $reason);

      # this will not be reached except in tests, since
      # Test::Builder::plan() calls exit();
      return;
    }
  }

  $Test->plan(@plan);
}


#---------------------------------------------------------------------
# very similar to Apache::Test::need_module() except that it doesn't
# worry about Apache C modules for obvious reasons
#---------------------------------------------------------------------
sub need_module {

    my @modules = grep defined $_,
        ref($_[0]) eq 'ARRAY' ? @{ $_[0] } : @_;

    my @reasons = ();
    for (@modules) {
        eval "require $_";
        if ($@) {
            push @reasons, "cannot find module '$_'";
        }
    }
    if (@reasons) {
        push @SkipReasons, @reasons;
        return 0;
    }
    else {
        return 1;
    }
}


#---------------------------------------------------------------------
# nearly identical to Apache::Test::need_min_perl_version()
# as of 1.21.  here no version means any version and we trap
# non-numeric warnings
#---------------------------------------------------------------------
sub need_min_perl_version {
    my $version = shift;

    # no version means any version
    return 1 unless defined $version;

    { 
      no warnings qw(numeric);
      return 1 if $] >= $version;
    }

    push @SkipReasons, "perl >= $version is required";
    return 0;
}


#---------------------------------------------------------------------
# nearly identical to Apache::Test::need_min_module_version()
# as of 1.21.  here no version means any version
#---------------------------------------------------------------------
sub need_min_module_version {
    my($module, $version) = @_;

    # need_module requires the perl module
    return 0 unless need_module($module);

    # no version means any version
    return 1 unless defined $version;

    # support dev versions like 0.18_01
    return 1
        if eval { no warnings qw(numeric); $module->VERSION($version) };

    push @SkipReasons, "$module version $version or higher is required";
    return 0;
}


#---------------------------------------------------------------------
# identical to Apache::Test::need_perl_iolayers() as of 1.21
#---------------------------------------------------------------------
sub need_perl_iolayers {
    if (my $ext = $Config{extensions}) {
        #XXX: better test?  might need to test patchlevel
        #if support depends bugs fixed in bleedperl
        return $ext =~ m:PerlIO/scalar:;
    }
    0;
}


#---------------------------------------------------------------------
# identical to Apache::Test::config_enabled() as of 1.21
# not exported, so don't use it (it should be marked as private)
#---------------------------------------------------------------------
sub config_enabled {
    my $key = shift;
    defined $Config{$key} and $Config{$key} eq 'define';
}


#---------------------------------------------------------------------
# nearly identical to Apache::Test::need_perl() as of 1.21
#---------------------------------------------------------------------
sub need_perl {
    my $thing = shift || '';
    #XXX: $thing could be a version
    my $config;

    my $have = \&{"need_perl_$thing"};
    if (defined &$have) {
        return 1 if $have->();
    }
    else {
        for my $key ($thing, "use$thing") {
            if (exists $Config{$key}) {
                $config = $key;
                return 1 if config_enabled($key);
            }
        }
    }

    push @SkipReasons, $config ?
      "Perl was not built with $config enabled" :
        "$thing is not available with this version of Perl";

    return 0;
}


#---------------------------------------------------------------------
# similar Apache::Test::need_threads() as of 1.21
# except we don't check APR
#---------------------------------------------------------------------
sub need_threads {
    my $status = 1;

    # check Perl's useithreads
    my $key = 'useithreads';
    unless (exists $Config{$key} and config_enabled($key)) {
        $status = 0;
        push @SkipReasons, "Perl was not built with 'ithreads' enabled";
    }

    return $status;
}


#---------------------------------------------------------------------
# identical to Apache::Test::under_construction as of 1.21
#---------------------------------------------------------------------
sub under_construction {
    push @SkipReasons, "This test is under construction";
    return 0;
}


#---------------------------------------------------------------------
# identical to Apache::Test::skip_reason() as of 1.21
#---------------------------------------------------------------------
sub skip_reason {
    my $reason = shift || 'no reason specified';
    push @SkipReasons, $reason;
    return 0;
}


#---------------------------------------------------------------------
# identical to Apache::Test::need() as of 1.21
#---------------------------------------------------------------------
sub need {
    my $need_all = 1;
    for my $cond (@_) {
        if (ref $cond eq 'HASH') {
            while (my($reason, $value) = each %$cond) {
                $value = $value->() if ref $value eq 'CODE';
                next if $value;
                push @SkipReasons, $reason;
                $need_all = 0;
            }
        }
        elsif ($cond =~ /^(0|1)$/) {
            $need_all = 0 if $cond == 0;
        }
        else {
            $need_all = 0 unless need_module($cond);
        }
    }
    return $need_all;
}

1;

__END__

=head1 NAME

Test::Plan - add some intelligence to your test plan

=head1 SYNOPSIS

  use Test::More;
  use Test::Plan;

  plan tests => 2, need_module('Foo::Bar');

  # ... do something that requires Foo::Bar in your test environment...

  ok($foo, 'this is Test::More::ok()');

=head1 DESCRIPTION

C<Test::Plan> provides a convenient way of scheduling tests (or not)
when the test environment has complex needs.  it includes an
alternate C<plan()> function that is C<Test::Builder> compliant,
which means C<Test::Plan> can be used alongside C<Test::More> and
other popular C<Test::> modules.  it also includes a few helper 
functions specifically designed to be used with C<plan()> to make
test planning that much easier.

in reality, there is nothing you can't do with this module that cannot
be accomplished via the traditional C<skip_all>.  however, the syntax
and convenient helper functions may appeal to some folks.  in fact,
if you are familiar with C<Apache-Test> then you should
feel right at home - the C<plan()> syntax and associated helper
functions are idential in almost all respects to what C<Apache::Test>
provides.

so yes, there is lots of code duplication between this module and
C<Apache::Test>.  but I like this syntax so much I wanted to share
it with the non-Apache inspired world.

=head1 PLAN

the following functions are identical in almost all respects to those
found in the C<Apache::Test> package, so reading the C<Apache::Test>
manpage is highly encouraged.

=over 4

=item plan()

for all practical purposes, C<Test::Plan::plan()> is a drop-in
replacement for the other C<plan()> functions you have been using
already.  in other words you can just 

  use Test::Plan;

  plan tests => 3;

and be on your way.  where C<Test::Plan::plan()> is different is that
it takes an optional final argument that is used to decide whether
the plan should occur or not.  that is

  use Test::Plan;

  plan tests => 3, sub { $^O ne 'MSWin32' };

has the same results as

  use Test::More;

  if ( $^O ne 'MSWin32' ) {
    plan tests => 3;
  }
  else {
    plan 'skip_all';
  }

much better, eh?  here is what you need to know...

first, the final argument to C<plan()> can be in any of the following
formats.  if the result evaluates to true the test is planned, otherwise
the entire test is skipped a la C<skip_all>.

=over 4

=item * a boolean

the boolean option is typically the result from a subroutine that
has already been evaluated.  here is an example

  plan tests => 3, foo();

at runtime, C<foo()> will be evaluated and the results passed as the
final argument to C<plan()>.  if the results are true then C<plan()>
will plan your tests, otherwise the entire test file is skipped.

while you can write your own subroutines, as in the above example,
you may be interested in using some of the helper functions
C<Test::Plan> provides.

=item * a reference to a subroutine

if the final argument to C<plan()> is a reference to a subroutine
that subroutine will be evaluated and the results used to decide
whether to plan your tests.

  plan tests => 3, sub { 1 };

or

  plan tests => 3, \&foo;

if the subroutine evaluates to true then C<plan()> will plan your
tests, otherwise the entire test file is skipped.

=item * a reference to an array

this is a shortcut to calling C<need_module()> for each element in
the array.  for example

  plan tests => 3, [ qw(CGI LWP::UserAgent) ];

is exactly equivalent to

  plan tests => 3, need_module(qw(CGI LWP::UserAgent));

see the below explanation of C<need_module()> for more details.

=back

in general, C<Test::Plan::plan()> functions identically to 
C<Apache::Test::plan()>, so reading the C<Apache::Test> manpage
is highly encouraged.

=back

=head1 HELPER FUNCTIONS

you might be wondering where the skip message comes from when you use
C<Test::Plan::plan()> as described above.  the answer is that it comes
from using one or more of the following helper functions.

=over 4

=item need()

C<need()> is a special function that is best described via an
illustration.

  plan tests => 3, need need_module('Foo::Bar'),
                        need_min_module_version(CGI => 3.0),
                        need_min_perl_version(5.6);

what happens here is that C<need()> is dispatching to each
decision-making function and aggregating the results.  the result
is that the skip message contains all the conditions that failed,
not merely the first one.  contrast the above to this

  plan tests => 3, need_module('Foo::Bar')              &&
                   need_min_module_version(CGI => 3.0)  &&
                   need_min_perl_version(5.6);

in this example if C<Foo::Bar> is not present the list of preconditions
is short-circuited and the others not even tried, which means that if
you fix the C<Foo::Bar> problem and run the test again you might be
hit with other precondition failures.  C<need()> is a function of
convenience, showing you all your failed preconditions at once.

C<need()> can accept arguments in the following forms:

=over 4

=item * another helper function

this corresponds to the C<need()> examples shown to this point.  note
that this is I<not> the same as a boolean - C<need()> looks specifically
for 0 or 1 to be returned from its functions.  for the reasons why see
the next entry or read that C<Apache::Test> manpage.

=item * a scalar

a simple scalar will be passed to C<need_module()>

  plan tests => 3, need qw(Foo::Bar CGI);

see the below entry for C<need_module()> for the specifics.

=item * a reference to a hash

the key to the hash should be the skip message and the value the thing
to be evaluated, either a boolean or a reference to a subroutine.

  plan tests => 3, need { 'not Win32' => sub { $^O eq 'MSWin32' },
                          'no Foo'    => need_module('Foo::Bar'),
                        };

if the value evaluates to true then key is used as the skip message.

=back

this is all rather complex, so if you are confused please see the 
C<Apache::Test> manpage.  remember, I didn't write this stuff :)

=item need_module()

determines whether a Perl module can be successfully required.

  plan tests => 3, need_module('Foo::Bar');

will plan the tests only if C<Foo::Bar> is present.  the skip
message will show that the module could not be found.

C<need_module()> accepts either a list or a reference to an
array.  in both cases all modules must be present for C<plan()>
to plan tests.

  plan tests => 3, need_module [ 'CGI', 'Foo::Bar', 'File::Spec' ];

=item need_min_module_version()

this first calls C<need_module()>.  if that succeeds then the module
version is checked using C<UNIVERSAL::VERSION>.  if the version
is greater than or equal to the specified version tests are planned.

  plan tests => 3, need_min_module_version(CGI => 3.01);

if no version is specified then a version check is not performed.
this is a difference between C<Test::Plan> and C<Apache::Test>.

=item need_min_perl_version()

similar to C<need_min_module_version()>, checks to make sure that the
version of perl currently running is greater than or equal to the
version specified.

  plan tests => 3, need_min_perl_version(5.6);

=item need_perl()

C<need_perl()> queries C<Config> for various properties.  for example

  plan tests => 3, need_perl('ithreads');

is equivalent to 

  plan tests => 3, sub { $Config{useithreads} eq 'define' };

in general, the argument to C<need_perl()> is prepended with the string
C<'use'> and the value within C<%Config> checked.  a special case is
C<'iolayers'> which is dispatched to C<need_perl_iolayers()>.

=item need_threads()

a shortcut to C<need_perl('ithreads')>.

=item need_perl_iolayers()

returns true if perl contains PerlIO extensions.

=item skip_reason()

this is a direct interface into the skip reason mechanism C<Test::Plan>
uses behind the scenes.

  plan tests => 3, skip_reason("I haven't implemented this feature yet");

while it is useful for one liners, you can also use it from your own
custom subroutine

  plan tests => 3, \&foo;

  sub foo {
    ...
    return 1 if $foo;  # success
    return skip_reason('condition foo not met');
  }

=item under_construction()

skips the test with a generic 'under construction' skip message

  plan tests => 3, under_construction;

=back

=head1 CAVEATS

this module jumps through some hoops so that you can use both
C<Test::Plan> and C<Test::More> in the same script without a lot
of trouble.  the main issue is that both modules want to export
C<plan()> into your namespace, which results in warnings and
collisions.

if you want to keep things simple, load C<Test::More> before
C<Test::Plan> and everything should work out ok.

  use Test::More;
  use Test::Plan;

  plan tests => 3, need_min_perl_version(5.6);

  # nary a warning to be found.

otherwise you would need to be explicit in what you import
from each module

  use Test::Plan qw(plan need_module);
  use Test::More import => [qw(!plan)];

  plan tests => 3, need_module('Foo::Bar');

yucko.

=head1 FEATURES/BUGS

since the vast majority of the code here has been lifted from
C<Apache::Test> it is very well tested.  the only novel thing
is the C<Test::More> workarounds mentioned in CAVEATS.

=head1 SEE ALSO

Apache::Test, Test::More

=head1 AUTHOR

Geoffrey Young <geoff@modperlcookbook.org>

=head1 COPYRIGHT

Copyright (c) 2005, Geoffrey Young
All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut
