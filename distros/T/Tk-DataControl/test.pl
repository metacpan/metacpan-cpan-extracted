#! /usr/bin/perl -w

use Tk;
use DataControl;
use DBI;
use strict;

my $mw = MainWindow->new();
my $text1 = $mw->Entry()->pack;
my $text2 = $mw->Entry()->pack;
my $dbh = DBI->connect("dbi:Pg:dbname=sanjay", "sanjay", "sanjay");
my $dc = $mw->DataControl
  (
   -dbh => $dbh, 
   -table => 'passwd_ent', 
   -textlist => [$text1, $text2], 
   -fieldlist => ['name', 'uid'], 
   -foreground => 'blue'
  );
  
$dc->pack();

MainLoop;
