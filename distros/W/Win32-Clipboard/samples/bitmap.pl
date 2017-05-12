use Win32::Clipboard;

if(Win32::Clipboard::IsBitmap) {
	$BUFFER = 
	open BMP, ">test.bmp";
	binmode BMP;
	print BMP Win32::Clipboard::Get();
	close BMP;
	undef $BUFFER;
	print "data written to test.bmp\n";
} else {
	print "clipboard does not contain a bitmap!\n";
}
