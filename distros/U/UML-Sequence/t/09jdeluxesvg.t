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

open TESTSVG, "$^X ./seq2svg.pl -m deluxewash.html -P ./ -c #80ffff -a yellow -j t/deluxewash.xml |"
        or die "Couldn't run seq2svg.pl: $!\n";
my @test_svg = <TESTSVG>;
close TESTSVG;

#
#    collect the html
#
open TESTSVG, '<deluxewash.html'
        or die "Can't read HTML output: $!\n";
@test_svg = <TESTSVG>;
close TESTSVG;

my @correct_svg = <DATA>;

#
#    cleanup newlines
#
s/\s+$//
    foreach (@test_svg);

s/\s+$//
    foreach (@correct_svg);

is_deeply(\@test_svg, \@correct_svg, "html output");

unlink 'deluxewash.html';

__DATA__
<html>
<body>
<img src='mapname.png' usemap='#mapname'>
<MAP NAME='mapname'>
<AREA TITLE='AtHome' HREF='./AtHome.html' SHAPE=RECT COORDS='22,25,147,45'>
<AREA TITLE='Garage' HREF='./Garage.html' SHAPE=RECT COORDS='150,25,275,45'>
<AREA TITLE='Kitchen' HREF='./Kitchen.html' SHAPE=RECT COORDS='278,25,403,45'>
<AREA TITLE='Driveway' HREF='./Driveway.html' SHAPE=RECT COORDS='406,25,531,45'>
<AREA NAME='mapname_0' TITLE='retrieve bucket' SHAPE=RECT COORDS='114,79,204,93'
onmouseover="this.T_STATIC=true;this.T_FONTCOLOR='black';this.T_FONTSIZE='12px';this.T_BGCOLOR='#e0e0e0';this.T_OPACITY=90;this.T_SHADOWWIDTH=8;return escape('the bucket is in the garage ')" >
<AREA NAME='mapname_1' TITLE='prepare bucket ' SHAPE=RECT COORDS='242,119,332,133' >
<AREA NAME='mapname_2' TITLE='pour soap in bucket ' SHAPE=RECT COORDS='384,165,504,179' >
<AREA NAME='mapname_3' TITLE='fill bucket ' SHAPE=RECT COORDS='384,205,456,219' >
<AREA NAME='mapname_4' TITLE='get sponge ' SHAPE=RECT COORDS='138,239,204,253' >
<AREA NAME='mapname_5' TITLE='checkDoor ' SHAPE=RECT COORDS='144,279,204,293' HREF='./Garage.html#checkDoor' >
<AREA NAME='mapname_6' TITLE='clickDoorOpener ' SHAPE=RECT COORDS='108,319,204,333' >
<AREA NAME='mapname_7' TITLE='[ ifDoorClosed ] open door ' SHAPE=RECT COORDS='256,365,418,379' >
<AREA NAME='mapname_8' TITLE='* apply soapy water ' SHAPE=RECT COORDS='340,399,460,413' >
<AREA NAME='mapname_9' TITLE='rinse  !' SHAPE=RECT COORDS='412,439,460,453' HREF='./Driveway.html#rinse' >
<AREA NAME='mapname_10' TITLE='empty bucket ' SHAPE=RECT COORDS='382,479,460,493' >
<AREA NAME='mapname_11' TITLE='close door ' SHAPE=RECT COORDS='138,519,204,533' >
<AREA NAME='mapname_12' TITLE='replace sponge ' SHAPE=RECT COORDS='114,559,204,573' >
<AREA NAME='mapname_13' TITLE='replace bucket ' SHAPE=RECT COORDS='114,599,204,613' >
</MAP>


<script language="JavaScript" type="text/javascript" src="../wz_tooltip.js"></script>

</body>
</html>
