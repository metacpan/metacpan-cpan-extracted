package GD::RPPNG;

# Author: Pascal Gloor pascal.gloor@spale.com
# Date: 11 Oct 2003

require 5.004;
require GD;

use strict;
use warnings;
use GD 2.11;

our $VERSION = '0.9';

############# Code Begin

# Turn off buffering
$|=1;

# Definition of the main hash
my %opt;

# Declaration of new object with data types defined and blessed for use
sub new
{
    my $package = shift;
    my $object = { myimage => [] };
    my $bless = bless($object, $package);
    _defaults($bless);
    return $bless;
}

# Setting all options to their default value
sub _defaults
{
    my $self = shift;
    $opt{$self}{xsize}               = 400;
    $opt{$self}{ysize}               = 75;
    $opt{$self}{charset}             = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789%&#$@';
    $opt{$self}{codelen}             = 8;
    $opt{$self}{colors}              = 1;
    $opt{$self}{fontminpt}           = 12;
    $opt{$self}{fontmaxpt}           = 28;
    $opt{$self}{xlinesfactor}        = 10;
    $opt{$self}{ylinesfactor}        = 10;
    $opt{$self}{ydivert}             = 10;
    $opt{$self}{angle}               = 45;
    $opt{$self}{transparent}         = 0;
    $opt{$self}{debugcode}           = 0;
    @{$opt{$self}{bgcolor}}          = ( 255, 255, 255 );
    @{$opt{$self}{fgcolor}}          = ( 0, 0, 0 );
    $opt{$self}{code}                = '';

    undef @{$opt{$self}{ttf}};
}

# User overriding default options
sub Config
{
    my $self = shift;
    my @options = @_ if (@_);

    while(@options)
    {
        my $name = shift(@options);
        $name =~ tr/[A-Z]/[a-z]/;
        my $value = shift(@options);
        if ( $name =~ /bgcolor|fgcolor/ )
        {
            $value =~ s/(..)(..)(..)/$1 $2 $3/;
            my ($r,$g,$b) = split(/ /,$value);
            @{$opt{$self}{$name}} = ( hex($r), hex($g), hex($b) );
        }
        else
        {
            $opt{$self}{$name}=$value;
        }
    }
}

# Adding a TrueType Font
sub AddFonts
{
    my $self = shift;
    my $font = shift;
    if ( -r "$font" )
    {
        push(@{$opt{$self}{ttf}},$font);
    }
    else
    {
        warn "Could not read TrueType Font \"$font\"\n";
    }
}

# Generating a random password
sub _gencode
{
    my $self = shift;
    my $len = length($opt{$self}{charset});
    my @charset;
    $opt{$self}{code} = '';

    foreach ( split(//,$opt{$self}{charset}) )
    {
        push(@charset,$_);
    }

    for ( 1 .. $opt{$self}{codelen} )
    {
        $opt{$self}{code} .= $charset[(int(rand(length($opt{$self}{charset}))))];
    }
}

# Generating the image
sub GenImage
{

    my $self = shift;

    # generate a random password if not set
    if ( !length($opt{$self}{code}) )
    {
        _gencode($self);
    }

    my $fonts = @{$opt{$self}{ttf}};

    # create base image
    my $image = new GD::Image($opt{$self}{xsize},$opt{$self}{ysize});

    # setting back/fore-ground colors
    my $fgcolor = $image->colorAllocate(@{$opt{$self}{fgcolor}});
    my $bgcolor = $image->colorAllocate(@{$opt{$self}{bgcolor}});

    # setting background as transparent if requested
    if ( $opt{$self}{transparent} )
    {
        $image->transparent($bgcolor);
    }

    my @colors;

    # adding some colors to the palette
    if ( $opt{$self}{colors} )
    {
        foreach(1..50)
        {
            push(@colors,$image->colorAllocate(
                int(rand(200)),
                int(rand(200)),
                int(rand(200)) ) );
        }
    }

    # setting the background
    $image->filledRectangle(0,0,$opt{$self}{xsize}-1,$opt{$self}{ysize}-1,$bgcolor);

    my $ncolors = @colors;
    my $pos = 10;

    # loop on each code char
    foreach(split(//,$opt{$self}{code}))
    {

        # setting font color and deviation
        my $color = $fgcolor;
        my $margin = int( $opt{$self}{ysize} * $opt{$self}{ydivert} / 100 );
        my $dev   = int( rand( $margin ) + ( ( $opt{$self}{ysize} - $margin ) / 2 ) );

        # re-setting color
        if ( $opt{$self}{colors} )
        {
            $color = $colors[int(rand($ncolors-2))+2];
        }

        # printing the char
        if ( @{$opt{$self}{ttf}} )
        {
            my $pt = int( rand( $opt{$self}{fontmaxpt} - $opt{$self}{fontminpt} ) + $opt{$self}{fontminpt} );
            my $angle = 0;
            if ( $opt{$self}{angle} )
            {
                $angle = sprintf("%0.2f", rand($opt{$self}{angle}/180*3.14) - ( $opt{$self}{angle}/360*3.14) );
            }

            $image->stringFT(
                $color,
                @{$opt{$self}{ttf}}[int(rand($fonts))],
                $pt,
                $angle,
                $pos,
                $dev+($pt/2),
                $_
            );
        }
        else
        {
            $image->string(gdGiantFont,$pos,$dev,$_,$color);
        }

        # moving the position forward for the next char
        $pos += int($opt{$self}{xsize}/length($opt{$self}{code}));
    }


    # printing the X lines
    for ( 1 .. ( $opt{$self}{xsize} * $opt{$self}{xlinesfactor} / 100 ) )
    {
        my $pos = int( rand($opt{$self}{xsize} ) );
        my $color = $fgcolor;

        if ( $opt{$self}{colors} )
        {
            $color = $colors[int(rand($ncolors))];
        }

        $image->line($pos,0,$pos,$opt{$self}{ysize},$color);
    }

    # printing the Y lines
    for ( 1 .. ( $opt{$self}{ysize} * $opt{$self}{ylinesfactor} / 100 ) )
    {
        my $pos = int( rand($opt{$self}{ysize} ) );
        my $color = $fgcolor;

        if ( $opt{$self}{colors} )
        {
            $color = $colors[int(rand($ncolors))];
        }

        $image->line(0,$pos,$opt{$self}{xsize},$pos,$color);
    }

    # adding the code to the image if debugcode enabled
    if ( $opt{$self}{debugcode} )
    {
        $image->filledRectangle(0,0,length($opt{$self}{code})*11+10,15,$fgcolor);
        $image->string(gdMediumBoldFont,0,0,"Code: $opt{$self}{code}",$bgcolor);
    }

    # return the code and the generated image
    return (
        $opt{$self}{code},
        $image->png,
    );

    delete $opt{$self};
}

############# Code End

1;
__END__


=head1 NAME

GD::RPPNG - Package for generating human only readable images

=head1 DESCRIPTION

GD::RPPNG - Package for generating human-only readable images

The GD::RPPNG (Random Password PNG) module was created to provide an easy access
to human-only readable images. This is very usefull to avoid automatic processing
of authentication. (ie: subscription to free email accounts).

=head1 SYNOPSIS

    use GD::RPPNG;

    # create a new image
    $myimage = new GD::RPPNG;

    # configure the image
    $myimage->Config (
        Xsize            => 400,
        Ysize            => 75,
        CharSet          => 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789',
        CodeLen          => 8,
        FontMinPT        => 12,
        FontMaxPT        => 28,
        yDivert          => 10,
        Angle            => 45,
        XLinesFactor     => 10,
        YLinesFactor     => 10,
        Transparent      => 0,
        Colors           => 1,
        bgColor          => 'FFFFFF',
        fgColor          => '000000',
        Code             => 'mypasswd',
        DebugCode        => 0,
        );

    # add TrueType(C) fonts
    $myimage->AddFonts (
        '/usr/X11R6/lib/X11/fonts/truetype/arial.ttf',
        '/usr/X11R6/lib/X11/fonts/truetype/courier.ttf',
    );


    # generate the image
    ( $mycode, $mypng ) = $image->GenImage();

=head1 METHODS

=over 4

=item $object = new GD::RPPNG

Creates a new object and sets all default options (see next METHOD for detailed description):

    Xsize         => 400
    Ysize         => 75
    CharSet       => 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    CodeLen       => 8
    FontMinPT     => 12
    FontMaxPT     => 28
    yDivert       => 10
    Angle         => 45
    XLinesFactor  => 10
    YLinesFactor  => 10
    Transparent   => 0
    Colors        => 1
    bgColor       => 'FFFFFF'
    fgColor       => '000000'
    Code          => ''
    DebugCode     => 0

=item $object->Config()

With this method you can override all the default options shown above.

'Xsize' defines the width of the image in pixels. here's an example:

    $object->Config( Xsize => 400 )

'Ysize' defines the height of the image in pixels. here's an example:

    $object->Config( Ysize => 75 )

'CharSet' defines the list of chars which may be used to generate the "code". Depending on the fonts you will use, its recommended to skip I,L,0,O and 1 as they might be confusing. here's an example:

    $object->Config( CharSet => 'ABCDEFGHJKMNOPQRSTUVWXYZ23456789%$#@' )

'CodeLen' defines the number of chars to be used to generate the "code". here's an example:

    $object->Config( CodeLen => 8 )

'FontMinPT' defines the minimal font size to use. here's an example:

    $object->Config( FontMinPT => 12 )

'FontMaxPT' defines the maximal font size to use. here's an example:

    $object->Config( FontMaxPT => 24 )

'yDivert' defines, in percent of the image height, the vertical range in which chars may be printed. here's an example:

    $object->Config( yDivert => 10 )

'Angle' defines, in degree, the angle range in which chars may be rotated. As an example, 90 will allow chars to be rotated from -45 to +45 degrees. here's an example:

    $object->Config( Angle => 45 )

'XLinesFactor' defines, in percent, the amount of horizontal lines to be draw. As an example, 50 on a 400 pixels wide image will draw about 200 lines. here's an example:

    $object->Config( XLinesFactor => 20 )

'YLinesFactor' defines, in percent, the amount of vertical lines to be draw. As an example, 50 on a 100 pixels high image will draw about 50 lines. here's an example:

    $object->Config( YLinesFactor => 20 )

'Transparent' defines if the background has to be transparent or not. here's an example:

    $object->Config( Transparent => 0 )

'Colors' defines if the image will use random colors or not. here's an example:

    $object->Config( Colors => 1 )

'bgColor' defines, in RRGGBB (hex) format, the background color to use. here's an example:

    $object->Config( bgColor => 'FFFFFF' )

'fgColor' defines, in RRGGBB (hex) format, the foreground color to use. here's an example:

    $object->Config( fgColor => '000000' )

'Code' defines the "code". If not set, a random code will be generated using the CharSet and the CodeLen options. If set, CharSet and CodeLen will be ignored. here's an example:

    $object->Config( Code => 'q12we34r' )

B<NOTE: You may specify multiple options at the same time> here's an example:

    $object->Config(
    	Xsize => 400,
    	Ysize => 75,
    	Colors => 1
   );

'DebugCode' defines if the "code" will be displayed on the top left of the image or not. NOTE: Do only use this for debugging purpose! here's an example:

=item $object->AddFonts()

With this method you can add TrueType fonts. Those fonts will be randomly used to draw the "code" on the image. here's an example:

    $object->AddFonts(
    	'/usr/X11R6/lib/X11/fonts/truetype/arial.ttf',
    	'/usr/X11R6/lib/X11/fonts/truetype/courier.ttf'
    );

=item $object->GenImage()

With this method you will generate the image. The method will return the "code" and the image in an array. here's an example:

    ($mycode, $myimage) = $object->GenImage();
    print "Content-type: image/png\n\n";
    print $myimage;

=back

=head1 EXAMPLES

Many examples may be found at L<http://www.spale.com/gd-rppng>

=head1 AUTHOR

Pascal Gloor E<lt>spale@cpan.orgE<gt>

The GD::RPPNG module was written by Pascal Gloor.

=head1 VERSION

Version 0.9, released on 11 Dec 2003.

=head1 COPYRIGHT

GD::RPPNG Copyright (C) 2003 Pascal Gloor E<lt>spale@cpan.orgE<gt>

GD Copyright (C) 1995-2000, Lincoln D. Stein.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<GD::RPPNG>

=cut
