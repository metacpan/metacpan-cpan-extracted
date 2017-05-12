use strict;
use warnings;

use Test::More tests => 1;

use UML::Sequence::SimpleSeq;
use UML::Sequence;

my $outline     = UML::Sequence::SimpleSeq->grab_outline_text('t/deluxewash.seq');
my $methods     = UML::Sequence::SimpleSeq->grab_methods($outline);

my $tree = UML::Sequence
    ->new($methods, $outline, \&UML::Sequence::SimpleSeq::parse_signature,
         \&UML::Sequence::SimpleSeq::grab_methods);

# run the seq2svg.pl script against deluxewash.xml from the distribution

open TESTSVG, "$^X ./seq2svg.pl -m deluxewash.html -P ./ -c #80ffff -a yellow -e t/deluxewash.xml |"
        or die "Couldn't run seq2svg.pl: $!\n";
my @test_svg = <TESTSVG>;
close TESTSVG;

my @correct_svg = <DATA>;

is_deeply(\@test_svg, \@correct_svg, "svg output");

unlink 'deluxewash.html';

__DATA__
<?xml version="1.0"?>
  <svg xmlns="http://www.w3.org/2000/svg" height="660" width="680">
    <defs>
      <style type="text/css">
              rect, line, path { stroke-width: 2; stroke: black }
              text { font-weight: bold }
      <marker orient="auto" refY="2.5" refX="4" markerHeight="7" markerWidth="6" id="mArrow">
        <path style="fill: black; stroke: none" d="M 0 0 6 3 0 7"/>
      </marker>
      <marker orient="auto" refY="2.5" refX="4" markerHeight="7" markerWidth="6" id="mRtHalfArrow">
        <path style="fill: black; stroke: none" d="M 0 7 6 2 0 2"/>
      </marker>

      <marker orient="0 deg" refY="2.5" refX="4" markerHeight="7" markerWidth="6" id="mLtHalfArrow">
        <path style="fill: black; stroke: none" d="M 0 2 6 2 6 7"/>
      </marker>
      </style>
    </defs>
  <rect style='fill: #80ffff' height='20' width='125' y='25' x='22' />
<text y='40' x='30'>AtHome</text>
  <line style='stroke-dasharray: 4,4; ' fill='none' stroke='black' x1='92' y1='55' x2='92' y2='655' />
    <rect style='fill: yellow' height='580' width='15' y='55' x='84'/>

  <rect style='fill: #80ffff' height='20' width='125' y='25' x='150' />
<text y='40' x='158'>Garage</text>
  <line style='stroke-dasharray: 4,4; ' fill='none' stroke='black' x1='220' y1='95' x2='220' y2='655' />
    <rect style='fill: yellow' height='20' width='15' y='95' x='212'/>
    <rect style='fill: yellow' height='20' width='15' y='255' x='212'/>
    <rect style='fill: yellow' height='100' width='15' y='295' x='212'/>
    <rect style='fill: yellow' height='20' width='15' y='375' x='222'/>
    <rect style='fill: yellow' height='20' width='15' y='535' x='212'/>
    <rect style='fill: yellow' height='20' width='15' y='575' x='212'/>
    <rect style='fill: yellow' height='20' width='15' y='615' x='212'/>

  <rect style='fill: #80ffff' height='20' width='125' y='25' x='278' />
<text y='40' x='286'>Kitchen</text>
  <line style='stroke-dasharray: 4,4; ' fill='none' stroke='black' x1='348' y1='135' x2='348' y2='655' />
    <rect style='fill: yellow' height='100' width='15' y='135' x='340'/>
    <rect style='fill: yellow' height='20' width='15' y='175' x='350'/>
    <rect style='fill: yellow' height='20' width='15' y='215' x='350'/>

  <rect style='fill: #80ffff' height='20' width='125' y='25' x='406' />
<text y='40' x='414'>Driveway</text>
  <line style='stroke-dasharray: 4,4; ' fill='none' stroke='black' x1='476' y1='415' x2='476' y2='655' />
    <rect style='fill: yellow' height='20' width='15' y='415' x='468'/>
    <rect style='fill: yellow' height='20' width='15' y='455' x='468'/>
    <rect style='fill: yellow' height='20' width='15' y='495' x='468'/>

<line x1='100' y1='95' x2='213' y2='95' style=' marker-end: url(#mArrow);' />
<text x='114' y='89' ><tspan>retrieve bucket<tspan baseline-shift="super">1</tspan></tspan></text>
<line x1='100' y1='135' x2='341' y2='135' style=' marker-end: url(#mArrow);' />
<text x='242' y='129' ><tspan>prepare bucket </tspan></text>
<line x1='356' y1='165' x2='381' y2='165' />
<line x1='381' y1='165' x2='381' y2='185' />
<line x1='381' y1='185' x2='366' y2='185' style='marker-end: url(#mArrow);' />
<text x='384' y='175' ><tspan>pour soap in bucket </tspan></text>
<line x1='356' y1='205' x2='381' y2='205' />
<line x1='381' y1='205' x2='381' y2='225' />
<line x1='381' y1='225' x2='366' y2='225' style='marker-end: url(#mArrow);' />
<text x='384' y='215' ><tspan>fill bucket </tspan></text>
<line x1='100' y1='255' x2='213' y2='255' style=' marker-end: url(#mArrow);' />
<text x='138' y='249' ><tspan>get sponge </tspan></text>
<line x1='100' y1='295' x2='213' y2='295' style=' marker-end: url(#mArrow);' />
<text x='144' y='289' ><tspan>checkDoor </tspan></text>
<line x1='120' y1='335' x2='213' y2='335' style=' marker-end: url(#mRtHalfArrow);' />
<text x='108' y='329' style='font-style: italic;'><tspan>clickDoorOpener </tspan></text>
<line x1='228' y1='365' x2='253' y2='365' />
<line x1='253' y1='365' x2='253' y2='385' />
<line x1='253' y1='385' x2='238' y2='385' style='marker-end: url(#mArrow);' />
<text x='256' y='375' ><tspan>[ ifDoorClosed ] open door </tspan></text>
<line x1='100' y1='415' x2='469' y2='415' style=' marker-end: url(#mArrow);' />
<text x='340' y='409' ><tspan>* apply soapy water </tspan></text>
<line x1='100' y1='455' x2='469' y2='455' style=' marker-end: url(#mArrow);' />
<text x='412' y='449' ><tspan>rinse  !</tspan></text>
<line x1='100' y1='495' x2='469' y2='495' style=' marker-end: url(#mArrow);' />
<text x='382' y='489' ><tspan>empty bucket </tspan></text>
<line x1='100' y1='535' x2='213' y2='535' style=' marker-end: url(#mArrow);' />
<text x='138' y='529' ><tspan>close door </tspan></text>
<line x1='100' y1='575' x2='213' y2='575' style=' marker-end: url(#mArrow);' />
<text x='114' y='569' ><tspan>replace sponge </tspan></text>
<line x1='100' y1='615' x2='213' y2='615' style=' marker-end: url(#mArrow);' />
<text x='114' y='609' ><tspan>replace bucket </tspan></text>
</svg>
