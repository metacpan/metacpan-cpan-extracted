# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::CtxtMenu::MagickConvert;

use Image::Magick 5.41;
use Win32::ShellExt::CtxtMenu;

$Win32::ShellExt::CtxtMenu::MagickConvert::VERSION='0.1';
$Win32::ShellExt::CtxtMenu::MagickConvert::COMMAND = {
					 'convert_jpg' => 'Convert to JPEG',
					 'convert_gif' => 'Convert to GIF',
					 'convert_png' => 'Convert to PNG',
					 'convert_fpx' => 'Convert to FPX'
					 };
@Win32::ShellExt::CtxtMenu::MagickConvert::ISA=qw(Win32::ShellExt::CtxtMenu);

$ENV{MAGICK_HOME}="C:\\perl\\bin";

sub query_context_menu() {
	my $self = shift;
	# @_ now holds a list of file paths to test to decide whether or not to pop our extension's menu.

	# return false if the menu item is not to be included, or a string to 
	# be used as display value if it is.
	my $ok = "Win32::ShellExt::CtxtMenu::MagickConvert";
	my $item;

	foreach $item (@_) { undef $ok if($item!~m!\.(jpg|gif|png|fpx)$!); }

	$ok;
}

sub AUTOLOAD {
  my $self = shift;
  my $type = ref($self) || die "$self is not an object";
  my $format = $AUTOLOAD;
  $format =~ s/.*://;   # strip fully-qualified portion

  $format =~ s/convert_//g;
  map {
    my $img=Image::Magick->new;
    my ($infile,$outfile)= ($_,$_);
    $outfile =~ s!\.([^.]+)$!!g;
    $outfile .= ".$format";
    my $status=$img->ReadImage($infile);
    my $status2=$img->WriteImage( filename=>"$outfile" ) ;
    local *F;
    open F,">>d:\\log8.txt";
    print F "$img $infile $outfile $status $status2\n";
    close F;
  } @_;

  1;
}

sub hkeys() {
  my $h = {
	   "CLSID" => "{A92DF786-9BCA-4DB8-882D-B527EFCBE0BE}",
	   "name"  => "MagickConvert shell Extension",
	   "package" => "Win32::ShellExt::CtxtMenu::MagickConvert"
	  };
  $h;
}

1;



