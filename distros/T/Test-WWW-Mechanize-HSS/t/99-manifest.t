use strict;
use Test::More;

# Check that MANIFEST and MANIFEST.skip are sane :

use File::Find;
use File::Spec;

my @files = qw( MANIFEST MANIFEST.skip );
plan tests => scalar @files * 4 +1;

for my $file (@files) {
  ok(-f $file, "$file exists");
  open F, "<$file"
    or die "Couldn't open $file : $!";
  my @lines = <F>;
  is_deeply([grep(/^$/, @lines)],[], "No empty lines in $file");
  is_deeply([grep(/^\s+$/, @lines)],[], "No whitespace-only lines in $file");
  is_deeply([grep(/^\s*\S\s+$/, @lines)],[],"No trailing whitespace on lines in $file");
  close F;
};

# Now, check that all files matching 't/*.t' (recursively) are in the manifest:
open my $manifest, "<", "MANIFEST"
    or die "Couldn't read MANIFEST: $!";
my %manifest = map { chomp; $_ => 1 } <$manifest>;
my @unknown_tests;
find(sub{ 
    push @unknown_tests, $File::Find::name 
        if /\.t$/i and ! $manifest{ $File::Find::name }
}, 't');
if (! is_deeply( \@unknown_tests, [], 'No test files left out of MANIFEST')) {
    diag "Missing from MANIFEST: $_" for @unknown_tests;
};
