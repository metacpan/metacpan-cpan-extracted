#!perl -w
#######################################################################
#
#                           Perl Image Viewer
#
#######################################################################
use strict;
use warnings;

use FindBin();
use Win32::GUI();
use Win32::GUI::DIBitmap();

my @PIVReadFilter;
my $PIVDirectory;
my $PIVDib;

PIVInit ();

my $Menu =  Win32::GUI::MakeMenu(
    "&File"                   => "File",
    "   > &Open..."           => "FileOpen",
    "   > -"                  => 0,
    "   > &Directory..."      => "FileDirectory",
    "   > -"                  => 0,
    "   > E&xit"              => "FileExit",
    );

my $Window = new Win32::GUI::Window (
    -name  => "Window",
    -title => "Perl Image Viewer Demo",
    -pos   => [100, 100],
    -size  => [400, 400],
    -menu  => $Menu,
);

$Window->AddGraphic (
    -name => "Graphic",
    -pos  => [0, 0],
    -size => [$Window->ScaleWidth,$Window->ScaleHeight],
);

$Window->Show();
Win32::GUI::Dialog();
$Window->Hide();
exit(0);

#######################################################################
#
#  PIV Functions
#
#######################################################################

sub PIVInit {

  #
  # Init PIVLoadFilter and PIVSaveFilter
  #

  my %ReadFilter;
  my $count = Win32::GUI::DIBitmap::GetFIFCount();
  my $list = "";

  for (my $fif = 0; $fif < $count; $fif++) {

    my $ext   = Win32::GUI::DIBitmap::FIFExtensionList($fif);
    my $desc  = Win32::GUI::DIBitmap::FIFDescription($fif);
    my $read  = Win32::GUI::DIBitmap::FIFSupportsReading($fif);
    my $write = Win32::GUI::DIBitmap::FIFSupportsWriting($fif);

    $desc .= " (*." . join (',*.', split ( ',', $ext)) . ")";
    $ext = "*." . join (';*.', split ( ',', $ext));

    if (Win32::GUI::DIBitmap::FIFSupportsReading($fif)) {
      $ReadFilter {$desc} = $ext;
      $list .= ";$ext";
    }

  }

  push @PIVReadFilter, "All PIV Files", $list;

  foreach my $i (sort keys %ReadFilter) {
    push @PIVReadFilter, $i, $ReadFilter{$i};
  }

  #
  # init PIVDirectory
  #

  $PIVDirectory = $FindBin::Bin;
  $PIVDirectory =~ tr/\//\\/;
}

sub PIVAdjustDisplay {

  if (defined $PIVDib) {
     my $w = $Window->Width - $Window->ScaleWidth;
     my $h = $Window->Height - $Window->ScaleHeight;
     $Window->Resize ($PIVDib->Width + $w, $PIVDib->Height + $h);
  }

}

sub PIVFinish {
  undef $PIVDib;
  return -1;
}

#######################################################################
#
#  Window Event
#
#######################################################################

sub Window_Terminate { return PIVFinish(); }

sub Window_Resize {

  $Window->Graphic->Resize ($Window->ScaleWidth, $Window->ScaleHeight);

}

#######################################################################
#
#  Graphic Event
#
#######################################################################

sub Graphic_Paint {

  my $DC = $Window->Graphic->GetDC();

  if (defined $PIVDib) {

    $PIVDib->CopyToDC($DC);
  }

  $DC->Validate();
}

#######################################################################
#
#  File Menu
#
#######################################################################

sub FileOpen_Click {

  my $ret = Win32::GUI::GetOpenFileName(
                 -title     => "Open Image File",
                 -filter    => \@PIVReadFilter,
                 -directory => $PIVDirectory,
                 );
  if ($ret) {
    undef $PIVDib;
    $PIVDib = newFromFile Win32::GUI::DIBitmap ($ret);
    PIVAdjustDisplay ();
  }
  elsif (Win32::GUI::CommDlgExtendedError()) {
     Win32::GUI::MessageBox (0,
                        "ERROR : ".Win32::GUI::CommDlgExtendedError(),
                        "GetOpenFileName Error");
  }

}

sub FileDirectory_Click {

  my $ret = Win32::GUI::BrowseForFolder (
                        -title     => "Select default directory",
                        -directory => $PIVDirectory,
                        -folderonly => 1,
                        );

  $PIVDirectory = $ret if ($ret);

  return 0;
}

sub FileExit_Click {
  return PIVFinish();
}

