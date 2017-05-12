#!/usr/bin/perl
BEGIN{unshift @INC, "./blib/lib"}

use Tk;
use Tk::MARC::Record;
use MARC::Record;
use MARC::File::USMARC;

my $file = MARC::File::USMARC->in( "pl/tcfm.mrc" );
#
#while ( my $marc = $file->next() ) {
#    # Do something
#}
#$file->close();
#undef $file;
#
my $record = $file->next();
$file->close();
undef $file;

my $mw = MainWindow->new;
$mw->title("record Test");
$mw->MARC_Record(-record => $record)->pack;

MainLoop;
