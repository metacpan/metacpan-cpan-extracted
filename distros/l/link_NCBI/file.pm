package file;

sub file_open
{
	open(HANDLE,">$_[0]");
	print HANDLE $_[1];
	close HANDLE;
}

1;
