use Test::More tests => 16;
use Digest::MD5 qw(md5_hex);

use lib './lib';

use Text::ProcessMap;

run_test('t/t01','basic');
run_test('t/t02','no id');
run_test('t/t03','no id, no title');
run_test('t/t04','multiple elements');
run_test('t/t05','one element');
run_test('t/t06','title only');
run_test('t/t07','id only');
run_test('t/t08','no header, no footer');
run_test('t/t09','large diagram');
run_test('t/t10','text wrap');
run_test('t/t11','fill columns right');
run_test('t/t12','fill columns edge');
run_test('t/t13','fill columns left');
run_test('t/t14','five columns');
run_test('t/t15','two columns with note wrap');
run_test('t/t16','narrow diagram');

unlink <t/*.txt>;

sub run_test
{
  my ($t, $d) = @_;

  my $pmap = Text::ProcessMap->new;

  $pmap->header(
    test        => 1,
    loader_file => $t . '.ini',
    output_file => $t . '.txt',
  );
  $pmap->draw;

  # remove platform dependencies
  my $tfile = read_file($t . '.txt');
  $tfile =~ s/\n//g;
  my $bfile = read_file($t . '.base');
  $bfile =~ s/\n//g;

  my $tsig = md5_hex($tfile);  # test file signature
  my $bsig = md5_hex($bfile);  # base file signature

  # the test
  ok($tsig eq $bsig, $d);

  undef $pmap;
}

# From File::Slurp by David Muir Sharnoff
sub read_file
{
  my ($file) = shift;

  local(*F);
  my (@r);

  open(F, "<$file") || die "open $file: $!";
  @r = <F>;
  close(F);

  return @r if wantarray;
  return join("",@r);
}
