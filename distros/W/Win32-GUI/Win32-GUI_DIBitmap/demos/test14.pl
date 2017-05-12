#!perl -w
use strict;
use warnings;

#
#  Test some effects
#

use FindBin();
use Win32::GUI();
use Win32::GUI::DIBitmap;

my $Menu =  Win32::GUI::Menu->new(
    "&Effect"                  => "Effect",
    "   > &Restore"            => "EffectRestore",
    "   > -"                   => 0,
    "   > Dither"              => "EffectDither",
    "   > Threshold (50)"      => "EffectThreshold",
    "   > -"                   => 0,
    "   > AdjustGamma (0.5)"      => "EffectAdjustGamma1",
    "   > AdjustGamma (1.5)"      => "EffectAdjustGamma2",
    "   > AdjustBrightness (-50)" => "EffectAdjustBrightness1",
    "   > AdjustBrightness (50)"  => "EffectAdjustBrightness2",
    "   > AdjustContrast (-50)"   => "EffectAdjustContrast1",
    "   > AdjustContrast (50)"    => "EffectAdjustContrast2",
    "   > Invert"            => "EffectInvert",
    "   > -"                 => 0,
    "   > Copy"              => "EffectCopy",
    "   > Paste"             => "EffectPaste",
    "   > -"                 => 0,
    "   > Rotate(45)"        => "EffectRotate",
    "   > RotateEx(45, 10, 10, 10, 10, 1)"        => "EffectRotateEx",
    "   > FlipHorizontal"    => "EffectFlipHorizontal",
    "   > FlipVertical"      => "EffectFlipVertical",
    "   > -"                 => 0,
    "   > Rescale (W+10, H+10)" => "EffectRescaleUp",
    "   > Rescale (W-10, H-10)" => "EffectRescaleDown",
    "   > -"                  => 0,
    "   > E&xit"              => "EffectExit",
    );

my $W = new Win32::GUI::Window (
    -title    => "Win32::GUI::DIBitmap test",
    -left     => 100,
    -top      => 100,
    -width    => 400,
    -height   => 400,
    -name     => "Window",
    -menu     => $Menu,
) or die "new Window";

my $G = Win32::GUI::Graphic->new ($W,
              -name     => "Graphic",
              -pos      => [0, 0],
              -size     => [$W->ScaleWidth,$W->ScaleHeight],
              );

my $dib;
EffectRestore_Click();

$W->Show();
Win32::GUI::Dialog();
exit(0);

sub Window_Resize {
  $G->Resize ($W->ScaleWidth, $W->ScaleHeight);
}

sub Graphic_Paint {
  my $dc = $G->GetDC();
  my ($width, $height) = ($G->GetClientRect)[2..3];

  $dib->StretchToDC($dc, 0, 0, $width, $height) if defined $dib;

  $dc->Validate();
}

sub EffectExit_Click {
    return -1;
}

sub EffectRestore_Click {
  $dib = newFromFile Win32::GUI::DIBitmap ("$FindBin::Bin/zapotec.bmp")
	  or die "newFromFile";
  $dib = $dib->ConvertTo32Bits();
  $G->InvalidateRect(1);
}

sub EffectDither_Click {
  $dib = $dib->Dither() if defined $dib;
  $G->InvalidateRect(1);
}

sub EffectThreshold_Click {
  $dib = $dib->Threshold(50) if defined $dib;
  $G->InvalidateRect(1);
}

sub EffectAdjustGamma1_Click {
  $dib->AdjustGamma(0.5) if defined $dib;
  $G->InvalidateRect(1);
}

sub EffectAdjustGamma2_Click {
  $dib->AdjustGamma(1.5) if defined $dib;
  $G->InvalidateRect(1);
}

sub EffectAdjustBrightness1_Click {
  $dib->AdjustBrightness(-50) if defined $dib;
  $G->InvalidateRect(1);
}

sub EffectAdjustBrightness2_Click {
  $dib->AdjustBrightness(50) if defined $dib;
  $G->InvalidateRect(1);
}

sub EffectAdjustContrast1_Click {
  $dib->AdjustContrast(-50) if defined $dib;
  $G->InvalidateRect(1);
}

sub EffectAdjustContrast2_Click {
  $dib->AdjustContrast(50) if defined $dib;
  $G->InvalidateRect(1);
}

sub EffectInvert_Click {
  $dib->Invert() if defined $dib;
  $G->InvalidateRect(1);
}

sub EffectCopy_Click {
  if (defined $dib and $dib->Width > 20 and $dib->Height > 20) 
  {
    $dib = $dib->Copy(10,10,$dib->Width-10,$dib->Height-10) or die "Copy";
  }
  $G->InvalidateRect(1);
}

sub EffectPaste_Click {
  if (defined $dib and $dib->Width > 20 and $dib->Height > 20) 
  {
     my $dib2 = newFromFile Win32::GUI::DIBitmap ("$FindBin::Bin/zapotec.bmp")
		 or die "newFromFile";
     $dib2 = $dib2->Copy(10,10,30,30);
     $dib->Paste($dib2, 10, 10, 500);
  }
  $G->InvalidateRect(1);
}

sub EffectFlipHorizontal_Click {

  $dib->FlipHorizontal() if defined $dib;
  $G->InvalidateRect(1);
}

sub EffectFlipVertical_Click {

  $dib->FlipVertical() if defined $dib;
  $G->InvalidateRect(1);
}

sub EffectRotate_Click {

  $dib = $dib->Rotate(45) or die "Rotate" if defined $dib;
  $G->InvalidateRect(1);
}

sub EffectRotateEx_Click {

  $dib = $dib->RotateEx(45,10,10,10,10,1) or die "RotateEx" if defined $dib;
  $G->InvalidateRect(1);
}

sub EffectRescaleUp_Click 
{
  $dib = $dib->Rescale($dib->Width+10,$dib->Height+10) or die "Rescale" if defined $dib;
  $G->InvalidateRect(1);
}

sub EffectRescaleDown_Click {
  if (defined $dib and $dib->Width > 20 and $dib->Height > 20) 
  {
    $dib = $dib->Rescale($dib->Width-10,$dib->Height-10) or die "Rescale";
  }
  $G->InvalidateRect(1);
}
