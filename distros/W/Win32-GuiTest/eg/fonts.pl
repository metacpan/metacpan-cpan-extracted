#!perl -w
# $Id: fonts.pl,v 1.4 2004/07/19 20:20:58 szabgab Exp $
# Use Win32::GuiTest to get a list of supported fonts from a
# dialog box.
# By Ernesto Guisado (erngui@acm.org).

use strict;

use Win32::GuiTest qw(:ALL);

#sub FontTxt { "Fuente"; } # i18n
#sub OpenFont { "%ef"; }   # i18n

# Let's see notepad
system("start notepad.exe");
sleep 1;

# Open the Font dialog
#SendKeys(OpenFont);
MenuSelect("F&ormat|&Font");  # this is also language dependent !
sleep(1);

# Find the Font dialog using the title and window class
# The Font dialog isn't a child of the notepad window
#my ($fontdlg) = FindWindowLike(0, FontTxt); 
my $fontdlg = GetForegroundWindow();
die "We could not fing the Font dialog\n" if not defined $fontdlg;
print GetWindowText($fontdlg), "\n\n";
sleep(3);

# Find the right combo using it's control id
my ($combo) = FindWindowLike($fontdlg, "", "ComboBox", 0x470);
die "Where is the combo with the font names?" unless $combo;

# Print all the font names
for (GetComboContents($combo)) {
    print "'$_'" . "\n";
}

# Close the dialog and notepad
SendKeys("{ESC}%{F4}");

