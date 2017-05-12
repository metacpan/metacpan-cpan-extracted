use Win32::Clipboard;

tie $clip, 'Win32::Clipboard';

print "Clipboard Content:\n\n$clip\n";

tied($clip)->Empty();

$clip = "ciao mondo!";

print "\nLook at your clipboard now!\n\n";
