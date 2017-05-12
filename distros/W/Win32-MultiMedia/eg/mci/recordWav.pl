use Win32::MultiMedia::Mci;

$mci = Win32::MultiMedia::Mci->open("new", type=>"waveaudio");

print "Press enter to start recording\n";
if ($mci->can("record") && !$mci->record())
{
	print "Press enter to stop recording\n";
	$t = <STDIN>;

	$mci->stop;
	$mci->save("test.wav") || print "test.wav written\n";
     print $mci->error;
}
else
{
	print $mci->error;
}
$mci->close;

