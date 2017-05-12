#!/usr/bin/perl -w -I../lib

use Tk::DBI::LoginDialog;

my $mw = new MainWindow;

my $ld = $mw->LoginDialog;

$ld->login;

