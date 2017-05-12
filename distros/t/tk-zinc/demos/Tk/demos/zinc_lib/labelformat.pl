#!/usr/bin/perl -w
# $Id: labelformat.pl,v 1.4 2003/09/15 12:25:05 mertz Exp $
# This simple demo has been developped by C. Mertz <mertz@cena.fr>

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

use Tk;
use Tk::Zinc;
use strict;

my $mw = MainWindow->new();


###########################################
# Text zone
###########################################

my $text = $mw->Text(-relief => 'sunken', -borderwidth => 2,
		     -height => 4);
$text->pack(qw/-expand yes -fill both/);

$text->insert('0.0',
'This toy-appli demonstrates the use of labelformat for tabular items.
The fieldPos (please, refer to the "labelformat type" description 
in the "Zinc reference manual") of each field as described in
the labelformat is displayed inside the field.');


###########################################
# Zinc
##########################################
my $zinc = $mw->Zinc(-width => 600, -height => 500,
		     -font => "10x20",
		     -borderwidth => 3, -relief => 'sunken',
		     )->pack;

###########################################
# Tabulars
###########################################

### first labelformat and tabular
my $labelformat1 = "300x300 x100x20+0+0 x100x20+100+0 x100x20+0+20 x100x20+100+20 x100x20+50+55";

my $tabular1 = $zinc->add('tabular',1, 5,
		    -position => [10,10],
		    -labelformat => $labelformat1,
		   );

&setLabelContent ($tabular1,$labelformat1);

$zinc->add('text', 1, -position => [10,100], -text =>
	   "All fields positions
are given in pixels");


### second labelformat and tabular
my $labelformat2 = "300x300 x110x20+100+30 x80x20<0<0 x80x20<0>0 x80x20>0>0 x80x20>0<0";

my $tabular2 = $zinc->add('tabular',1, 5,
                    -position => [270,10],
		    -labelformat => $labelformat2,
		    );
&setLabelContent ($tabular2,$labelformat2);

$zinc->add('text', 1, -position => [260,100], -text =>
	   "All fields positions are given
relatively to field 0.
They are either on the left/right
and up/down the field 0.");


### third labelformat and tabular
my $labelformat3 = "400x300 x200x70+100+70 x80x26^0<0 x80x26^0>0 x80x29\$0\$0 x80x32\$0^0 x90x20\<1^1 x90x20<2\$2 x90x20^4<4 x90x20^3>3";

my $tabular3 = $zinc->add('tabular',1, 9,
                    -position => [150,180],
                    -labelformat => $labelformat3,
                    );
&setLabelContent ($tabular3,$labelformat3);

$zinc->add('text', 1, -position => [40,360], -text =>
	   "Fields 1-4 are positionned relatively to field 0.
Field 5 is positionned relatively to field 1,
Field 6 is positionned relatively to field 2..."
);


### this function displays in each field, the corresponding <fieldPos>
### part of the labelformat
sub setLabelContent {
  my ($item,$labelformat) = @_;

  my @fieldsSpec = split (/ / , $labelformat);
  shift @fieldsSpec;

  my $i=0;
  foreach my $fieldSpec (@fieldsSpec) {
    my ($posSpec) = $fieldSpec =~ /^.\d+.\d+(.*)/ ;
#    print "$fieldSpec\t$i\t$posSpec\n";
    $zinc->itemconfigure ($item,$i,
                          -text => "$i: $posSpec",
  			  -border => "contour",
			  );
    $i++;
  }
}



MainLoop;
