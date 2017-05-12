package Win32::Wallpaper;
require Exporter;
@Win32::Wallpaper::ISA    = qw(Exporter);
@Win32::Wallpaper::EXPORT = qw(wallpaper);
$VERSION = '0.04';

use Win32::API;
use File::Spec::Functions qw(rel2abs);
use Win32::TieRegistry(Delimiter=>"/");
use Image::Size;

sub wallpaper {

    my ( $file, $style ) = @_;

    unless ($file) {
    my $CW = $Registry->{"CUser/Control Panel/Desktop/Wallpaper"};
    return($CW);    
    } 
    
    open( IN, $file ) or die "Cannot open $file: $!";
    my ( $width, $height, $id ) = imgsize( \*IN );
    die "Only Windows BitMaP images supported. You used a $id."
      unless ( $id =~ /bmp/i );

    if ( $style =~ /\btile\b|\bstretch\b|\bcenter\b/i ) {
        my $opt1 = "CUser/Control Panel/Desktop/TileWallpaper";
        my $opt2 = "CUser/Control Panel/Desktop/WallpaperStyle";


        if ( $style =~ /tile/i ) {
            $Registry->{$opt1}=1;  
            $Registry->{$opt2}=0; 
           
        }
        elsif ( $style =~ /stretch/i ) {
            $Registry->{$opt1}=0;
            $Registry->{$opt2}=2; 
           
        }
        else {
            $Registry->{$opt1}=0;
            $Registry->{$opt2}=0; 
            
        }
    }
    else {
        die
"Your wallpaper style - $style - is unsupported. Try \"Center\" \"Tile\" or \"Stretch\""
          if $style;

    }

    $file = rel2abs $file;

    my $SystemParametersInfo =
      new Win32::API(qw(user32 SystemParametersInfoA NNPN N)) || die $^E;
    use constant SPIF_SETDESKWALLPAPER => 20;
    use constant SPIF_UPDATEINIFILE    => 1;
    $SystemParametersInfo->Call( SPIF_SETDESKWALLPAPER, 0, $file,
        SPIF_UPDATEINIFILE ) || die $^E;

}

1;
__END__

=pod

=head1 NAME

Win32::Wallpaper - Modify Win32 Wallpaper

=head1 SYNOPSIS

	use Win32::Wallpaper;

	wallpaper("image.bmp", "tile");

=head1 DESCRIPTION

With this Win32 module, you can set a new wallpaper image and style. 
Three styles are supported: center, stretch, and tile. Only Window BitMaP 
(BMP) images are supported at this time. 

You can also get the current wallpaper by calling the function without 
parameters. For example:

	my $current_wallpaper = wallpaper();
	
=head1 NOTES

This will probably be the last release of this module, as I continue 
working on a module that will support the activedesktop interface.

=head1 AUTHOR

Mike Accardo <mikeaccardo@yahoo.com>

=head1 COPYRIGHT

   Copyright (c) 2003, Mike Accardo. All Rights Reserved.
 This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License

=cut
