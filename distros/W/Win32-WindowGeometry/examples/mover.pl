use Win32::WindowGeometry;

my @theseWindows = ListWindows('bin\\perl');

foreach(@theseWindows)
{
	AdjustWindow($_, 0, 0, 480, 320);
}
sleep(1);
foreach(@theseWindows)
{
	AdjustWindow($_, 0, 80, 480, 320);
}
sleep(1);
foreach(@theseWindows)
{
	AdjustWindow($_, 80, 80, 480, 320);
}
sleep(1);
foreach(@theseWindows)
{
	AdjustWindow($_, 80, 0, 480, 320);
}
sleep(1);
foreach(@theseWindows)
{
	AdjustWindow($_, 160, 160, 640, 320);
}
sleep(1);
foreach(@theseWindows)
{
	AdjustWindow($_, 160, 160, 640, 480);
}
sleep(1);
foreach(@theseWindows)
{
	AdjustWindow($_, 320, 160, 640, 480);
}
sleep(1);
foreach(@theseWindows)
{
	AdjustWindow($_, 480, 160, 640, 480);
}
sleep(5);
exit;