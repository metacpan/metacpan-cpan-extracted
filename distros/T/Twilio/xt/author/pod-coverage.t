use 5.016;
use warnings;

use File::Find qw(find);
use Pod::Coverage;
use Test::More;

# all_pod_coverage_ok only checks the package named after each file, and a resource file holds
# four more. Those cannot be required by name, so %INC says they are already loaded.
my @files;
find(sub { push @files, $File::Find::name if /[.]pm\z/ }, 'lib');

for my $file (sort @files) {
  my $module = ($file =~ s{\Alib/}{}r =~ s{[.]pm\z}{}r =~ s{/}{::}gr);
  require_ok($module);

  for my $package (packages_in($file)) {
    my $path = ($package =~ s{::}{/}gr) . '.pm';
    $INC{$path} //= $file;    ## no critic (RequireLocalizedPunctuationVars)

    my $coverage = Pod::Coverage->new(package => $package, pod_from => $file);
    my $rating   = $coverage->coverage;

    my @naked = $coverage->naked;
    ok(!@naked, "$package is documented") or diag("Not documented: @naked");
    ok(defined $rating || $coverage->why_unrated =~ /no public symbols/, "$package can be rated")
      or diag($coverage->why_unrated);
  }
}

done_testing;

sub packages_in {
  my ($file) = @_;

  open my $handle, '<', $file or die "Cannot read $file: $!\n";
  my @packages;
  while (my $line = <$handle>) {
    last if $line =~ /\A__END__/;
    if (my ($package) = $line =~ /\Apackage ([\w:]+);/) { push @packages, $package }
  }
  close $handle or die "Cannot read $file: $!\n";
  return @packages;
}
