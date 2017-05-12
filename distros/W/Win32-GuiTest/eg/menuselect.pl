#!perl -w
# $Id: menuselect.pl,v 1.8 2004/07/28 11:45:13 szabgab Exp $

# Example how to get the names of the menus

use strict;

use Win32::GuiTest qw(:ALL);

system "start notepad";
sleep 1;

my $menu = GetMenu(GetForegroundWindow());
print "Menu: $menu\n";
my $submenu = GetSubMenu($menu, 0);
print "Submenu: $submenu\n";
print "Count:", GetMenuItemCount($menu), "\n";

use Data::Dumper;

my %h = GetMenuItemInfo($menu, 1);   # Edit on the main menu
print Dumper \%h;
%h = GetMenuItemInfo($submenu, 1);   # Open in the File menu
print Dumper \%h;
%h = GetMenuItemInfo($submenu, 4);   # Separator in the File menu
print Dumper \%h;

print "===================\n";
menu_parse($menu);

#MenuSelect("&Archivo|&Salir");

# Close the menu and notepad
SendKeys("{ESC}%{F4}");


# this function receives a menu id and prints as much information about that menu and 
# all its submenues as it can
# One day we might include this in the distributionor in some helper module
sub menu_parse {
	my ($menu, $depth) = @_;
	$depth ||= 0;
	
	foreach my $i (0..GetMenuItemCount($menu)-1) {
		my %h = GetMenuItemInfo($menu, $i);
		print "   " x $depth;
		print "$i  ";
		print $h{text} if $h{type} and $h{type} eq "string"; 
		print "------" if $h{type} and $h{type} eq "separator"; 
		print "UNKNOWN" if not $h{type};
		print "\n";
		
		my $submenu = GetSubMenu($menu, $i);
		if ($submenu) {
			menu_parse($submenu, $depth+1);
		}
	}
}


SendKeys("%{F4}");


