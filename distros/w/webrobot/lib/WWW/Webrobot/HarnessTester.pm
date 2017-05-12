package WWW::Webrobot::HarnessTester;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG

use Test::Harness;
use File::Path;
use File::Basename;


my $USAGE = <<EOF;
bin/runtests.pl [options]
Option          Description
-h -? --help    This message
-v --verbose    Print all output of tests
EOF

sub run {
    my %parm = (@_);
    my @tests = @{$parm{tests}};
    my @argv = @{$parm{argv}};
    foreach (@argv) {
        /^--help$/ || /^-h$/ || /^-\?$/ and do {
            print $USAGE;
            return 0;
        };
        /^--verbose$/ || /^-v$/ and do {
            $Test::Harness::verbose = 1;
            next;
        };
    }

    # Problem: 'runtests' accepts filenames to execute, but no parameters

    my @files = ();
    -d "bin/t" or mkdir "bin/t" or die "Can't create bin/t";
    my $i=0;
    foreach (@tests) {
        #my $filename = "bin/t/t$i.t";
        my $filename = "bin/t/" . $_ . ".t";

        my ($base, $path, $type) = fileparse($filename);
        -d $path || mkpath($path, 1);
    
        open FILE, ">$filename" or die "Can't write to $filename";
        print FILE <<EOF;
#!/usr/bin/perl -w
use WWW::Webrobot;
my \$arg = shift || '';
my \$USAGE = <<EOF_USAGE;
usage: $filename [option]
Executes testscript if called without option.
OPTION           DESCRIPTION
-h --help        print this message
-n --name        print the name of the testplan that belongs to this test
EOF_USAGE
print("\$USAGE"), exit if \$arg eq "-h" || \$arg eq "--help";
print("$_\\n"), exit if \$arg eq "-n" || \$arg eq "--name";
print("\$USAGE"), exit if \$arg;
my \$webrobot = WWW::Webrobot -> new(\\"bin/webtest.prop");
\$webrobot -> run(\\"$_");
1;
EOF
        close FILE;
        chmod 0777, $filename or warn "Can't chmod a+x, $filename";
        push @files, $filename;
        $i++;
    }
    eval {runtests(@files) };
    print $@;

    if ($@) {
        print <<EOF;
======================================================================
* For complete output run this script again with option '--verbose'.
* If you want to run an individual test, just call it.
EOF
        return 1;
    }
    return 0;
}

1;

=head1 NAME

WWW::Webrobot::HarnessTester - make *.t executables from *.xml testplans and run the plans

=head1 SYNOPSIS

use WWW::Webrobot::HarnessTester;
WWW::Webrobot::HarnessTester::run(argv => \@ARGV, tests => \@tests);

=head1 DESCRIPTION

Make *.t executables from *.xml testplans and run the plans.

Runs tests for the abas-eB shop.
The config file is C<bin/webtest.prop>,
change it for your needs.

=head1 METHODS

=over

=item exit WWW::Webrobot::HarnessTester::run(%parm);

 - 'argv': checks commandline parameters
 - 'test' is a ref to a list of .xml testplan names

Creates *.t files to be run by Test::Harness.
The source for a *.t file is a *.xml file.

=back
