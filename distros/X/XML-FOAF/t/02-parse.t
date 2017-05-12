use strict;

use Test::More;
use XML::FOAF;
use File::Basename qw( dirname );
use File::Spec;

my $dir = File::Spec->catfile(dirname($0), 'samples');
opendir my $dh, $dir or die "Error opening $dir: $!";
my @tests;
for my $test_file (readdir $dh) {
    push @tests, File::Spec->catfile($dir, $test_file)
        if $test_file =~ /\.foaf$/;
}
closedir $dh;

plan tests => scalar @tests;

for my $test_file (@tests) {
    my $foaf;
    ok(XML::FOAF->new($test_file, 'http://foo.com'));
}
