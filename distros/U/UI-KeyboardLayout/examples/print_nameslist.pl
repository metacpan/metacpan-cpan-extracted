#!/usr/bin/perl -wC31
use UI::KeyboardLayout; 
use strict;

#die "Usage: $0 [<] files" unless @ARGV;
#open my $f, '<', 
my $d = "$ENV{HOME}/Downloads";
my $f = "NamesList.txt";		# or die;
-e "$d/$f" or $d = "$ENV{HOMEDRIVE}$ENV{HOMEPATH}/Downloads";	# '/cygdrive/c/Users/ilya/Downloads';
my $k = UI::KeyboardLayout::->new()->load_unidata("$d/$f", "$d/DerivedAge.txt");

my $s;
my $hex = (@ARGV and $ARGV[0] eq '-hex' and shift);
{  local $/;
   $s = <>		# Unicod::UCD is not compatible with non-standard $/
}
if ($hex) {
  my %s;
  $s{chr hex $1}++ while $s =~ /^([\da-f]{4,})\b/mig;
  $s = join '', keys %s;
}
$k->print_coverage_string($s);
