#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
sub MY () {__PACKAGE__}
use base qw(File::Spec);
use File::Basename;

use FindBin;
sub untaint_any {$_[0] =~ m{(.*)} and $1}
use Cwd ();
my ($app_root, @libdir);
BEGIN {
  if (-r __FILE__) {
    # detect where app.psgi is placed.
    $app_root = dirname(dirname(File::Spec->rel2abs(__FILE__)));
  } else {
    # older uwsgi do not set __FILE__ correctly, so use cwd instead.
    $app_root = Cwd::cwd();
  }
  my $dn;
  if (-d (($dn = "$app_root/lib") . "/YATT")) {
    push @libdir, $dn
  } elsif (($dn) = $app_root =~ m{^(.*?/)YATT/}) {
    push @libdir, $dn;
  }
}
use lib @libdir;
#----------------------------------------

use utf8;
use Test::More;

BEGIN {
  foreach my $req (qw(DBI DBD::mysql)) {
    unless (eval qq{require $req}) {
      plan skip_all => "$req is not installed."; exit;
    }
  }
}

my $passfile = "$app_root/.htdbpass";
unless (-r $passfile) {
  plan skip_all => ".htdbpass is not configured";
}

plan tests => 1;

ok do_mysql($passfile, <<END), "test user is deleted";
delete from user where login = 'hkoba'
END


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
  1;
}
