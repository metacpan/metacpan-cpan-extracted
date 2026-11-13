use 5.016;
use warnings;

use File::Find qw(find);
use Module::Metadata;
use Test::More;
use Twilio;

# PAUSE keeps package names and file paths in 128-character columns, and fails the whole
# upload with a database error when one is longer. The paths are those of META's provides,
# which Makefile.PL fills with the one versioned package of each file.
my $LIMIT = 128;

my @files = pm_files();
my %package_of_file;
for my $file (@files) {
  (my $package = $file) =~ s{\Alib/|[.]pm\z}{}g;
  $package_of_file{$file} = $package =~ s{/}{::}gr;
}

subtest 'names and paths fit in PAUSE' => sub {
  my @long_packages = grep { length > $LIMIT } map { declared_packages($_) } @files;
  is_deeply(\@long_packages, [], "package names of $LIMIT characters at most");

  my @long_paths = grep { length > $LIMIT } @files;
  is_deeply(\@long_paths, [], "file paths of $LIMIT characters at most");
};

subtest 'each file has its own package, with the version' => sub {
  my $found = Module::Metadata->provides(dir => 'lib', version => 2, prefix => 'lib');
  my @wrong;
  for my $file (@files) {
    my $package = $package_of_file{$file};
    my $entry   = $found->{$package};
    my $version = $entry && $entry->{version};
    push @wrong, "$file: " . ($version // 'no own package with a $VERSION')
      if ($version // q{}) ne $Twilio::VERSION;
  }
  is_deeply(\@wrong, [], "every file has its package, at $Twilio::VERSION");

  my %own = map { $_ => 1 } values %package_of_file;

  my @others = sort grep { defined $found->{$_}{version} && !$own{$_} } keys %{$found};
  is_deeply(\@others, [], 'no other package has a $VERSION, so provides lists one per file');
};

done_testing;

sub pm_files {
  my @found;
  find(sub { push @found, $File::Find::name if /[.]pm\z/ }, 'lib');
  my @sorted = sort @found;
  return @sorted;
}

sub declared_packages {
  my ($file) = @_;
  open my $handle, '<', $file or die "Cannot read $file: $!\n";
  my @packages = map { /\Apackage\s+([\w:]+)/ ? $1 : () } <$handle>;
  close $handle or die "Cannot read $file: $!\n";
  return @packages;
}
