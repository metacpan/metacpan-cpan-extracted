# -*- cperl -*-
#
# (C) 2002 jbnivoit@cpan.org
#

package Win32::ShellExt::QueryInfo::JpgSize;

use 5.006;
use strict;
use warnings;
use Win32::ShellExt::QueryInfo 0.1;
use Image::Magick 5.41;

$Win32::ShellExt::QueryInfo::JpgSize::VERSION='0.1';
@Win32::ShellExt::QueryInfo::JpgSize::ISA=qw(Win32::ShellExt::QueryInfo);

sub get_info_tip() {
  my ($self,$file) = @_;

# another way of doing it, with a different module:
#  use Image::Size qw(:all);
#  my ($w, $h, $err) = imgsize($file);
#  print "JPEG size $h x $w\n";

  my $img = new Image::Magick;
  $img->Read($file);
  my $h = $img->GetAttribute('height');
  my $w = $img->GetAttribute('width');
  undef $img;
  "JPEG size $h x $w";
}

sub hkeys() {
  my $h = {
	   "CLSID" => "{C29C09C5-AEBF-4504-9667-169A16E11F24}",
	   "extension" => "jpg",
	   "package" => "Win32::ShellExt::QueryInfo::JpgSize"
	  };
  $h;
}

1;
