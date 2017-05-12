#!/usr/bin/perl

# usage:
# perl -Ilib  verby_par.pl @opts $input_script $output_exe
#
# creates $output_exe and $output_exe.par
# you can use 'pp -P -o $output_exe $output_exe.par' on a different platform as long as the .xs modules are installed on that machine
# or drop the -P to not rely on a perl installation at all
#
# note that this will try to parse 'step "Verby::Action::Moose"' lines and add them to -M

use strict;
use warnings;

my $output = pop @ARGV or die "You must supply an output file";
my $script = pop @ARGV or die "You must supply an input script";;

open my $fh, "<", $script or die "can't open($script): $!";

my @extra;
for ( <$fh> ) { push @extra, $1 if /step\s*[\s\(]\s*["']([\w:]+)["']/; last if /__(END|DATA)__/ }

my %seen;
@extra = grep { !$seen{$_}++ } @extra;

close $fh;

warn join("\n", "Bundling extra modules (from step 'Foo' syntax):", map { "- $_" } @extra) . "\n";

$ENV{PERL5LIB} = join(":", @INC);

system(qw/pp -d -p -x -v -z 9/, -o => "${output}.par", (map { ("-M", $_) } @extra), @ARGV, $script ) && die "error during .par archive creation";
system(qw/pp -P/, -o => $output, "${output}.par") && die "error during executable creation";

