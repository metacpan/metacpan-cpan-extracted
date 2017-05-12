use Test::More tests => 6;
use Cwd;
use Capture::Tiny qw(capture_merged);

$ENV{PERL5LIB} = Cwd::abs_path('lib');
my $xt = -e 'xt' ? 'xt' : 'test/devel';
chdir "$xt/module-install" or die;

unlink('Makefile.PL', 'Makefile');

my ($rc, $out);

$out = capture_merged {
    $rc = system("$^X -Makefile=MP,plugin=Ingy:modern");
};
die $out unless $rc == 0;

pass 'perl -Makefile=PL worked';

ok -f('Makefile.PL'), 'Makefile.PL was created';
ok -f('Makefile'), 'Makefile was created';

$out = capture_merged {
    $rc = system("make purge");
};
die $out unless $rc == 0;

pass 'make purge worked';

ok +not(-f('Makefile')), 'Makefile was deleted';
ok +not(-f('Makefile.PL')), 'Makefile.PL was deleted';
