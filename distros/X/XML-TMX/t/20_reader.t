# -*- cperl -*-
use Test::More tests => 10;

use File::Temp;
use XML::TMX::Reader;
ok 1;

my $reader;

$reader = XML::TMX::Reader->new('foobar.tmx');
ok(!$reader,"rigth foobar.tmx is not present");

$reader = XML::TMX::Reader->new('t/sample.tmx');
ok($reader, "reading sample.tmx");

is_deeply($reader->{header}, { '-prop' => { 'bodykey' => ['bodyvalue'] },
                               '-note' => [ 'bodynote' ],
                               'o-tmf' => 'TW4Win 2.0 Format',
                               adminlang => 'EN-US',
                               creationdate => '20020312T164816Z',
                               creationtoolversion => '5.0',
                               creationtool => 'MyTool',
                               srclang => 'EN-GB',
                               segtype => 'sentence',
                               datatype => 'html',
                             });

my $count = 0;
$reader->for_tu( sub {
		   my $tu = shift;
		   $count++;
		 });

my $tmp = File::Temp->new(SUFFIX=>'.tmx', UNLINK => 0);

is($count, 7, "counting tu's with for_tu");

$reader->for_tu( { -output => $tmp->filename },
                 sub {
                     my $tu = shift;
                     $tu->{-prop}={q=>[77], aut=>["jj","ambs"]};
                     $tu->{-note}=[2..5];
                     $tu;
		 });

ok( -f $tmp->filename );

$reader = XML::TMX::Reader->new( $tmp->filename );
ok $reader,"loading " . $tmp->filename;


my $tmp2 = File::Temp->new(SUFFIXE=>'.tmx', UNLINK => 0);

$reader->for_tu( {output => $tmp2->filename },
                 sub {
		   my $tu = shift;
		   for (keys %{$tu->{-prop}}){
		     $tu->{-prop}{$_} .= "batatas";
		   }
		   for (@{$tu->{-note}}){
		     $_ = "$_ cabolas"
		   }
		   $tu;
                 });

my @langs = $reader->languages;

is(@langs, 2 , "languages".join(",",@langs));

ok(grep { $_ eq "EN-GB" } @langs, "en");
ok(grep { $_ eq "PT-PT" } @langs, "pt");

unlink( $tmp->filename );
unlink( $tmp2->filename );
