#!/usr/bin/perl

use strict;
use warnings;
use version;
use Module::CoreList;
use Term::ANSIColor;
use File::Basename;
use Cwd qw(abs_path);

my $min_perl = version->declare('5.10.0');

my $current = $^V;
if ($current < $min_perl) {
    die "Perl version $current is too old.  Require $min_perl or higher.\n";
}
print colored("Perl version is $current\n\n", 'green');

my $script_dir = dirname(abs_path($0));
my $makefile = "$script_dir/../Makefile.PL";
open my $fh, '<', $makefile or die "Cannot open $makefile: $!";
my %modules;

while (<$fh>) {
    if (/^\s*'([\w:]+)'\s*=>\s*\d+,?/) {
        my $mod = $1;
        next if Module::CoreList::is_core($mod);
        $modules{$mod} = 1;
    }
} 
close $fh;

print colored("\nChecking modules from PREREQ_PM...\n\n", 'cyan');
my @missing;

for my $mod (sort keys %modules) {
    eval "use $mod";
    if ($@) {
        print colored("Missing: $mod\n", 'red');
        push @missing, $mod;
    } else {
        print colored("Found: $mod\n", 'green');
    }
}

if (@missing) {
    print "\nWould you like to install missing modules with `cpan -T`? [Y/N]";
    chomp(my $choice = <STDIN>);
    if (lc $choice eq 'y') {
        for my $mod (@missing) {
            print colored("\nInstalling $mod...\n", 'yellow');
            system("cpan -T $mod");
        }
    } else {
        print colored("\nSkipped installation. Missing modules may cause runtime errors.\n", 'yellow');
    }
} else {
    print colored("\nAll required modules are installed.\n", 'bright_green');
}