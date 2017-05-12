#!perl

package Ponfish::ThreadHandler;

use strict;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Ponfish::Menu::Main;
use Ponfish::Utilities;
use Ponfish::Config;

@ISA = qw(Exporter);
@EXPORT = qw(
);
$VERSION = '0.01';
use threads;
use Thread::Queue;


sub new {
  my $type		= shift;

  return bless {}, $type;
}



1;

