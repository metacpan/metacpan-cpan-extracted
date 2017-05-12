# -*- cperl -*-
#
# (C) 2002 jbnivoit@cpan.org
#

package Win32::ShellExt::ColumnProvider::JpgSize;

use 5.006;
use strict;
use warnings;
use Win32::ShellExt::ColumnProvider 0.1;
use Image::Magick 5.41;

$Win32::ShellExt::ColumnProvider::JpgSize::VERSION='0.1';
@Win32::ShellExt::ColumnProvider::JpgSize::ISA=qw(Win32::ShellExt::ColumnProvider);

$ENV{MAGICK_HOME}="C:\\perl\\bin";

$Win32::ShellExt::ColumnProvider::JpgSize::COLUMNS = {
						      'height' => { 'description' => 'provides the height of JPGs', 'callback' => 'get_item_data_height' },
						      'width'  => { 'description' => 'provides the width of JPGs',  'callback' => 'get_item_data_width'  }
						     };


sub log() {
  my ($m,$s) = @_;
  local *F;
  open F,">>D:\log8.txt";
  print F "$m $s\n";
  close F;
}

sub get_item_data_height() {
  my ($self,$file) = @_;
  &log("get_item_data_height",$file);
  return undef if($file!~m!jpg$!i) ;
  my $img = new Image::Magick;
  $img->Read($file);
  my $s = $img->GetAttribute('height');
  &log("get_item_data_height",$s);
  $s;
}
sub get_item_data_width() {
  my ($self,$file) = @_;
  &log("get_item_data_width",$file);
  return undef if($file!~m!jpg$!i) ;
  my $img = new Image::Magick;
  $img->Read($file);
  my $s = $img->GetAttribute('width');
  &log("get_item_data_width",$s);
  $s;
}

sub hkeys() {
  my $h = {
	   "CLSID" => "{DF02ACD0-8458-453A-8541-699EE3FC676D}",
	   "package" => "Win32::ShellExt::ColumnProvider::JpgSize"
	  };
  $h;
}

1;
