package Test::Valgrind;

use strict;
use warnings;

=head1 NAME

Test::Valgrind - Generate suppressions, analyse and test any command with valgrind.

=head1 VERSION

Version 1.19

=cut

our $VERSION = '1.19';

=head1 SYNOPSIS

    # From the command-line
    perl -MTest::Valgrind leaky.pl

    # From the command-line, snippet style
    perl -MTest::Valgrind -e 'leaky()'

    # In a test file
    use Test::More;
    eval 'use Test::Valgrind';
    plan skip_all => 'Test::Valgrind is required to test your distribution with valgrind' if $@;
    leaky();

    # In all the test files of a directory
    prove --exec 'perl -Iblib/lib -Iblib/arch -MTest::Valgrind' t/*.t

=head1 DESCRIPTION

This module is a front-end to the C<Test::Valgrind::*> API that lets you run Perl code through the C<memcheck> tool of the C<valgrind> memory debugger, to test for memory errors and leaks.
If they aren't available yet, it will first generate suppressions for the current C<perl> interpreter and store them in the portable flavour of F<~/.perl/Test-Valgrind/suppressions/$VERSION>.
The actual run will then take place, and tests will be passed or failed according to the result of the analysis.

The complete API is much more versatile than this.
By declaring an appropriate L<Test::Valgrind::Command> class, you can run any executable (that is, not only Perl scripts) under valgrind, generate the corresponding suppressions on-the-fly and convert the analysis result to TAP output so that it can be incorporated into your project's testsuite.
If you're not interested in producing TAP, you can output the results in whatever format you like (for example HTML pages) by defining your own L<Test::Valgrind::Action> class.

Due to the nature of perl's memory allocator, this module can't track leaks of Perl objects.
This includes non-mortalized scalars and memory cycles.
However, it can track leaks of chunks of memory allocated in XS extensions with C<Newx> and friends or C<malloc>.
As such, it's complementary to the other very good leak detectors listed in the L</SEE ALSO> section.

=head1 METHODS

=head2 C<analyse>

    Test::Valgrind->analyse(%options);

Run a C<valgrind> analysis configured by C<%options> :

=over 4

=item *

C<< command => $command >>

The L<Test::Valgrind::Command> object (or class name) to use.

Defaults to L<Test::Valgrind::Command::PerlScript>.

=item *

C<< tool => $tool >>

The L<Test::Valgrind::Tool> object (or class name) to use.

Defaults to L<Test::Valgrind::Tool::memcheck>.

=item *

C<< action => $action >>

The L<Test::Valgrind::Action> object (or class name) to use.

Defaults to L<Test::Valgrind::Action::Test>.

=item *

C<< file => $file >>

The file name of the script to analyse.

Ignored if you supply your own custom C<command>, but mandatory otherwise.

=item *

C<< callers => $number >>

Specify the maximum stack depth studied when valgrind encounters an error.
Raising this number improves granularity.

Ignored if you supply your own custom C<tool>, otherwise defaults to C<24> (the maximum allowed by C<valgrind>).

=item *

C<< diag => $bool >>

If true, print the output of the test script as diagnostics.

Ignored if you supply your own custom C<action>, otherwise defaults to false.

=item *

C<< regen_def_supp => $bool >>

If true, forcefully regenerate the default suppression file.

Defaults to false.

=item *

C<< no_def_supp => $bool >>

If true, do not use the default suppression file.

Defaults to false.

=item *

C<< allow_no_supp => $bool >>

If true, force running the analysis even if the suppression files do not refer to any C<perl>-related symbol.

Defaults to false.

=item *

C<< extra_supps => \@files >>

Also use suppressions from C<@files> besides C<perl>'s.

Defaults to empty.

=back

=cut

sub _croak {
 require Carp;
 Carp::croak(@_);
}

my %skippable_errors = (
 session => [
  'Empty valgrind candidates list',
  'No appropriate valgrind executable could be found',
 ],
 action  => [ ],
 tool    => [ ],
 command => [ ],
 run     => [
  'No compatible suppressions available',
 ],
);

my %filter_errors;

for my $obj (keys %skippable_errors) {
 my @errors = @{$skippable_errors{$obj} || []};
 if (@errors) {
  my $rxp   = join '|', @errors;
  $rxp      = qr/($rxp)\s+at.*/;
  $filter_errors{$obj} = sub {
   my ($err) = @_;
   if ($err =~ /$rxp/) {
    return ($1, 1);
   } else {
    return ($err, 0);
   }
  };
 } else {
  $filter_errors{$obj} = sub {
   return ($_[0], 0);
  };
 }
}

sub _default_abort {
 my ($err) = @_;

 require Test::Builder;
 my $tb   = Test::Builder->new;
 my $plan = $tb->has_plan;
 if (defined $plan) {
  $tb->BAIL_OUT($err);
  return 255;
 } else {
  $tb->skip_all($err);
  return 0;
 }
}

sub analyse {
 shift;

 my %args = @_;

 my $instanceof = sub {
  require Scalar::Util;
  Scalar::Util::blessed($_[0]) && $_[0]->isa($_[1]);
 };

 my $tool = delete $args{tool};
 unless ($tool->$instanceof('Test::Valgrind::Tool')) {
  my $callers = delete $args{callers} || 24;
  $callers = 24 if $callers <= 0;
  require Test::Valgrind::Tool;
  local $@;
  $tool = eval {
   Test::Valgrind::Tool->new(
    tool    => $tool || 'memcheck',
    callers => $callers,
   );
  };
  unless ($tool) {
   my ($err, $skippable) = $filter_errors{tool}->($@);
   _croak($err) unless $skippable;
   return _default_abort($err);
  }
 }

 require Test::Valgrind::Session;
 my $sess = eval {
  Test::Valgrind::Session->new(
   min_version => $tool->requires_version,
   map { $_ => delete $args{$_} } qw<
    regen_def_supp
    no_def_supp
    allow_no_supp
    extra_supps
   >
  );
 };
 unless ($sess) {
  my ($err, $skippable) = $filter_errors{session}->($@);
  _croak($err) unless $skippable;
  return _default_abort($err);
 }

 my $action = delete $args{action};
 unless ($action->$instanceof('Test::Valgrind::Action')) {
  require Test::Valgrind::Action;
  local $@;
  $action = eval {
   Test::Valgrind::Action->new(
    action => $action || 'Test',
    diag   => delete $args{diag},
   );
  };
  unless ($action) {
   my ($err, $skippable) = $filter_errors{action}->($@);
   _croak($err) unless $skippable;
   return _default_abort($err);
  }
 }

 my $cmd = delete $args{command};
 unless ($cmd->$instanceof('Test::Valgrind::Command')) {
  require Test::Valgrind::Command;
  local $@;
  $cmd = eval {
   Test::Valgrind::Command->new(
    command => $cmd || 'PerlScript',
    file    => delete $args{file},
    args    => [ '-MTest::Valgrind=run,1' ],
   );
  };
  unless ($cmd) {
   my ($err, $skippable) = $filter_errors{command}->($@);
   _croak($err) unless $skippable;
   $action->abort($sess, $err);
   return $action->status($sess);
  }
 }

 {
  local $@;
  eval {
   $sess->run(
    command => $cmd,
    tool    => $tool,
    action  => $action,
   );
   1
  } or do {
   my ($err, $skippable) = $filter_errors{run}->($@);
   if ($skippable) {
    $action->abort($sess, $err);
    return $action->status($sess);
   } else {
    require Test::Valgrind::Report;
    $action->report($sess, Test::Valgrind::Report->new_diag($@));
   }
  }
 }

 my $status = $sess->status;
 $status = 255 unless defined $status;

 return $status;
}

=head2 C<import>

    use Test::Valgrind %options;

In the parent process, L</import> calls L</analyse> with the arguments it received itself - except that if no C<file> option was supplied, it tries to pick the first caller context that looks like a script.
When the analysis ends, it exits with the status returned by the action (for the default TAP-generator action, it's the number of failed tests).

In the child process, it just C<return>s so that the calling code is actually run under C<valgrind>, albeit two side-effects :

=over 4

=item *

L<Perl::Destruct::Level> is loaded and the destruction level is set to C<3>.

=item *

Autoflush on C<STDOUT> is turned on.

=back

=cut

# We use as little modules as possible in run mode so that they don't pollute
# the analysis. Hence all the requires.

my $run;

sub import {
 my $class = shift;
 $class = ref($class) || $class;

 _croak('Optional arguments must be passed as key => value pairs') if @_ % 2;
 my %args = @_;

 if (defined delete $args{run} or $run) {
  require Perl::Destruct::Level;
  Perl::Destruct::Level::set_destruct_level(3);
  {
   my $oldfh = select STDOUT;
   $|++;
   select $oldfh;
  }
  $run = 1;
  return;
 }

 my $file = delete $args{file};
 unless (defined $file) {
  my ($next, $last_pm);
  for (my $l = 0; 1; ++$l) {
   $next = (caller $l)[1];
   last unless defined $next;
   next if $next =~ /^\s*\(\s*eval\s*\d*\s*\)\s*$/;
   if ($next =~ /\.pmc?$/) {
    $last_pm = $next;
   } else {
    $file = $next;
    last;
   }
  }
  $file = $last_pm unless defined $file;
 }

 unless (defined $file) {
  require Test::Builder;
  Test::Builder->new->diag('Couldn\'t find a valid source file');
  return;
 }

 if ($file ne '-e') {
  exit $class->analyse(
   file => $file,
   %args,
  );
 }

 require File::Temp;
 my $tmp = File::Temp->new;

 require Filter::Util::Call;
 Filter::Util::Call::filter_add(sub {
  my $status = Filter::Util::Call::filter_read();
  if ($status > 0) {
   print $tmp $_;
  } elsif ($status == 0) {
   close $tmp;
   my $code = $class->analyse(
    file => $tmp->filename,
    %args,
   );
   exit $code;
  }
  $status;
 });
}

=head1 VARIABLES

=head2 C<$dl_unload>

When set to true, all dynamic extensions that were loaded during the analysis will be unloaded at C<END> time by L<DynaLoader/dl_unload_file>.

Since this obfuscates error stack traces, it's disabled by default.

=cut

our $dl_unload;

END {
 if ($dl_unload and $run and eval { require DynaLoader; 1 }) {
  my @rest;
  DynaLoader::dl_unload_file($_) or push @rest, $_ for @DynaLoader::dl_librefs;
  @DynaLoader::dl_librefs = @rest;
 }
}

=head1 CAVEATS

Perl 5.8 is notorious for leaking like there's no tomorrow, so the suppressions are very likely not to be complete on it.
You also have a better chance to get more accurate results if your perl is built with debugging enabled.
Using the latest C<valgrind> available will also help.

This module is not really secure.
It's definitely not taint safe.
That shouldn't be a problem for test files.

What your tests output to C<STDOUT> and C<STDERR> is eaten unless you pass the C<diag> option, in which case it will be reprinted as diagnostics.

=head1 DEPENDENCIES

L<XML::Twig>, L<File::HomeDir>, L<Env::Sanctify>, L<Perl::Destruct::Level>.

=head1 SEE ALSO

All the C<Test::Valgrind::*> API, including L<Test::Valgrind::Command>, L<Test::Valgrind::Tool>, L<Test::Valgrind::Action> and L<Test::Valgrind::Session>.

The C<valgrind(1)> man page.

L<Test::LeakTrace>.

L<Devel::Leak>, L<Devel::LeakTrace>, L<Devel::LeakTrace::Fast>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-valgrind at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Valgrind>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Valgrind

=head1 ACKNOWLEDGEMENTS

RafaE<euml>l Garcia-Suarez, for writing and instructing me about the existence of L<Perl::Destruct::Level> (Elizabeth Mattijsen is a close second).

H.Merijn Brand, for daring to test this thing.

David Cantrell, for providing shell access to one of his smokers where the tests were failing.

The Debian-perl team, for offering all the feedback they could regarding the build issues they met.

All you people that showed interest in this module, which motivated me into completely rewriting it.

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009,2010,2011,2013,2015,2016 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Test::Valgrind
