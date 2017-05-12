use Test::More tests => 4;
use Digest::MD5 qw(md5_hex);

use lib './lib';

use Text::ProcessMap;

run_test('t/t17','stack layout');
run_test('t/t18','matrix layout blank row');
run_test('t/t19','matrix layout');
run_test('t/t20','minimum width');

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
