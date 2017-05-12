package Test::Flatten;

use strict;
use warnings;
use Test::More ();
use Test::Builder ();
use Term::ANSIColor qw(colored);

our $VERSION = '0.11';

our $BORDER_COLOR  = [qw|cyan bold|];
our $BORDER_CHAR   = '-';
our $BORDER_LENGTH = 78;
our $CAPTION_COLOR = ['clear'];
our $NOTE_COLOR    = ['yellow'];

our $ORG_SUBTEST = Test::Builder->can('subtest');
our $ORG_TEST_MORE_SUBTEST = Test::More->can('subtest');

$ENV{ANSI_COLORS_DISABLED} = 1 if $^O eq 'MSWin32';

sub import {
    my $class = caller(0);
    no warnings qw(redefine prototype);
    no strict 'refs';
    *Test::Builder::subtest = \&subtest;

    # backward campatibility
    *{"$class\::subtest"} = Test::More->can('subtest');
}

my $TEST_DIFF = 0;
END {
    if ($TEST_DIFF) {
        my $builder = Test::More->builder;
        _diag_plan($builder->{Curr_Test} - $TEST_DIFF, $builder->{Curr_Test});
        Test::Builder::_my_exit(255); # report fail
        undef $Test::Builder::Test;   # disabled original END{} block
    }
}

sub subtest {
    my ($self, $caption, $test, @args) = @_;

    my $builder = Test::More->builder;
    unless (ref $test eq 'CODE') {
        $builder->croak("subtest()'s second argument must be a code ref");
    }

    # copying original setting
    my $current_test = $builder->{Curr_Test};
    my $skip_all     = $builder->{Skip_All};
    my $have_plan    = $builder->{Have_Plan};
    my $no_plan      = $builder->{No_Plan};
    my $in_filter    = $builder->{__in_filter__};

    ## this idea from http://d.hatena.ne.jp/tokuhirom/20111017/1318831330
    if (my $filter  = $ENV{SUBTEST_FILTER}) {
        if ($caption =~ qr{$filter} || $in_filter) {
            $builder->{__in_filter__} = 1;
        }
        else {
            $builder->note(colored $NOTE_COLOR, "SKIP: $caption by SUBTEST_FILTER");
            return;
        }
    }

    $builder->note(colored $BORDER_COLOR, $BORDER_CHAR x $BORDER_LENGTH);
    $builder->note(colored $CAPTION_COLOR, $caption);
    $builder->note(colored $BORDER_COLOR, $BORDER_CHAR x $BORDER_LENGTH);

    # reset
    $builder->{Have_Plan} = 0;

    no warnings 'redefine';
    no strict 'refs';
    local *{ref($builder).'::plan'} = _fake_plan(\my $tests, \my $is_skip_all);
    local *{ref($builder).'::done_testing'} = sub {}; # temporary disabled

    use warnings;
    use strict;

    local $Test::Builder::Level = $Test::Builder::Level = 1;
    my $is_passing = eval { $test->(@args); 1 };
    my $e = $@;

    die $e if $e && !eval { $e->isa('Test::Builder::Exception') };

    if ($is_skip_all) {
        $builder->{Skip_All} = $skip_all;
    }
    elsif ($tests && $builder->{Curr_Test} != $current_test + $tests) {
        _diag_plan($tests, $builder->{Curr_Test} - $current_test);
        $TEST_DIFF = $builder->{Curr_Test} - $current_test - $tests;
        $is_passing = $builder->is_passing(0);
    }
    elsif ($builder->{Curr_Test} == $current_test) {
        $builder->croak("No tests run for subtest $caption");
    }

    # restore
    $builder->{Have_Plan}     = $have_plan;
    $builder->{No_Plan}       = $no_plan;
    $builder->{__in_filter__} = $in_filter;

    return $is_passing;
}

sub _diag_plan {
    my ($plan, $ran) = @_;
    my $s = $plan == 1 ? '' : 's';
    Test::More->builder->diag(sprintf 'Looks like you planned %d test%s but ran %d.',
        $plan, $s, $ran,
    );
}

sub _fake_plan {
    my ($tests, $is_skip_all) = @_;

    return sub {
        my ($self, $cmd, $arg) = @_;
        return unless $cmd;
        local $Test::Builder::Level = $Test::Builder::Level + 2;
        $self->croak("You tried to plan twice") if $self->{Have_Plan};

        if ($cmd eq 'no_plan') {
            local $Test::Builder::Level = $Test::Builder::Level + 1;
            $self->no_plan($arg);
        }
        elsif ($cmd eq 'skip_all') {
            local $Test::Builder::Level = $Test::Builder::Level + 1;
            $self->{Skip_All} = 1;
            $self->note(join q{ }, 'SKIP:', $arg) unless $self->no_header;
            $$is_skip_all = 1; # set flag
            die bless {}, 'Test::Builder::Exception';
        }
        elsif ($cmd eq 'tests') {
            if($arg) {
                local $Test::Builder::Level = $Test::Builder::Level + 1;
                unless ($arg =~ /^\+?\d+$/) {
                    $self->croak("Number of tests must be a positive integer.  You gave it '$arg'");
                }
                $$tests = $arg; # set tests
            }
            elsif( !defined $arg ) {
                $self->croak("Got an undefined number of tests");
            }
            else {
                $self->croak("You said to run 0 tests");
            }
        }
        else {
            my @args = grep { defined } ( $cmd, $arg );
            $self->croak("plan() doesn't understand @args");
        }
        return 1;
    };
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Test::Flatten - subtest output to a flatten

=head1 SYNOPSIS

in t/foo.t

  use Test::More;
  use Test::Flatten;

  subtest 'foo' => sub {
      pass 'OK';
  };
  
  subtest 'bar' => sub {
      pass 'ok';
      subtest 'baz' => sub {
          pass 'ok';
      };
  };

  done_testing;

run it

  $ prove -lvc t/foo.t
  t/foo.t .. 
  # ------------------------------------------------------------------------------
  # foo
  # ------------------------------------------------------------------------------
  ok 1 - ok
  # ------------------------------------------------------------------------------
  # bar
  # ------------------------------------------------------------------------------
  ok 2 - ok
  # ------------------------------------------------------------------------------
  # baz
  # ------------------------------------------------------------------------------
  ok 3 - ok
  1..3
  ok

oh, flatten!

=head1 DESCRIPTION

Test::Flatten is override Test::More::subtest.

The subtest I think there are some problems.

=over

=item 1. Caption is appears at end of subtest block.

  use Test::More;

  subtest 'foo' => sub {
      pass 'ok';
  };

  done_testing;

  # ok 1 - foo is end of subtest block.
  t/foo.t .. 
      ok 1 - ok
      1..1
  ok 1 - foo
  1..1
  ok

I want B<< FIRST >>.

=item 2. Summarizes the test would count.

  use Test::More;

  subtest 'foo' => sub {
      pass 'bar';
      pass 'baz';
  };

  done_testing;

  # total tests is 1
  t/foo.t .. 
      ok 1 - bar
      ok 2 - baz
      1..2
  ok 1 - foo
  1..1

I want B<< 2 >>.

=item 3. Forked test output will be broken. (Even with Test::SharedFork!)

  use Test::More;
  
  subtest 'foo' => sub {
      pass 'parent one';
      pass 'parent two';
      my $pid = fork;
      unless ($pid) {
          pass 'child one';
          pass 'child two';
          fail 'child three';
          exit;
      }
      wait;
      pass 'parent three';
  };
  
  done_testing;

  # success...?
  t/foo.t .. 
      ok 1 - parent one
      ok 2 - parent two
      ok 3 - child one
      ok 4 - child two
      not ok 5 - child three
      
      #   Failed test 'child three'
      #   at t/foo.t line 13.
      ok 3 - parent three
      1..3
  ok 1 - foo
  1..1
  ok

oh, really? I want B<< FAIL >> and sync count.

=back

Yes, We can!!

=head1 FUNCTIONS 

=over

=item C<< subtest($name, \&code) >>

This like Test::More::subtest.

=back

=head1 SUBTEST_FILTER

If you need, you can using C<< SUBTEST_FILTER >> environment.
This is just a B<< *hack* >> to skip only blocks matched the block name by environment variable.
C<< SUBTEST_FILTER >> variable can use regexp

  $ env SUBTEST_FILTER=foo prove -lvc t/bar.t
  # SKIP: bar by SUBTEST_FILTER
  # ------------------------------------------------------------------------------
  # foo
  # ------------------------------------------------------------------------------
  ok 1 - passed
  # SKIP: baz by SUBTEST_FILTER
  1..1

=head1 AUTHOR

xaicron E<lt>xaicron {at} cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2011 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<< Test::SharedFork >>

=cut
