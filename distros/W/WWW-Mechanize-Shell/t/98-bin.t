use strict;
use Test::More;

# Check that all programs below bin/ compile :

use File::Find;
use File::Spec;

my $blib = File::Spec->catfile(qw(blib lib));
my @files;

my @skip;
opendir DIST,'.';
my @manifest = grep { /^manifest.skip$/i } (readdir DIST);
closedir DIST;
if (-f $manifest[0]) {
  open F, "<$manifest[0]"
    or die "Couldn't open $manifest[0] : $!";
  @skip = map { s/\s*$//; $_ } <F>;
  close F;
};

find(\&wanted, "bin");
plan tests => scalar @files;

foreach my $file (@files) {
  my $result = `$^X "-I$blib" -c "$file" 2>&1`;
  chomp $result;
  is( $result, "$file syntax OK", "Script '$file' compiles");
}

sub wanted {
  my $name = $File::Find::name;
  push @files, $name if -f $_ and /\.pl$/ and not grep { $name =~ /$_/  } @skip;
  $File::Find::prune = 1 if -d $_ and $_ ne '.';
}
