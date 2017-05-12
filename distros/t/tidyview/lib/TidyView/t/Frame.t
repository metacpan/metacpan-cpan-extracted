#!/use/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);

use Data::Dumper;

BEGIN {
  use_ok('TidyView::Frame');
}

require_ok('TidyView::Frame');

use Log::Log4perl qw(:levels);

Log::Log4perl->init_and_watch('bin/log.conf', 10);

# public UI
can_ok('TidyView::Frame', qw(new));

use Tk;

my $mainWin = MainWindow->new();

my $tvf = TidyView::Frame->new(parent => $mainWin);

isa_ok($tvf, 'Tk::Frame');

$mainWin = MainWindow->new();

$tvf = TidyView::Frame->new(
			    parent => $mainWin,
			    frameOptions => {
					     -relief => 'sunken',
					     },
			    packOptions  => {
					     -side => 'top',
					     },
			   );

isa_ok($tvf, 'Tk::Frame');

