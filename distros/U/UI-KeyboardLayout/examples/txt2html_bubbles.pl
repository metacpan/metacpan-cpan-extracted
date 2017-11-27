#!/usr/bin/perl -wC31
use UI::KeyboardLayout; 
use strict;

#open my $f, '<', 
my $d = "$ENV{HOME}/Downloads";
my $f = 'NamesList.txt';		# or die;
-e "$d/$f" or $ENV{HOMEDRIVE} and $ENV{HOMEPATH} and $d = '$ENV{HOMEDRIVE}$ENV{HOMEPATH}';
-e "$d/$f" or $d = '/cygdrive/c/Users/ilya/Downloads';
UI::KeyboardLayout::->set_NamesList("$d/$f", "$d/DerivedAge.txt"); 
my $k = UI::KeyboardLayout::->new()->require_unidata_age;	# ->load_unidata("$d/$f", "$d/DerivedAge.txt");

print <<EOP;
<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/></head><body><table>
EOP
while (<>) {
  s/\s+$//;
  s(/|(?<=\t)(?=\S))(</td><td>)g;	# Make tabs and / separate columns
  s{([^\x00-\x7E])}{ sprintf '<span title="%04X  %s">%s</span>', ord $1, $k->UName("$1", 'verbose'), $1 }ge;
  print "<tr><td>$_</td></tr>\n"
}
print <<EOP;
</table></body></html>
EOP
