use strict;
use warnings;
use Test::Most;
use YAML::XS qw(LoadFile);
use File::Spec;
use File::Basename qw(dirname);

my $dir = dirname(__FILE__) . '/../lib/Text/Names/Canonicalize/Rules';

opendir my $dh, $dir or die "Cannot open $dir: $!";
my @yaml = grep { /\.yaml$/ } readdir $dh;
closedir $dh;

foreach my $file (@yaml) {
    my $path = File::Spec->catfile($dir, $file);
    ok eval { LoadFile($path); 1 }, "$file loads";
}

done_testing;
