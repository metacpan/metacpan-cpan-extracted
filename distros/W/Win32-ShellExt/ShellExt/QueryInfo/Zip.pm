# -*- cperl -*-
#
# sample extension that extracts the package version number out of a .zip file.
#
# Kind of like 'ZipTip' (http://www.na.rim.or.jp/~norio/index-e.shtml), i think,
# but then i haven't tried it, i'm just giving the URL for future reference.
#
# (C) 2001-2002 jbnivoit@cpan.org
#

package Win32::ShellExt::QueryInfo::Zip;

use 5.006;
use warnings;
use Win32::ShellExt::QueryInfo;

use Archive::Zip 0.11;

$Win32::ShellExt::QueryInfo::Zip::VERSION='0.1';
@Win32::ShellExt::QueryInfo::Zip::ISA=qw(Win32::ShellExt::QueryInfo);

sub get_info_tip() {
  my ($self,$file) = @_;

  my $zip = Archive::Zip->new();
  my $status = $zip->read($file);
  my $s="zip archive";
  if($status == AZ_OK) {
    foreach my $member ($zip->members())
      {
	$s .= "\n " . $member->fileName()
	  . " (" . $member->uncompressedSize() . "/" . $member->compressedSize() . ")" 
	    unless $member->uncompressedSize()==0; # this skips over directories.
      }
    # FIXME maybe add a limit to the number of members we examine, for fear of creating a 
    # string too large to go into a tooltip...
  }
  $s;
}

sub hkeys() {
  my $h = {
	   "CLSID" => "{99934D3C-6386-477F-8004-F19CAC35C829}",
	   "extension" => "zip",
	   "package" => "Win32::ShellExt::QueryInfo::Zip"
	  };
  $h;
}

1;

