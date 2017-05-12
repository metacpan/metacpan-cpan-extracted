#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin;
BEGIN {
  if (-d (my $dir = "$FindBin::RealBin/../../../../t")) {
    local (@_, $@) = $dir;
    do "$dir/t_lib.pl";
    die $@ if $@;
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
use Test::More;

use base qw(t_register);

MY->do_test("$FindBin::Bin/..", REQUIRE => [qw(DBD::mysql)]);

sub skip_check {
  my ($pack, $app_root, %opts) = @_;
  my $passfile = "$app_root/.htdbpass";

  if (-r $passfile) {
    '';
  } else {
    ".htdbpass is not configured";
  }
}

sub cleanup_sql {
  my ($pack, $app, $dbh, $app_root, $sql) = @_;
  my $passfile = "$app_root/.htdbpass";
  do_mysql($passfile, $sql);
}

sub do_mysql {
  my ($fn, $sql) = @_;
  open my $fh, '<', $fn or die "Can't open '$fn': $!";
  my %opts;
  while (my $line = <$fh>) {
    chomp $line;
    next unless $line =~ /^(\w+): (.*)/;
    $opts{$1} = $2;
  }

  my @keys = qw(dbname dbuser dbpass);
  if (my @missing = grep {not defined $opts{$_}} @keys) {
    die "dbconfig (@missing) is missing\n";
  }
  my ($dbname, $dbuser, $dbpass) = @opts{@keys};
  require DBI;
  my $dbh = DBI->connect("dbi:mysql:database=$dbname", $dbuser, $dbpass
			 , {PrintError => 0, RaiseError => 1, AutoCommit => 0});
  $dbh->do($sql);
  $dbh->commit;
}
