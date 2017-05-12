#!/usr/local/bin/perl5

use Tk::SlideShow;
use strict;

my $p = Tk::SlideShow->init(1024,768) or die;
$p->save;
my ($mw,$c,$h,$w) = ($p->mw, $p->canvas, $p->h, $p->w);
my $d;

#--------------------------------------------
# the pie example
#
$d = $p->add('summary',
	     sub {
	       title('First title');
                            # tag
	       my $pie = pie('pie1', 'A' => 12, 'Beaucoup de text' => 2 ,'C' => 20);
	       $pie->width(300);

	       $p->load;
	     });


#--------------------------------------------

$d->html(" ");

sub title { $p->Text('title',shift,-font,$p->f3); }


$p->current(shift || 0);
$p->play;
