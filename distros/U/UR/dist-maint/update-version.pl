#!/usr/bin/env perl
use strict;
use warnings;
my $new = shift;
die "please supply the new version number N.NN\n" unless $new;
my $old = shift;
$old ||= ($new - 0.01);
print "updating version from $old to $new\n";

my $cmd = qq{cd ..; dist-maint/findreplace '$old"; # UR \\\$VERSION' '$new"; # UR \$VERSION' `grep -rn '# UR \\\$VERSION' lib/ | sed s/:.*//`};
print $cmd,"\n";
system $cmd;

$cmd = qq{cd ..; dist-maint/findreplace ' version $old' ' version $new' `grep -rn 'This document describes ' lib/ | sed s/:.*//`};
print $cmd,"\n";
system $cmd;
