#!/usr/bin/env perl

use strict;
use File::Spec;
use Getopt::Long;
use ExtUtils::MakeMaker ();

# May specify encoding from ENV
my $default_encoding = $ENV{PERL_TEXT_MECAB_ENCODING} || 'euc-jp';

my $default_config;
if (! GetOptions(
    "encoding=s" => \$default_encoding,
    "mecab-config=s" => \$default_config,
)) {
    exit 1;
}

# XXX Silly hack
local *STDIN = *STDIN;
if ($ENV{TRAVIS_TEST}) {
    close STDIN;
}

my($version, $cflags, $libs, $include, $mecab_config);

$cflags = '';
$mecab_config = '';

# Save the poor puppies that run on Windows
if ($^O eq 'MSWin32') {
    $version = ExtUtils::MakeMaker::prompt(
        join(
            "\n",
            "",
            "You seem to be running on an environment that may not have mecab-config",
            "available. This script uses mecab-config to auto-probe",
            "  1. The version string of libmecab that you are building Text::MeCab",
            "     against. (e.g. 0.90)",
            "  2. Additional compiler flags that you may have built libmecab with, and",
            "  3. Additional linker flags that you may have build libmecab with.",
            "  4. Location where mecab.h header file may be found",
            "",
            "Since we can't auto-probe, you should specify the above three to proceed",
            "with compilation:",
            "",
            "Version of libmecab that you are compiling against (e.g. 0.90)? (REQUIRED) []"
        )
    );
    chomp $version;

    if (! $version) {
        print STDERR "no version specified! cowardly refusing to proceed.";
        exit;
    }

    $cflags  = ExtUtils::MakeMaker::prompt("Additional compiler flags (e.g. -DWIN32 -Ic:\\path\\to\\mecab\\sdk)? []");

    $libs    = ExtUtils::MakeMaker::prompt("Additional linker flags (e.g. -lc:\\path\\to\\mecab\\sdk\\libmecab.lib)? [] ");
    $include = ExtUtils::MakeMaker::prompt("Directory containing mecab.h (e.g. c:\\path\\to\\include)? [] ");
} else {
    # try probing in places where we expect it to be
    if (! defined $default_config || ! -x $default_config) {
        foreach my $path (qw(/usr/bin /usr/local/bin /opt/local/bin)) {
            my $tmp = File::Spec->catfile($path, 'mecab-config');
            if (-f $tmp && -x _) {
                $default_config = $tmp;
                last;
            }
        }
    }

    $mecab_config = ExtUtils::MakeMaker::prompt( "Path to mecab config?", $default_config );

    if (!-f $mecab_config || ! -x _) {
        print STDERR "Can't proceed without mecab-config. Aborting...\n";
        exit;
    }
    
    $version = `$mecab_config --version`;
    chomp $version;

    $cflags = `$mecab_config --cflags`;
    chomp($cflags);

    $libs   = `$mecab_config --libs`;
    chomp($libs);
    $include = `$mecab_config --inc-dir`;
    chomp $include;
}

print "detected mecab version $version\n";
if ($version < 0.90) {
    print " + mecab version < 0.90 doesn't contain some of the features\n",
          " + that are available in Text::MeCab. Please read the documentation\n",
          " + carefully before using\n";
}

my($major, $minor, $micro) = map { s/\D+//g; $_ } split(/\./, $version);

$cflags .= " -DMECAB_MAJOR_VERSION=$major -DMECAB_MINOR_VERSION=$minor";

# remove whitespaces from beginning and ending of strings
$cflags =~ s/^\s+//;
$cflags =~ s/\s+$//;

print "Using compiler flags '$cflags'...\n";

if ($libs) {
    $libs =~ s/^\s+//;
    $libs =~ s/\s+$//;
    print "Using linker flags '$libs'...\n";
} else {
    print "No linker flags specified\n";
}

my $encoding = ExtUtils::MakeMaker::prompt(
    join(
        "\n",
        "",
        "Text::MeCab needs to know what encoding you built your dictionary with",
        "to properly execute tests.",
        "",
        "Encoding of your mecab dictionary? (shift_jis, euc-jp, utf-8)",
    ),
    $default_encoding
);

print "Using $encoding as your dictionary encoding\n";

return {
    version  => $version,
    cflags   => $cflags,
    libs     => $libs,
    include  => $include,
    encoding => $encoding,
    config   => $mecab_config,
};
