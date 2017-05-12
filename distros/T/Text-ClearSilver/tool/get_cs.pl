#!perl -w

# downlowd, extract the clearsilver distribution, and apply patches in patch/

use strict;
use Fatal qw(open close);
use LWP::Simple qw(mirror);
use File::Path qw(rmtree);
use Archive::Tar;
use File::Find qw(find);
use Text::Patch qw(patch);

my $cs_dir = shift(@ARGV) || die "Usage: $0 CS_BUILD_DIRECTRY\n";

my $version = shift(@ARGV) || '0.10.5';

print "getting the ClearSilver distribution ...\n";
my $distfile = "clearsilver.tar.gz";
mirror(
    "http://www.clearsilver.net/downloads/clearsilver-$version.tar.gz",
    $distfile,
);

print "extracting from $distfile ...\n";
Archive::Tar->extract_archive($distfile);

rmtree $cs_dir;
rename "clearsilver-$version" => $cs_dir;

my @patches;
find sub{
    return if not /\.patch$/;
    return if not -f $_;

    push @patches, $File::Find::name;
}, qw(patch);

foreach my $patch(@patches) {
    print "patching $patch ...\n";

    my $source = $patch;
    $source =~ s/^patch/$cs_dir/;
    $source =~ s/\.patch$//;

    if(not -f $source) {
        print "PATCH: $source not found, skipped.\n";
    }

    my $input = do {
        local $/;
        open my $in, '<', $source;
        <$in>;
    };
    my $diff = do {
        local $/;
        open my $in, '<', $patch;
        <$in>;
    };

    my $output = patch($input, $diff, { STYLE => 'Unified' });

    rename $source => sprintf '%s.%d~', $source, time;

    open my $out, '>', $source;
    print $out $output;
    close $out;
}

print "done.\n";
