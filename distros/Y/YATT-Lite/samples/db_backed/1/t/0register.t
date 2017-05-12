#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use constant DEBUG => $ENV{DEBUG_YATT_TEST_REGISTER};
use FindBin;
BEGIN {
  if (-d (my $dir = "$FindBin::RealBin/../../../../t")) {
    local (@_, $@) = $dir;
    do "$dir/t_lib.pl";
    die $@ if $@;
    print STDERR "# distdir=$dir\n" if DEBUG;
  } else {
    die "Can't find dist t directory: realbin=$FindBin::RealBin" if DEBUG;
  }
}
use lib $FindBin::RealBin;

use Cwd ();
my ($app_root);
BEGIN {
  if (-r __FILE__) {
    # detect where app.psgi is placed.
    $app_root = dirname(dirname(File::Spec->rel2abs(__FILE__)));
  } else {
    # older uwsgi do not set __FILE__ correctly, so use cwd instead.
    $app_root = Cwd::cwd();
  }
}
#----------------------------------------


use utf8;
use base qw(t_register);

MY->do_test("$FindBin::Bin/..", REQUIRE => [qw(DBD::SQLite)]);

sub cleanup_sql {
  my ($pack, $app, $dbh, $app_root, $sql) = @_;
  do_sqlite($dbh, "$app_root/data/.htdata.db", $sql);
}

sub do_sqlite {
  my ($dbh, $fn, $sql) = @_;
  require DBI;
  $dbh ||= DBI->connect("dbi:SQLite:dbname=$fn", undef, undef
			, {PrintError => 0, RaiseError => 1, AutoCommit => 0});
  $dbh->do($sql);
  $dbh->commit unless $dbh->{AutoCommit};
}
