#!/usr/bin/perl
BEGIN{unshift @INC, "./blib/lib"}

use Tk;
use Tk::MARC::Subfield;
use MARC::Record;
use MARC::File::USMARC;

my $file = MARC::File::USMARC->in( 'pl/tcfm.mrc' );
print $MARC::File::ERROR . $/ unless defined $file;
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

my $fld = $rec->field('245');
my @subfields = $fld->subfields();
foreach my $sfld (@subfields) {
    $mw->MARC_Subfield(-field => '245',
		       -label => @$sfld[0],
		       -value => @$sfld[1],
		       )->pack(-anchor => 'w');
}

MainLoop;
