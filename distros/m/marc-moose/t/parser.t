#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 24;

use MARC::Moose::Record;
use MARC::Moose::Field;
use MARC::Moose::Field::Control;
use MARC::Moose::Field::Std;
use MARC::Moose::Parser::Marcxml;
use MARC::Moose::Reader::File::Marcxml;
use MARC::Moose::Reader::File::Iso2709;
use MARC::Moose::Reader::String::Iso2709;
use MARC::Moose::Parser::Iso2709;
use YAML;


my $xml_chunk = <<EOS;
<record>
  <leader>01529    a2200217   4500</leader>
  <controlfield tag="001">   00000002 </controlfield>
  <controlfield tag="003">DLC</controlfield>
  <controlfield tag="005">20040505165105.0</controlfield>
  <controlfield tag="008">800108s1899    ilu           000 0 eng  </controlfield>
  <datafield tag="020" ind1=" " ind2=" ">
    <subfield code="a">0-19-877306-4</subfield>
  </datafield>
  <datafield tag="041" ind1=" " ind2=" ">
    <subfield code="a">eng</subfield>
  </datafield>
  <datafield tag="100" ind1=" " ind2=" ">
    <subfield code="a">Burda, Michael C.</subfield>
    <subfield code="u">Economics and Political Science</subfield>
  </datafield>
  <datafield tag="245" ind1=" " ind2=" ">
    <subfield code="a">Macroeconomics:</subfield>
    <subfield code="b">a European text</subfield>
  </datafield>
  <datafield tag="260" ind1=" " ind2=" ">
    <subfield code="b">Oxford University Press,</subfield>
    <subfield code="c">1993.</subfield>
  </datafield>
  <datafield tag="300" ind1=" " ind2=" ">
    <subfield code="a">486 p. :</subfield>
    <subfield code="b">Graphs ;</subfield>
    <subfield code="c">25 cm.</subfield>
  </datafield>
  <datafield tag="504" ind1=" " ind2=" ">
    <subfield code="a">Includes bibliographical references and index and glossary</subfield>
  </datafield>
  <datafield tag="520" ind1=" " ind2=" ">
    <subfield code="a">The book covers two courses. The first part (chapters 1-12) corresponds to the macro course. It starts with an open economy from the very beginning, presents the building blocks of the economic model, explores the controversies and concludes on the eclectic view. Thus the view is taken that macroeconomists are actually in agreement over a large range of issues and that the points of disagreement need not be over-emphasized for the general public. At the same time differing views are presented, mostly emphasizing the assumptions on one hand, and the policy implication on the other. It illustrates each concept and result with examples drawn from the real world. Considerable effort is expended in analysing the supply-side in Europe, which is wholly neglected in US textbooks</subfield>
  </datafield>
  <datafield tag="690" ind1=" " ind2=" ">
    <subfield code="a">Economics</subfield>
  </datafield>
  <datafield tag="700" ind1=" " ind2=" ">
    <subfield code="a">Wyplosz, Charles</subfield>
  </datafield>
  <datafield tag="942" ind1=" " ind2=" ">
    <subfield code="c">IBK</subfield>
  </datafield>
  <datafield tag="952" ind1=" " ind2=" ">
    <subfield code="1">0</subfield>
    <subfield code="7">0</subfield>
    <subfield code="a">DO</subfield>
    <subfield code="b">DO</subfield>
    <subfield code="c">MC</subfield>
    <subfield code="o">HB172.5 .B87 1993</subfield>
    <subfield code="p">000426795</subfield>
    <subfield code="y">IBK</subfield>
  </datafield>
  <datafield tag="952" ind1=" " ind2=" ">
    <subfield code="1">0</subfield>
    <subfield code="7">0</subfield>
    <subfield code="a">DO</subfield>
    <subfield code="b">DO</subfield>
    <subfield code="c">MC</subfield>
    <subfield code="o">HB172.5 .B87 1993</subfield>
    <subfield code="p">000426811</subfield>
    <subfield code="y">IBK</subfield>
  </datafield>
  <datafield tag="952" ind1=" " ind2=" ">
    <subfield code="1">0</subfield>
    <subfield code="7">0</subfield>
    <subfield code="a">DO</subfield>
    <subfield code="b">DO</subfield>
    <subfield code="c">MC</subfield>
    <subfield code="o">HB172.5 .B87 1993</subfield>
    <subfield code="p">000466130</subfield>
    <subfield code="y">IBK</subfield>
  </datafield>
  <datafield tag="952" ind1=" " ind2=" ">
    <subfield code="1">0</subfield>
    <subfield code="7">0</subfield>
    <subfield code="a">TA</subfield>
    <subfield code="b">TA</subfield>
    <subfield code="c">MC</subfield>
    <subfield code="o">HB172.5 .B87 1993</subfield>
    <subfield code="p">900099163</subfield>
    <subfield code="y">IBK</subfield>
  </datafield>
  <datafield tag="998" ind1=" " ind2=" ">
    <subfield code="b">76</subfield>
    <subfield code="e">8</subfield>
  </datafield>
</record>
EOS

ok ( my $parser = MARC::Moose::Parser::Marcxml->new(), "MARC::Moose::Parser::MARC::Moosexml instantiated" );
ok ( my $record = $parser->parse( $xml_chunk ), "Chunk of XML record parsed" );
ok ( @{$record->fields} == 20, "Correct number of fields retrieved" );
ok ( $record->leader eq '01529    a2200217   4500', 'Control field correctly parsed' );
ok ( $record->field('001')->value eq '   00000002 ', '001 Control field correctly parsed' );
ok ( my $f245 = $record->field('245'), '245 field has been parsed' );
ok ( $f245->tag eq '245', '245 is correctly placed into a 245 field' );
ok ( my $subf = $f245->subf, '245 has subfields' );
ok ( @$subf == 2, '245 has 2 subfields' );
ok ( $subf->[0][0] eq 'a' && $subf->[0][1] eq 'Macroeconomics:' &&
     $subf->[1][0] eq 'b' && $subf->[1][1] eq 'a European text',
     '245 subfields are valids' );

# Read biblio file which contains 4 records
ok( my $reader = MARC::Moose::Reader::File::Marcxml->new( file => 't/biblios.xml' ),
    'Reader created on biblios.xml file' );
ok( $record = $reader->read(), "Read first record" );
ok( $record = $reader->read(), "Read second record" );
ok( $record = $reader->read(), "Read third record" );
ok( $record = $reader->read(), "Read fourth record" );
ok( !defined($record = $reader->read()), "End of file" );

ok ( $parser = MARC::Moose::Parser::Iso2709->new(), "MARC::Moose::Parser::Iso2709 instantiated" );
ok ( $reader = MARC::Moose::Reader::File::Iso2709->new( file => 't/biblios.iso2709' ), "Reader on a file" );
ok ( $record = $reader->read(), "Read first record" );
ok ( $record = $reader->read(), "Read second record" );
ok ( !defined($record = $reader->read()), "End of file" );

open my $fh, "<:encoding(utf8)", "t/biblios.iso2709";
my $content = <$fh>;
ok ( $reader = MARC::Moose::Reader::String::Iso2709->new( string => $content ), "Reader on a string" );
ok ( $record = $reader->read(), "Read first record from string" );
#print $record->as('Text');
#ok ( $record = $reader->read(), "Read second record from string" );
ok ( !defined($record = $reader->read()), "End of string" );
