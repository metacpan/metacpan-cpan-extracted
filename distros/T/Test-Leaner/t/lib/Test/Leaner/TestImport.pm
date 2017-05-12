package Test::Leaner::TestImport;

use strict;
use warnings;

use Carp ();

use Test::Leaner ();
use Test::More   ();

sub get_subroutine {
 my ($stash, $name) = @_;

 my $glob = $stash->{$name};
 return undef unless $glob;

 return *$glob{CODE};
}

sub has_module_version {
 my ($module, $version) = @_;

 local $@;
 eval qq{
  require $module;
  "$module"->VERSION(\$version);
  1;
 }
}

sub has_test_more_version { has_module_version 'Test::More', @_ }
sub has_exporter_version  { has_module_version 'Exporter',   @_ }

my $this_stash = \%Test::Leaner::TestImport::;

my @default_exports = qw<
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

sub default_exports { @default_exports }

sub check_imports {
 my %imported     = map { $_ => 1 } @{ $_[0] || [] };
 my @not_imported = @{ $_[1] || [] };

SKIP:
 {
  local $Test::Builder::Level = ($Test::Builder::Level || 0) + 1;
  Test::More::skip($_[2] => @not_imported + @default_exports) if defined $_[2];

  for (@not_imported, grep !$imported{$_}, @default_exports) {
   Test::More::ok(!exists $this_stash->{$_}, "$_ was not imported");
  }
  for (grep $imported{$_}, @default_exports) {
   my $code = get_subroutine($this_stash, $_);
   Test::More::ok($code, "$_ was imported");
  }
 }

 delete $this_stash->{$_} for @default_exports, keys %imported, @not_imported;
}

sub test_import_arg {
 local $Test::Builder::Level = ($Test::Builder::Level || 0) + 1;

 my $use_fallback = $ENV{PERL_TEST_LEANER_USES_TEST_MORE};
 if ($use_fallback and "$]" >= 5.008_004 and "$]" <= 5.008_005) {
  Test::More::plan(skip_all
                       => 'goto may segfault randomly on perl 5.8.4 and 5.8.5');
 } else {
  Test::More::plan(tests => 9 * @default_exports + 8 + 3);
 }

 check_imports(
  [ ], [ ], has_test_more_version('0.51')
                       ? undef
                       : 'Test::More::plan exports stuff on Test::More <= 0.51'
 );

 local *Carp::carp = sub {
  local $Carp::CarpLevel = ($Carp::CarpLevel || 0) + 1;
  Carp::croak(@_);
 } unless has_exporter_version('5.565');

 {
  local $@;
  eval {
   Test::Leaner->import(import => [ ]);
  };
  Test::More::is($@, '', 'empty import does not croak');
  check_imports(\@default_exports);
 }

 {
  local $@;
  eval {
   Test::Leaner->import(import => [ 'nonexistent' ]);
  };
  my $class = $use_fallback ? 'Test::More' : 'Test::Leaner';
  Test::More::like(
   $@, qr/^"nonexistent" is not exported by the $class module/,
   'import "nonexistent" croaks'
  );
  check_imports([ ], [ 'nonexistent' ]);
 }

 {
  delete $this_stash->{use_ok} unless has_test_more_version('0.51');
  local $@;
  eval {
   Test::Leaner->import(import => [ 'use_ok' ]);
  };
  Test::More::like(
   $@, qr/^"use_ok" is not exported by the Test::Leaner module/,
   'import "use_ok" croaks'
  );
  check_imports([ ], [ 'use_ok' ]);
 }

 {
  local $@;
  eval {
   Test::Leaner->import(import => [ 'ok' ]);
  };
  Test::More::is($@, '', 'import "ok" does not croak');
  check_imports([ 'ok' ], [ ]);
 }

 {
  local $@;
  eval {
   Test::Leaner->import(
    import => [ qw<like unlike> ],
    import => [ qw<diag note> ],
   );
  };
  Test::More::is($@, '',
                 'import "like", "unlike", "diag" and "note" does not croak');
  check_imports([ qw<like unlike diag note> ], [ ]);
 }

 {
  local $@;
  eval {
   Test::Leaner->import(import => [ '!fail' ]);
  };
  Test::More::is($@, '', 'import "!fail" does not croak');
  check_imports([ grep $_ ne 'fail', @default_exports ], [ 'fail' ]);
 }

 SKIP:
 {
  Test::More::skip('Exporter 5.58 required to test negative imports'
                   => 1 + @default_exports) unless has_exporter_version('5.58');
  local $@;
  eval {
   Test::Leaner->import(import => [ 'pass' ], import => [ '!fail' ]);
  };
  Test::More::is($@, '', 'import "pass", "!fail" does not croak');
  check_imports([ 'pass' ], [ ]);
 }

 SKIP:
 {
  Test::More::skip('Exporter 5.58 required to test negative imports'
                   => 1 + @default_exports) unless has_exporter_version('5.58');
  local $@;
  eval {
   Test::Leaner->import(import => [ 'fail' ], import => [ '!fail' ]);
  };
  Test::More::is($@, '', 'import "fail", "!fail" does not croak');
  check_imports();
 }
}

our @EXPORT_OK = qw<
 get_subroutine
 has_module_version
 has_test_more_version
 has_exporter_version
 default_exports
 test_import_arg
>;

use Exporter ();

sub import { goto &Exporter::import }

1;
