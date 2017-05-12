#!/usr/bin/perl
# -*- Mode: perl -*-


use ExtUtils::MakeMaker;
use Getopt::Long();

my $TESTCOLLECTION = "/tmp/test_collection";
my $TESTBINDIR = "/verity/_solaris/bin";
my $CONFIGFILE = 't/config_opts.txt';

use vars qw($opt);
$opt =
  { "help" => \&Usage,
  };
Getopt::Long::GetOptions($opt, "help", "testbindir=s", "testcollection=s");
my $source = {};
delete $opt->{'help'};

foreach my $key (qw/testbindir testcollection/) {
  Configure($opt, $key);
}
WriteToFile($CONFIGFILE, $opt);

print <<"MSG";
I will use the following settings for compiling and testing:

MSG

my $keylen = 0;
foreach my $key (keys %$opt) {
  $keylen = length($key) if length($key) > $keylen;
}
foreach my $key (sort { $a <=> $b} keys %$opt) {
  printf("  %-" . $keylen . "s (%-" . $slen . "s) = %s\n",
	 $key, $source->{$key}, $opt->{$key})
}

print <<"MSG";

To change these settings, see 'perl Makefile.PL --help'.

MSG

my $test_options = " --bindir=" . $opt->{testbindir} .
                   " --collection=" . $opt->{testcollection};

WriteMakefile(
		'MAKEFILE'=> 'Makefile',
		'VERSION_FROM' => 'lib/Verity/Collection.pm',
		'NAME'    => 'Verity::Collection', 
            	dist => {
			COMPRESS     =>'gzip',
			SUFFIX       =>'gz',
		},
                test => {TESTS => "t/*.t"}

	      );

open(MANIFEST, "MANIFEST");
foreach my $file (grep /\.pm$/, <MANIFEST>) {
    chomp $file;
    my($module) = $file =~ m|^lib/(.*)\.pm$|;
    $module =~ s|/|-|g;
    system("pod2test $file t/embedded-$module.t");
}


############################################################################
#
#   Name:    Usage
#
#   Purpose: Print Usage message and exit with error status.
#
############################################################################

sub Usage {
  print STDERR <<"USAGE";
Usage: perl $0 [options]

Possible options are:

  --testbindir=<dir>     Use Verity binaries in <dir> for running the test suite;
                         defaults to $TESTBINDIR
  --testcollection=<dir> Use the directory <dir> to hold a collection for the
                         test suite; defaults to $TESTCOLLECTION
  --help                 Print this message and exit

USAGE
  exit 1;
}


############################################################################
#
#   Name:    Configure
#
#   Purpose: Automatic configuration
#
#   Inputs:  $param - Name of the parameter being configured
#
#   Returns: Generated value, never undef
#
############################################################################

sub Configure {
    my($opt, $param) = @_;

    if (exists($opt->{$param})) {
        return;
    } 
    if ($param eq 'testcollection') {
        $opt->{$param} = $TESTCOLLECTION;
    }
    if ($param eq 'testbindir') {
        $opt->{$param} = $TESTBINDIR;
    }
}
my $bindir = '';
my $colldir = '';

sub WriteToFile {
    my($filename, $opts) = @_;

    open(OUTPUTFILE, ">$filename") || die $@;

    foreach $key (keys %{$opts}) {
        print OUTPUTFILE "$key = " . $opts->{$key} . "\n";
    }
}


