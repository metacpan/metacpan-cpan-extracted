use 5.016;
use warnings;

use Carp       qw(croak);
use File::Find qw(find);
use Perl::Tidy;
use Test::More;

for my $file (perl_files()) {
  my $original = slurp($file);
  my ($tidied, $errors);

  my $failed = Perl::Tidy::perltidy(
    source      => $file,
    destination => \$tidied,
    perltidyrc  => '.perltidyrc',
    argv        => [],
    stderr      => \$errors,
    errorfile   => \$errors,
  );

  ok(!$failed && $tidied eq $original, $file) or diag($errors // 'differs from perltidy output');
}

done_testing;

sub perl_files {
  my @files = ('Makefile.PL');
  find(sub { push @files, $File::Find::name if /[.](?:pm|pl|t)\z/ }, 'lib', 't', 'tools', 'xt');
  my @sorted = sort @files;
  return @sorted;
}

sub slurp {
  my ($file) = @_;
  open my $handle, '<:raw', $file or croak "Cannot read $file: $!";
  my $content = do { local $/ = undef; <$handle> };
  close $handle or croak "Cannot close $file: $!";
  return $content;
}
