use 5.016;
use warnings;

use File::Find qw(find);
use Perl::Critic;
use Test::More;

my $critic = Perl::Critic->new(-profile => '.perlcriticrc');

for my $file (perl_files()) {
  my @violations = map { "$_" } $critic->critique($file);
  is_deeply(\@violations, [], $file);
}

done_testing;

sub perl_files {
  my @files = ('Makefile.PL');
  find(sub { push @files, $File::Find::name if /[.](?:pm|pl|t)\z/ }, 'lib', 't', 'tools', 'xt');
  my @sorted = sort @files;
  return @sorted;
}
