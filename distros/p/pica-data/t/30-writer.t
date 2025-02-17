use strict;
use warnings;
use utf8;

use Test::More;
use Test::XML;

use PICA::Data qw(pica_writer pica_parser pica_string);
use PICA::Writer::Plain;
use PICA::Writer::Plus;
use PICA::Writer::Import;
use PICA::Writer::XML;
use PICA::Writer::PPXML;
use PICA::Parser::PPXML;
use PICA::Writer::JSON;
use PICA::Writer::Generic;
use PICA::Schema;

use File::Temp qw(tempfile);
use IO::File;
use Encode qw(encode);
use Scalar::Util qw(reftype);
use JSON::PP;

my @pica_records = (
    [['003@', '', '0', '1041318383'], ['021A', '', 'a', 'Hello $¥!'],],
    {record => [['028C', '01', d => 'Emma', a => 'Goldman']]}
);

note 'PICA::Writer::Plain';

{
    my ($fh, $filename) = tempfile();
    my $writer = pica_writer('plain', fh => $fh);
    foreach my $record (@pica_records) {
        $writer->write($record);
    }
    close $fh;

    my $PLAIN = <<'PLAIN';
003@ $01041318383
021A $aHello $$¥!

028C/01 $dEmma$aGoldman

PLAIN

    my $out = do {local (@ARGV, $/) = $filename; <>};
    is $out, $PLAIN, 'Plain writer';

    (undef, $filename) = tempfile(OPEN => 0);
    pica_writer('plain', fh => $filename);
    ok -e $filename, 'write to file';
}

sub write_result {
    my ($type, $options, @records) = @_;

    my ($fh, $filename) = tempfile();
    my $writer = pica_writer($type, fh => $fh, %$options);

    foreach my $record (@records) {
        $writer->write($record);
    }
    $writer->end;
    close $fh;

    return do {local (@ARGV, $/) = $filename; <>};
}

note 'PICA::Writer::Import';
{
    my $out = write_result('import', {}, @pica_records);
    my $expect = <<EXPECT;
\x1D
\x1E003@ \x1F01041318383
\x1E021A \x1FaHello \$¥!
\x1D
\x1E028C/01 \x1FdEmma\x1FaGoldman
EXPECT

    is $out, $expect, 'Import Writer';
}

note 'PICA::Writer::Plus';

{
    my $out = write_result('plus', {}, @pica_records);
    my $PLUS = <<'PLUS';
003@ 01041318383021A aHello $¥!
028C/01 dEmmaaGoldman
PLUS

    is $out, $PLUS, 'Plus Writer';
}

note 'PICA::Writer::XML';

{
    my $schema = {
        fields => {
            '003@' => {label => 'PPN', url => 'http://example.org/'},
            '028C/01' => {subfields => {d => {pica3 => ', '}}}
        }
    };
    my $out = write_result('xml', { schema => $schema }, @pica_records);
    my $xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>

<collection xmlns="info:srw/schema/5/picaXML-v1.0">
  <record>
    <datafield tag="003@" label="PPN" url="http://example.org/">
      <subfield code="0">1041318383</subfield>
    </datafield>
    <datafield tag="021A">
      <subfield code="a">Hello $¥!</subfield>
    </datafield>
  </record>
  <record>
    <datafield tag="028C" occurrence="01">
      <subfield code="d" pica3=", ">Emma</subfield>
      <subfield code="a">Goldman</subfield>
    </datafield>
  </record>
</collection>
XML

    is $out, $xml, 'XML writer';
}

{
    {

        package MyStringWriter;
        sub print {$_[0]->{out} .= $_[1]}
    }

    my $string = bless {}, 'MyStringWriter';

    my $writer = PICA::Writer::XML->new(fh => $string);
    $writer->write($_) for map {bless $_, 'PICA::Data'} @pica_records;
    $writer->end;
    like $string->{out}, qr{^<\?xml.+collection>$}sm,
        'XML writer (to object)';
}

note 'PICA::Writer::PPXML';

{
    my $parser = pica_parser('PPXML' => 't/files/slim_ppxml.xml');
    my $record;
    my ($fh, $filename) = tempfile();
    my $writer = PICA::Writer::PPXML->new(fh => $fh);
    while ($record = $parser->next) {
        $writer->write($record);
    }
    $writer->end;
    close $fh;

    my $out = do {local (@ARGV, $/) = $filename; <>};
    my $in = do {local (@ARGV, $/) = 't/files/slim_ppxml.xml'; <>};

    is_xml($out, $in, 'PPXML writer');
}

note 'PICA::Writer::Generic';

{
    my $out = write_result('generic', {
        us => "#",
        rs => "%",
        gs => "\n\n"
    }, @pica_records);
    my $PLUS = <<'PLUS';
003@ #01041318383%021A #aHello $¥!%

028C/01 #dEmma#aGoldman%

PLUS

    is $out, $PLUS, 'Generic Writer';
}

{
    my $out = write_result('generic', {}, @pica_records);
    is $out, '003@ 01041318383021A aHello $¥!028C/01 dEmmaaGoldman',
        'Generic Writer (default)';

    my $binary = write_result('binary', {}, @pica_records);
    is $binary, $out, 'Binary Writer (default=generic)';
}

note 'PICA::Writer::JSON';
{
    my $out    = "";
    my $writer = PICA::Writer::JSON->new(fh => \$out);
    my $record = $pica_records[0];
    $writer->write($record);
    $writer->end;
    is $out, encode_json([@$record]) . "\n", 'JSON (array)';

    $out    = "";
    $writer = PICA::Writer::JSON->new(fh => \$out);
    $record = $pica_records[1];
    $writer->write($record);
    $writer->end;
    is $out, encode_json($record->{record}) . "\n", 'JSON (hash)';

    $out = "";
    $writer = PICA::Writer::JSON->new(fh => \$out, pretty => 1);
    $writer->write($record);
    $writer->end;
    like $out, qr/^\[\n\s+\[/m, 'JSON (pretty)';
}

note 'PICA::Data';

{
    my $append = "";
    foreach my $record (@pica_records) {
        bless $record, 'PICA::Data';
        $record->write(plain => \$append);
    }

    my $PLAIN = <<'PLAIN';
003@ $01041318383
021A $aHello $$¥!

028C/01 $dEmma$aGoldman

PLAIN

    is $append, $PLAIN, 'record->write (multiple records)';

    my $record = bless $pica_records[1], 'PICA::Data';
    my $json = JSON::PP->new->utf8->convert_blessed->encode($record);
    is "$json\n", $record->string('JSON'), 'encode as JSON via TO_JSON';
}

note 'Exeptions';

{
    eval {pica_writer('plain', fh => '')};
    ok $@, 'invalid filename';

    eval {pica_writer('plain', fh => {})};
    ok $@, 'invalid handle';
}

note 'undefined occurrence';

{
    my $pica_record = [['003@', undef, '0', '1041318383']];
    my ($fh, $filename) = tempfile();
    my $writer = PICA::Writer::Plus->new(fh => $fh);
    $writer->write($pica_record);
    close $fh;

    my $out = do {local (@ARGV, $/) = $filename; <>};
    my $PLUS = <<'PLUS';
003@ 01041318383
PLUS
    is $out, $PLUS, 'undef occ';
}

{
    my %tests = (
        "  123A \$xy\n\n" => [["123A",undef,"x","y"," "]],
        "? 123A \$xy\n\n" => [["123A",undef,"x","y","?"]]
    );

    while (my ($plain, $record) = each %tests) {
        is pica_string($record), $plain, 'write annotated PICA';
        my $pp = pica_string($record, 'plain', annotate => 1);
        my $parsed = pica_parser(plain => \$plain, annotate => 1)->next;
        is $plain, $parsed->string, 'round-tripping annotated PICA';
    }

    is pica_string([["123A",undef,"x","y"]], "plain", annotate => 1),
      "  123A \$xy\n\n", "ensure annotation";

    is pica_string([["123A",undef,"x","y"," "]], "plain", annotate => 0),
      "123A \$xy\n\n", "ignore annotation";

    is pica_string([["123A",undef,"x","y","?"]], "plus"),
      "123A?\x1Fxy\x1E\n", "plus with annotation";
}

is pica_string([]), '', 'empty record';

done_testing;
