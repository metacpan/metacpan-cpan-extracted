use strict;
use warnings;
use Test::More tests => 5;
use App::SmokeBox::Mini;

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

my @jobs = App::SmokeBox::Mini::_get_jobs_from_file( 'jobs.txt' );

foreach my $test ( @tests ) {
  my $job = shift @jobs;
  ok( $test eq $job, "$test" );
}

unlink 'jobs.txt';
