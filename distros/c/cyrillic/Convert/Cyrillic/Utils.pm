package Convert::Cyrillic::Utils;

$VERSION = '1.01';

sub cs2encoding {
	my ($enc) = @_;
	my ($charset);
	
	$charset = "koi8-r" if $enc=~/koi/io; 
	$charset = "windows-1251" if $enc=~/win/io; 
	$charset = "x-mac-cyrillic" if $enc=~/mac/io; 
	$charset = "ibm866" if $enc=~/dos/io;
	$charset = "ISO-8859-5" if $enc=~/iso/io;
	$charset = "UTF-8" if $enc=~/utf8/io;

	$META = <<"EOF"
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=$charset">
EOF
		if $charset;
}

sub Platform2DefEncoding {
	my ($platform) = @_;
	$encoding = '';
	$encoding = 'win' if $platform=~/WIN/io;
	$encoding = 'mac' if $platform eq 'MAC';
	$encoding = 'koi' if $platform eq 'UNIX';
	$encoding = 'dos' if $platform eq 'OS2';
	$encoding = 'nocs' if $platform eq 'Linux';
	return $encoding;
}

