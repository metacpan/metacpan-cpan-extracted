package Test::Valgrind::Test::Action;

use strict;
use warnings;

use base qw<Test::Valgrind::Action::Test>;

my $extra_tests;

BEGIN {
 eval {
  require Test::Valgrind;
  require XSLoader;
  XSLoader::load('Test::Valgrind', $Test::Valgrind::VERSION);
 };
 if ($@) {
  $extra_tests = 0;
 } else {
  $extra_tests = 3;
  *report = *report_smart;
  *abort  = *abort_smart;
 }
}

use Test::Builder;

sub new {
 my $class = shift;

 $class->SUPER::new(
  diag        => 1,
  extra_tests => $extra_tests,
 );
}

my @filtered_reports;

sub report_smart {
 my ($self, $sess, $report) = @_;

 if ($report->can('is_leak') and $report->is_leak) {
  my $data  = $report->data;
  my @trace = map $_->[2] || '?',
               @{$data->{stack} || []}[0 .. 3];
  my $valid_trace = (
       $trace[0] eq 'malloc'
   and $trace[1] eq 'tv_leak'
   and ($trace[2] eq 'Perl_pp_entersub' or $trace[3] eq 'Perl_pp_entersub')
  );

  if ($valid_trace) {
   push @filtered_reports, [
    $report->dump,
    $data->{leakedbytes},
    $data->{leakedblocks},
   ];
   return;
  }
 }

 $self->SUPER::report($sess, $report);
}

sub abort_smart {
 my $self = shift;

 $extra_tests = 0;

 $self->SUPER::abort(@_);
}

sub DESTROY {
 return unless $extra_tests;

 my $tb = Test::Builder->new;

 $tb->is_eq(scalar(@filtered_reports), 1, 'caught one extra leak');

 if (@filtered_reports) {
  my $first = shift @filtered_reports;
  $tb->diag("The subsequent report was correctly caught:\n" . $first->[0]);
  $tb->is_eq($first->[1], 10_000, '10_000 bytes leaked');
  $tb->is_eq($first->[2], 1,      '  in one block');

  for my $extra_report (@filtered_reports) {
   $tb->diag(
    "The subsequent report should NOT have been caught:\n" . $extra_report->[0]
   );
  }
 } else {
  $tb->ok(0, 'no extra leak caught, hence no bytes leaked');
  $tb->ok(0, 'no extra leak caught, hence no block leaked');
 }
}

1;
