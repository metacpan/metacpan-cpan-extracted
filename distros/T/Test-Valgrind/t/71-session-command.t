#!perl

use strict;
use warnings;

BEGIN { delete $ENV{PATH} }

use Test::More tests => 2;

use Test::Valgrind::Command;
use Test::Valgrind::Tool;
use Test::Valgrind::Session;

use lib 't/lib';
use Test::Valgrind::FakeValgrind;

my $cmd = Test::Valgrind::Command->new(
 command => 'Perl',
 args    => [ '-e1' ],
);

{
 package Test::Valgrind::Parser::Dummy;

 use base 'Test::Valgrind::Parser';

 sub parse { }
}

{
 package Test::Valgrind::Tool::Dummy;

 use base 'Test::Valgrind::Tool::memcheck';

 sub parser_class { 'Test::Valgrind::Parser::Dummy' }
}

my $tool = Test::Valgrind::Tool::Dummy->new();

{
 package Test::Valgrind::Action::Dummy;

 use base 'Test::Valgrind::Action';

 sub do_suppressions { 0 }

 sub report {
  my ($self, $sess, $report) = @_;

  if ($report->is_diag) {
   my $contents = $report->data;
   if ($contents !~ /^(?:Using valgrind |No suppressions used)/) {
    ::diag($contents);
   }
   return;
  } else {
   $self->SUPER::report($sess, $report);
  }
 }
}

my $action = Test::Valgrind::Action::Dummy->new();

SKIP: {
 my $tmp_vg;
 my $sess;

 {
  my $dummy_vg = Test::Valgrind::FakeValgrind->new(
   exe_name => 'invisible_pink_unicorn'
  );
  skip $dummy_vg => 2 unless ref $dummy_vg;
  $tmp_vg = $dummy_vg->path;

  local $@;
  $sess = eval {
   Test::Valgrind::Session->new(
    allow_no_supp => 1,
    no_def_supp   => 1,
    valgrind      => $tmp_vg,
   );
  };
  is $@, '', 'session was correctly created';
 }

 skip 'dummy valgrind executable was not deleted' => 1 if -e $tmp_vg;

 local $@;
 eval {
  $sess->run(
   action  => $action,
   command => $cmd,
   tool    => $tool,
  );
 };
 like $@, qr/invisible_pink_unicorn/, 'command not found croaks';
}
