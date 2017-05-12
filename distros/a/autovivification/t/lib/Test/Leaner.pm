package Test::Leaner;

use 5.006;
use strict;
use warnings;

=head1 NAME

Test::Leaner - A slimmer Test::More for when you favor performance over completeness.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use Test::Leaner tests => 10_000;
    for (1 .. 10_000) {
     ...
     is $one, 1, "checking situation $_";
    }


=head1 DESCRIPTION

When profiling some L<Test::More>-based test script that contained about 10 000 unit tests, I realized that 60% of the time was spent in L<Test::Builder> itself, even though every single test actually involved a costly C<eval STRING>.

This module aims to be a partial replacement to L<Test::More> in those situations where you want to run a large number of simple tests.
Its functions behave the same as their L<Test::More> counterparts, except for the following differences :

=over 4

=item *

Stringification isn't forced on the test operands.
However, L</ok> honors C<'bool'> overloading, L</is> and L</is_deeply> honor C<'eq'> overloading (and just that one), L</isnt> honors C<'ne'> overloading, and L</cmp_ok> honors whichever overloading category corresponds to the specified operator.

=item *

L</pass>, L</fail>, L</ok>, L</is>, L</isnt>, L</like>, L</unlike>, L</cmp_ok> and L</is_deeply> are all guaranteed to return the truth value of the test.

=item *

C<isn't> (the sub C<t> in package C<isn>) is not aliased to L</isnt>.

=item *

L</like> and L</unlike> don't special case regular expressions that are passed as C<'/.../'> strings.
A string regexp argument is always treated as the source of the regexp, making C<like $text, $rx> and C<like $text, qr[$rx]> equivalent to each other and to C<cmp_ok $text, '=~', $rx> (and likewise for C<unlike>).

=item *

L</cmp_ok> throws an exception if the given operator isn't a valid Perl binary operator (except C<'='> and variants).
It also tests in scalar context, so C<'..'> will be treated as the flip-flop operator and not the range operator.

=item *

L</is_deeply> doesn't guard for memory cycles.
If the two first arguments present parallel memory cycles, the test may result in an infinite loop.

=item *

The tests don't output any kind of default diagnostic in case of failure ; the rationale being that if you have a large number of tests and a lot of them are failing, then you don't want to be flooded by diagnostics.
Moreover, this allows a much faster variant of L</is_deeply>.

=item *

C<use_ok>, C<require_ok>, C<can_ok>, C<isa_ok>, C<new_ok>, C<subtest>, C<explain>, C<TODO> blocks and C<todo_skip> are not implemented.

=back

=cut

use Exporter ();

my $main_process;

BEGIN {
 $main_process = $$;

 if ("$]" >= 5.008 and $INC{'threads.pm'}) {
  my $use_ithreads = do {
   require Config;
   no warnings 'once';
   $Config::Config{useithreads};
  };
  if ($use_ithreads) {
   require threads::shared;
   *THREADSAFE = sub () { 1 };
  }
 }
 unless (defined &Test::Leaner::THREADSAFE) {
  *THREADSAFE = sub () { 0 }
 }
}

my ($TAP_STREAM, $DIAG_STREAM);

my ($plan, $test, $failed, $no_diag, $done_testing);

our @EXPORT = qw<
 plan
 skip
 done_testing
 pass
 fail
 ok
 is
 isnt
 like
 unlike
 cmp_ok
 is_deeply
 diag
 note
 BAIL_OUT
>;

=head1 ENVIRONMENT

=head2 C<PERL_TEST_LEANER_USES_TEST_MORE>

If this environment variable is set, L<Test::Leaner> will replace its functions by those from L<Test::More>.
Moreover, the symbols that are imported when you C<use Test::Leaner> will be those from L<Test::More>, but you can still only import the symbols originally defined in L<Test::Leaner> (hence the functions from L<Test::More> that are not implemented in L<Test::Leaner> will not be imported).
If your version of L<Test::More> is too old and doesn't have some symbols (like L</note> or L</done_testing>), they will be replaced in L<Test::Leaner> by croaking stubs.

This may be useful if your L<Test::Leaner>-based test script fails and you want extra diagnostics.

=cut

sub _handle_import_args {
 my @imports;

 my $i = 0;
 while ($i <= $#_) {
  my $item = $_[$i];
  my $splice;
  if (defined $item) {
   if ($item eq 'import') {
    push @imports, @{ $_[$i+1] };
    $splice  = 2;
   } elsif ($item eq 'no_diag') {
    lock $plan if THREADSAFE;
    $no_diag = 1;
    $splice  = 1;
   }
  }
  if ($splice) {
   splice @_, $i, $splice;
  } else {
   ++$i;
  }
 }

 return @imports;
}

if ($ENV{PERL_TEST_LEANER_USES_TEST_MORE}) {
 require Test::More;

 my $leaner_stash = \%Test::Leaner::;
 my $more_stash   = \%Test::More::;

 my %stubbed;

 for (@EXPORT) {
  my $replacement = exists $more_stash->{$_} ? *{$more_stash->{$_}}{CODE}
                                             : undef;
  unless (defined $replacement) {
   $stubbed{$_}++;
   $replacement = sub {
    @_ = ("$_ is not implemented in this version of Test::More");
    goto &croak;
   };
  }
  no warnings 'redefine';
  $leaner_stash->{$_} = $replacement;
 }

 my $import = sub {
  my $class = shift;

  my @imports = &_handle_import_args;
  if (@imports == grep /^!/, @imports) {
   # All imports are negated, or @imports is empty
   my %negated;
   /^!(.*)/ and ++$negated{$1} for @imports;
   push @imports, grep !$negated{$_}, @EXPORT;
  }

  my @test_more_imports;
  for (@imports) {
   if ($stubbed{$_}) {
    my $pkg = caller;
    no strict 'refs';
    *{$pkg."::$_"} = $leaner_stash->{$_};
   } elsif (/^!/ or !exists $more_stash->{$_} or exists $leaner_stash->{$_}) {
    push @test_more_imports, $_;
   } else {
    # Croak for symbols in Test::More but not in Test::Leaner
    Exporter::import($class, $_);
   }
  }

  my $test_more_import = 'Test::More'->can('import');
  return unless $test_more_import;

  @_ = (
   'Test::More',
   @_,
   import => \@test_more_imports,
  );
  {
   lock $plan if THREADSAFE;
   push @_, 'no_diag' if $no_diag;
  }

  goto $test_more_import;
 };

 no warnings 'redefine';
 *import = $import;

 return 1;
}

sub NO_PLAN  () { -1 }
sub SKIP_ALL () { -2 }

BEGIN {
 if (THREADSAFE) {
  threads::shared::share($_) for $plan, $test, $failed, $no_diag, $done_testing;
 }

 lock $plan if THREADSAFE;

 $plan   = undef;
 $test   = 0;
 $failed = 0;
}

sub carp {
 my $level = 1 + ($Test::Builder::Level || 0);
 my @caller;
 do {
  @caller = caller $level--;
 } while (!@caller and $level >= 0);
 my ($file, $line) = @caller[1, 2];
 warn @_, " at $file line $line.\n";
}

sub croak {
 my $level = 1 + ($Test::Builder::Level || 0);
 my @caller;
 do {
  @caller = caller $level--;
 } while (!@caller and $level >= 0);
 my ($file, $line) = @caller[1, 2];
 die @_, " at $file line $line.\n";
}

sub _sanitize_comment {
 $_[0] =~ s/\n+\z//;
 $_[0] =~ s/#/\\#/g;
 $_[0] =~ s/\n/\n# /g;
}

=head1 FUNCTIONS

The following functions from L<Test::More> are implemented and exported by default.

=head2 C<plan>

    plan tests => $count;
    plan 'no_plan';
    plan skip_all => $reason;

See L<Test::More/plan>.

=cut

sub plan {
 my ($key, $value) = @_;

 return unless $key;

 lock $plan if THREADSAFE;

 croak("You tried to plan twice") if defined $plan;

 my $plan_str;

 if ($key eq 'no_plan') {
  croak("no_plan takes no arguments") if $value;
  $plan       = NO_PLAN;
 } elsif ($key eq 'tests') {
  croak("Got an undefined number of tests") unless defined $value;
  croak("You said to run 0 tests")          unless $value;
  croak("Number of tests must be a positive integer.  You gave it '$value'")
                                            unless $value =~ /^\+?[0-9]+$/;
  $plan       = $value;
  $plan_str   = "1..$value";
 } elsif ($key eq 'skip_all') {
  $plan       = SKIP_ALL;
  $plan_str   = '1..0 # SKIP';
  if (defined $value) {
   _sanitize_comment($value);
   $plan_str .= " $value" if length $value;
  }
 } else {
  my @args = grep defined, $key, $value;
  croak("plan() doesn't understand @args");
 }

 if (defined $plan_str) {
  local $\;
  print $TAP_STREAM "$plan_str\n";
 }

 exit 0 if $plan == SKIP_ALL;

 return 1;
}

sub import {
 my $class = shift;

 my @imports = &_handle_import_args;

 if (@_) {
  local $Test::Builder::Level = ($Test::Builder::Level || 0) + 1;
  &plan;
 }

 @_ = ($class, @imports);
 goto &Exporter::import;
}

=head2 C<skip>

    skip $reason => $count;

See L<Test::More/skip>.

=cut

sub skip {
 my ($reason, $count) = @_;

 lock $plan if THREADSAFE;

 if (not defined $count) {
  carp("skip() needs to know \$how_many tests are in the block")
                                      unless defined $plan and $plan == NO_PLAN;
  $count = 1;
 } elsif ($count =~ /[^0-9]/) {
  carp('skip() was passed a non-numeric number of tests.  Did you get the arguments backwards?');
  $count = 1;
 }

 for (1 .. $count) {
  ++$test;

  my $skip_str = "ok $test # skip";
  if (defined $reason) {
   _sanitize_comment($reason);
   $skip_str  .= " $reason" if length $reason;
  }

  local $\;
  print $TAP_STREAM "$skip_str\n";
 }

 no warnings 'exiting';
 last SKIP;
}

=head2 C<done_testing>

    done_testing;
    done_testing $count;

See L<Test::More/done_testing>.

=cut

sub done_testing {
 my ($count) = @_;

 lock $plan if THREADSAFE;

 $count = $test unless defined $count;
 croak("Number of tests must be a positive integer.  You gave it '$count'")
                                                 unless $count =~ /^\+?[0-9]+$/;

 if (not defined $plan or $plan == NO_PLAN) {
  $plan         = $count; # $plan can't be NO_PLAN anymore
  $done_testing = 1;
  local $\;
  print $TAP_STREAM "1..$plan\n";
 } else {
  if ($done_testing) {
   @_ = ('done_testing() was already called');
   goto &fail;
  } elsif ($plan != $count) {
   @_ = ("planned to run $plan tests but done_testing() expects $count");
   goto &fail;
  }
 }

 return 1;
}

=head2 C<ok>

    ok $ok;
    ok $ok, $desc;

See L<Test::More/ok>.

=cut

sub ok ($;$) {
 my ($ok, $desc) = @_;

 lock $plan if THREADSAFE;

 ++$test;

 my $test_str = "ok $test";
 $ok or do {
  $test_str   = "not $test_str";
  ++$failed;
 };
 if (defined $desc) {
  _sanitize_comment($desc);
  $test_str .= " - $desc" if length $desc;
 }

 local $\;
 print $TAP_STREAM "$test_str\n";

 return $ok;
}

=head2 C<pass>

    pass;
    pass $desc;

See L<Test::More/pass>.

=cut

sub pass (;$) {
 unshift @_, 1;
 goto &ok;
}

=head2 C<fail>

    fail;
    fail $desc;

See L<Test::More/fail>.

=cut

sub fail (;$) {
 unshift @_, 0;
 goto &ok;
}

=head2 C<is>

    is $got, $expected;
    is $got, $expected, $desc;

See L<Test::More/is>.

=cut

sub is ($$;$) {
 my ($got, $expected, $desc) = @_;
 no warnings 'uninitialized';
 @_ = (
  (not(defined $got xor defined $expected) and $got eq $expected),
  $desc,
 );
 goto &ok;
}

=head2 C<isnt>

    isnt $got, $expected;
    isnt $got, $expected, $desc;

See L<Test::More/isnt>.

=cut

sub isnt ($$;$) {
 my ($got, $expected, $desc) = @_;
 no warnings 'uninitialized';
 @_ = (
  ((defined $got xor defined $expected) or $got ne $expected),
  $desc,
 );
 goto &ok;
}

my %binops = (
 'or'  => 'or',
 'xor' => 'xor',
 'and' => 'and',

 '||'  => 'hor',
 ('//' => 'dor') x ("$]" >= 5.010),
 '&&'  => 'hand',

 '|'   => 'bor',
 '^'   => 'bxor',
 '&'   => 'band',

 'lt'  => 'lt',
 'le'  => 'le',
 'gt'  => 'gt',
 'ge'  => 'ge',
 'eq'  => 'eq',
 'ne'  => 'ne',
 'cmp' => 'cmp',

 '<'   => 'nlt',
 '<='  => 'nle',
 '>'   => 'ngt',
 '>='  => 'nge',
 '=='  => 'neq',
 '!='  => 'nne',
 '<=>' => 'ncmp',

 '=~'  => 'like',
 '!~'  => 'unlike',
 ('~~' => 'smartmatch') x ("$]" >= 5.010),

 '+'   => 'add',
 '-'   => 'substract',
 '*'   => 'multiply',
 '/'   => 'divide',
 '%'   => 'modulo',
 '<<'  => 'lshift',
 '>>'  => 'rshift',

 '.'   => 'concat',
 '..'  => 'flipflop',
 '...' => 'altflipflop',
 ','   => 'comma',
 '=>'  => 'fatcomma',
);

my %binop_handlers;

sub _create_binop_handler {
 my ($op) = @_;
 my $name = $binops{$op};
 croak("Operator $op not supported") unless defined $name;
 {
  local $@;
  eval <<"IS_BINOP";
sub is_$name (\$\$;\$) {
 my (\$got, \$expected, \$desc) = \@_;
 \@_ = (scalar(\$got $op \$expected), \$desc);
 goto &ok;
}
IS_BINOP
  die $@ if $@;
 }
 $binop_handlers{$op} = do {
  no strict 'refs';
  \&{__PACKAGE__."::is_$name"};
 }
}

=head2 C<like>

    like $got, $regexp_expected;
    like $got, $regexp_expected, $desc;

See L<Test::More/like>.

=head2 C<unlike>

    unlike $got, $regexp_expected;
    unlike $got, $regexp_expected, $desc;

See L<Test::More/unlike>.

=cut

{
 no warnings 'once';
 *like   = _create_binop_handler('=~');
 *unlike = _create_binop_handler('!~');
}

=head2 C<cmp_ok>

    cmp_ok $got, $op, $expected;
    cmp_ok $got, $op, $expected, $desc;

See L<Test::More/cmp_ok>.

=cut

sub cmp_ok ($$$;$) {
 my ($got, $op, $expected, $desc) = @_;
 my $handler = $binop_handlers{$op};
 unless ($handler) {
  local $Test::More::Level = ($Test::More::Level || 0) + 1;
  $handler = _create_binop_handler($op);
 }
 @_ = ($got, $expected, $desc);
 goto $handler;
}

=head2 C<is_deeply>

    is_deeply $got, $expected;
    is_deeply $got, $expected, $desc;

See L<Test::More/is_deeply>.

=cut

BEGIN {
 local $@;
 if (eval { require Scalar::Util; 1 }) {
  *_reftype = \&Scalar::Util::reftype;
 } else {
  # Stolen from Scalar::Util::PP
  require B;
  my %tmap = qw<
   B::NULL   SCALAR

   B::HV     HASH
   B::AV     ARRAY
   B::CV     CODE
   B::IO     IO
   B::GV     GLOB
   B::REGEXP REGEXP
  >;
  *_reftype = sub ($) {
   my $r = shift;

   return undef unless length ref $r;

   my $t = ref B::svref_2object($r);

   return exists $tmap{$t} ? $tmap{$t}
                           : length ref $$r ? 'REF'
                                            : 'SCALAR'
  }
 }
}

sub _deep_ref_check {
 my ($x, $y, $ry) = @_;

 no warnings qw<numeric uninitialized>;

 if ($ry eq 'ARRAY') {
  return 0 unless $#$x == $#$y;

  my ($ex, $ey);
  for (0 .. $#$y) {
   $ex = $x->[$_];
   $ey = $y->[$_];

   # Inline the beginning of _deep_check
   return 0 if defined $ex xor defined $ey;

   next if not(ref $ex xor ref $ey) and $ex eq $ey;

   $ry = _reftype($ey);
   return 0 if _reftype($ex) ne $ry;

   return 0 unless $ry and _deep_ref_check($ex, $ey, $ry);
  }

  return 1;
 } elsif ($ry eq 'HASH') {
  return 0 unless keys(%$x) == keys(%$y);

  my ($ex, $ey);
  for (keys %$y) {
   return 0 unless exists $x->{$_};
   $ex = $x->{$_};
   $ey = $y->{$_};

   # Inline the beginning of _deep_check
   return 0 if defined $ex xor defined $ey;

   next if not(ref $ex xor ref $ey) and $ex eq $ey;

   $ry = _reftype($ey);
   return 0 if _reftype($ex) ne $ry;

   return 0 unless $ry and _deep_ref_check($ex, $ey, $ry);
  }

  return 1;
 } elsif ($ry eq 'SCALAR' or $ry eq 'REF') {
  return _deep_check($$x, $$y);
 }

 return 0;
}

sub _deep_check {
 my ($x, $y) = @_;

 no warnings qw<numeric uninitialized>;

 return 0 if defined $x xor defined $y;

 # Try object identity/eq overloading first. It also covers the case where
 # $x and $y are both undefined.
 # If either $x or $y is overloaded but none has eq overloading, the test will
 # break at that point.
 return 1 if not(ref $x xor ref $y) and $x eq $y;

 # Test::More::is_deeply happily breaks encapsulation if the objects aren't
 # overloaded.
 my $ry = _reftype($y);
 return 0 if _reftype($x) ne $ry;

 # Shortcut if $x and $y are both not references and failed the previous
 # $x eq $y test.
 return 0 unless $ry;

 # We know that $x and $y are both references of type $ry, without overloading.
 _deep_ref_check($x, $y, $ry);
}

sub is_deeply {
 @_ = (
  &_deep_check,
  $_[2],
 );
 goto &ok;
}

sub _diag_fh {
 my $fh = shift;

 return unless @_;

 lock $plan if THREADSAFE;
 return if $no_diag;

 my $msg = join '', map { defined($_) ? $_ : 'undef' } @_;
 _sanitize_comment($msg);
 return unless length $msg;

 local $\;
 print $fh "# $msg\n";

 return 0;
};

=head2 C<diag>

    diag @lines;

See L<Test::More/diag>.

=cut

sub diag {
 unshift @_, $DIAG_STREAM;
 goto &_diag_fh;
}

=head2 C<note>

    note @lines;

See L<Test::More/note>.

=cut

sub note {
 unshift @_, $TAP_STREAM;
 goto &_diag_fh;
}

=head2 C<BAIL_OUT>

    BAIL_OUT;
    BAIL_OUT $desc;

See L<Test::More/BAIL_OUT>.

=cut

sub BAIL_OUT {
 my ($desc) = @_;

 lock $plan if THREADSAFE;

 my $bail_out_str = 'Bail out!';
 if (defined $desc) {
  _sanitize_comment($desc);
  $bail_out_str  .= "  $desc" if length $desc; # Two spaces
 }

 local $\;
 print $TAP_STREAM "$bail_out_str\n";

 exit 255;
}

END {
 if ($main_process == $$ and not $?) {
  lock $plan if THREADSAFE;

  if (defined $plan) {
   if ($failed) {
    $? = $failed <= 254 ? $failed : 254;
   } elsif ($plan >= 0) {
    $? = $test == $plan ? 0 : 255;
   }
   if ($plan == NO_PLAN) {
    local $\;
    print $TAP_STREAM "1..$test\n";
   }
  }
 }
}

=pod

L<Test::Leaner> also provides some functions of its own, which are never exported.

=head2 C<tap_stream>

    my $tap_fh = tap_stream;
    tap_stream $fh;

Read/write accessor for the filehandle to which the tests are outputted.
On write, it also turns autoflush on onto C<$fh>.

Note that it can only be used as a write accessor before you start any thread, as L<threads::shared> cannot reliably share filehandles.

Defaults to C<STDOUT>.

=cut

sub tap_stream (;*) {
 if (@_) {
  $TAP_STREAM = $_[0];

  my $fh = select $TAP_STREAM;
  $|++;
  select $fh;
 }

 return $TAP_STREAM;
}

tap_stream *STDOUT;

=head2 C<diag_stream>

    my $diag_fh = diag_stream;
    diag_stream $fh;

Read/write accessor for the filehandle to which the diagnostics are printed.
On write, it also turns autoflush on onto C<$fh>.

Just like L</tap_stream>, it can only be used as a write accessor before you start any thread, as L<threads::shared> cannot reliably share filehandles.

Defaults to C<STDERR>.

=cut

sub diag_stream (;*) {
 if (@_) {
  $DIAG_STREAM = $_[0];

  my $fh = select $DIAG_STREAM;
  $|++;
  select $fh;
 }

 return $DIAG_STREAM;
}

diag_stream *STDERR;

=head2 C<THREADSAFE>

This constant evaluates to true if and only if L<Test::Leaner> is thread-safe, i.e. when this version of C<perl> is at least 5.8, has been compiled with C<useithreads> defined, and L<threads> has been loaded B<before> L<Test::Leaner>.
In that case, it also needs a working L<threads::shared>.

=head1 DEPENDENCIES

L<perl> 5.6.

L<Exporter>, L<Test::More>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-leaner at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Leaner>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Leaner

=head1 COPYRIGHT & LICENSE

Copyright 2010,2011,2013 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Except for the fallback implementation of the internal C<_reftype> function, which has been taken from L<Scalar::Util> and is

Copyright 1997-2007 Graham Barr, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Test::Leaner
