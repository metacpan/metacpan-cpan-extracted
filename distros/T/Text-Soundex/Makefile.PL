# -*- perl -*-
use strict;

use ExtUtils::MakeMaker;

my $useXS = 1;

foreach (@ARGV) {
    /^--use-xs$/ && do {
	$useXS = 1;
	next;
    };

    /^--no-xs$/ && do {
	$useXS = 0;
	next;
    };

    warn "WARNING: Option $_ was not recognized. (ignoring)\n";
}

my %BuildOptions;
$BuildOptions{'NAME'}         = "Text::Soundex";
$BuildOptions{'LICENSE'}      = "perl";

$BuildOptions{'VERSION_FROM'} = "Soundex.pm";      # Finds $VERSION
$BuildOptions{'INSTALLDIRS'}  = $] > 5.011 ? 'site' : "perl"; # Install in CORE.
$BuildOptions{'NORECURS'}     = 1;                 # No need to recurse.

$BuildOptions{'dist'}         = {
                                 'COMPRESS'    => "gzip -v9Nf",
                                 'SUFFIX'      => "gz",
                                };

$BuildOptions{'PREREQ_PM'}    = {
                                 'if'          => 0,
                                };

if ($useXS) {
    print "The XS code will be compiled.\n" if -t STDOUT;
    $BuildOptions{'XS'}   = {'Soundex.xs' => 'Soundex.c'};
    $BuildOptions{'C'}    = ['Soundex.c'];

} else {
    print "The XS code will not be compiled.\n" if -t STDOUT;
    $BuildOptions{'XS'}   = {};
    $BuildOptions{'C'}    = [];

}

WriteMakefile(%BuildOptions);
