#!/usr/bin/perl
BEGIN{unshift @INC, "./blib/lib"}

use Tk;
use Tk::MARC::Field;
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
my $rec = $file->next();
$file->close();
undef $file;

my $mw = MainWindow->new;
$mw->title("Editor Test");
my @fields = $rec->fields();
foreach my $fld (@fields) {
#    next unless ($fld->tag() ge '010');
    $mw->MARC_Field(-field => $fld)->pack(-anchor => 'w');
}

MainLoop;
