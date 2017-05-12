#!perl -w
#######################################################################
#
#                           Perl Image Viewer
#
#######################################################################

use strict;
use warnings;

use FindBin();
use Win32::GUI qw(MB_ICONQUESTION MB_ICONINFORMATION MB_YESNOCANCEL);
use Win32::GUI::DIBitmap;

my @PIVReadFilter;
my @PIVSaveFilter;
my $PIVDirectory;
my $PIVDib;
my $PIVFile = "";

PIVInit ();

my $Menu =  Win32::GUI::MakeMenu(
    "&File"                   => "File",
    "   > &Open..."           => "FileOpen",
    "   > -"                      => 0,
    "   > &Save"              => "FileSave",
    "   > &Save As..."        => "FileSaveAs",
    "   > -"                  => 0,
    "   > &Directory..."      => "FileDirectory",
    "   > -"                  => 0,
    "   > E&xit"              => "FileExit",
    "&Image"                  => "Image",
    "   > &Properties..."     => "ImageProperties",
    "   > -"                  => 0,
    "   > &Convert"           => "ImageConvert",
    "   >> &8bits"            => "ImageConvert8bits",
    "   >> &16bits"           => "ImageConvert16bits",
    "   >> &24bits"           => "ImageConvert24bits",
    "   >> &32bits"           => "ImageConvert32bits",
    "   > -"                  => 0,
    "   > Color &Quantize"    => "ImageColor",
    "   >> Methode WUQUANT"   => "ImageColor1",
    "   >> Methode NNQUANT"   => "ImageColor2",
    "&Help"                   => "Help",
    "   > &About PIV"         => "HelpAbout",
    );

my $Window = new Win32::GUI::Window(
    -name  => "Window",
    -title => "Perl Image Viewer",
    -pos   => [100, 100],
    -size  => [400, 400],
    -menu  => $Menu,
);

$Window->AddGraphic(
    -name => "Graphic",
    -pos  => [0, 0],
    -size => [$Window->ScaleWidth,$Window->ScaleHeight],
);

my $WProp = new Win32::GUI::DialogBox(
    -title  => "Image Properties",
    -left   => 110,
    -top    => 110,
    -width  => 400,
    -height => 150,
    -name   => "WProp",
);

$WProp->AddLabel (
    -name => "pFile",
    -text => "File   :",
    -pos  => [10, 25],
    -size => [$WProp->ScaleWidth()-20, 20],
);

$WProp->AddLabel (
    -name => "pWidth",        -pos  => [10, 25],
        -size => [280, 20]
    -text => "Width  :",
    -pos  => [10, 50],
    -size => [200, 20]
);

$WProp->AddLabel (
    -name => "pHeight",
    -text => "Height :",
    -pos  => [10, 75],
    -size => [200, 20]
);

$WProp->AddLabel (
    -name => "pBPP",
    -text => "BPP    :",
    -pos  => [10, 100],
    -size => [200, 20]
);

$WProp->AddButton (
    -name => "WPropClose",
    -text => "Close",
    -pos  => [$WProp->ScaleWidth()-50, $WProp->ScaleHeight()-30],
);


PIVMenu();

$Window->Show();
Win32::GUI::Dialog();

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
  my %SaveFilter;

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
      $ReadFilter {"$desc"} = $ext;
      $list .= ";$ext";
    }

    if (Win32::GUI::DIBitmap::FIFSupportsWriting($fif)) {
      $SaveFilter {"$desc"} = $ext;
    }
  }


  push @PIVReadFilter, "All PIV Files", $list;

  foreach my $i (sort keys %ReadFilter) {
    push @PIVReadFilter, $i, $ReadFilter{$i};
  }

  foreach my $i (sort keys %SaveFilter) {
    push @PIVSaveFilter, $i, $SaveFilter{$i};
  }

  #
  # init PIVDirectory
  #

  $PIVDirectory = $FindBin::Bin;
  $PIVDirectory =~ tr/\//\\/;
}

sub PIVMenu {

  if (defined $PIVDib) {
    $Menu->{ImageProperties}->Enabled(1);
    $Menu->{ImageConvert}->Enabled(1);

    my $bpp = $PIVDib->GetBPP();
    $Menu->{ImageColor}->Enabled($bpp == 24);
    $Menu->{ImageConvert8bits}->Enabled($bpp != 8);
    $Menu->{ImageConvert16bits}->Enabled($bpp != 16);
    $Menu->{ImageConvert24bits}->Enabled($bpp != 24);
    $Menu->{ImageConvert32bits}->Enabled($bpp != 32);

    $Menu->{FileSave}->Enabled(1);
    $Menu->{FileSaveAs}->Enabled(1);
  }
  else {
    $Menu->{ImageProperties}->Enabled(0);
    $Menu->{ImageConvert}->Enabled(0);
    $Menu->{ImageColor}->Enabled(0);
    $Menu->{FileSave}->Enabled(0);
    $Menu->{FileSaveAs}->Enabled(0);
  }
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

sub Window_Terminate {

  return PIVFinish();
}

sub Window_Resize {

  $Window->Graphic->Resize($Window->ScaleWidth, $Window->ScaleHeight);

}

#######################################################################
#
#  Graphic Event
#
#######################################################################

sub Graphic_Paint {

  my $DC = $Window->Graphic->GetDC();

  if (defined $PIVDib) {

    # $PIVDib->CopyToDC($DC);
    $PIVDib->AlphaCopyToDC($DC);
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
    $PIVFile = $ret;
    PIVAdjustDisplay ();
    PIVAdjustDisplay ();
    PIVMenu();
  }
  elsif (Win32::GUI::CommDlgExtendedError()) {
     Win32::GUI::MessageBox (0, "ERROR : ".Win32::GUI::CommDlgExtendedError(),
                            "GetOpenFileName Error");
  }

}

sub FileSave_Click {

  my $ret = Win32::GUI::MessageBox (0, "Overwrite existing file ?",
                         "About",MB_ICONQUESTION | MB_YESNOCANCEL);


  if ($ret == 6) {
    $ret = $PIVDib->SaveToFile ($PIVFile);
    unless ($ret) {
      Win32::GUI::MessageBox (0, "ERROR : SaveToFile failed\r\nDoes the save format you selected support the BPP of the current image?", "Save Error");
    }
  }
  elsif ($ret == 7) {
    FileSaveAs_Click();
  }
}

sub FileSaveAs_Click {


  my $ret = Win32::GUI::GetSaveFileName(
                 -title     => "Save Image File As",
                 -filter    => \@PIVSaveFilter,
                 -directory => $PIVDirectory,
                 );

  if ($ret) {
	  print "$ret\n";
    $PIVFile = $ret;
    $ret = $PIVDib->SaveToFile ($PIVFile);
    unless ($ret) {
      Win32::GUI::MessageBox (0, "ERROR : SaveToFile failed\r\nDoes the save format you selected support the BPP of the current image?", "Save Error");
    }

  }
  elsif (Win32::GUI::CommDlgExtendedError()) {
     Win32::GUI::MessageBox (0, "ERROR : ".Win32::GUI::CommDlgExtendedError(),
                            "GetSaveFileName Error");
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

#######################################################################
#
#  Image Menu
#
#######################################################################

sub ImageProperties_Click {

  if (defined $PIVDib) {
    $Window->Disable();
    $WProp->pFile->Text("File    : ".$PIVFile);
    $WProp->pWidth->Text("Width   : ".$PIVDib->Width());
    $WProp->pHeight->Text("Height  : ".$PIVDib->Height());
    $WProp->pBPP->Text("BPP,Colors useds,Color type : ".$PIVDib->GetBPP().
                                ",".$PIVDib->GetColorsUsed().
                                ",".$PIVDib->GetColorType());
    $WProp->Show();
  }
}

sub ImageConvert8bits_Click {

  $PIVDib = $PIVDib->ConvertTo8Bits();
  Graphic_Paint();
  PIVMenu();
}

sub ImageConvert16bits_Click {

  $PIVDib = $PIVDib->ConvertTo16Bits555();
  Graphic_Paint();
  PIVMenu();
}

sub ImageConvert24bits_Click {

  $PIVDib = $PIVDib->ConvertTo24Bits();
  Graphic_Paint();
  PIVMenu();
}

sub ImageConvert32bits_Click {

  $PIVDib = $PIVDib->ConvertTo32Bits();
  Graphic_Paint();
  PIVMenu();
}


sub ImageColor1_Click {

  $PIVDib = $PIVDib->ColorQuantize(FIQ_WUQUANT);
  Graphic_Paint();
  PIVMenu();
}

sub ImageColor2_Click {

  $PIVDib = $PIVDib->ColorQuantize(FIQ_NNQUANT);
  Graphic_Paint();
  PIVMenu();
}

#######################################################################
#
#  Help Menu
#
#######################################################################

sub HelpAbout_Click {

  Win32::GUI::MessageBox (0, "Perl Image Viewer 1.0 by Laurent Rocher",
                         "About",MB_ICONINFORMATION);

}

#######################################################################
#
#  Image Properties
#
#######################################################################

sub WPropClose_Click {

  $WProp->Hide();
  $Window->Enable();
  $Window->SetForegroundWindow();
}
