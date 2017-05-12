use strict;
use warnings;
use Test::More tests => 1;
use App::SmokeBox::Mini;
use File::Path qw[rmtree];
use File::Spec;
use Cwd;

$ENV{PERL5_SMOKEBOX_DIR} = cwd();
my $smokebox_dir = File::Spec->catdir( App::SmokeBox::Mini::_smokebox_dir(), '.smokebox' );

rmtree($smokebox_dir);
mkdir $smokebox_dir unless -d $smokebox_dir;
die "$!\n" unless -d $smokebox_dir;

open CONFIG, '> ' . File::Spec->catfile( $smokebox_dir, 'minismokebox' ) or die "$!\n";
print CONFIG <<EOF;
debug=0
indices=1
backend=Test::SmokeBox::Mini
EOF
close CONFIG;

my @tests = qw(
A/AA/AAU/MRIM/Net-MRIM-1.10.tar.gz
A/AD/ADAMK/ORLite-1.17.tar.gz
A/AD/ADAMK/Test-NeedsDisplay-1.06.tar.gz
A/AD/ADAMK/Test-NeedsDisplay-1.07.tar.gz
A/AD/ADAMK/YAML-Tiny-1.36.tar.gz
);

open JOBS, '> jobs.txt' or die "$!\n";
print JOBS $_, "\n" for @tests;
close JOBS;

@ARGV = qw(--jobs jobs.txt);
ok( App::SmokeBox::Mini->run(), 'App::SmokeBox::Mini->run()' );
unlink 'jobs.txt';
exit 0;
