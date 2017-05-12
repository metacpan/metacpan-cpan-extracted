use Win32::Clipboard;

$clip = Win32::Clipboard;

print "Clipboard Content:\n\n", $clip->Get, "\n";

$clip->Empty();

$clip->Set("ciao mondo!");

print "\nLook at your clipboard now!\n\n";
