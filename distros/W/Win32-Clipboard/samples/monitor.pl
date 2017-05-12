use blib;
use Win32::Clipboard;

print <<EOP;

  copy "quit" to the clipboard to quit!

EOP

$C = Win32::Clipboard();
$C->Empty();
LOOP:
while ($C->Get() ne "quit") {
	$whathappened = $C->WaitForChange(10000);
	if(not defined $whathappened) {
		die "error in WaitForChange: $^E\n";
		last LOOP;
	} elsif($whathappened == 1) {
		print "got a change!\n\n";
		print join("\n", $C->Get()), "\n";
	} else {
		print "ten seconds passed...\n";
	}
}
