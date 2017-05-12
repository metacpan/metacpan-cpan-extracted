#!/usr/bin/perl -w -I../lib
use strict;
use warnings;

use Tk::DBI::LoginDialog;

# ---- globals ----
my $top = new MainWindow;

# ---- create ----
my $ld = $top->LoginDialog(-dsn => 'XE', -driver => 'Oracle');

$ld->configure('-mask' => "#");

$ld->login(3);
