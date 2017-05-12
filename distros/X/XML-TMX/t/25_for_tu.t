# -*- cperl -*-
use Data::Dumper;
use Test::More tests => 9;

BEGIN {
  use_ok(XML::TMX::Reader);
};

my $reader;

$reader = XML::TMX::Reader->new('t/sample.tmx');
ok($reader, "reading sample.tmx");

my $count = 0;
$reader->for_tu( sub {
		   my $tu = shift;
		   $count++;
		 });
is($count, 7, "counting tu's with for_tu");

$count = 0;
$reader->for_tu( {output => "t/_tmp.tmx", proc_tu => 6 },
                  sub {
		   my $tu = shift;
                   $tu->{-prop}={number => ++$count};
                   $tu;
		 });

ok( -f "t/_tmp.tmx");
#unlink( "t/_tmp.tmx");

$reader = XML::TMX::Reader->new('t/_tmp.tmx');
ok($reader,"loadind t/_tmp.tmx");

$count = 0;
$reader->for_tu( sub {
		   my $tu = shift;
		   $count++;
		 });
is($count, 6, "counting tu's with for_tu");

$reader->for_tu( {output => "t/_tmp2.tmx", gen_tu=>2},
                  sub {
                   my $tu = shift;
                   if($tu->{-prop}{number} % 2 == 0) { return undef }
                   else { $tu->{-note}[0]="This one is even";
                          return $tu;}
                 });

my @langs = $reader->languages;

is(@langs, 2 , "languages".join(",",@langs));

ok(grep { $_ eq "EN-GB" } @langs, "en");
ok(grep { $_ eq "PT-PT" } @langs, "pt");
unlink( "t/_tmp.tmx");
unlink( "t/_tmp2.tmx");

