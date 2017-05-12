package Tk::ColourChooser ;    # Documented at the __END__.
#use Data::Dumper;

# $Id: ColourChooser.pm,v 1.32 2000/05/05 16:40:27 root Exp $

require 5.004 ;

use strict ;
use warnings;

use Carp ;
use Symbol ;
use Tk ;

require Tk::Toplevel ;

use vars qw( $VERSION @ISA %Translate ) ;

$VERSION = '1.52';

@ISA = qw( Tk::Toplevel ) ;

Construct Tk::Widget 'ColourChooser' ;

# Global hashes available to all instances
my( %Name2hex, %Hex2name ) ;
my $Loaded ; # Flag indicating whether we're read the colour data or not.


#############################
sub Populate { 
    my( $win, $args ) = @_ ;

    $win->{-language} = delete $args->{-language} || 'en' ; 
    $win->{-showhex}  = delete $args->{-showhex}  || 0 ;
    $win->{-language} = 'en' if $win->{-language} eq 'english' ; # Backward compatibility.
    $args->{-title}   = $Translate{$win->{-language}}{-title} 
                        unless defined $args->{-title} ;
    my $hexonly       = delete $args->{-hexonly} ;
    $win->{HEX_ONLY}  = defined $hexonly and $hexonly ? 1 : 0 ;
    my $transparent   = delete $args->{-transparent} ;
    my $colour        = delete $args->{-colour} ;

    $win->SUPER::Populate( $args ) ;

    $win->withdraw ;
    $win->iconname( $args->{-title} ) ;
    $win->protocol( 'WM_DELETE_WINDOW' => sub { } ) ;
    $win->transient( $win->parent ) ;
    
    &_read_rgb( $win ) ;
    
    # Create listbox.
    my $Frame     = $win->Frame()->pack( -fill => 'x' ) ;
    $win->{COLOUR_FRAME} = $Frame ; 
    my $scrollbar = $Frame->Scrollbar->pack( -side => 'right', -fill => 'y' ) ;
    my $list      = $Frame->Listbox(
        -height          => 1,
        -selectmode      => 'single',
        -background      => 'white',
        -exportselection => 0,
        )->pack( -expand => 'ns', -fill => 'x', -pady => 20, -padx => 10 ) ;
    $list->configure( 
        -yscrollcommand => [ \&_listbox_scroll, $scrollbar, $list, $win ] ) ;
    $scrollbar->configure( -command => [ $list => 'yview' ] ) ;

    $list->insert( 'end', sort { lc $a cmp lc $b } keys %Name2hex ) ;

    $list->bind( '<Down>', [ \&_set_colour_from_list, $win ] ) ;
    $list->bind( '<Up>',   [ \&_set_colour_from_list, $win ] ) ;
    $list->bind( '<1>',    [ \&_set_colour_from_list, $win ] ) ;

    $win->{COLOUR_LIST} = $list ;

    &_set_list( $win, 0 ) ;

    # Colour sliders.
    foreach my $colour ( qw( red green blue ) ) { 
        my $scale = $win->Scale(
            -orient       => 'horizontal',
            -from         => 0,
            -to           => 255,
            -tickinterval => 25,
            -label        => $Translate{$win->{-language}}{'-' . $colour},
            -fg           => "dark$colour",
            '-length'     => 300,
            )->pack( -fill => 'x' ) ;
        $win->{'-' . $colour} = 0 ;
        $scale->configure( 
            -variable => \$win->{'-' . $colour}, 
            -command  => [ \&_set_colour, $win ],
            ) ;
    }
 
    # Create buttons.
    $Frame  = $win->Frame()->pack() ;
    my $column = 0 ;
    foreach my $button ( $Translate{$win->{-language}}{-ok},
                         $Translate{$win->{-language}}{-transparent},
                         $Translate{$win->{-language}}{-cancel} ) {
        next if $button eq $Translate{$win->{-language}}{-transparent} and 
                defined $transparent and
                        $transparent == 0 ;

        my $Button = $Frame->Button(
            -text      => $button,
            -underline => 0,
            -width     => 10,
            -command   => [ \&_close, $win, $button ],
            )->grid( -row => 0, -column => $column++, -pady => 5 ) ;
            
        my $char = lc substr( $button, 0, 1 ) ;

        $win->bind( "<Control-${char}>", [ \&_close, $win, $button ] ) ;
        $win->bind( "<Alt-${char}>",     [ \&_close, $win, $button ] ) ;
        $win->bind( "<${char}>",         [ \&_close, $win, $button ] ) ;
    }

    $win->bind( "<Return>", 
        [ \&_close, $win, $Translate{$win->{-language}}{-ok} ] ) ;
    $win->bind( "<Escape>", 
        [ \&_close, $win, $Translate{$win->{-language}}{-cancel} ] ) ;

    # Set initial colour if given.
    if( defined $colour ) {
        if( lc $colour eq 'none' ) {
            $win->{-red} = $win->{-green} = $win->{-blue} = 0 ;
        }
        elsif( $colour =~ 
            /^#?([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/o ) {
            $win->{-red}   = hex $1 ; 
            $win->{-green} = hex $2 ; 
            $win->{-blue}  = hex $3 ;
        }
        else {
            my $hex        = $Name2hex{$colour} ;
            if (defined $hex) {
                $win->{-red}   = hex substr( $hex, 0, 2 ) ; 
                $win->{-green} = hex substr( $hex, 2, 2 ) ; 
                $win->{-blue}  = hex substr( $hex, 4, 2 ) ;
            }
        }   
        &_set_colour( $win ) ; 
    }
 
    $win->{-colour} = undef ;
}

#############################
sub _find_rgb {

    if ($ENV{RGB_TEXT}) {
        return $ENV{RGB_TEXT} if -r $ENV{RGB_TEXT};
    }
    else {
        foreach my $file (
            '/usr/local/lib/X11/rgb.txt',       '/usr/lib/X11/rgb.txt', 
            '/usr/local/X11R5/lib/X11/rgb.txt', '/X11/R5/lib/X11/rgb.txt',
            '/X11/R4/lib/rgb/rgb.txt',          '/usr/openwin/lib/X11/rgb.txt',
            '/usr/X11R6/lib/X11/rgb.txt',
            ) {
            return $file if -e $file ;
        }
    }
    carp "Failed to find `rgb.txt', set \$ENV{RGB_TEXT} to the filename" ;

    return;
}

#############################
sub _read_rgb {
    my $win = shift ;

    return if $Loaded ;
    $Loaded = 1 ;

    my $file = &_find_rgb ;

    if( defined $file ) {
        $Name2hex{'_Unnamed'} = '000000' ;
        $Hex2name{'000000'}  = '_Unnamed' ;
        my $fh = gensym ;
        open $fh, $file or croak "Failed to open `$file': $!" ;
        local $_ ;
        while( <$fh> ) {
            chomp ;
            my @array = split ; 
            if( scalar @array == 4 ) {
                my $hex = sprintf "%02X%02X%02X", @array[0..2] ;
                # We only use the first name for a given colour.
                if( not exists $Name2hex{$array[3]} ) {
                    $Name2hex{$array[3]} = $hex ;
                    $Hex2name{$hex}      = $array[3] ;
                }
            }
        }
        close $fh or carp "Failed to close `$file': $!" ;
    }
}

#############################
sub _listbox_scroll {
    my( $scrollbar, $list, $win, @args ) = @_ ;

    $scrollbar->set( @args ) ;
    my $index = int( $list->size * $args[0] ) ;
    $list->activate( $index ) ;
    $list->selectionSet( $index ) ;
}

#############################
sub _set_colour {
    my $win = shift ;

    my $hex = sprintf "%02X%02X%02X", 
                $win->{-red}, $win->{-green}, $win->{-blue} ;

    my $index = 0 ;
    if( exists $Hex2name{$hex} ) {
        my $list = $win->{COLOUR_LIST} ;
        for( $index = 0 ; $index < $list->size ; $index++ ) {
            last if $list->get( $index ) eq $Hex2name{$hex} ;
        }                    
    }
    &_set_list( $win, $index ) ;

    &_update_colour( $win, $hex ) ; 
}

#############################
sub _set_colour_from_list {
    my( $list, $win ) = @_ ;

    $list->selectionSet( 'active' ) ;
    my $colour     = $list->get( 'active' ) ;
    my $hex        = $Name2hex{$colour} ;
    $win->{-red}   = hex substr( $hex, 0, 2 ) ; 
    $win->{-green} = hex substr( $hex, 2, 2 ) ; 
    $win->{-blue}  = hex substr( $hex, 4, 2 ) ; 

    &_update_colour( $win, $hex ) ; 
}


#############################
sub _update_colour {
    my( $win, $hex ) = @_ ;

    if( $win->{-showhex} ) {
        my $title = $win->cget( -title ) ;
        $title = substr( $title, 0, index( $title, ' -' ) ) ;
        $win->configure( -title, "$title - #$hex" ) ;
    }
    $win->{COLOUR_FRAME}->configure( -bg => "#$hex" ) ;
}


#############################
sub _set_list {
    my( $win, $index ) = @_ ;

    my $list = $win->{COLOUR_LIST} ;
    $list->activate( $index ) ;
    $list->see( $index ) ;
    $list->selectionSet( $index ) ;
}

#############################
sub Show {
    my $win = shift ;

    $win->Popup() ; 

    my $list = $win->{COLOUR_LIST} ;
    $list->focus ;

    $win->waitVariable( \$win->{-colour} ) ;
    $win->withdraw ;

    $win->{-colour} ;
}

#############################
sub _close {

    my $win ;
    while( ref $_[0] ) {
        $win = shift ;
        last if ref $win =~ /ColourChooser/o ;
    }
    my $button = shift ;

    if( $button eq $Translate{$win->{-language}}{-transparent} ) {
        $win->{-colour} = 'None' ;
    }
    elsif( $button eq $Translate{$win->{-language}}{-cancel} ) {
        $win->{-colour} = '' ;
    }
    else {
        my $hex = sprintf "%02X%02X%02X", 
                    $win->{-red}, $win->{-green}, $win->{-blue} ;
        if( exists $Hex2name{$hex} and not $win->{HEX_ONLY} ) {
            $win->{-colour} = $Hex2name{$hex} ;
        }
        else {
            $win->{-colour} = "#$hex" ;
        }
    }

    $win->{-colour} ;
}

#############################
BEGIN {
    %Translate = (
        'de' => {
            -title       => 'Farbe Chooser',
            -red         => 'Rot',
            -blue        => 'Blau',
            -green       => 'Grün',
            -ok          => 'OK',
            -transparent => 'Transparent',
            -cancel      => 'Löschen',
            },
        'en' => {
            -title       => 'Colour Chooser',
            -red         => 'Red',
            -blue        => 'Blue',
            -green       => 'Green',
            -ok          => 'OK',
            -transparent => 'Transparent',
            -cancel      => 'Cancel',
            },
        'fr' => {
            -title       => 'Couleur Chooser',
            -red         => 'Rouge',
            -blue        => 'Bleu',
            -green       => 'Vert',
            -ok          => 'OK',
            -transparent => 'Transparent',
            -cancel      => 'Annulent',
            },
         ) ;
}

1 ;

__END__

=head1 NAME

ColourChooser - Perl/Tk module providing a Colour selection dialogue box.

=head1 SYNOPSIS

    use Tk::ColourChooser ; 

    my $col_dialog = $Window->ColourChooser ;
    my $colour     = $col_dialog->Show ;
    if( $colour ) {
        # They pressed OK and the colour chosen is in $colour - could be
        # transparent which is 'None' unless -transparent is set.
    }
    else {
        # They cancelled.
    }

    # May optionally have the colour initialised.
    my $col_dialog = $Window->ColourChooser( -colour => 'green' ) ;
    my $col_dialog = $Window->ColourChooser( -colour => '#0A057C' ) ;

    # The title may also be overridden; and we can insist that only hex values
    # are returned rather than colour names. We can disallow transparent.
    my $col_dialog = $Window->ColourChooser( 
                        -language    => 'en', # Or 'de' or 'fr'.
                        -title       => 'Select a colour',
                        -colour      => '0A057C',
                        -transparent => 0,
                        -hexonly     => 1,
                        -showhex     => 1,
                        ) ;

=head1 DESCRIPTION

ColourChooser is a dialogue box which allows the user to pick a colour from
the list in rgb.txt (supplied with X Windows), or to create a colour by
setting RGB (red, green, blue) values with slider controls.

You can scroll through all the named colours by using the <Down> and <Up>
arrow keys on the keyboard or by clicking the mouse on the scrollbar and then
clicking the colour list.

=head2 Options

=over 4

=item C<-language>
This is optional. Default is `en'. This option allows you to set the language
for the title and labels. Valid values are C<en> (english), C<de> (german),
C<fr> (french) and C<english> (for backward compatibility) which is also the
default. Translations are by Babelfish. Other languages will be added if
people provide translations.

=item C<-title>  
This is optional and allows you to set the title. Default is 'Colour Chooser'
in the C<-language> specified.

=item C<-colour> 
This is optional and allows you to specify the colour that is shown when the
dialogue is invoked. It may be specified as a colour name from rgb.txt or as a
six digit hex number with an optional leading hash, i.e. as 'HHHHHH' or
'#HHHHHH'. Default is 'black'.

=item C<-hexonly>
This is optional. If set to 1 it forces the ColourChooser to only return
colours as hex numbers in Tk format ('#HHHHHH'); if set to 0 it returns
colours as names if they are named in rgb.txt, and as hex numbers if they have
no name. Transparent is always returned as 'None' however. Default is 0.

=item C<-transparent>
This is optional. If set to 0 it stops ColourChooser offering the Transparent
button so that only valid colours may be chosen - or cancel. Default is 1.

=item C<-showhex>
This is optional. If set to 1 it shows the hex value of the colour in the
title bar. Default is 0.

=back

The user has three options: 

=head2 OK

Pressing OK will return the selected colour, as a name if it has one or as an
RGB value if it doesn't. (Colours which do not have names are listed as
'Unnamed' in the colour list box.) If the C<-hexonly> option has been specified
the colour is always returned as a Tk colour hex value, i.e. in the form
'#HHHHHH' except if Transparent is chosen in which case 'None' is returned.

OK is pressed by a mouse click or <Return> or <o> or <Control-o> or <Alt-o>.

=head2 Transparent

Pressing Transparent will return the string 'None' which is xpm's name for
transparent.

Transparent is pressed by a mouse click or <t> or <Control-t> or <Alt-t>.

=head2 Cancel

Pressing Cancel will return an empty string.

Cancel is pressed by a mouse click or <Escape> or <c> or <Control-c> or
<Alt-c>. (Note that if the language is not english then the letter to press
will be the first letter of the translation of the word 'Cancel'.

=head1 INSTALLATION

ColourChooser.pm should be placed in any Tk directory in any lib directory in
Perl's %INC path, for example, '/usr/lib/perl5/Tk'.

ColourChooser looks for the file rgb.txt on your system - if it can't find it
you will only be able to specify colours by RGB value.
Or you can set the environment variable RGB_TEXT to the filename.

=head1 METHODS

=over 4

=item Populate

Inherited from Tk::Toplevel

=item Show

Inherited from Tk::Toplevel

=back

=head1 BUGS

Does almost no error checking.

Can be slow to load because rgb.txt is large; however we now load a single
instance of the colour names when the module is first used and these names are
then shared.

If you scroll the list by keyboard or use the mouse to move the colour sliders
the colour updates as you go; but if you use the mouse on the scrollbar you
must click the colour name box for the colour to update. I don't know why this
is and any advice on how to fix it would be welcome.

=head1 AUTHOR

Tina Mueller

=head1 ORIGINAL AUTHOR

This module was developed by Mark Summerfield <summer@perlpress.com> until version 1.50.

The code draws from Stephen O. Lidie's work.

=head1 COPYRIGHT

Copyright (c) Mark Summerfield 1999-2000. All Rights Reserved.

This module may be used/distributed/modified under the LGPL.

=cut

