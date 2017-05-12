# -*- cperl -*-

use Test::More tests => 4;


use XML::TMX::Writer;
ok 1;

my $tmx = new XML::TMX::Writer();

isa_ok($tmx, "XML::TMX::Writer");

$tmx->start_tmx(id => "foobar",
                -prop => {
                          prop1 => 'val1',
                          prop2 => 'val2',
                         },
                -note => [
                          'note1', 'note2', 'note3'
                         ],
                -output => "_${$}_");

$tmx->add_tu(srclang => 'en',
             -note => ['snote1', 'snote2', 'snote3'],
             -prop => { sprop1 => 'sval1',
                        sprop2 => 'sval2' },
	     'en' => {-prop => { a=>'b',c=>'d'},
                      -note => [qw,a b c d,],
                      -seg  =>'some text', },
	     'pt' => 'algum texto');

$tmx->end_tmx();

ok(-f "_${$}_");

ok file_contents_almost_identical("t/writer1.xml", "_${$}_");

unlink "_${$}_";


sub file_contents_almost_identical {
  my ($file1, $file2) = @_;

  return 0 unless -f $file1;
  return 0 unless -f $file2;

  open F1, $file1 or die;
  open F2, $file2 or die;

  my ($l1,$l2);

  while (defined($l1 = <F1>) && defined($l2 = <F2>)) {

      s/>\s*</></g           for ($l1, $l2);
      s/(^\s*|\s*$)//g       for ($l1, $l2);
      s/"\d+T\d+Z"/"000"/    for ($l1, $l2);
      s/version="\d+\.\d+"// for ($l1, $l2);

      if ($l1 ne $l2) {
          chomp $l1;
          chomp $l2;
          print STDERR "lines differ:\nexpected {$l1}\ngot {$l2}\n";
          return 0;
      }
  }

  return 0 if <F1>;
  return 0 if <F2>;

  return 1;
}
