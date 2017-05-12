#!perl

use strict;
use warnings;

use Test::More tests => 4;

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

my $dummy_action = Test::Valgrind::Action::Dummy->new();

SKIP: {
 my $sess = eval { Test::Valgrind::Session->new(
  min_version => $tool->requires_version,
 ) };
 if (my $err = $@) {
  if ($err =~ /^(Empty valgrind candidates list|No appropriate valgrind executable could be found)\s+at.*/) {
   $err = $1;
  }
  skip $err => 2;
 }

 $sess->command($cmd);
 $sess->tool($tool);

 my $file    = $sess->def_supp_file;
 my $VERSION = quotemeta $Test::Valgrind::Session::VERSION;
 my $exp     = qr!$VERSION/memcheck-\d+(?:\.\d+)*-[0-9a-f]{32}\.supp$!;
 like $file, $exp, 'default suppression file is correctly named';

 my $res = open my $supp_fh, '<', $file;
 my $err = $!;
 ok $res, 'default suppression file can be opened';
 diag "open($file): $err" unless $res;

 if ($res) {
  my ($count, $non_empty, $perl_related) = (0, 0, 0);
  my ($in, $valid_frames, $seen_perl);
  while (<$supp_fh>) {
   chomp;
   s/^\s*//;
   s/\s*$//;
   if (!$in && $_ eq '{') {
    $in           = 1;
    $valid_frames = 0;
    $seen_perl    = 0;
   } elsif ($in) {
    if ($_ eq '}') {
     ++$count;
     ++$non_empty    if $valid_frames;
     ++$perl_related if $seen_perl;
     $in = 0;
    } else {
     ++$valid_frames if /^\s*fun:/;
     ++$seen_perl    if /^\s*fun:(Perl|S|XS)_/
                     or /^\s*obj:.*perl/;
    }
   }
  }
  diag "The default suppression file contains $count suppressions, of which $non_empty are not empty and $perl_related apply to perl";
  close $supp_fh;
 }
}

delete $ENV{PATH};

SKIP: {
 my $dummy_vg = Test::Valgrind::FakeValgrind->new();
 skip $dummy_vg => 2 unless ref $dummy_vg;

 eval { Test::Valgrind::Session->new(
  valgrind    => $dummy_vg->path,
  no_def_supp => 1,
  extra_supp  => [ 't/supp/no_perl' ],
 )->run(
  tool    => $tool,
  command => $cmd,
  action  => $dummy_action,
 ) };
 like $@, qr/No compatible suppressions available/,
          'incompatible suppression file';

 eval { Test::Valgrind::Session->new(
  valgrind      => $dummy_vg->path,
  no_def_supp   => 1,
  allow_no_supp => 1,
  extra_supp    => [ 't/supp/no_perl' ],
 )->run(
  tool    => $tool,
  command => $cmd,
  action  => $dummy_action,
 ) };
 is $@, '', 'incompatible suppression file, but forced';
}
