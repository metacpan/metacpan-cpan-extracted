package Win32::VolumeInformation;

use Win32::API;
use File::Spec;

use Exporter ();
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( GetVolumeInformation );

our $VERSION = 0.2;

our $volinfofunc = Win32::API->new('kernel32', 'GetVolumeInformation', ['P','P','N','P','P','P','P','N'], 'N')
	or die "Win32::API->new GetVolumeInformation: $!";

our %flags = (
	 0x00000001 => 'FS_CASE_SENSITIVE'
	,0x00000002 => 'FS_CASE_IS_PRESERVED'
	,0x00000004 => 'FS_UNICODE_STORED_ON_DISK'
	,0x00000008 => 'FS_PERSISTENT_ACLS'
	,0x00000010 => 'FS_FILE_COMPRESSION'
	,0x00000020 => 'FILE_VOLUME_QUOTAS'
	,0x00000040 => 'FILE_SUPPORTS_SPARSE_FILES'
	,0x00000080 => 'FILE_SUPPORTS_REPARSE_POINTS'
	,0x00008000 => 'FS_VOL_IS_COMPRESSED'
	,0x00000000 => 'FILE_NAMED_STREAMS'
	,0x00020000 => 'FILE_SUPPORTS_ENCRYPTION'
	,0x00010000 => 'FILE_SUPPORTS_OBJECT_IDS'
);

sub get_flags{
	my $flags = shift;
	my %result;
	for( keys %flags ){
		$result{ $flags{$_} } = $flags & $_ ? 1 : 0;
	}
	return \%result;
}

sub GetVolumeInformation{
	my( $vol,$path,$file) = File::Spec->splitpath(shift);
	$vol = ( $vol ) ? $vol."\\" : 0;
	my $name,$serial,$maxlen,$flags,$fstype;
	$name = $fstype = "\0"x256;
	$serial = $maxlen = $flags = pack("L", 0);
	if( $volinfofunc->Call($vol,$name,256,$serial,$maxlen,$flags,$fstype,256) ){
		$_ =~ s/\0*$// for ( $name,$fstype );
		$_ = unpack("L", $_) for ( $serial,$maxlen,$flags );
		my $result = get_flags($flags);
		$result->{VolumeName} = $name;
		$result->{VolumeSerialNumber} = $serial;
		$result->{MaximumComponentLength} = $maxlen;
		$result->{FileSystemName} = $fsname;
		$_[1] = $result;
		return 1;
	}
	return 0;
}

1;