#!/usr/bin/perl -w

# tabgen.pl -- generate translation tables

use strict;

my $RCS_Id = '$Id: tabgen.pl,v 1.3 2002-11-26 19:03:27+01 jv Exp $ ';
# Author          : Johan Vromans
# Created On      : Sun Sep  9 12:24:22 1990
# Last Modified By: Johan Vromans
# Last Modified On: Tue Nov 26 19:03:17 2002
# Update Count    : 44
# Status          : OK

my ($my_name, $my_version) = $RCS_Id =~ /: (.+).pl,v ([\d.]+)/;
$my_version .= '*' if length('$Locker:  $ ') > 12;

use Getopt::Long;

# program parameters

my $all = 0;
my $iso2tex = 0;

GetOptions(all => \$all, iso2tex => \$iso2tex)
  or die("Usage: $0 [ -all | -iso2tex ]\n");

$iso2tex   = $all || $iso2tex;

# Read & build the internal tables

my ($iso, $apple, $sym, $pc, $tex, $name);

my %iso2tex;
my %iso2name;

while ( <> ) {
    next if /^#/ || /^$/;
    chop;
    ($iso, $apple, $sym, $pc, $tex, $name) = split (/\t/);
    $iso2tex{$iso} = $tex
	if $iso2tex && ($iso ne "" && $tex ne "");
    $iso2name{$iso} = $name;
}

# Emit requested tables

if ( $iso2tex ) {
    print '%::iso2tex = (', "\n";
    foreach $iso (sort (keys (%iso2tex))) {
	emit(dpiso($iso), dpsym($iso2tex{$iso}), $iso2name{$iso});
    }
    print "  );\n";
}


print "\n1;\n";

################ Subroutines ################

sub emit {
    print STDOUT ("    ", $_[0], ",\t", $_[1], ",\t# ", $_[2], "\n");
}

sub dpsym {
    my ($sym) = @_;
    if ( $sym =~ /'/ ) {
	$sym =~ s/([\134\044\100\045])/\\$1/g;
	return '"' . $sym . '"';
    }
    "'" . $sym . "'";
}

sub dpiso {
    "\"\\" . $_[0] . "\"";
}
